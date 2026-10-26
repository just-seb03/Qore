/// File: startup_theme_selector_view.dart
/// Description: Interactive theme selection view featuring an identical miniature clone of the
/// expanded music player (presenting "Dewdrop Digital" by Iglooghost from album "Tidal Memory Exo",
/// duration 4:05 paused with full-width square cover, Inconsolata metadata, M3 squiggly wavy seek bar,
/// circular bordered controls, and live reactive theme palette updates), ordered theme family selector
/// (Monochrome, That Pad, Neo-Tokyo, Solar, Corporate), Dark/Light mode toggle, and bottom-docked Next button.
///
/// Components / Classes / Functions:
/// - StartupThemeSelectorView: Stateful theme selection view.
/// - StartupPlayerPreview: Exact miniature visual clone of PlayerScreen.
/// - _MiniWavyTrackPainter: Custom painter rendering the M3 Expressive sinusoidal wave for the mock player.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/startup/models/startup_theme_option.dart';

/// Screen presenting a miniature clone of the expanded player view with real-time theme reactivity,
/// ordered theme selector (< Monochrome >, < That Pad >, < Neo-Tokyo >, < Solar >, < Corporate >),
/// mode selector (< Dark > / < Light >), and bottom-docked next button.
class StartupThemeSelectorView extends StatefulWidget {
  /// Callback triggered when the user accepts the active theme.
  final VoidCallback onAccept;

  /// Optional initial theme option. Defaults to [StartupThemeOption.monochrome].
  final StartupThemeOption? initialThemeOption;

  /// Optional initial brightness mode. Defaults to dark mode (`true`).
  final bool initialIsDark;

  const StartupThemeSelectorView({
    super.key,
    required this.onAccept,
    this.initialThemeOption,
    this.initialIsDark = true,
  });

  @override
  State<StartupThemeSelectorView> createState() => _StartupThemeSelectorViewState();
}

class _StartupThemeSelectorViewState extends State<StartupThemeSelectorView> {
  late int _selectedThemeIndex;
  late bool _isDark;

  List<StartupThemeOption> get _themeOptions => StartupThemeOption.all;
  StartupThemeOption get _selectedOption => _themeOptions[_selectedThemeIndex];

  @override
  void initState() {
    super.initState();
    final currentFamily = widget.initialThemeOption?.id ?? ThemeController.instance.activeFamily;
    final foundIndex = _themeOptions.indexWhere((opt) => opt.id == currentFamily);
    _selectedThemeIndex = foundIndex >= 0 ? foundIndex : 0;
    _isDark = widget.initialIsDark;
  }

  void _selectThemeAt(int index) {
    final clamped = (index + _themeOptions.length) % _themeOptions.length;
    setState(() {
      _selectedThemeIndex = clamped;
    });
    ThemeController.instance.setTheme(
      _selectedOption.id,
      isDark: _isDark,
    );
  }

  void _nextTheme() => _selectThemeAt(_selectedThemeIndex + 1);
  void _prevTheme() => _selectThemeAt(_selectedThemeIndex - 1);

  void _toggleMode() {
    setState(() {
      _isDark = !_isDark;
    });
    ThemeController.instance.setTheme(
      _selectedOption.id,
      isDark: _isDark,
    );
  }

  void _onAcceptTheme() {
    ThemeController.instance.setTheme(
      _selectedOption.id,
      isDark: _isDark,
    );
    widget.onAccept();
  }

  String _localizedThemeName(BuildContext context, String id) {
    final l10n = context.l10n.startup;
    switch (id) {
      case 'monochrome':
        return l10n.themeNameMonochrome;
      case 'that_pad':
        return l10n.themeNameThatPad;
      case 'neo_tokyo':
        return l10n.themeNameNeoTokyo;
      case 'solar':
        return l10n.themeNameSolar;
      case 'corporate':
      default:
        return l10n.themeNameCorporate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.startup;
    final String currentDisplayName = _localizedThemeName(context, _selectedOption.id);
    final String currentModeName = _isDark ? l10n.darkModeLabel : l10n.lightModeLabel;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section: Scaled down identical clone of Expanded Player
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! < -150) {
                          _nextTheme();
                        } else if (details.primaryVelocity! > 150) {
                          _prevTheme();
                        }
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Prompt Title: "¿Cuál es tu estilo?" in Inconsolata
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            l10n.themePromptTitle,
                            key: const ValueKey('startup_theme_prompt_title'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inconsolata(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppColors.futuristicWhite,
                            ),
                          ),
                        ),

