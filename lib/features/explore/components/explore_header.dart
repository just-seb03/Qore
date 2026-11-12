/// File: explore_header.dart
/// Description: Top header component for the Explore screen styled in the authentic
/// Windows Phone Metro Pivot/Panorama design language with prominent Segoe UI Light typography.
///
/// Components / Classes / Functions:
/// - ExploreHeader: Stateless widget rendering the authentic Metro pivot section header.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Top header for the Explore screen in Windows Phone Metro Pivot aesthetic.
class ExploreHeader extends StatelessWidget {
  /// The header text to display. Defaults to localized 'Explorar'.
  final String? title;

  /// Custom padding around the header.
  final EdgeInsetsGeometry padding;

  const ExploreHeader({
    super.key,
    this.title,
    this.padding = const EdgeInsets.only(
      left: 20.0,
      right: 20.0,
      top: 14.0,
      bottom: 10.0,
    ),
  });

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    final lower = text.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final rawTitle = title ?? context.l10n.navigation.exploreTab;
    final displayTitle = _capitalize(rawTitle);

    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          displayTitle,
          style: AppFonts.segoe(
            fontSize: 42.0,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
            color: AppColors.onBackground,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
