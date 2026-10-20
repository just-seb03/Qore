/// File: search_loading_view.dart
/// Description: Centered loading state view displayed while debouncing or awaiting
/// fuzzy search engine results.
///
/// Components / Classes / Functions:
/// - SearchLoadingView: Indeterminate progress indicator widget.
library;

import 'package:flutter/material.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Loading indicator displayed during search debounce or in-flight engine execution.
class SearchLoadingView extends StatelessWidget {
  /// Stroke width of the spinner. Defaults to 2.0.
  final double strokeWidth;

  /// Spinner size. Defaults to 32.0.
  final double size;

  const SearchLoadingView({
    super.key,
    this.strokeWidth = 2.0,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          color: AppColors.futuristicWhite,
        ),
      ),
    );
  }
}
