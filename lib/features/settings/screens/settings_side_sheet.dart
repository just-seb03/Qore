/// File: settings_side_sheet.dart
/// Description: Full-height lateral side sheet sliding in from the left edge of the screen
/// upon rightward swipe gesture release in Space. Displays staged theme, brightness mode,
/// and language options with startup aesthetics and zero mid-session mutations.
/// All staged changes are persisted and applied upon dismissal, triggering an application reboot.
/// Features a vertical drag handle pill '|' centered on the right edge and pauses live tile flips while open.
///
/// Components / Classes / Functions:
/// - SettingsSideSheet: Stateful lateral drawer with right-edge drag handle and staged change application.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/database/dao/app_metadata_dao.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/localization/localization_controller.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/settings/components/settings_language_card.dart';
import 'package:project_anima/features/settings/components/settings_theme_card.dart';
import 'package:project_anima/features/settings/controls/settings_controller.dart';
import 'package:project_anima/main.dart';

/// Lateral sheet component sliding in from the edge to host Settings options.
class SettingsSideSheet extends StatefulWidget {
  /// Optional controller override for dependency injection in tests.
  final SettingsController? controller;

  const SettingsSideSheet({
    super.key,
    this.controller,
  });

  @override
  State<SettingsSideSheet> createState() => _SettingsSideSheetState();
}

class _SettingsSideSheetState extends State<SettingsSideSheet>
    with SingleTickerProviderStateMixin {
  SettingsController get _controller =>
      widget.controller ?? SettingsController.instance;

  late final AnimationController _animationController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _scrimAnimation;

  // Staged pending state: changes are only committed upon closing the sheet
  late String _pendingFamily;
  late bool _pendingIsDark;
  late AppLocale _pendingLocale;

  @override
  void initState() {
    super.initState();
    _pendingFamily = ThemeController.instance.activeFamily;
    _pendingIsDark = ThemeController.instance.isDarkMode;
    _pendingLocale = LocalizationController.instance.currentAppLocale;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _scrimAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _controller.addListener(_onControllerChanged);
    if (_controller.isSheetOpen) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_controller.isSheetOpen) {
      setState(() {
        _pendingFamily = ThemeController.instance.activeFamily;
        _pendingIsDark = ThemeController.instance.isDarkMode;
        _pendingLocale = LocalizationController.instance.currentAppLocale;
      });
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Future<void> _closeAndApplyChanges() async {
    final bool hasThemeChanged =
        _pendingFamily != ThemeController.instance.activeFamily;
    final bool hasModeChanged =
        _pendingIsDark != ThemeController.instance.isDarkMode;
    final bool hasLocaleChanged =
        _pendingLocale != LocalizationController.instance.currentAppLocale;
    final bool hasChanges =
        hasThemeChanged || hasModeChanged || hasLocaleChanged;

    _controller.closeSheet();

    if (hasChanges) {
      if (hasThemeChanged) {
        await AppMetadataDao.instance.setThemeFamily(_pendingFamily);
      }
      if (hasModeChanged) {
        await AppMetadataDao.instance.setIsDarkMode(_pendingIsDark);
      }
      if (hasLocaleChanged) {
        await AppMetadataDao.instance.setAppLanguage(_pendingLocale.languageCode);
      }

      ThemeController.instance.setTheme(_pendingFamily, isDark: _pendingIsDark);
      LocalizationController.instance.setLocale(_pendingLocale, followSystem: false);

      if (mounted) {
        AnimaApp.restart(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        if (_animationController.value <= 0.0 && !_controller.isSheetOpen) {
          return const SizedBox.shrink();
        }

        final size = MediaQuery.of(context).size;
        final sheetWidth = math.min(size.width * 0.86, 360.0);
        final bool isDark = ThemeController.instance.isDarkMode;
        final double scrimAlpha = isDark ? 0.65 : 0.38;

        return PopScope(
          canPop: !_controller.isSheetOpen,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _controller.isSheetOpen) {
              _closeAndApplyChanges();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Tap-to-dismiss Scrim Backdrop
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeAndApplyChanges,
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: _scrimAnimation.value * scrimAlpha,
                    ),
                  ),
                ),
              ),

              // Sliding Lateral Side Sheet
              Positioned(
                top: 0.0,
                bottom: 0.0,
                left: _slideAnimation.value * sheetWidth,
                width: sheetWidth,
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! < -200) {
                      _closeAndApplyChanges();
                    }
                  },
                  child: Material(
                    elevation: 16.0,
                    shadowColor: Colors.black.withValues(alpha: 0.5),
                    color: AppColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(24.0),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(24.0),
                        ),
                        border: Border(
                          right: BorderSide(
                            color: AppColors.outlineVariant.withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Internal Scrollable Content
                          SafeArea(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 12.0),

                                // Subtle minimal insignia line
                                Center(
                                  child: Container(
                                    width: 32.0,
                                    height: 3.0,
                                    decoration: BoxDecoration(
                                      color: AppColors.onSurfaceVariant
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18.0),

                                // Clean Header Title (No 'x' close button)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 20.0,
                                    right: 32.0,
                                  ),
                                  child: Text(
                                    context.l10n.settings.title,
                                    style: GoogleFonts.inconsolata(
                                      fontSize: 17.0,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.8,
                                      color: AppColors.futuristicWhite,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 14.0),
                                Divider(
                                  height: 1.0,
                                  thickness: 1.0,
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.2),
                                ),

                                // Scrollable Options Body
                                Expanded(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.only(
                                      left: 20.0,
                                      right: 30.0, // Breathing space for right handle
                                      top: 18.0,
                                      bottom: 24.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // 1. Staged Theme Family and Brightness Card
                                        SettingsThemeCard(
                                          selectedFamily: _pendingFamily,
                                          isDark: _pendingIsDark,
                                          onFamilyChanged: (family) {
                                            setState(() {
                                              _pendingFamily = family;
                                            });
                                          },
                                          onModeChanged: (isDark) {
                                            setState(() {
                                              _pendingIsDark = isDark;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 18.0),

                                        // 2. Staged Language Card
                                        SettingsLanguageCard(
                                          selectedLocale: _pendingLocale,
                                          onLocaleChanged: (locale) {
                                            setState(() {
                                              _pendingLocale = locale;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 42.0),

                                        // 3. Clean minimal footer: project_anima & version 1.0.0
                                        Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'project_anima',
                                                style: GoogleFonts.inconsolata(
                                                  fontSize: 13.0,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 2.5,
                                                  color: AppColors.onSurfaceVariant
                                                      .withValues(alpha: 0.6),
                                                ),
                                              ),
                                              const SizedBox(height: 3.0),
                                              Text(
                                                '1.0.0',
                                                style: GoogleFonts.inconsolata(
                                                  fontSize: 11.5,
                                                  letterSpacing: 1.5,
                                                  color: AppColors.onSurfaceVariant
                                                      .withValues(alpha: 0.4),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 20.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Vertical Drag Handle Pill '|' Centered on the Right Edge
                          Positioned(
                            right: 0.0,
                            top: 0.0,
                            bottom: 0.0,
                            child: Center(
                              child: GestureDetector(
                                key: const ValueKey('settings_sheet_drag_handle'),
                                behavior: HitTestBehavior.opaque,
                                onTap: _closeAndApplyChanges,
                                child: Container(
                                  width: 28.0,
                                  height: 80.0,
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 4.5,
                                    height: 48.0,
                                    decoration: BoxDecoration(
                                      color: AppColors.onSurfaceVariant
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(2.5),
                                    ),
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
              ),
            ],
          ),
        );
      },
    );
  }
}
