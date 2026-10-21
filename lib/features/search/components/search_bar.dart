/// File: search_bar.dart
/// Description: Material Design 3 Expressive SearchBar component leveraging the
/// material_3_expressive package and material_symbols_icons. Features M3ESearchBar,
/// morphing M3ELoadingIndicator, and M3EIconButton matching the project's monochromatic design.
/// Implements static caching of Inconsolata TextStyles and internal ValueListenableBuilder
/// to isolate clear button visibility without triggering parent widget rebuilds on keystrokes.
///
/// Components / Classes / Functions:
/// - AppSearchBar: Primary M3 Expressive search bar widget with dynamic loading and clear actions.
///   - _baseHintTextStyle: Static cached TextStyle for hint text.
///   - _baseTextStyle: Static cached TextStyle for input text.
/// - _AppSearchBarState: State class managing effective controller and isolated reactive trailing actions.
/// - ExpressiveSearchBar: Type alias pointing to AppSearchBar.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Type alias for flexible naming conventions.
typedef ExpressiveSearchBar = AppSearchBar;

/// Native Material 3 Expressive SearchBar using M3ESearchBar and M3ELoadingIndicator.
class AppSearchBar extends StatefulWidget {
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

  /// Pre-cached base text style for the search input hint.
  static final TextStyle _baseHintTextStyle = GoogleFonts.inconsolata(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
  );

  /// Pre-cached base text style for the search input text.
  static final TextStyle _baseTextStyle = GoogleFonts.inconsolata(
    fontSize: 15.0,
    fontWeight: FontWeight.w500,
  );

  const AppSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.isLoading = false,
    this.hintText = 'What do you want to listen to?',
    this.focusNode,
    this.autoFocus = false,
    this.padding = const EdgeInsets.only(
      left: 16.0,
      top: 0.0,
      right: 16.0,
      bottom: 8.0,
    ),
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  TextEditingController? _internalController;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_internalController ??= TextEditingController());

  @override
  void didUpdateWidget(AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null) {
      _internalController = TextEditingController();
    } else if (widget.controller != null && oldWidget.controller == null) {
      _internalController?.dispose();
      _internalController = null;
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveController = _effectiveController;

    return Padding(
      padding: widget.padding,
      child: M3ESearchBar(
        controller: effectiveController,
        focusNode: widget.focusNode,
        autoFocus: widget.autoFocus,
        onChanged: widget.onChanged,
        contextMenuBuilder: (context, editableTextState) {
          return AdaptiveTextSelectionToolbar.editableText(
            editableTextState: editableTextState,
          );
        },
        hintText: widget.hintText,
        hintStyle: WidgetStatePropertyAll(
          AppSearchBar._baseHintTextStyle.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          AppSearchBar._baseTextStyle.copyWith(
            color: colorScheme.onSurface,
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
          if (widget.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: M3ELoadingIndicator(
                size: 24,
                color: AppColors.futuristicWhite,
              ),
            )
          else
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: effectiveController,
              builder: (context, value, _) {
                if (value.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return M3EIconButton(
                  icon: Icon(
                    Symbols.close_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20.0,
                  ),
                  variant: M3EIconButtonVariant.standard,
                  size: M3EIconButtonSize.xs,
                  onPressed: () {
                    effectiveController.clear();
                    widget.onClear?.call();
                  },
                );
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
