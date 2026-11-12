/// File: explore_header.dart
/// Description: Top header component for the Explore screen styled in the authentic
/// Windows Phone Metro Pivot/Panorama design language with Segoe UI Light typography.
///
/// Components / Classes / Functions:
/// - ExploreHeader: Stateless widget rendering the authentic Metro pivot section header.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Top header for the Explore screen in Windows Phone Metro Pivot aesthetic.
class ExploreHeader extends StatelessWidget {
  /// The header text to display. Defaults to localized 'Explore'.
  final String? title;

  /// Optional Metro category overline. Defaults to 'MÚSICA'.
  final String? category;

  /// Custom padding around the header.
  final EdgeInsetsGeometry padding;

  const ExploreHeader({
    super.key,
    this.title,
    this.category,
    this.padding = const EdgeInsets.only(
      left: 20.0,
      right: 20.0,
      top: 12.0,
      bottom: 12.0,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title ?? context.l10n.navigation.exploreTab;
    final effectiveCategory = category ?? 'MÚSICA';

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small uppercase category overline
          Text(
            effectiveCategory.toUpperCase(),
            style: AppFonts.segoe(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 2.5,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 2.0),
          // Large panoramic pivot title in Segoe UI Light
          Text(
            effectiveTitle.toLowerCase(),
            style: AppFonts.segoe(
              fontSize: 34.0,
              fontWeight: FontWeight.w300,
              letterSpacing: -0.5,
              color: AppColors.onBackground,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
