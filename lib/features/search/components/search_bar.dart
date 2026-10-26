/// File: search_bar.dart
/// Description: Material Design 3 Expressive SearchBar component with animated focus transition.
/// In unfocused state, displays the search magnifying glass icon flanked by breathing `<` and `>`
/// chevrons oscillating gently on horizontal axis with no placeholder text.
/// Upon tap/focus, smoothly animates the bar expanding: chevrons fade out, the magnifying glass travels
/// to the left margin, and the localized search placeholder ('¿Qué quieres escuchar?') and text field fade in.
/// Supports reliable keyboard focus and smooth reverse transition when exiting.
///
/// Components / Classes / Functions:
/// - AppSearchBar: Primary search bar widget with `< 🔍 >` breathing animation and focus expansion.
///   - _baseHintTextStyle: Static cached TextStyle for hint text.
///   - _baseTextStyle: Static cached TextStyle for input text.
/// - _AppSearchBarState: State class managing focus transition, chevron oscillation, and clear actions.
/// - ExpressiveSearchBar: Type alias pointing to AppSearchBar.
library;

import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Type alias for flexible naming conventions.
typedef ExpressiveSearchBar = AppSearchBar;

/// Native Material 3 Expressive SearchBar with `< 🔍 >` breathing animation and focus expansion.
class AppSearchBar extends StatefulWidget {
  /// Controller managing the text input state.
  final TextEditingController? controller;

  /// Callback executed when search query text changes.
  final ValueChanged<String>? onChanged;

  /// Callback executed when the clear button is pressed.
  final VoidCallback? onClear;

  /// Controls visibility of the morphing M3ELoadingIndicator.
  final bool isLoading;

  /// Placeholder hint text displayed when the input is focused and empty.
  final String? hintText;

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
    this.hintText,
    this.focusNode,
    this.autoFocus = false,
    this.padding = const EdgeInsets.only(
      left: 16.0,
      top: 12.0,
      right: 16.0,
      bottom: 8.0,
    ),
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar>
    with TickerProviderStateMixin {
  TextEditingController? _internalController;
  FocusNode? _internalFocusNode;

  late final AnimationController _focusAnimController;
  late final Animation<double> _focusCurvedAnimation;

  late final AnimationController _arrowAnimController;
  late final Animation<double> _arrowOffsetAnimation;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_internalController ??= TextEditingController());

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    // 1. Focus expansion transition controller
    _focusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _focusCurvedAnimation = CurvedAnimation(
      parent: _focusAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    // 2. Subtle breathing animation for '<' and '>' chevrons
    _arrowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _arrowOffsetAnimation = Tween<double>(begin: 0.0, end: 3.5).animate(
      CurvedAnimation(
        parent: _arrowAnimController,
        curve: Curves.easeInOutSine,
      ),
    );

    _effectiveFocusNode.addListener(_handleFocusOrTextChanged);
    _effectiveController.addListener(_handleFocusOrTextChanged);

    final shouldBeActive =
        _effectiveFocusNode.hasFocus || _effectiveController.text.isNotEmpty;
    _focusAnimController.value = shouldBeActive ? 1.0 : 0.0;
  }

  void _handleFocusOrTextChanged() {
    if (!mounted) return;
    final shouldBeActive =
        _effectiveFocusNode.hasFocus || _effectiveController.text.isNotEmpty;
    if (shouldBeActive) {
      if (_focusAnimController.value < 1.0 &&
          _focusAnimController.status != AnimationStatus.forward) {
        _focusAnimController.forward();
      }
    } else {
      if (_focusAnimController.value > 0.0 &&
          _focusAnimController.status != AnimationStatus.reverse) {
        _focusAnimController.reverse();
      }
    }
  }