                        // Identical miniature replica of PlayerScreen
                        StartupPlayerPreview(
                          isDark: _isDark,
                          themeOption: _selectedOption,
                        ),
                        const SizedBox(height: 10.0),

                        // Swipeable Theme Family Selector: < ThemeName >
                        GestureDetector(
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity != null) {
                              if (details.primaryVelocity! < -120) {
                                _nextTheme();
                              } else if (details.primaryVelocity! > 120) {
                                _prevTheme();
                              }
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                key: const ValueKey('startup_theme_prev_button'),
                                icon: const Icon(Icons.chevron_left_rounded),
                                color: AppColors.onSurfaceVariant,
                                iconSize: 24.0,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                                onPressed: _prevTheme,
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, anim) => FadeTransition(
                                  opacity: anim,
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 0.94, end: 1.0).animate(anim),
                                    child: child,
                                  ),
                                ),
                                child: Text(
                                  '< $currentDisplayName >',
                                  key: ValueKey('theme_name_${_selectedOption.id}'),
                                  style: GoogleFonts.inconsolata(
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.0,
                                    color: AppColors.futuristicWhite,
                                  ),
                                ),
                              ),
                              IconButton(
                                key: const ValueKey('startup_theme_next_button'),
                                icon: const Icon(Icons.chevron_right_rounded),
                                color: AppColors.onSurfaceVariant,
                                iconSize: 24.0,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                                onPressed: _nextTheme,
                              ),
                            ],
                          ),
                        ),

                        // Swipeable Dark / Light Mode Selector: < Oscuro > / < Claro >
                        GestureDetector(
                          onTap: _toggleMode,
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 100) {
                              _toggleMode();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  key: const ValueKey('startup_mode_toggle_prev'),
                                  icon: const Icon(Icons.chevron_left_rounded),
                                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                                  iconSize: 18.0,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 26.0, minHeight: 26.0),
                                  onPressed: _toggleMode,
                                ),
                                const SizedBox(width: 4.0),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    '< $currentModeName >',
                                    key: ValueKey('mode_name_$_isDark'),
                                    style: GoogleFonts.inconsolata(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.6,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                IconButton(
                                  key: const ValueKey('startup_mode_toggle_next'),
                                  icon: const Icon(Icons.chevron_right_rounded),
                                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                                  iconSize: 18.0,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 26.0, minHeight: 26.0),
                                  onPressed: _toggleMode,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10.0),

            // Bottom-docked Next Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('startup_theme_accept_button'),
                onTap: _onAcceptTheme,
                borderRadius: BorderRadius.circular(16.0),
                child: Ink(
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.28),
                        blurRadius: 12.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      l10n.nextAction,
                      style: GoogleFonts.inconsolata(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                        color: AppColors.onAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Identical miniature visual clone of [PlayerScreen] presenting
/// "Dewdrop Digital" by Iglooghost from album "Tidal Memory Exo"
/// (duration 4:05, paused at 1:38), with live reactivity to the active theme palette.
class StartupPlayerPreview extends StatelessWidget {
  final bool isDark;
  final StartupThemeOption themeOption;

  const StartupPlayerPreview({
    super.key,
    required this.isDark,
    required this.themeOption,
  });

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 196.0;

    return SizedBox(
      width: cardWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Giant Square Cover covering entire upper width (identical to PlayerArtworkView)
          SizedBox(
            width: cardWidth,
            height: cardWidth,
            child: Image.asset(
              'lib/core/img/cover.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surfaceContainerHigh,
                child: Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 46.0,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),

          // 2. Lower Section: Metadata, Wavy Progress Bar, Circular Border Controls, V Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Metadata (Dewdrop Digital - Iglooghost - Tidal Memory Exo)
                Text(
                  'Dewdrop Digital',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inconsolata(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.futuristicWhite,
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  'Iglooghost',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inconsolata(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1.0),
                Text(
                  'Tidal Memory Exo',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inconsolata(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurfaceDisabled,
                  ),
                ),
                const SizedBox(height: 7.0),

                // Wavy Seek Bar (paused at 1:38 / 4:05)
                CustomPaint(
                  size: const Size(cardWidth - 24.0, 14.0),
                  painter: const _MiniWavyTrackPainter(
                    progress: 0.40,
                    phase: 0.0,
                    isPlaying: false,
                  ),
                ),
                const SizedBox(height: 1.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1:38',
                      style: GoogleFonts.inconsolata(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '4:05',
                      style: GoogleFonts.inconsolata(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7.0),

                // Playback Controls Row (exact replica of PlayerControls)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Shuffle icon with dot
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shuffle_rounded,
                          size: 14.0,
                          color: AppColors.onSurfaceDisabled,
                        ),
                        const SizedBox(height: 2.0),
                        Container(
                          width: 3.0,
                          height: 3.0,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                        ),
                      ],
                    ),

                    // Previous Circular Border Button
                    Container(
                      width: 30.0,
                      height: 30.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.outline,
                          width: 1.1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.skip_previous_rounded,
                          size: 16.5,
                          color: AppColors.futuristicWhite,
                        ),
                      ),
                    ),

                    // Center Play Button in theme accent with shadow (paused)
                    Container(
                      width: 38.0,
                      height: 38.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.28),
                            blurRadius: 9.0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 22.0,
                          color: AppColors.onAccent,
                        ),
                      ),
                    ),

                    // Next Circular Border Button
                    Container(
                      width: 30.0,
                      height: 30.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.outline,
                          width: 1.1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.skip_next_rounded,
                          size: 16.5,
                          color: AppColors.futuristicWhite,
                        ),
                      ),
                    ),

                    // Repeat icon with dot
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          size: 14.0,
                          color: AppColors.onSurfaceDisabled,
                        ),
                        const SizedBox(height: 2.0),
                        Container(
                          width: 3.0,
                          height: 3.0,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),

                // Dismiss Indicator (V Chevron at bottom of player)
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16.0,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Miniature CustomPainter for the Material 3 Expressive wavy progress bar.
class _MiniWavyTrackPainter extends CustomPainter {
  final double progress;
  final double phase;
  final bool isPlaying;

