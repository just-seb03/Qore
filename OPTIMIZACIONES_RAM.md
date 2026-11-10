# ⚡ Plan Integral de Optimización de Memoria RAM — Project Anima

> **Objetivo:** Reducir drásticamente el consumo de memoria RAM (tanto en el *Dart Heap* como en la memoria nativa *Graphic/ExoPlayer Heap*) garantizando al mismo tiempo una fluidez ininterrumpida de **60 FPS / 120 FPS** sin caídas de cuadros (*zero jank*).

---

## 📊 Diagnóstico General del Proyecto

Tras una inspección profunda de todos los módulos del proyecto (`core/`, `components/`, `features/`, `controls/`, `android/`), se han identificado los principales factores de sobreconsumo de RAM:

| Categoría | Causa Principal | Impacto Estimado en RAM |
| :--- | :--- | :--- |
| **1. Flutter ImageCache** | `PaintingBinding.imageCache` configurado a **250 MB** y 600 imágenes. | **~150 – 200 MB** |
| **2. Sobredimensionado de Bitmaps** | `AnimaArtworkImage` calcula `cacheWidth: 1600` para tarjetas de lista/grid donde `width: double.infinity`. | **~60 – 100 MB** |
| **3. Falta de `ResizeImage`** | `MaterialArtistAvatar` carga fotos originales (cámara de 12–48 MP) directamente sin reescalar. | **~20 – 50 MB** |
| **4. Carga de Tablas Completas** | Múltiples servicios ejecutan `dao.getAllSongs()` cargando miles de objetos `Song` en heap de Dart. | **~15 – 35 MB** |
| **5. Exceso de Buffering de Audio** | `AndroidLoadControl` mantiene **50 segundos** de audio pre-bufferizado en RAM nativa para archivos locales. | **~25 – 45 MB** |
| **6. Ruptura de Virtualización** | Múltiples `ListView.builder` usan `shrinkWrap: true`, forzando a Flutter a instanciar todos los ítems. | **~20 – 40 MB** + Jank |
| **7. GC Churn en Animaciones** | Creación de nuevos `Path()`, `LinearGradient().createShader()` y `List.unmodifiable()` en cada frame (60/120 Hz). | GC Spikes + Micro-tirones |
| **8. Tickers por Celda** | `LiquidTrackGestureWrapper` inicializa 3 `AnimationController`s por cada canción en lista. | **~10 – 20 MB** + Sobrecarga de Tickers |

---

## 1. 🖼️ Gestión de Caché de Imágenes (`ImageCache`)

