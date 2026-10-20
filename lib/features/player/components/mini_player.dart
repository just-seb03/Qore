/// File: mini_player.dart
/// Description: Global Material 3 Expressive floating mini-player component situated above
/// the bottom navigation bar. Features an elevated tonal pill shape, rounded album artwork,
/// typography hierarchy, high-contrast circular Play/Pause action button, and a mesmerizing
/// animated liquid fill water effect that progressively fills the mini-player from the bottom up
/// with dual-layer fluid waves as the song advances, with isolated GPU rebuild boundaries.
/// Tapping anywhere on the card (except playback buttons) opens the maximized player screen.
///
/// Components / Classes / Functions:
/// - MiniPlayer: Floating M3 Expressive mini-player widget with animated liquid water fill.
/// - _MiniPlayerLiquidProgress: Isolated liquid water progress layer observing song position.
/// - _LiquidFillPainter: Custom painter rendering the dual-layer animated undulating water waves.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/player/screens/player_screen.dart';

/// Global Material 3 Expressive floating mini-player bar positioned directly above the bottom nav.
class MiniPlayer extends StatelessWidget {
  /// Custom controller instance override. Defaults to [PlaybackController.instance].
  final PlaybackController? controller;

  /// Optional callback override when mini-player card is tapped.
  /// Defaults to navigating to [PlayerScreen].
  final VoidCallback? onTap;