  static const double trackHeight = 2.5;
  static const double thumbRadius = 4.5;
  static const double wavelength = 16.0;
  static const double waveAmplitude = 2.4;

  const _MiniWavyTrackPainter({
    required this.progress,
    required this.phase,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cy = size.height / 2;
    final double trackWidth = size.width;
    final double thumbX = (trackWidth * progress).clamp(0.0, trackWidth);

    // 1. Inactive straight track
    if (thumbX < trackWidth) {
      final inactivePaint = Paint()
        ..color = AppColors.surfaceContainerHighest
        ..strokeWidth = trackHeight
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(thumbX, cy),
        Offset(trackWidth, cy),
        inactivePaint,
      );
    }

    // 2. Active sinusoidal wavy track
    if (thumbX > 0) {
      final activePaint = Paint()
        ..color = AppColors.accent
        ..strokeWidth = trackHeight
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final Path wavePath = Path();
      wavePath.moveTo(0, cy);

      const double step = 1.0;
      final double activeLength = thumbX;
      final double currentAmplitude = waveAmplitude * 0.5;

      for (double x = 0; x <= activeLength; x += step) {
        double taper = 1.0;
        if (x < 8.0) {
          taper = x / 8.0;
        } else if (activeLength - x < 8.0) {
          taper = (activeLength - x) / 8.0;
        }

        final double y = cy +
            currentAmplitude *
                taper *
                math.sin((x / wavelength) * 2 * math.pi - phase);

        wavePath.lineTo(x, y);
      }

      wavePath.lineTo(thumbX, cy);
      canvas.drawPath(wavePath, activePaint);
    }

    // 3. Thumb circle
    final thumbPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(thumbX, cy), thumbRadius, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniWavyTrackPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.isPlaying != isPlaying;
  }
}
