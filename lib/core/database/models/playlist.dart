/// File: playlist.dart
/// Description: Immutable domain model representing a user-created Playlist.
/// Contains metadata, track count, total duration, and optional cover artwork path.
///
/// Components / Classes / Functions:
/// - Playlist: Data class for playlists in the SQLite database.
library;

/// Immutable playlist data model.
class Playlist {
  /// Unique database identifier.
  final int? id;

  /// Custom name given to the playlist.
  final String name;

  /// Local filesystem path to custom picked playlist cover image, if any.
  final String? coverPath;

  /// Unix timestamp in milliseconds when playlist was created.
  final int createdAt;

  /// Unix timestamp in milliseconds when playlist was last modified.
  final int updatedAt;

  /// Total number of tracks in this playlist.
  final int songCount;

  /// Total cumulative duration of all songs in milliseconds.
  final int totalDuration;

  /// Representative MediaStore ID of the first song, used as cover fallback.
  final int? firstMediaStoreId;

  /// Custom typography font family for the playlist title, if specified.
  final String? fontFamily;

  /// Proportional horizontal alignment of the text inside the 2:1 banner (-1.0 left to 1.0 right).
  final double textAlignX;

  /// Proportional vertical alignment of the text inside the 2:1 banner (-1.0 top to 1.0 bottom).
  final double textAlignY;

  /// Primary 32-bit ARGB color integer for the title text (defaults to white 0xFFFFFFFF).
  final int textColor;

  /// Optional second 32-bit ARGB color integer for a dual-color text gradient.
  final int? textGradientColor;

  /// Typography font size in logical pixels (defaults to 26.0).
  final double fontSize;

  /// Visual styling effect identifier (e.g. 'none', 'shadow', 'neon', 'glitch', 'outline', 'retro3d').
  final String textEffect;

  const Playlist({
    this.id,
    required this.name,
    this.coverPath,
    required this.createdAt,
    required this.updatedAt,
    this.songCount = 0,
    this.totalDuration = 0,
    this.firstMediaStoreId,
    this.fontFamily,
    this.textAlignX = 0.0,
    this.textAlignY = 0.0,
    this.textColor = 0xFFFFFFFF,
    this.textGradientColor,
    this.fontSize = 26.0,
    this.textEffect = 'none',
  });

  /// Instantiates a [Playlist] from an SQLite query row.
  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: (map['id'] as num?)?.toInt(),
      name: (map['name'] as String?) ?? 'Untitled Playlist',
      coverPath: map['cover_path'] as String?,
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
      updatedAt: (map['updated_at'] as num?)?.toInt() ?? 0,
      songCount: (map['song_count'] as num?)?.toInt() ?? 0,
      totalDuration: (map['total_duration'] as num?)?.toInt() ?? 0,
      firstMediaStoreId: (map['first_media_store_id'] as num?)?.toInt(),
      fontFamily: map['font_family'] as String?,
      textAlignX: (map['text_align_x'] as num?)?.toDouble() ?? 0.0,
      textAlignY: (map['text_align_y'] as num?)?.toDouble() ?? 0.0,
      textColor: (map['text_color'] as num?)?.toInt() ?? 0xFFFFFFFF,
      textGradientColor: (map['text_gradient_color'] as num?)?.toInt(),
      fontSize: (map['font_size'] as num?)?.toDouble() ?? 26.0,
      textEffect: (map['text_effect'] as String?) ?? 'none',
    );
  }

  /// Converts this [Playlist] into SQLite column map for inserts/updates.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'cover_path': coverPath,
      if (fontFamily != null) 'font_family': fontFamily,
      'text_align_x': textAlignX,
      'text_align_y': textAlignY,
      'text_color': textColor,
      if (textGradientColor != null) 'text_gradient_color': textGradientColor,
      'font_size': fontSize,
      'text_effect': textEffect,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Playlist copyWith({
    int? id,
    String? name,
    String? coverPath,
    int? createdAt,
    int? updatedAt,
    int? songCount,
    int? totalDuration,
    int? firstMediaStoreId,
    String? fontFamily,
    double? textAlignX,
    double? textAlignY,
    int? textColor,
    int? textGradientColor,
    double? fontSize,
    String? textEffect,
    bool clearGradient = false,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      coverPath: coverPath ?? this.coverPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      songCount: songCount ?? this.songCount,
      totalDuration: totalDuration ?? this.totalDuration,
      firstMediaStoreId: firstMediaStoreId ?? this.firstMediaStoreId,
      fontFamily: fontFamily ?? this.fontFamily,
      textAlignX: textAlignX ?? this.textAlignX,
      textAlignY: textAlignY ?? this.textAlignY,
      textColor: textColor ?? this.textColor,
      textGradientColor: clearGradient ? null : (textGradientColor ?? this.textGradientColor),
      fontSize: fontSize ?? this.fontSize,
      textEffect: textEffect ?? this.textEffect,
    );
  }

  @override
  String toString() {
    return 'Playlist(id: $id, name: $name, font: $fontFamily, songs: $songCount, duration: ${totalDuration}ms)';
  }
}