  const MiniPlayer({
    super.key,
    this.controller,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeController = controller ?? PlaybackController.instance;

    return ListenableBuilder(
      listenable: activeController,
      builder: (context, _) {
        final currentSong = activeController.currentSong;

        return AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: currentSong == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 8.0),
                  child: Container(
                    height: 64.0,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.55),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 16.0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: Stack(
                        children: [
                          // 1. Animated Subtle Liquid Water Fill Layer (Rises from base as song plays)
                          Positioned.fill(
                            child: _MiniPlayerLiquidProgress(
                              controller: activeController,
                            ),
                          ),

                          // 2. Tappable M3 Expressive Card Surface
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20.0),
                              onTap: onTap ??
                                  () {
                                    Navigator.of(context).push(PlayerScreen.route());
                                  },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                child: Row(
                                  children: [
                                    // 1. Album Artwork Thumbnail (Dual-Tier fast cache)
                                    AnimaArtworkImage(
                                      mediaStoreId: currentSong.mediaStoreId,
                                      albumId: currentSong.albumId,
                                      width: 46.0,
                                      height: 46.0,
                                      borderRadius: 12.0,
                                      isThumbnail: true,
                                      fit: BoxFit.cover,
                                      fallbackIcon: Icons.music_note_rounded,
                                    ),
                                    const SizedBox(width: 12.0),

                                    // 2. Song Metadata (Title + Artist)
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentSong.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Inconsolata',
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.futuristicWhite,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2.0),
                                          Text(
                                            currentSong.artist ?? '<Desconocido>',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Inconsolata',
                                              fontSize: 11.5,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 3. Playback Controls Row (Prev, Filled M3 Play/Pause, Next)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Previous Track Button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.skip_previous_rounded,
                                            size: 24.0,
                                            color: AppColors.futuristicWhite,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 36.0,
                                            minHeight: 36.0,
                                          ),
                                          splashRadius: 18.0,
                                          tooltip: 'Canción anterior',
                                          onPressed: () => activeController.skipToPrevious(),
                                        ),

                                        // Material 3 Expressive Filled Circular Play / Pause Button
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                          child: Material(
                                            color: Colors.transparent,
                                            shape: const CircleBorder(),
                                            child: InkWell(
                                              customBorder: const CircleBorder(),
                                              onTap: () => activeController.togglePlayPause(),
                                              child: Container(
                                                width: 38.0,
                                                height: 38.0,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppColors.futuristicWhite,
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    activeController.isPlaying
                                                        ? Icons.pause_rounded
                                                        : Icons.play_arrow_rounded,
                                                    size: 24.0,
                                                    color: AppColors.background,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Next Track Button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.skip_next_rounded,
                                            size: 24.0,
                                            color: AppColors.futuristicWhite,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 36.0,
                                            minHeight: 36.0,
                                          ),
                                          splashRadius: 18.0,
                                          tooltip: 'Siguiente canción',
                                          onPressed: () => activeController.skipToNext(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// Standalone animated widget rendering the dual-layer fluid water waves rising
/// with song progress, completely isolated with [RepaintBoundary].
class _MiniPlayerLiquidProgress extends StatefulWidget {
  final PlaybackController controller;

  const _MiniPlayerLiquidProgress({required this.controller});

  @override
  State<_MiniPlayerLiquidProgress> createState() => _MiniPlayerLiquidProgressState();
}

class _MiniPlayerLiquidProgressState extends State<_MiniPlayerLiquidProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.controller.isPlaying) {
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _MiniPlayerLiquidProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.isPlaying && !_waveController.isAnimating) {
      _waveController.repeat();
    } else if (!widget.controller.isPlaying && _waveController.isAnimating) {
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.controller.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = widget.controller.duration;
        final double progress = total.inMilliseconds > 0
            ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _LiquidFillPainter(
                  progress: progress,
                  wavePhase: _waveController.value * 2 * math.pi,
                  isPlaying: widget.controller.isPlaying,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// CustomPainter rendering two layers of fluid sinusoidal water waves
/// filling the mini-player card with subtle monochromatic transparency.
class _LiquidFillPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final bool isPlaying;

  const _LiquidFillPainter({
    required this.progress,
    required this.wavePhase,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || progress <= 0.0) return;

    final double w = size.width;
    final double h = size.height;

    // Water level rises from bottom (h) to top (0)
    final double waterHeight = (progress * h).clamp(0.0, h);
    final double baseWaterY = h - waterHeight;

    // Taper wave amplitude near 0% and 100% so liquid starts and finishes cleanly
    final double amplitudeTaper = math.min(1.0, math.min(progress, 1.0 - progress) * 6.0);
    final double amp1 = 2.4 * amplitudeTaper;
    final double amp2 = 1.8 * amplitudeTaper;
    const double wavelength1 = 160.0;
    const double wavelength2 = 120.0;

    // 1. Back Wave (deeper, shifted phase, slower flow)
    final Path backWavePath = Path();
    backWavePath.moveTo(0, h);
    backWavePath.lineTo(0, (baseWaterY + amp1 * math.sin(wavePhase * 0.8)).clamp(0.0, h));

    for (double x = 0; x <= w; x += 3.0) {
      final double y = baseWaterY + amp1 * math.sin((x / wavelength1) * 2 * math.pi + wavePhase * 0.8);
      backWavePath.lineTo(x, y.clamp(0.0, h));
    }
    backWavePath.lineTo(w, h);
    backWavePath.close();

    final Paint backWavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawPath(backWavePath, backWavePaint);

    // 2. Front Wave (crisper crest, faster flow, subtle luminous gradient)
    final Path frontWavePath = Path();
    frontWavePath.moveTo(0, h);
    frontWavePath.lineTo(0, (baseWaterY + amp2 * math.sin(wavePhase + math.pi / 2)).clamp(0.0, h));

    for (double x = 0; x <= w; x += 3.0) {
      final double y = baseWaterY + amp2 * math.sin((x / wavelength2) * 2 * math.pi + wavePhase + math.pi / 2);
      frontWavePath.lineTo(x, y.clamp(0.0, h));
    }
    frontWavePath.lineTo(w, h);
    frontWavePath.close();

    final Rect liquidRect = Rect.fromLTWH(0, math.max(0.0, baseWaterY - amp2), w, waterHeight + amp2);
    final Paint frontWavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.14),
          const Color(0xFF323242).withValues(alpha: 0.18),
        ],
      ).createShader(liquidRect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(frontWavePath, frontWavePaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidFillPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.isPlaying != isPlaying;
  }
}
