/// File: library_playlist_tile.dart
/// Description: Compatibility export for library playlist presentation.
/// Re-exports LibraryPlaylistCard for backwards compatibility across tests and views.
///
/// Components / Classes / Functions:
/// - LibraryPlaylistTile: Type alias for LibraryPlaylistCard.
library;

export 'package:project_anima/features/library/components/playlists/library_playlist_card.dart';

import 'package:project_anima/features/library/components/playlists/library_playlist_card.dart';

/// Backwards compatibility alias for LibraryPlaylistCard.
typedef LibraryPlaylistTile = LibraryPlaylistCard;

