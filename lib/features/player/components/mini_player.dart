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

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/ambient_particles/controllers/ambient_particles_controller.dart';
import 'package:project_anima/features/player/components/playback_queue_sheet.dart';
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

  /// Adapts raw cover art color (or `#5BABCE` default) so the liquid wave fill stays
  /// vivid and legible across both dark and light surfaces.
  static Color resolveWaterColor(Color rawColor, {required bool isDark}) {
    final HSLColor rawHsl = HSLColor.fromColor(rawColor);
    final double clampedLightness = isDark
        ? rawHsl.lightness.clamp(0.45, 0.72)
        : rawHsl.lightness.clamp(0.36, 0.60);
    return rawHsl.withLightness(clampedLightness).toColor();
  }

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
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.55),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.60),
                          blurRadius: 22.0,
                          spreadRadius: 1.0,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.30),
                          blurRadius: 8.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: Stack(
                        children: [
                          // 1. Animated Subtle Liquid Water Fill Layer (Rises from base as song plays)
                          Positioned.fill(
                            child: _MiniPlayerLiquidProgress(
                              controller: activeController,
                            ),
                          ),

                          // 2. Tappable & Draggable M3 Expressive Card Surface
                          Material(
                            color: Colors.transparent,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onVerticalDragEnd: (details) {
                                if (details.primaryVelocity != null && details.primaryVelocity! < -120) {
                                  PlaybackQueueSheet.show(context);
                                }
                              },
                              onLongPress: () {
                                PlaybackQueueSheet.show(context);
                              },
                              child: InkWell(
                                borderRadius: BorderRadius.zero,
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
                                      albumName: currentSong.album,
                                      artistName: currentSong.albumArtist ?? currentSong.artist,
                                      width: 46.0,
                                      height: 46.0,
                                      borderRadius: 0.0,
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
                                            style: TextStyle(
                                              fontFamily: 'Inconsolata',
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.futuristicWhite,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2.0),
                                          Text(
                                            currentSong.artist ?? context.l10n.common.unknownArtist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
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
                                          icon: Icon(
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
                                          tooltip: context.l10n.player.previousTooltip,
                                          onPressed: () => activeController.skipToPrevious(),
                                        ),

                                        // Material 3 Expressive Filled Circular Play / Pause Button
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                          child: Tooltip(
                                            message: activeController.isPlaying
                                                ? context.l10n.player.pauseTooltip
                                                : context.l10n.player.playTooltip,
                                            child: Material(
                                              color: Colors.transparent,
                                              shape: const CircleBorder(),
                                              child: InkWell(
                                                customBorder: const CircleBorder(),
                                                onTap: () => activeController.togglePlayPause(),
                                                child: Container(
                                                  width: 38.0,
                                                  height: 38.0,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: AppColors.accent,
                                                  ),
                                                  child: Center(
                                                    child: Icon(
                                                      activeController.isPlaying
                                                          ? Icons.pause_rounded
                                                          : Icons.play_arrow_rounded,
                                                      size: 24.0,
                                                      color: AppColors.onAccent,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Next Track Button
                                        IconButton(
                                          icon: Icon(
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
                                          tooltip: context.l10n.player.nextTooltip,
                                          onPressed: () => activeController.skipToNext(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  StreamSubscription<Duration>? _positionSub;
  Duration _lastPosition = Duration.zero;
  bool _isTickerEnabled = true;
  late bool _isDark;
  late Color _targetWaterColor;

  bool get _shouldTrackPlayback =>
      _isTickerEnabled &&
      !AmbientParticlesController.instance.isExpandedPlayerVisible;

  Color _resolveTargetColor(bool isDark) {
    return MiniPlayer.resolveWaterColor(
      AmbientParticlesController.instance.targetWaveColor,
      isDark: isDark,
    );
  }

  @override
  void initState() {
    super.initState();
    _isDark = ThemeController.instance.isDarkMode;
    _targetWaterColor = _resolveTargetColor(_isDark);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    AmbientParticlesController.instance.addListener(_onAmbientChanged);
    ThemeController.instance.addListener(_onThemeChanged);
    widget.controller.addListener(_onPlaybackChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool tickerEnabled = TickerMode.valuesOf(context).enabled;
    _isTickerEnabled = tickerEnabled;
    _syncPlaybackSubscriptions();
  }

  @override
  void didUpdateWidget(covariant _MiniPlayerLiquidProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onPlaybackChanged);
      _positionSub?.cancel();
      _positionSub = null;
      _lastPosition = Duration.zero;
      _progressNotifier.value = 0.0;
      widget.controller.addListener(_onPlaybackChanged);
    }
    _syncPlaybackSubscriptions();
  }

  void _syncPlaybackSubscriptions() {
    if (_shouldTrackPlayback) {
      _positionSub ??= widget.controller.positionStream.listen(_onPositionUpdate);
      if (widget.controller.isPlaying) {
        if (!_waveController.isAnimating) {
          _waveController.repeat();
        }
      } else if (_waveController.isAnimating) {
        _waveController.stop();
      }
    } else {
      _positionSub?.cancel();
      _positionSub = null;
      if (_waveController.isAnimating) {
        _waveController.stop();
      }
    }
  }

  void _onPositionUpdate(Duration position) {
    _lastPosition = position;
    final int totalMs = widget.controller.duration.inMilliseconds;
    _progressNotifier.value = totalMs > 0
        ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : 0.0;
  }

  void _onPlaybackChanged() {
    _syncPlaybackSubscriptions();
    _onPositionUpdate(_lastPosition);
  }

  void _onAmbientChanged() {
    _syncPlaybackSubscriptions();
    final Color nextColor = _resolveTargetColor(_isDark);
    if (nextColor != _targetWaterColor && mounted) {
      setState(() {
        _targetWaterColor = nextColor;
      });
    }
  }

  void _onThemeChanged() {
    final bool nextDark = ThemeController.instance.isDarkMode;
    final Color nextColor = _resolveTargetColor(nextDark);
    if ((nextDark != _isDark || nextColor != _targetWaterColor) && mounted) {
      setState(() {
        _isDark = nextDark;
        _targetWaterColor = nextColor;
      });
    }
  }

  @override
  void dispose() {
    AmbientParticlesController.instance.removeListener(_onAmbientChanged);
    ThemeController.instance.removeListener(_onThemeChanged);
    widget.controller.removeListener(_onPlaybackChanged);
    _positionSub?.cancel();
    _waveController.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: _targetWaterColor),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, animatedColor, _) {
        final Color waterColor = animatedColor ?? _targetWaterColor;
        return RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('mini_player_liquid_paint'),
            size: Size.infinite,
            painter: _LiquidFillPainter(
              progressListenable: _progressNotifier,
              waveAnimation: _waveController,
              waterColor: waterColor,
              isDark: _isDark,
            ),
          ),
        );
      },
    );
  }
}

/// CustomPainter rendering two layers of fluid sinusoidal water waves
/// tinted with the active track's cover color (falling back to `#5BABCE`),
/// caching the fill gradient shader and repainting via [Listenable.merge].
class _LiquidFillPainter extends CustomPainter {
  final ValueListenable<double> progressListenable;
  final Animation<double> waveAnimation;
  final Color waterColor;
  final bool isDark;

  static final Path _backWavePath = Path();
  static final Path _frontWavePath = Path();
  static final Paint _backWavePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _frontWavePaint = Paint()..style = PaintingStyle.fill;

  static Shader? _cachedFrontShader;
  static int? _cachedShaderColorArgb;
  static bool? _cachedShaderIsDark;
  static double _cachedShaderWidth = -1.0;
  static double _cachedShaderTop = -1.0;
  static double _cachedShaderHeight = -1.0;

  _LiquidFillPainter({
    required this.progressListenable,
    required this.waveAnimation,
    required this.waterColor,
    required this.isDark,
  }) : super(repaint: Listenable.merge([waveAnimation, progressListenable]));

  @override
  void paint(Canvas canvas, Size size) {
    final double progress = progressListenable.value;
    if (size.width <= 0 || size.height <= 0 || progress <= 0.0) return;

    final double wavePhase = waveAnimation.value * 2 * math.pi;
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
    const double stepX = 6.0;

    // 1. Back Wave (deeper, shifted phase, slower flow)
    _backWavePath.reset();
    _backWavePath.moveTo(0, h);
    _backWavePath.lineTo(0, (baseWaterY + amp1 * math.sin(wavePhase * 0.8)).clamp(0.0, h));

    for (double x = 0; x <= w; x += stepX) {
      final double y = baseWaterY + amp1 * math.sin((x / wavelength1) * 2 * math.pi + wavePhase * 0.8);
      _backWavePath.lineTo(x, y.clamp(0.0, h));
    }
    _backWavePath.lineTo(
      w,
      (baseWaterY + amp1 * math.sin((w / wavelength1) * 2 * math.pi + wavePhase * 0.8)).clamp(0.0, h),
    );
    _backWavePath.lineTo(w, h);
    _backWavePath.close();

    _backWavePaint.color = waterColor.withValues(alpha: isDark ? 0.18 : 0.16);
    canvas.drawPath(_backWavePath, _backWavePaint);

    // 2. Front Wave (crisper crest, faster flow, subtle luminous gradient)
    _frontWavePath.reset();
    _frontWavePath.moveTo(0, h);
    _frontWavePath.lineTo(0, (baseWaterY + amp2 * math.sin(wavePhase + math.pi / 2)).clamp(0.0, h));

    for (double x = 0; x <= w; x += stepX) {
      final double y = baseWaterY + amp2 * math.sin((x / wavelength2) * 2 * math.pi + wavePhase + math.pi / 2);
      _frontWavePath.lineTo(x, y.clamp(0.0, h));
    }
    _frontWavePath.lineTo(
      w,
      (baseWaterY + amp2 * math.sin((w / wavelength2) * 2 * math.pi + wavePhase + math.pi / 2)).clamp(0.0, h),
    );
    _frontWavePath.lineTo(w, h);
    _frontWavePath.close();

    final double rectTop = math.max(0.0, baseWaterY - amp2);
    final double rectHeight = waterHeight + amp2;
    final int colorArgb = waterColor.toARGB32();
    if (_cachedFrontShader == null ||
        _cachedShaderColorArgb != colorArgb ||
        _cachedShaderIsDark != isDark ||
        (_cachedShaderWidth - w).abs() >= 1.0 ||
        (_cachedShaderTop - rectTop).abs() >= 1.0 ||
        (_cachedShaderHeight - rectHeight).abs() >= 1.0) {
      final Rect liquidRect = Rect.fromLTWH(0, rectTop, w, rectHeight);
      _cachedFrontShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          waterColor.withValues(alpha: isDark ? 0.36 : 0.30),
          waterColor.withValues(alpha: isDark ? 0.13 : 0.11),
        ],
      ).createShader(liquidRect);
      _cachedShaderColorArgb = colorArgb;
      _cachedShaderIsDark = isDark;
      _cachedShaderWidth = w;
      _cachedShaderTop = rectTop;
      _cachedShaderHeight = rectHeight;
    }

    _frontWavePaint.shader = _cachedFrontShader;
    canvas.drawPath(_frontWavePath, _frontWavePaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidFillPainter oldDelegate) {
    return !identical(oldDelegate.progressListenable, progressListenable) ||
        !identical(oldDelegate.waveAnimation, waveAnimation) ||
        oldDelegate.waterColor != waterColor ||
        oldDelegate.isDark != isDark;
  }
}