### 1.1 Reducción del búfer global de rasterizado
En [lib/main.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/main.dart#L36-L39):
```dart
// ❌ ESTADO ACTUAL (lib/main.dart):
// Permite hasta 250 MB de texturas RGBA descomprimidas en memoria gráfica
PaintingBinding.instance.imageCache.maximumSizeBytes = 250 * 1024 * 1024;
PaintingBinding.instance.imageCache.maximumSize = 600;
```

**Problema:** Un teléfono móvil estándar asigna entre 192 MB y 256 MB a la app. Un ImageCache de 250 MB empuja al sistema a situaciones de *Low Memory Killer (LMK)* y fuerza recolecciones de basura agresivas.

```dart
// ✅ OPTIMIZACIÓN RECOMENDADA:
// Suficiente para 60/120 FPS sin retraso de disco, usando solo una fracción de RAM
PaintingBinding.instance.imageCache.maximumSizeBytes = 45 * 1024 * 1024; // 45 MB
PaintingBinding.instance.imageCache.maximumSize = 100; // 100 imágenes
```

### 1.2 Liberación reactiva de memoria al minimizar la app
En [lib/main.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/main.dart): escuchar el ciclo de vida del sistema operativo (`AppLifecycleListener` / `WidgetsBindingObserver`) para purgar texturas vivas no visibles cuando la app pasa a segundo plano:

```dart
AppLifecycleListener(
  onPause: () {
    // Libera texturas GPU de imágenes que ya no están visibles en pantalla
    PaintingBinding.instance.imageCache.clearLiveImages();
  },
  onHide: () {
    PaintingBinding.instance.imageCache.clearLiveImages();
  },
);
```

---

## 2. 🎨 Decodificación y Downsampling de Portadas (`AnimaArtworkImage`)

### 2.1 Corrección del cálculo de `cacheWidth` y `cacheHeight`
En [lib/core/artwork/widgets/anima_artwork_image.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/core/artwork/widgets/anima_artwork_image.dart#L106-L127):

**Problema:**
En `LibraryAlbumCard` y `SpaceTilesGrid`, el widget se invoca con `width: double.infinity`. La condición `hasFiniteWidth` evalúa a `false`, por lo que el código cae en:
```dart
final screenWidth = MediaQuery.maybeSizeOf(context)?.width ?? 400.0;
cacheSize = (screenWidth * dpr).round().clamp(800, 1600); // ❌ ¡Decodifica a 1600x1600 px!
```
Una imagen de 1600×1600 en formato RGBA ocupa **10.24 MB** en memoria descomprimida. 10 portadas en un grid consumen **102.4 MB**.

**Solución:**
1. Para listas y rejillas de 2 columnas, el ancho visible por tarjeta es aproximadamente `(screenWidth - padding) / 2`.
2. Limitar el tamaño máximo de decodificación a los píxeles físicos reales que ocupará en pantalla:

```dart
// ✅ OPTIMIZACIÓN EN AnimaArtworkImage:
final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.5;
final int targetCacheSize;

if (isThumbnail) {
  // Miniaturas de canciones en lista (48–56 dp -> 120–160 px reales)
  final double base = (width != null && width!.isFinite) ? width! : 48.0;
  targetCacheSize = (base * dpr).round().clamp(96, 200);
} else {
  // Tarjetas de álbum o rejilla (160–200 dp -> 360–500 px reales)
  if (width != null && width!.isFinite) {
    targetCacheSize = (width! * dpr).round().clamp(256, 720);
  } else {
    // Si es double.infinity en grid de 2 columnas o reproductor:
    final screenWidth = MediaQuery.maybeSizeOf(context)?.width ?? 400.0;
    // Máximo 500 px para tarjetas, 800 px solo para Player full-screen
    targetCacheSize = (screenWidth * 0.5 * dpr).round().clamp(300, 720);
  }
}
```

3. Cambiar `filterQuality` de `FilterQuality.high` (cúbica costosa) a `FilterQuality.medium` (bilineal con mipmaps) o `FilterQuality.low`:
```dart
filterQuality: FilterQuality.medium, // Mantiene la nitidez sin el impacto de memoria de alta calidad
```

---

## 3. 👤 Reescalado de Fotos de Artista (`MaterialArtistAvatar`)

En [lib/features/search/components/common/material_artist_avatar.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/features/search/components/common/material_artist_avatar.dart#L62-L66):

```dart
// ❌ ESTADO ACTUAL:
CircleAvatar(
  radius: radius,
  backgroundColor: effectiveBg,
  backgroundImage: FileImage(File(customPath)), // Decodifica resolución completa del archivo
);
```

**Problema:** Si el usuario selecciona una foto de galería de 12 megapíxeles (ej. 4000×3000), `FileImage` la decodifica completa ocupando **48 MB de RAM** para un círculo de solo 26 dp.

```dart
// ✅ OPTIMIZACIÓN RECOMENDADA:
final pixelSize = (radius * 2 * (MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.5)).round();

CircleAvatar(
  radius: radius,
  backgroundColor: effectiveBg,
  backgroundImage: ResizeImage(
    FileImage(File(customPath)),
    width: pixelSize,
    height: pixelSize,
    policy: ResizeImagePolicy.fit,
  ),
);
```

---

## 4. 🗄️ Optimización de Consultas SQLite y Eliminación de `getAllSongs()`

### 4.1 `TodaySelectionService`: Consulta aleatoria en SQL
En [lib/core/selection/today_selection_service.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/core/selection/today_selection_service.dart#L43-L64):

**Problema:**
```dart
// ❌ Carga las 10,000 canciones completas de la base de datos a memoria para elegir 20
final allSongs = await dao.getAllSongs();
final shuffled = List.of(allSongs);
shuffled.shuffle(rng);
_cachedTodaySongs = shuffled.take(20).toList();
```

**Solución:**
Crear un método en `SongDao` que traiga únicamente 20 filas mediante SQL:
```dart
// ✅ OPTIMIZACIÓN EN SongDao:
Future<List<Song>> getRandomDailySelection({required int seed, int limit = 20}) async {
  final db = await _appDatabase.database;
  // Selección pseudoaleatoria determinista basada en el ID y la semilla del día
  final results = await db.rawQuery('''
    SELECT * FROM songs 
    ORDER BY ((id * ? + 1013904223) & 0x7FFFFFFF) 
    LIMIT ?
  ''', [seed, limit]);
  return results.map((r) => Song.fromMap(r)).toList();
}
```
*Impacto:* Se pasa de deserializar 10.000 instancias de `Song` (con strings de título, artista, álbum, ruta) a solo 20 instancias. Ahorro inmediato de **10 – 25 MB de RAM**.

### 4.2 Desduplicación en `ArtworkService.preloadAlbumMappings`
En [lib/core/artwork/artwork_service.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/core/artwork/artwork_service.dart#L151-L186):

**Problema:**
Duplica la ruta del archivo en `_thumbnailCache` y `_coverCache` para **cada canción** del álbum. Si un álbum tiene 20 temas, se guardan 20 entradas idénticas en dos mapas en memoria.

**Solución:**
Indexar las carátulas únicamente a nivel de álbum (`albumKey -> coverPath`). Para obtener la carátula de una canción, consultar la clave del álbum en $O(1)$ sin duplicar claves por cada pista individual.

### 4.3 SQLite PRAGMAs para limitar la memoria de páginas
En [lib/core/database/app_database.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/core/database/app_database.dart#L65-L73):

```dart
// ✅ AÑADIR A _onConfigure:
await db.execute('PRAGMA cache_size = -2000'); // Limita el caché de páginas a 2 MB
await db.execute('PRAGMA temp_store = MEMORY');
await db.execute('PRAGMA mmap_size = 268435456'); // 256MB mmap para lecturas ultrarrápidas sin duplicar heap
```

---

## 5. 📜 Virtualización de Listas y Eliminación de `shrinkWrap: true`

`shrinkWrap: true` desactiva la virtualización de scroll de Flutter: obliga al motor a instanciar, medir y renderizar **todos los elementos de la lista simultáneamente** aunque no estén en pantalla.

### Archivos identificados con `shrinkWrap: true`:
1. [lib/features/album/components/album_tracks_section.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/features/album/components/album_tracks_section.dart#L66)
2. [lib/features/artist/components/artist_assorted_songs_section.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/features/artist/components/artist_assorted_songs_section.dart#L89)
3. [lib/features/artist/components/artist_top_tracks_section.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/features/artist/components/artist_top_tracks_section.dart#L50)
4. [lib/features/playlist/components/playlist_reorderable_song_list.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/features/playlist/components/playlist_reorderable_song_list.dart#L103)
5. [lib/features/playlist/screens/playlist_detail_screen.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/features/playlist/screens/playlist_detail_screen.dart#L550)
6. [lib/features/playlist/screens/playlist_edit_screen.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/features/playlist/screens/playlist_edit_screen.dart#L581)
7. [lib/features/search/components/sections/search_songs_section.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/features/search/components/sections/search_songs_section.dart#L60)

### Optimización:
- **Para listas pequeñas acotadas (≤ 5 elementos, como en Search):**
  Reemplazar `ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` por un simple `Column(children: [for (final s in songs) SearchSongTile(s)])`. Esto elimina completamente el overhead de `Scrollable`, `ScrollPosition` y `Viewport`.
- **Para listas medianas o grandes (Álbumes, Playlists, Artistas):**
  Migrar a `CustomScrollView` utilizando `SliverList.builder` o `SliverFixedExtentList` (cuando la altura del ítem es fija, ej. 64 dp). Con altura fija, Flutter calcula posiciones por multiplicación matemática sin necesidad de medir widgets en memoria.

---

## 6. 🎧 Reducción del Búfer Nativo de ExoPlayer (`AudioPlaybackBuffer`)

En [lib/core/playback/audio_playback_buffer.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/core/playback/audio_playback_buffer.dart#L28-L36):

```dart
// ❌ ESTADO ACTUAL:
androidLoadControl: AndroidLoadControl(
  minBufferDuration: Duration(seconds: 20),
  maxBufferDuration: Duration(seconds: 50), // 50s de audio local en memoria nativa
  bufferForPlaybackDuration: Duration(milliseconds: 200),
  bufferForPlaybackAfterRebufferDuration: Duration(milliseconds: 500),
  prioritizeTimeOverSizeThresholds: true,
  backBufferDuration: Duration(seconds: 5),
),
```

**Problema:** Al reproducir música almacenada localmente en la memoria flash del dispositivo, la latencia de lectura es de **0 ms** (no hay jitter de red). Mantener 50 segundos de audio descomprimido (especialmente en archivos FLAC a 24-bit 96/192 kHz o WAV) reserva entre **25 MB y 50 MB de memoria nativa**.

```dart
// ✅ OPTIMIZACIÓN RECOMENDADA PARA AUDIO LOCAL:
androidLoadControl: AndroidLoadControl(
  minBufferDuration: Duration(seconds: 5),
  maxBufferDuration: Duration(seconds: 12), // 12 segundos son más que suficientes para gapless 0ms
  bufferForPlaybackDuration: Duration(milliseconds: 150),
  bufferForPlaybackAfterRebufferDuration: Duration(milliseconds: 300),
  prioritizeTimeOverSizeThresholds: true,
  backBufferDuration: Duration(seconds: 3),
),
```
*Impacto:* Se conserva el cambio de pista instantáneo (*gapless 0 ms*) pero liberando **~30 MB de RAM nativa**.

---

## 7. ⏱️ Optimización de Animaciones y Reducción de Recolección de Basura (GC)

### 7.1 Reutilización de `Path` y Shaders en `_LiquidFillPainter`
En [lib/features/player/components/mini_player.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/features/player/components/mini_player.dart#L357-L398):

**Problema:**
En cada frame (60 a 120 veces por segundo):
- Se instancia `final Path backWavePath = Path();`
- Se instancia `final Path frontWavePath = Path();`
- Se crea `LinearGradient(...).createShader(liquidRect);`

Esto genera miles de objetos efímeros por minuto, forzando pausas del Garbage Collector (*GC pauses*) que se traducen en micro-tirones.

**Solución:**
Convertir el pintor para reutilizar instancias mutables de `Path`:
```dart
class _LiquidFillPainter extends CustomPainter {
  // Mantener paths estáticos o cacheados por instancia
  static final Path _backWavePath = Path();
  static final Path _frontWavePath = Path();

  @override
  void paint(Canvas canvas, Size size) {
    _backWavePath.reset();
    _frontWavePath.reset();
    // Dibujar sobre los paths existentes...
  }
}
```

### 7.2 Evitar `List.unmodifiable` por frame en `AmbientParticlesController`
En [lib/features/ambient_particles/controllers/ambient_particles_controller.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/features/ambient_particles/controllers/ambient_particles_controller.dart#L54):

```dart
// ❌ ESTADO ACTUAL (se invoca en cada frame de pintado a 60/120 Hz):
List<AmbientParticle> get particles => List.unmodifiable(_particles);
```
`List.unmodifiable()` reserva un nuevo objeto envoltorio de lista en **cada fotograma**.
**Solución:**
Exponer una vista inmutable persistente creada una sola vez:
```dart
// ✅ OPTIMIZACIÓN:
late final UnmodifiableListView<AmbientParticle> _particlesView = 
    UnmodifiableListView(_particles);

List<AmbientParticle> get particles => _particlesView;
```

---

## 8. 🎛️ Inicialización Perezosa (Lazy) en `LiquidTrackGestureWrapper`

En [lib/components/liquid_track_gesture_wrapper.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/components/liquid_track_gesture_wrapper.dart#L51-L67):

**Problema:**
Cada fila de canción inicializa tres `AnimationController`s (`_waveController`, `_fillController`, `_flashController`) en `initState`. Una lista de 80 canciones mantiene **240 controladores de animación** y sus respectivos listeners en memoria.

**Solución:**
Inicialización *Lazy On-Demand*:
- No crear los controladores en `initState`.
- Crearlos únicamente en `_onPointerDown` cuando el usuario pulsa y mantiene el dedo sobre la canción.
- Desecharlos (`dispose`) o resetearlos al levantar el dedo (`_onPointerUp`/`_onPointerCancel`).

---

## 9. 🔍 Optimización del Motor de Búsqueda Difusa (`FuzzySearchEngine`)

En [lib/core/search/fuzzy_search_engine.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/core/search/fuzzy_search_engine.dart#L38-L43):

### 9.1 Proyección Liviana del Diccionario
En lugar de cargar todos los objetos `Song` con todas sus cadenas:
```dart
// ❌ Carga toda la entidad Song en memoria:
final songs = await _songDao.getAllSongs();
_cachedSongs = songs;
```
Crear un modelo liviano `SearchSongDictionaryItem` con solo `(id, title, artist, album)` o consultar con un filtro previo en SQLite (`title LIKE '%query%'`) antes de aplicar la distancia Levenshtein.

### 9.2 Optimización de Matriz en `damerauLevenshteinDistance`
En [lib/core/search/fuzzy_search_engine.dart](file:///home/sebastian/Proyectos/Desarrollo/project_anima/lib/core/search/fuzzy_search_engine.dart#L57):
```dart
// ❌ Reserva una matriz 2D completa de listas en cada palabra evaluada:
final d = List.generate(sLen + 1, (_) => List.filled(tLen + 1, 0));
```
Se puede implementar el algoritmo con solo **dos buffers unidimensionales (`List<int>` de tamaño `tLen + 1`)** rotados, o un búfer preasignado reutilizable, reduciendo las reservas de memoria en un 90% durante la búsqueda en tiempo real.

---

## 10. ⚙️ Configuraciones de Compilación y Nivel de Sistema Operativo (Android)

### 10.1 ProGuard / R8 Shrinking & Resource Optimization
En [android/app/build.gradle.kts](file:///home/sebastian/Proyectos/Desarrollo/project_anima/android/app/build.gradle.kts):
Asegurar que la compilación `release` tenga activado el optimizador R8 y la reducción de recursos no utilizados:

```kotlin
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

### 10.2 Tree-shaking de Fuentes e Iconos
El paquete `material_symbols_icons` incluye fuentes muy extensas. Al compilar en producción, Flutter ejecuta `--tree-shake-icons` por defecto, pero es importante evitar referencias dinámicas a iconos por string para que el compilador descarte los glifos no utilizados.

---

## 📈 Resumen de Impacto Estimado

| Métrica | Antes de Optimizar | Con Optimizaciones Aplicadas | Reducción |
| :--- | :--- | :--- | :--- |
| **RAM en Reposo (Home / Space)** | ~180 – 260 MB | **~65 – 85 MB** | **-65%** |
| **RAM en Scroll Intenso (Library / Search)** | ~320 – 480 MB | **~90 – 120 MB** | **-72%** |
| **RAM en Reproducción Continua** | ~220 – 310 MB | **~80 – 105 MB** | **-66%** |
| **Frecuencia de Recolección (GC)** | Cada 1 – 3 seg (tirones) | Mínima / Estable | **Zero Jank** |
| **Tasa de Refresco** | 60/120 Hz con caídas | 60/120 Hz constante | **Fluidez Total** |

---

## 🚀 Plan de Implementación y Estado de Ejecución

1. **Parte 1 (Completado - Commit `c119dab`):**
   - Ajuste de `PaintingBinding.instance.imageCache` a 45 MB / 100 ítems y purga automática de texturas en background.
   - Downsampling 1:1 DPR en `AnimaArtworkImage` y `MaterialArtistAvatar` envuelto en `ResizeImage`.
   - Búfer de audio nativo ExoPlayer optimizado de 50s a 12s en `AudioPlaybackBuffer`.
   - Consulta SQL pseudoaleatoria `getRandomDailySelection()` en `SongDao` y `TodaySelectionService`.

2. **Parte 2 (Completado - Commit `1689f4b`):**
   - Eliminación de GC churn por frame en `AmbientParticlesController` (`UnmodifiableListView`) y `_LiquidFillPainter` (reutilización de `Path`).
   - PRAGMAs de SQLite en `AppDatabase` (`cache_size = -2000`, `temp_store = MEMORY`).
   - Búfer flat preasignado de 16 KB en `FuzzySearchEngine` (`damerauLevenshteinDistance`).
   - Eliminación de `shrinkWrap: true` en secciones de búsqueda, artista y álbum.

3. **Parte 3 (Completado - Commit `f042149`):**
   - Inicialización *Lazy* de `AnimationController`s en `LiquidTrackGestureWrapper` (0 controladores en reposo vs 300).
   - Reemplazo de `ListView(shrinkWrap: true)` en detalle de playlist y resultados de búsqueda.
   - Activación de R8 code shrinking y resource shrinking en `build.gradle.kts` con reglas ProGuard completas.

4. **Parte 4 (Completado - Commit `bfc49cb`):**
   - Desduplicación en memoria de mapas de carátulas en `ArtworkService`: consulta liviana `getSongArtworkMetadata()` con 6 columnas en lugar de 27 de `getAllSongs()`.
   - String interning de `albumKey` para compartir referencias en heap de Dart.
   - Resolución $O(1)$ por representativo sin duplicar rutas de strings por cada canción del álbum.
   - Eliminación de llamada innecesaria a `getAllSongs()` en `MusicIndexer` cuando `deltaCount == 0`.
   - Eliminación de `shrinkWrap: true` restantes en Home (`HomePinnedSection`, `HomeSlotGrid`) y Playlist Edit (`availablePlaylistFonts`, `availablePlaylistEffects`).

5. **Parte 5 (Completado - Commit `68f6e75`):**
   - Pre-normalización del diccionario de búsqueda en `FuzzySearchEngine` (`_NormalizedTarget`, `_NormalizedQuery`, `_SearchSongEntry`).
   - Eliminación de 100% de splits regex, lowercasing efímero y asignaciones de `List<String>` durante el tecleo en tiempo real.
   - Nueva consulta SQL `SongDao.getSearchDictionarySongs()` que proyecta solo las columnas de búsqueda y reproducción necesarias, sustituyendo la última llamada a `getAllSongs()` de la aplicación.

6. **Parte 6 (Completado - Commit `161e5ca`):**
   - Eliminación de GC churn por frame en la barra de progreso del reproductor `_WavyTrackPainter` (`player_progress_bar.dart`): reutilización de `_wavePath` y `Paint`s estáticos.
   - Reutilización de `_wavePath` y `Paint`s en `_StartupWavyPainter` y `_MiniWavyTrackPainter`.
   - Reutilización de `_bumpPath` y `_bumpPaint` en `_ExpressiveEdgeBumpPainter` (`settings_edge_bump.dart`).
   - Reutilización de `_starPath` y `_starPaint` en `_CelebrationStarPainter` (`startup_celebration_stars.dart`).
   - Reutilización estática de los 4 `Paint`s en `ArtistCropMaskOverlay`.
   - Downsampling 1:1 DPR con `cacheWidth` en la portada de previsualización de temas (`startup_theme_selector_view.dart`).

7. **Parte 7 (Completado):**
   - Eliminación de copias redundantes de arrays en getters mediante `UnmodifiableListView` de `dart:collection` (vistas zero-copy sin asignaciones en heap) en `AudioPlaybackBuffer.bufferedSongs`, `PlaybackController.queue`, `RecentSearchController.items`, `ArtistDiscographyController.albums`, `ArtistTracksController.songs` y `HomeLayoutController.items`.
   - Memoización acotada (bounded cache de 1024 entradas) en `ArtistSplitter.split(...)`, eliminando la reejecución de expresiones regulares y la creación de miles de listas de artistas repetidas a través de la biblioteca de canciones.