  @override
  void didUpdateWidget(AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _internalController)
          ?.removeListener(_handleFocusOrTextChanged);
      if (widget.controller == null && oldWidget.controller != null) {
        _internalController = TextEditingController();
      } else if (widget.controller != null && oldWidget.controller == null) {
        _internalController?.dispose();
        _internalController = null;
      }
      _effectiveController.addListener(_handleFocusOrTextChanged);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)
          ?.removeListener(_handleFocusOrTextChanged);
      if (widget.focusNode == null && oldWidget.focusNode != null) {
        _internalFocusNode = FocusNode();
      } else if (widget.focusNode != null && oldWidget.focusNode == null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
      _effectiveFocusNode.addListener(_handleFocusOrTextChanged);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusOrTextChanged);
    _effectiveController.removeListener(_handleFocusOrTextChanged);
    _internalFocusNode?.dispose();
    _internalController?.dispose();
    _focusAnimController.dispose();
    _arrowAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveController = _effectiveController;

    return Padding(
      padding: widget.padding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_effectiveFocusNode.hasFocus) {
            _effectiveFocusNode.requestFocus();
          } else {
            SystemChannels.textInput.invokeMethod<void>('TextInput.show');
          }
        },
        child: SizedBox(
          height: 52.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              const collapsedWidth = 76.0;
              const barHeight = 52.0;
              const iconSize = 22.0;
              const chevronSize = 18.0;

              return AnimatedBuilder(
                animation: Listenable.merge([
                  _focusCurvedAnimation,
                  _arrowOffsetAnimation,
                ]),
                builder: (context, _) {
                  final animValue = _focusCurvedAnimation.value;
                  final arrowOffset = _arrowOffsetAnimation.value;

                  final currentWidth =
                      lerpDouble(collapsedWidth, maxWidth, animValue)!;
                  final iconLeft =
                      lerpDouble((collapsedWidth - iconSize) / 2, 16.0, animValue)!;
                  final chevronOpacity =
                      (1.0 - animValue * 2.5).clamp(0.0, 1.0);

                  // Chevrons symmetrically positioned inside collapsed width
                  final leftChevronX =
                      (collapsedWidth - iconSize) / 2 - chevronSize - 2.0 - arrowOffset;
                  final rightChevronX =
                      (collapsedWidth - iconSize) / 2 + iconSize + 2.0 + arrowOffset;

                  final barBgColor = colorScheme.surfaceContainerHigh
                      .withValues(alpha: 0.5 * animValue);
                  final barBorderColor = colorScheme.outlineVariant
                      .withValues(alpha: 0.4 * animValue);

                  return Center(
                    child: Container(
                      width: currentWidth,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: barBgColor,
                        borderRadius: BorderRadius.circular(28.0),
                        border: Border.all(
                          color: barBorderColor,
                          width: 1.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // A. Left Chevron '<' (breathing outward to left)
                          if (chevronOpacity > 0.0)
                            Positioned(
                              left: leftChevronX,
                              top: (barHeight - chevronSize) / 2,
                              child: Opacity(
                                opacity: chevronOpacity,
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  size: chevronSize,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            ),

                          // B. Animated Search Icon (travels from center to left margin: 16.0)
                          Positioned(
                            left: iconLeft,
                            top: (barHeight - iconSize) / 2,
                            child: Icon(
                              Symbols.search_rounded,
                              color: Color.lerp(
                                colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                                colorScheme.onSurfaceVariant,
                                animValue,
                              ),
                              size: iconSize,
                            ),
                          ),

                          // C. Right Chevron '>' (breathing outward to right)
                          if (chevronOpacity > 0.0)
                            Positioned(
                              left: rightChevronX,
                              top: (barHeight - chevronSize) / 2,
                              child: Opacity(
                                opacity: chevronOpacity,
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: chevronSize,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            ),

                          // D. Expanded Search Input Field & Placeholder
                          Positioned(
                            left: 48.0,
                            width: (maxWidth - 96.0).clamp(100.0, double.infinity),
                            child: Opacity(
                              opacity: animValue.clamp(0.0, 1.0),
                              child: IgnorePointer(
                                ignoring: animValue < 0.2,
                                child: TextField(
                                  controller: effectiveController,
                                  focusNode: _effectiveFocusNode,
                                  autofocus: widget.autoFocus,
                                  onChanged: widget.onChanged,
                                  onTapOutside: (_) {
                                    _effectiveFocusNode.unfocus();
                                  },
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
                                    hintStyle:
                                        AppSearchBar._baseHintTextStyle.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  contextMenuBuilder:
                                      (context, editableTextState) {
                                    return AdaptiveTextSelectionToolbar
                                        .editableText(
                                      editableTextState: editableTextState,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          // E. Trailing Action: Loading Indicator or Clear Button
                          if (animValue > 0.01)
                            Positioned(
                              right: 12.0,
                              child: Opacity(
                                opacity: animValue,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.isLoading)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
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
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              size: 20.0,
                                            ),
                                            variant:
                                                M3EIconButtonVariant.standard,
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
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
