/// File: playlist_color_picker_dialog.dart
/// Description: Interactive web-style custom color picker dialog with visual HSV sliders,
/// direct HEX input with clipboard paste support, live preview swatch, and quick palette presets.
///
/// Components / Classes / Functions:
/// - PlaylistColorPickerDialog: Modal dialog for fine-tuned ARGB color selection.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/core/theme/theme.dart';

/// Interactive modal dialog allowing precise visual and HEX color selection.
class PlaylistColorPickerDialog extends StatefulWidget {
  /// Initial color when opening the picker.
  final Color initialColor;

  /// Dialog header title (e.g. 'COLOR SÓLIDO', 'COLOR INICIAL', 'COLOR FINAL').
  final String title;

  const PlaylistColorPickerDialog({
    super.key,
    required this.initialColor,
    this.title = 'PERSONALIZAR COLOR',
  });

  /// Displays the [PlaylistColorPickerDialog] modal and returns the chosen [Color], or null if dismissed.
  static Future<Color?> show(
    BuildContext context, {
    required Color initialColor,
    String title = 'PERSONALIZAR COLOR',
  }) {
    return showDialog<Color>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PlaylistColorPickerDialog(
        initialColor: initialColor,
        title: title,
      ),
    );
  }

  @override
  State<PlaylistColorPickerDialog> createState() => _PlaylistColorPickerDialogState();
}

class _PlaylistColorPickerDialogState extends State<PlaylistColorPickerDialog> {
  late double _hue; // 0.0 - 360.0
  late double _saturation; // 0.0 - 1.0
  late double _value; // 0.0 - 1.0

  late TextEditingController _hexController;
  bool _isUpdatingFromHex = false;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;

    _hexController = TextEditingController(
      text: _colorToHex(widget.initialColor),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _currentColor {
    return HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
  }

  String _colorToHex(Color color) {
    return (color.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  void _onColorChanged({bool updateHexField = true}) {
    if (updateHexField) {
      _isUpdatingFromHex = true;
      _hexController.text = _colorToHex(_currentColor);
      _isUpdatingFromHex = false;
    }
    setState(() {});
  }

  void _handleHexInput(String value) {
    if (_isUpdatingFromHex) return;
    final clean = value.replaceAll('#', '').trim().toUpperCase();
    if (clean.length == 6) {
      final parsed = int.tryParse('FF$clean', radix: 16);
      if (parsed != null) {
        final color = Color(parsed);
        final hsv = HSVColor.fromColor(color);
        setState(() {
          _hue = hsv.hue;
          _saturation = hsv.saturation;
          _value = hsv.value;
        });
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    final clean = text.replaceAll('#', '').trim().toUpperCase();
    if (clean.length == 6) {
      _hexController.text = clean;
      _handleHexInput(clean);
    } else if (clean.length == 8) {
      // Ignore alpha if 8 chars
      final hex6 = clean.substring(2);
      _hexController.text = hex6;
      _handleHexInput(hex6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _currentColor;
    final isDark = activeColor.computeLuminance() < 0.45;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380.0),
        decoration: BoxDecoration(
          color: AppColors.bottomNavBackground,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.35),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.75),
              blurRadius: 32.0,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header with Title and Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: AppFonts.segoe(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20.0, color: AppColors.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 18.0,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // 2. Large Color Preview & Hex Swatch
              Container(
                height: 64.0,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.45),
                      blurRadius: 16.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '#${_colorToHex(activeColor)}',
                  style: AppFonts.segoe(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 18.0),

              // 3. HEX Input Field with Paste helper
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.45),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
                child: Row(
                  children: [
                    Text(
                      '#',
                      style: AppFonts.segoe(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextField(
                        controller: _hexController,
                        onChanged: _handleHexInput,
                        maxLength: 6,
                        style: AppFonts.segoe(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: AppColors.onSurface,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'FFFFFF',
                          counterText: '',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.paste_rounded, size: 18.0),
                      color: AppColors.onSurfaceVariant,
                      tooltip: 'Pegar código HEX',
                      splashRadius: 18.0,
                      onPressed: _pasteFromClipboard,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // 4. Hue Slider (0° - 360°)
              _buildSliderLabel('MATIZ (HUE)', '${_hue.toInt()}°'),
              Container(
                height: 24.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF0000),
                      Color(0xFFFFFF00),
                      Color(0xFF00FF00),
                      Color(0xFF00FFFF),
                      Color(0xFF0000FF),
                      Color(0xFFFF00FF),
                      Color(0xFFFF0000),
                    ],
                  ),
                ),
                child: SliderTheme(
                  data: _sliderThemeData(Colors.white),
                  child: Slider(
                    value: _hue,
                    min: 0.0,
                    max: 360.0,
                    onChanged: (val) {
                      _hue = val;
                      _onColorChanged();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14.0),

              // 5. Saturation Slider (0% - 100%)
              _buildSliderLabel('SATURACIÓN', '${(_saturation * 100).toInt()}%'),
              Container(
                height: 24.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  gradient: LinearGradient(
                    colors: [
                      HSVColor.fromAHSV(1.0, _hue, 0.0, _value).toColor(),
                      HSVColor.fromAHSV(1.0, _hue, 1.0, _value).toColor(),
                    ],
                  ),
                ),
                child: SliderTheme(
                  data: _sliderThemeData(Colors.white),
                  child: Slider(
                    value: _saturation,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      _saturation = val;
                      _onColorChanged();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14.0),

              // 6. Brightness / Value Slider (0% - 100%)
              _buildSliderLabel('BRILLO', '${(_value * 100).toInt()}%'),
              Container(
                height: 24.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black,
                      HSVColor.fromAHSV(1.0, _hue, _saturation, 1.0).toColor(),
                    ],
                  ),
                ),
                child: SliderTheme(
                  data: _sliderThemeData(Colors.white),
                  child: Slider(
                    value: _value,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      _value = val;
                      _onColorChanged();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12.0),

              // 7. Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.onSurfaceVariant,
                    ),
                    child: Text(
                      'CANCELAR',
                      style: AppFonts.segoe(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(_currentColor),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18.0),
                    label: Text(
                      'APLICAR',
                      style: AppFonts.segoe(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderLabel(String title, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppFonts.segoe(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (val.isNotEmpty)
            Text(
              val,
              style: AppFonts.segoe(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  SliderThemeData _sliderThemeData(Color thumbColor) {
    return SliderThemeData(
      trackHeight: 24.0,
      activeTrackColor: Colors.transparent,
      inactiveTrackColor: Colors.transparent,
      thumbColor: thumbColor,
      overlayColor: thumbColor.withValues(alpha: 0.2),
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 10.0,
        elevation: 3.0,
      ),
    );
  }
}
