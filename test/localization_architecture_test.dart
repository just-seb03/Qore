/// File: localization_architecture_test.dart
/// Description: Unit and widget tests verifying the Project Anima localization architecture,
/// contracts, English translations, and LocalizationController runtime switching.
///
/// Components / Classes / Functions Tested:
/// - AppLocale: Enum mapping and fallback resolution.
/// - AppLocalizations: Factory loading and BuildContext extension.
/// - LocalizationController: Locale state management and reactive notifications.
/// - EnStrings & contracts: Album, Artist, Artist Discography, Artist Tracks, and Common.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/localization/localization_controller.dart';
import 'package:project_anima/core/localization/translations/es/es_strings.dart';

void main() {
  group('AppLocale Unit Tests', () {
    test('AppLocale enum supports en and es with correct codes and titles', () {
      expect(AppLocale.en.languageCode, equals('en'));
      expect(AppLocale.en.displayName, equals('English'));
      expect(AppLocale.es.languageCode, equals('es'));
      expect(AppLocale.es.displayName, equals('Español'));
    });

    test('AppLocale.fromLocale resolves matching locales and defaults to en', () {
      expect(AppLocale.fromLocale(const Locale('en')), equals(AppLocale.en));
      expect(AppLocale.fromLocale(const Locale('es')), equals(AppLocale.es));
      expect(AppLocale.fromLocale(const Locale('fr')), equals(AppLocale.en));
      expect(AppLocale.fromLocale(null), equals(AppLocale.en));
    });

    test('AppLocale.fromLanguageCode resolves matching codes and defaults to en', () {
      expect(AppLocale.fromLanguageCode('en'), equals(AppLocale.en));
      expect(AppLocale.fromLanguageCode('es'), equals(AppLocale.es));
      expect(AppLocale.fromLanguageCode('de'), equals(AppLocale.en));
      expect(AppLocale.fromLanguageCode(null), equals(AppLocale.en));
    });

    test('AppLocale.supportedLocales exposes en and es', () {
      expect(
        AppLocale.supportedLocales.map((l) => l.languageCode).toList(),
        containsAll(['en', 'es']),
      );
    });
  });

  group('English Localization Contracts & Formatting Tests', () {
    const strings = AppLocalizations.defaultStrings;

    test('Common strings return valid English text', () {
      expect(strings.common.addToFavorites, equals('Add to favorites'));
      expect(strings.common.removeFromFavorites, equals('Remove from favorites'));
      expect(strings.common.addToQueue, equals('Add to queue'));
      expect(strings.common.unknownArtist, equals('Unknown Artist'));
      expect(strings.common.unknownAlbum, equals('Unknown Album'));
      expect(strings.common.unknownTitle, equals('Unknown Title'));
      expect(strings.common.unknownGenre, equals('Unknown Genre'));
    });

    test('Album strings format plurals, disc numbers, and durations accurately', () {
      expect(strings.album.tracksHeader, equals('TRACKS'));
      expect(strings.album.discHeader(1), equals('DISC 1'));
      expect(strings.album.discHeader(2), equals('DISC 2'));
      expect(strings.album.songCount(1), equals('1 song'));
      expect(strings.album.songCount(12), equals('12 songs'));
      expect(strings.album.durationHoursMinutes(1, 15), equals('1 hr 15 min'));
      expect(strings.album.durationMinutes(45), equals('45 mins'));
      expect(
        strings.album.metadataSubtitle(countStr: '10 songs', durationStr: '45 mins'),
        equals('10 songs • 45 mins'),
      );
      expect(
        strings.album.metadataSubtitle(countStr: '10 songs', durationStr: ''),
        equals('10 songs'),
      );
      expect(strings.album.unknownArtist, equals('Unknown Artist'));
    });

    test('Artist strings provide headers, photo actions, and snackbars', () {
      expect(strings.artist.featuredHeader, equals('FEATURED'));
      expect(strings.artist.discographyHeader, equals('DISCOGRAPHY'));
      expect(strings.artist.songsHeader, equals('SONGS'));
      expect(strings.artist.changeArtistPhoto, equals('Change artist photo'));
      expect(strings.artist.removeCustomPhoto, equals('Remove custom photo'));
      expect(strings.artist.albumSongCount(1), equals('1 song'));
      expect(strings.artist.albumSongCount(8), equals('8 songs'));
      expect(strings.artist.albumTrackCount(1), equals('1 track'));
      expect(strings.artist.albumTrackCount(8), equals('8 tracks'));
      expect(strings.artist.songCount(1), equals('1 song'));
      expect(strings.artist.songCount(25), equals('25 songs'));
      expect(strings.artist.pinArtistTooltip, equals('Pin artist to favorites'));
      expect(strings.artist.unpinArtistTooltip, equals('Unpin artist from favorites'));
      expect(strings.artist.photoResetSuccess, equals('Artist photo reset to default'));
      expect(strings.artist.photoUpdateSuccess, equals('Artist photo updated successfully'));
    });

    test('Artist Discography strings format album and track counts', () {
      expect(strings.artistDiscography.headerTitle, equals('DISCOGRAPHY'));
      expect(strings.artistDiscography.albumCount(1), equals('1 album'));
      expect(strings.artistDiscography.albumCount(4), equals('4 albums'));
      expect(strings.artistDiscography.trackCount(1), equals('1 track'));
      expect(strings.artistDiscography.trackCount(14), equals('14 tracks'));
    });

    test('Artist Tracks strings format tracks header and durations', () {
      expect(strings.artistTracks.headerTitle, equals('TRACKS'));
      expect(strings.artistTracks.trackCount(1), equals('1 track'));
      expect(strings.artistTracks.trackCount(48), equals('48 tracks'));
      expect(strings.artistTracks.totalDuration(2, 10), equals('2 hr 10 min'));
      expect(strings.artistTracks.totalDurationMinutes(55), equals('55 mins'));
    });

    test('Home strings provide greetings, section titles, and subtitles', () {
      expect(strings.home.spaceTitle, equals('Space'));
      expect(strings.home.welcomeTitle, equals('WELCOME'));
      expect(strings.home.doneButtonTooltip, equals('Done'));
      expect(strings.home.favoritesHeroTitle, equals('Favorites'));
      expect(strings.home.todaySelectionHeroTitle, equals('Today Selection'));
      expect(strings.home.artistSubtitle, equals('Artist'));
    });

    test('Library strings provide header, filters, and empty states', () {
      expect(strings.library.headerTitle, equals('Library'));
      expect(strings.library.filterAlbums, equals('Albums'));
      expect(strings.library.filterArtists, equals('Artists'));
      expect(strings.library.filterPlaylists, equals('Playlists'));
      expect(strings.library.artistSubtitle, equals('Artist'));
      expect(strings.library.emptyAlbumsTitle, equals('NO ALBUMS FOUND'));
      expect(
        strings.library.emptyAlbumsSubtitle,
        equals('Add music to your device to see your albums here'),
      );
      expect(strings.library.emptyArtistsTitle, equals('NO ARTISTS FOUND'));
      expect(
        strings.library.emptyArtistsSubtitle,
        equals('Add music to your device to see your artists here'),
      );
      expect(strings.library.emptyPlaylistsTitle, equals('NO PLAYLISTS YET'));
      expect(
        strings.library.emptyPlaylistsSubtitle,
        equals('Custom playlists will appear here'),
      );
    });

    test('Player strings format queue, headers, and controls tooltips', () {
      expect(strings.player.nowPlayingHeader, equals('NOW PLAYING'));
      expect(strings.player.noPlayback, equals('No playback'));
      expect(strings.player.queueTitle, equals('PLAYING QUEUE'));
      expect(strings.player.upNextHeader(1), equals('UP NEXT • 1 TRACK'));
      expect(strings.player.upNextHeader(5), equals('UP NEXT • 5 TRACKS'));
      expect(strings.player.emptyQueue, equals('Queue is empty'));
      expect(strings.player.clearQueue, equals('Clear'));
      expect(strings.player.shuffleTooltip, equals('Shuffle mode'));
      expect(strings.player.previousTooltip, equals('Previous track'));
      expect(strings.player.nextTooltip, equals('Next track'));
      expect(strings.player.playTooltip, equals('Play'));
      expect(strings.player.pauseTooltip, equals('Pause'));
      expect(strings.player.loopTooltip, equals('Repeat mode'));
      expect(strings.player.queueTooltip, equals('Playback queue'));
    });

    test('Playlist strings format metadata, covers, editor, and dialogs', () {
      expect(strings.playlist.headerCategory, equals('PLAYLIST'));
      expect(strings.playlist.songCount(1), equals('1 song'));
      expect(strings.playlist.songCount(15), equals('15 songs'));
      expect(strings.playlist.durationHoursMinutes(1, 20), equals('1 hr 20 min'));
      expect(strings.playlist.durationMinutes(42), equals('42 mins'));
      expect(
        strings.playlist.metadataSubtitle(countStr: '15 songs', durationStr: '42 mins'),
        equals('15 songs • 42 mins'),
      );
      expect(strings.playlist.createPlaylistTitle, equals('Create Playlist'));
      expect(strings.playlist.editPlaylistTitle, equals('Edit Playlist'));
      expect(strings.playlist.playlistNameHint, equals('Playlist Name'));
      expect(strings.playlist.saveAction, equals('Save'));
      expect(strings.playlist.changeCover, equals('Change hero banner (1920x620)'));
      expect(strings.playlist.addCover, equals('Choose hero banner (1920x620)'));
      expect(strings.playlist.typographySection, equals('TYPOGRAPHY'));
      expect(strings.playlist.songsInPlaylistSection, equals('SONGS IN PLAYLIST'));
      expect(strings.playlist.emptyPlaylistTitle, equals('NO TRACKS IN THIS PLAYLIST'));
      expect(
        strings.playlist.emptyPlaylistSubtitle,
        equals('Add tracks to your playlist by editing it.'),
      );
      expect(strings.playlist.addSongsButton, equals('Add Songs'));
      expect(strings.playlist.searchSongsPlaceholder, equals('What song do you want to add?'));
      expect(strings.playlist.noSongsFound, equals('No matching songs found in your library'));
      expect(strings.playlist.addedSongSuccess('Song A'), equals('Added "Song A" to playlist'));
      expect(strings.playlist.savePlaylistError('Disk full'), equals('Failed to save playlist: Disk full'));
      expect(strings.playlist.galleryPickError, equals('Failed to pick image from gallery'));
      expect(strings.playlist.discardDialogTitle, equals('Discard playlist?'));
      expect(
        strings.playlist.discardDialogMessage,
        equals('You have unsaved changes. Are you sure you want to leave without saving?'),
      );
      expect(strings.playlist.keepEditingAction, equals('Keep editing'));
      expect(strings.playlist.discardAction, equals('Discard'));
      expect(strings.playlist.playAction, equals('Play'));
      expect(strings.playlist.shuffleAction, equals('Shuffle'));
      expect(strings.playlist.tracksHeader, equals('TRACKS'));
      expect(strings.playlist.tracksHeaderWithCount(3), equals('TRACKS (3)'));
      expect(strings.playlist.dragToReorder, equals('Drag to reorder'));
      expect(
        strings.playlist.noSongsAddedYet,
        equals('No songs added yet.\nSearch above to add songs to your playlist.'),
      );
      expect(strings.playlist.removeTrackTooltip, equals('Remove track'));
      expect(strings.playlist.addSongsSection, equals('ADD SONGS'));
      expect(strings.playlist.defaultPlaylistName, equals('My Playlist'));
      expect(strings.playlist.heroBannerPlaceholder, equals('HERO BANNER 1920x620'));
    });

    test('Search strings return valid English text and formats', () {
      expect(strings.search.headerTitle, equals('Search'));
      expect(strings.search.searchPlaceholder, equals('What do you want to listen to?'));
      expect(strings.search.emptyLibraryTitle, equals('SEARCH YOUR LIBRARY'));
      expect(
        strings.search.emptyLibrarySubtitle,
        equals('Indexed titles, artists, or albums'),
      );
      expect(strings.search.noResultsTitle, equals('NO RESULTS FOUND'));
      expect(
        strings.search.noResultsSubtitle('Radiohead'),
        equals('No matches found for "Radiohead"'),
      );
      expect(strings.search.recentSearchesHeader, equals('RECENT SEARCHES'));
      expect(strings.search.clearAllRecentAction, equals('Clear all'));
      expect(strings.search.removeRecentTooltip, equals('Remove from recents'));
      expect(strings.search.topResultHeader, equals('TOP RESULT'));
      expect(strings.search.albumsSectionHeader, equals('ALBUMS'));
      expect(strings.search.artistsSectionHeader, equals('ARTISTS'));
      expect(strings.search.songsSectionHeader, equals('SONGS'));
      expect(strings.search.artistSubtitle, equals('Artist'));
      expect(strings.search.songCount(1), equals('1 song'));
      expect(strings.search.songCount(10), equals('10 songs'));
      expect(strings.search.clearSearchTooltip, equals('Clear search'));
    });

    test('Startup strings return valid English text', () {
      expect(strings.startup.appTitle, equals('PROJECT ANIMA'));
      expect(strings.startup.audioAccessRequiredTitle, equals('AUDIO ACCESS REQUIRED'));
      expect(
        strings.startup.audioAccessRequiredMessage,
        equals('Project Anima requires access to your audio files to discover, organize, and play your local music library.'),
      );
      expect(strings.startup.continueAction, equals('CONTINUE'));
      expect(strings.startup.scanningLibrary, equals('Scanning library...'));
      expect(strings.startup.savingTracks, equals('Saving your tracks...'));
      expect(strings.startup.savingCovers, equals('Saving covers...'));
      expect(strings.startup.finalizingSetup, equals('Finalizing setup...'));
      expect(strings.startup.allSet, equals('All set!'));
    });

    test('Navigation strings return valid English text', () {
      expect(strings.navigation.exploreTab, equals('Explore'));
      expect(strings.navigation.exploreTabTooltip, equals('Explore'));
      expect(strings.navigation.searchTab, equals('Search'));
      expect(strings.navigation.searchTabTooltip, equals('Search'));
      expect(strings.navigation.homeTab, equals('Space'));
      expect(strings.navigation.homeTabTooltip, equals('Space'));
      expect(strings.navigation.libraryTab, equals('Library'));
      expect(strings.navigation.libraryTabTooltip, equals('Library'));
      expect(strings.navigation.profileTab, equals('Profile'));
      expect(strings.navigation.profileTabTooltip, equals('Profile'));
    });
  });

  group('Spanish Localization Contracts & Formatting Tests', () {
    const es = EsStrings();

    test('Common strings return valid Spanish text', () {
      expect(es.common.addToFavorites, equals('Añadir a favoritos'));
      expect(es.common.removeFromFavorites, equals('Quitar de favoritos'));
      expect(es.common.addToQueue, equals('Añadir a la cola'));
      expect(es.common.unknownArtist, equals('Artista desconocido'));
      expect(es.common.unknownAlbum, equals('Álbum desconocido'));
      expect(es.common.unknownTitle, equals('Título desconocido'));
      expect(es.common.unknownGenre, equals('Género desconocido'));
      expect(es.common.done, equals('Listo'));
    });

    test('Album strings format plurals and Spanish durations accurately', () {
      expect(es.album.tracksHeader, equals('PISTAS'));
      expect(es.album.discHeader(1), equals('DISCO 1'));
      expect(es.album.songCount(1), equals('1 canción'));
      expect(es.album.songCount(12), equals('12 canciones'));
      expect(es.album.durationHoursMinutes(1, 15), equals('1 h 15 min'));
      expect(es.album.durationMinutes(45), equals('45 mins'));
      expect(
        es.album.metadataSubtitle(countStr: '10 canciones', durationStr: '45 mins'),
        equals('10 canciones • 45 mins'),
      );
      expect(es.album.unknownArtist, equals('Artista desconocido'));
    });

    test('Artist and Discography strings return valid Spanish text', () {
      expect(es.artist.featuredHeader, equals('DESTACADOS'));
      expect(es.artist.discographyHeader, equals('DISCOGRAFÍA'));
      expect(es.artist.songsHeader, equals('CANCIONES'));
      expect(es.artist.changeArtistPhoto, equals('Cambiar foto de artista'));
      expect(es.artist.removeCustomPhoto, equals('Eliminar foto personalizada'));
      expect(es.artistDiscography.headerTitle, equals('DISCOGRAFÍA'));
      expect(es.artistDiscography.albumCount(1), equals('1 álbum'));
      expect(es.artistDiscography.albumCount(4), equals('4 álbumes'));
      expect(es.artistTracks.headerTitle, equals('PISTAS'));
      expect(es.artistTracks.totalDuration(2, 10), equals('2 h 10 min'));
    });

    test('Home and Library strings return valid Spanish text', () {
      expect(es.home.spaceTitle, equals('Space'));
      expect(es.home.welcomeTitle, equals('BIENVENIDO'));
      expect(es.home.doneButtonTooltip, equals('Listo'));
      expect(es.home.favoritesHeroTitle, equals('Favoritos'));
      expect(es.home.todaySelectionHeroTitle, equals('Selección de hoy'));
      expect(es.home.artistSubtitle, equals('Artista'));
      expect(es.library.headerTitle, equals('Biblioteca'));
      expect(es.library.filterAlbums, equals('Álbumes'));
      expect(es.library.filterArtists, equals('Artistas'));
      expect(es.library.filterPlaylists, equals('Listas'));
      expect(es.library.emptyAlbumsTitle, equals('NO SE ENCONTRARON ÁLBUMES'));
      expect(es.library.emptyArtistsTitle, equals('NO SE ENCONTRARON ARTISTAS'));
      expect(es.library.emptyPlaylistsTitle, equals('AÚN NO HAY LISTAS'));
    });

    test('Navigation and Player strings return valid Spanish text', () {
      expect(es.navigation.exploreTab, equals('Explorar'));
      expect(es.navigation.searchTab, equals('Buscar'));
      expect(es.navigation.homeTab, equals('Space'));
      expect(es.navigation.libraryTab, equals('Biblioteca'));
      expect(es.navigation.profileTab, equals('Perfil'));
      expect(es.player.nowPlayingHeader, equals('EN REPRODUCCIÓN'));
      expect(es.player.noPlayback, equals('Sin reproducción'));
      expect(es.player.queueTitle, equals('COLA DE REPRODUCCIÓN'));
      expect(es.player.upNextHeader(3), equals('A CONTINUACIÓN • 3 PISTAS'));
      expect(es.player.clearQueue, equals('Limpiar'));
      expect(es.player.playTooltip, equals('Reproducir'));
      expect(es.player.pauseTooltip, equals('Pausar'));
    });

    test('Playlist, Search, and Startup strings return valid Spanish text', () {
      expect(es.playlist.headerCategory, equals('LISTA'));
      expect(es.playlist.createPlaylistTitle, equals('Crear lista'));
      expect(es.playlist.editPlaylistTitle, equals('Editar lista'));
      expect(es.playlist.typographySection, equals('TIPOGRAFÍA'));
      expect(es.playlist.emptyPlaylistTitle, equals('NO HAY PISTAS EN ESTA LISTA'));
      expect(es.playlist.discardDialogTitle, equals('¿Descartar lista?'));
      expect(es.search.headerTitle, equals('Buscar'));
      expect(es.search.searchPlaceholder, equals('¿Qué quieres escuchar?'));
      expect(es.search.emptyLibraryTitle, equals('BUSCA EN TU BIBLIOTECA'));
      expect(es.search.noResultsTitle, equals('NO SE ENCONTRARON RESULTADOS'));
      expect(es.search.topResultHeader, equals('MEJOR RESULTADO'));
      expect(es.search.albumsSectionHeader, equals('ÁLBUMES'));
      expect(es.search.artistsSectionHeader, equals('ARTISTAS'));
      expect(es.search.songsSectionHeader, equals('CANCIONES'));
      expect(es.startup.appTitle, equals('PROJECT ANIMA'));
      expect(es.startup.audioAccessRequiredTitle, equals('ACCESO A AUDIO REQUERIDO'));
      expect(es.startup.continueAction, equals('CONTINUAR'));
      expect(es.startup.scanningLibrary, equals('Escaneando biblioteca...'));
      expect(es.startup.allSet, equals('¡Todo listo!'));
    });
  });

  group('LocalizationController & Device Language Auto-Detection Tests', () {
    test('LocalizationController updates locale and notifies listeners', () {
      final controller = LocalizationController.instance;
      controller.setLocale(AppLocale.en);

      bool notified = false;
      void listener() {
        notified = true;
      }

      controller.addListener(listener);
      expect(controller.currentAppLocale, equals(AppLocale.en));
      expect(controller.currentLocale.languageCode, equals('en'));

      controller.setLocale(AppLocale.es);
      expect(notified, isTrue);
      expect(controller.currentAppLocale, equals(AppLocale.es));
      expect(controller.currentLocale.languageCode, equals('es'));

      // Clean up back to en
      controller.setLocale(AppLocale.en);
      controller.removeListener(listener);
    });

    test('detectDeviceLocale resolves Spanish when platform language is es', () {
      expect(
        LocalizationController.detectDeviceLocale(const Locale('es')),
        equals(AppLocale.es),
      );
      expect(
        LocalizationController.detectDeviceLocale(const Locale('es', 'ES')),
        equals(AppLocale.es),
      );
      expect(
        LocalizationController.detectDeviceLocale(const Locale('es', 'MX')),
        equals(AppLocale.es),
      );
    });

    test('detectDeviceLocale defaults to English for other locales', () {
      expect(
        LocalizationController.detectDeviceLocale(const Locale('en')),
        equals(AppLocale.en),
      );
      expect(
        LocalizationController.detectDeviceLocale(const Locale('fr')),
        equals(AppLocale.en),
      );
      expect(
        LocalizationController.detectDeviceLocale(const Locale('de')),
        equals(AppLocale.en),
      );
      expect(
        LocalizationController.detectDeviceLocale(null),
        equals(AppLocale.en),
      );
    });

    test('init with initialDeviceLocale configures Spanish automatically', () {
      final controller = LocalizationController.instance;
      controller.init(initialDeviceLocale: const Locale('es'));
      expect(controller.currentAppLocale, equals(AppLocale.es));
      expect(controller.followSystemLocale, isTrue);

      controller.init(initialDeviceLocale: const Locale('en'));
      expect(controller.currentAppLocale, equals(AppLocale.en));
    });

    test('didChangeLocales updates locale when followSystemLocale is active', () {
      final controller = LocalizationController.instance;
      controller.enableSystemLocale();
      expect(controller.followSystemLocale, isTrue);

      controller.didChangeLocales([const Locale('es')]);
      expect(controller.currentAppLocale, equals(AppLocale.es));

      controller.didChangeLocales([const Locale('en')]);
      expect(controller.currentAppLocale, equals(AppLocale.en));

      // Manual override disables automatic system locale updates
      controller.setLocale(AppLocale.en, followSystem: false);
      expect(controller.followSystemLocale, isFalse);

      controller.didChangeLocales([const Locale('es')]);
      expect(controller.currentAppLocale, equals(AppLocale.en)); // Stays en due to manual lock
    });
  });

  group('Widget Integration Tests', () {
    testWidgets('context.l10n resolves correct strings via MaterialApp across features', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    Text(context.l10n.album.tracksHeader),
                    Text(context.l10n.artist.discographyHeader),
                    Text(context.l10n.artistDiscography.headerTitle),
                    Text(context.l10n.artistTracks.headerTitle),
                    Text(context.l10n.common.unknownArtist),
                    Text(context.l10n.home.welcomeTitle),
                    Text(context.l10n.library.headerTitle),
                    Text(context.l10n.player.nowPlayingHeader),
                    Text(context.l10n.playlist.headerCategory),
                    Text(context.l10n.search.headerTitle),
                    Text(context.l10n.startup.appTitle),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('TRACKS'), findsNWidgets(2)); // album.tracksHeader and artistTracks.headerTitle
      expect(find.text('DISCOGRAPHY'), findsNWidgets(2)); // artist.discographyHeader and artistDiscography.headerTitle
      expect(find.text('Unknown Artist'), findsOneWidget);
      expect(find.text('WELCOME'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.text('PLAYLIST'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('PROJECT ANIMA'), findsOneWidget);
    });

    testWidgets('AppBottomNav renders localized destinations for Explore, Search, Space, Library, and Profile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(
            bottomNavigationBar: AppBottomNav(showMiniPlayer: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Space'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Spanish locale renders Spanish translations across widgets and AppBottomNav', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    Text(context.l10n.album.tracksHeader),
                    Text(context.l10n.artist.discographyHeader),
                    Text(context.l10n.common.unknownArtist),
                    Text(context.l10n.home.welcomeTitle),
                    Text(context.l10n.library.headerTitle),
                    Text(context.l10n.player.nowPlayingHeader),
                    Text(context.l10n.playlist.headerCategory),
                    Text(context.l10n.search.headerTitle),
                    Text(context.l10n.startup.appTitle),
                  ],
                ),
                bottomNavigationBar: const AppBottomNav(showMiniPlayer: false),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('PISTAS'), findsOneWidget);
      expect(find.text('DISCOGRAFÍA'), findsOneWidget);
      expect(find.text('Artista desconocido'), findsOneWidget);
      expect(find.text('BIENVENIDO'), findsOneWidget);
      expect(find.text('Biblioteca'), findsNWidgets(2)); // in body and bottom nav
      expect(find.text('EN REPRODUCCIÓN'), findsOneWidget);
      expect(find.text('LISTA'), findsOneWidget);
      expect(find.text('Buscar'), findsNWidgets(2)); // in body search bar and bottom nav
      expect(find.text('Explorar'), findsOneWidget); // in bottom nav
      expect(find.text('Perfil'), findsOneWidget); // in bottom nav
      expect(find.text('PROJECT ANIMA'), findsOneWidget);
      expect(find.text('Space'), findsOneWidget); // bottom nav home tab
    });
  });
}
