/// File: profile_header.dart
/// Description: Top header component for the Profile screen displaying a centered
/// title in the 'Inconsolata' typeface matching SpaceHeader, LibraryHeader, and SearchHeader.
///
/// Components / Classes / Functions:
/// - ProfileHeader: Stateless widget rendering the centered Inconsolata section title.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Top header for the Profile screen with centered Inconsolata typography.
class ProfileHeader extends StatelessWidget {
  /// The header text to display. Defaults to localized 'Profile'.
  final String? title;

  /// Custom padding around the header text.
  final EdgeInsetsGeometry padding;

  /// Dynamic text style for the Inconsolata title matching active theme.
  static TextStyle get _titleTextStyle => GoogleFonts.inconsolata(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.onBackground,
  );

  const ProfileHeader({
    super.key,
    this.title,
    this.padding = const EdgeInsets.only(
      top: 6.0,
      bottom: 12.0,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Text(
          title ?? context.l10n.navigation.profileTab,
          textAlign: TextAlign.center,
          style: _titleTextStyle,
        ),
      ),
    );
  }
}

