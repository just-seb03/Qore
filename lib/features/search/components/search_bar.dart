/// File: search_bar.dart
/// Description: Material Design 3 Expressive SearchBar component leveraging the
/// material_3_expressive package and material_symbols_icons. Features M3ESearchBar,
/// morphing M3ELoadingIndicator, and M3EIconButton matching the project's monochromatic design.
///
/// Components / Classes / Functions:
/// - AppSearchBar: Primary M3 Expressive search bar widget with dynamic loading and clear actions.
/// - ExpressiveSearchBar: Type alias pointing to AppSearchBar.
library;

import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Type alias for flexible naming conventions.
typedef ExpressiveSearchBar = AppSearchBar;

/// Native Material 3 Expressive SearchBar using M3ESearchBar and M3ELoadingIndicator.
class AppSearchBar extends StatelessWidget {
  /// Controller managing the text input state.
  final TextEditingController? controller;

  /// Callback executed when search query text changes.
  final ValueChanged<String>? onChanged;

  /// Callback executed when the clear button is pressed.
  final VoidCallback? onClear;

  /// Controls visibility of the morphing M3ELoadingIndicator.
  final bool isLoading;

  /// Placeholder hint text displayed when the input is empty.
  final String hintText;

  /// Optional focus node for managing keyboard focus.
  final FocusNode? focusNode;

  /// Whether the search bar should automatically focus upon rendering.
  final bool autoFocus;

  /// External padding around the search bar container.
  final EdgeInsetsGeometry padding;

  const AppSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.isLoading = false,
    this.hintText = 'Search titles, genres, creators...',
    this.focusNode,
    this.autoFocus = false,
    this.padding = const EdgeInsets.only(
      left: 16.0,
      top: 32.0,
      right: 16.0,
      bottom: 8.0,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasText = (controller?.text.isNotEmpty ?? false);

    return Padding(
      padding: padding,
      child: M3ESearchBar(
        controller: controller,
        focusNode: focusNode,
        autoFocus: autoFocus,
        onChanged: onChanged,
        contextMenuBuilder: (context, editableTextState) {
          return AdaptiveTextSelectionToolbar.editableText(
            editableTextState: editableTextState,
          );
        },
        hintText: hintText,
        hintStyle: WidgetStateProperty.all(
          TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 14.0,
            fontWeight: FontWeight.w400,
          ),
        ),
        textStyle: WidgetStateProperty.all(
          TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 8.0),
          child: Icon(
            Symbols.search_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 22.0,
          ),
        ),
        trailing: [
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: M3ELoadingIndicator(
                size: 24,
                color: AppColors.futuristicWhite,
              ),
            )
          else if (hasText)
            M3EIconButton(
              icon: Icon(
                Symbols.close_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20.0,
              ),
              variant: M3EIconButtonVariant.standard,
              size: M3EIconButtonSize.xs,
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            ),
        ],
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        ),
        side: WidgetStateProperty.all(
          BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.0),
          ),
        ),
      ),
    );
  }
}
