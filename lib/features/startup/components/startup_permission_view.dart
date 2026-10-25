/// File: startup_permission_view.dart
/// Description: Dedicated permission request screen presented when audio/storage permissions
/// are missing or declined, rendered strictly in Inconsolata typography and monochromatic aesthetic.
///
/// Components / Classes / Functions:
/// - StartupPermissionView: Clean permission explanation card with retry action button.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Permission requirement screen presented when audio storage access is missing.
class StartupPermissionView extends StatelessWidget {
  /// Callback executed when the user taps the action button to request or retry permissions.
  final VoidCallback onRequestPermission;

  /// Optional custom title. Defaults to localized [StartupStrings.audioAccessRequiredTitle].
  final String? title;

  /// Optional custom message. Defaults to localized [StartupStrings.audioAccessRequiredMessage].
  final String? message;

  /// Optional custom action button text. Defaults to localized [StartupStrings.continueAction].
  final String? actionText;

  const StartupPermissionView({
    super.key,
    required this.onRequestPermission,
    this.title,
    this.message,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Music note insignia icon in rounded elevated container
            Container(
              width: 80.0,
              height: 80.0,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.6),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16.0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.music_note_rounded,
                size: 38.0,
                color: AppColors.futuristicWhite,
              ),
            ),
            const SizedBox(height: 28.0),
            // 2. Permission title in Inconsolata
            Text(
              title ?? context.l10n.startup.audioAccessRequiredTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inconsolata(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: AppColors.futuristicWhite,
              ),
            ),
            const SizedBox(height: 12.0),
            // 3. Informational description in Inconsolata
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                message ?? context.l10n.startup.audioAccessRequiredMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inconsolata(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  letterSpacing: 0.4,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 36.0),
            // 4. Material 3 Expressive pill action button in Inconsolata
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRequestPermission,
                borderRadius: BorderRadius.circular(28.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36.0,
                    vertical: 14.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(28.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.28),
                        blurRadius: 12.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionText ?? context.l10n.startup.continueAction,
                        style: GoogleFonts.inconsolata(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: AppColors.onAccent,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16.0,
                        color: AppColors.onAccent,
                      ),
                    ],
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
