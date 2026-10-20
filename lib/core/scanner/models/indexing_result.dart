/// File: indexing_result.dart
/// Description: Result model returned by MusicIndexer summarizing indexing metrics and delta changes.
///
/// Components / Classes / Functions:
/// - IndexingResult: Data model holding sync outcome metrics.
library;

/// Summary metrics returned upon completion of music indexing.
class IndexingResult {
  /// Total count of songs in SQLite database after synchronization.
  final int totalSongs;

  /// Number of newly discovered tracks added to database.
  final int addedCount;

  /// Number of tracks updated due to modification timestamp changes.
  final int updatedCount;

  /// Number of tracks removed because their files no longer exist on the device.
  final int deletedCount;

  /// Total elapsed time of the scan and sync process in milliseconds.
  final int elapsedMilliseconds;

  /// Whether the indexing request was skipped because a sync was already in progress.
  final bool isAlreadyRunning;

  const IndexingResult({
    required this.totalSongs,
    required this.addedCount,
    required this.updatedCount,
    required this.deletedCount,
    required this.elapsedMilliseconds,
    this.isAlreadyRunning = false,
  });

  /// Factory constructor when an indexing run is skipped due to concurrency lock.
  factory IndexingResult.alreadyRunning() {
    return const IndexingResult(
      totalSongs: 0,
      addedCount: 0,
      updatedCount: 0,
      deletedCount: 0,
      elapsedMilliseconds: 0,
      isAlreadyRunning: true,
    );
  }

  @override
  String toString() {
    if (isAlreadyRunning) {
      return 'IndexingResult(alreadyRunning: true)';
    }
    return 'IndexingResult(total: $totalSongs, added: $addedCount, updated: $updatedCount, deleted: $deletedCount, time: ${elapsedMilliseconds}ms)';
  }
}
