/// File: search_bar.dart
/// Description: Windows Phone Metro SearchBar component with sharp 90-degree corners,
/// crisp accent focus border, direct TextField input, and clear/loading trailing actions.
///
/// Components / Classes / Functions:
/// - AppSearchBar: Primary Metro search bar widget.
/// - _AppSearchBarState: State class managing focus border styling and clear actions.
/// - ExpressiveSearchBar: Type alias pointing to AppSearchBar.
library;

import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Type alias for flexible naming conventions.
typedef ExpressiveSearchBar = AppSearchBar;

/// Clean Windows Phone Metro SearchBar with direct TextField focus and zero animation interference.
class AppSearchBar extends StatefulWidget {
  /// Controller managing the text input state.
  final TextEditingController? controller;

  /// Callback executed when search query text changes.
  final ValueChanged<String>? onChanged;

  /// Callback executed when the clear button is pressed.
  final VoidCallback? onClear;

  /// Kept for backward compatibility with callers.
  final bool? isExpanded;

  /// Kept for backward compatibility with callers.
  final VoidCallback? onExpand;

  /// Controls visibility of the morphing M3ELoadingIndicator.
  final bool isLoading;

  /// Placeholder hint text displayed when the input is empty.
  final String? hintText;

  /// Optional focus node for managing keyboard focus.
  final FocusNode? focusNode;

  /// Whether the search bar should automatically focus upon rendering.
  final bool autoFocus;

  /// External padding around the search bar container.
  final EdgeInsetsGeometry padding;

  /// Pre-cached base text style for the search input hint.
  static final TextStyle _baseHintTextStyle = AppFonts.segoe(
    fontSize: 15.0,
    fontWeight: FontWeight.w300,
  );

  /// Pre-cached base text style for the search input text.
  static final TextStyle _baseTextStyle = AppFonts.segoe(
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
  );

  const AppSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.isExpanded,
    this.onExpand,
    this.isLoading = false,
    this.hintText,
    this.focusNode,
    this.autoFocus = false,
    this.padding = const EdgeInsets.only(
      left: 16.0,
      top: 8.0,
      right: 16.0,
      bottom: 12.0,
    ),
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  TextEditingController? _internalController;
  FocusNode? _internalFocusNode;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_internalController ??= TextEditingController());

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void didUpdateWidget(AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (widget.controller == null && oldWidget.controller != null) {
        _internalController = TextEditingController();
      } else if (widget.controller != null && oldWidget.controller == null) {
        _internalController?.dispose();
        _internalController = null;
      }
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (widget.focusNode == null && oldWidget.focusNode != null) {
        _internalFocusNode = FocusNode();
      } else if (widget.focusNode != null && oldWidget.focusNode == null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveController = _effectiveController;
    final effectiveFocusNode = _effectiveFocusNode;

    return TapRegion(
      onTapOutside: (_) {
        if (effectiveFocusNode.hasFocus) {
          effectiveFocusNode.unfocus();
        }
      },
      child: Padding(
        padding: widget.padding,
        child: ListenableBuilder(
          listenable: effectiveFocusNode,
          builder: (context, child) {
            final isFocused = effectiveFocusNode.hasFocus;
            final barBgColor = colorScheme.surfaceContainerHigh.withValues(alpha: 0.45);
            final barBorderColor = isFocused
                ? AppColors.accent.withValues(alpha: 0.85)
                : colorScheme.outlineVariant.withValues(alpha: 0.55);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget.onExpand?.call();
                if (!effectiveFocusNode.hasFocus) {
                  effectiveFocusNode.requestFocus();
                }
              },
              child: Container(
                height: 44.0,
                decoration: BoxDecoration(
                  color: barBgColor,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: barBorderColor,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: child,
              ),
            );
          },
          child: Row(
            children: [
              Icon(
                Symbols.search_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 22.0,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: TextField(
                  controller: effectiveController,
                  focusNode: effectiveFocusNode,
                  autofocus: widget.autoFocus,
                  onChanged: widget.onChanged,
                  onTapOutside: (_) {},
                  style: AppSearchBar._baseTextStyle.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.hintText ??
                        context.l10n.search.searchPlaceholder,
                    hintStyle: AppSearchBar._baseHintTextStyle.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.editableText(
                      editableTextState: editableTextState,
                    );
                  },
                ),
              ),
              if (widget.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: M3ELoadingIndicator(
                    size: 20,
                    color: AppColors.accent,
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
          ),
        ),
      ),
    );
  }
}
