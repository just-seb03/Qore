/// File: startup_permission_card_view.dart
/// Description: Modern elevated card component presenting requests for audio storage access
/// and playback notification access, accompanied by an action button initiating runtime permissions.
///
/// Components / Classes / Functions:
/// - StartupPermissionCardView: Container card displaying required permissions and request trigger.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Interactive card detailing required audio and notification permissions
/// and providing an explicit action to launch system permission dialogs.
class StartupPermissionCardView extends StatelessWidget {
  /// Callback triggered when user accepts and requests device permissions.
  final VoidCallback onRequestPermissions;

  const StartupPermissionCardView({
    super.key,
    required this.onRequestPermissions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.startup;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 28.0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(26.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Badge & Title
              Row(
                children: [
                  Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      size: 20.0,
                      color: AppColors.futuristicWhite,
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Text(
                      l10n.permissionsCardTitle,
                      style: GoogleFonts.inconsolata(
                        fontSize: 17.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: AppColors.futuristicWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14.0),
              // Explanatory note
              Text(
                l10n.permissionsCardDescription,
                style: GoogleFonts.inconsolata(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                  letterSpacing: 0.3,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24.0),
              // Permission 1: Music / Audio Access
              _PermissionRow(
                icon: Icons.music_note_rounded,
                title: l10n.musicAccessTitle,
                description: l10n.musicAccessDescription,
              ),
              const SizedBox(height: 16.0),
              // Permission 2: Playback Notifications
              _PermissionRow(
                icon: Icons.notifications_active_rounded,
                title: l10n.notificationAccessTitle,
                description: l10n.notificationAccessDescription,
              ),
              const SizedBox(height: 30.0),
              // Action Button to request permissions
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRequestPermissions,
                  borderRadius: BorderRadius.circular(16.0),
                  child: Ink(
                    height: 52.0,
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
                        l10n.grantPermissionsButton,
                        style: GoogleFonts.inconsolata(
                          fontSize: 14.5,
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
      ),
    );
  }
}

/// Internal item displaying an icon badge, title, and descriptive body for a permission.
class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36.0,
            height: 36.0,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Icon(
              icon,
              size: 19.0,
              color: AppColors.futuristicWhite,
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inconsolata(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.futuristicWhite,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  description,
                  style: GoogleFonts.inconsolata(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
