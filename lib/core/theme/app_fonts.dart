/// File: app_fonts.dart
/// Description: Central typography architecture providing the Segoe UI font family
/// (the iconic Microsoft Metro typeface used in Windows Phone and Windows 8) across the entire application.
///
/// Components / Classes / Functions:
/// - AppFonts: Centralized font provider for Segoe UI typography and styles.
library;

import 'package:flutter/material.dart';

/// Central typography provider delivering the iconic Windows Phone / Windows 8 Segoe UI font.
abstract final class AppFonts {
  const AppFonts._();

  /// Primary font family name configured in pubspec.yaml and Windows system installations.
  static const String segoeUi = 'Segoe UI';

  /// Font family fallback chain prioritizing Segoe UI, Selawik, and system sans-serif.
  static const List<String> fallbackChain = [
    'Segoe UI',
    'Selawik',
    'sans-serif',
  ];

  /// Returns a [TextStyle] using Segoe UI with consistent metrics and fallbacks.
  static TextStyle segoe({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    final effectiveStyle = textStyle ?? const TextStyle();
    return effectiveStyle.copyWith(
      fontFamily: segoeUi,
      fontFamilyFallback: fallbackChain,
      color: color ?? effectiveStyle.color,
      backgroundColor: backgroundColor ?? effectiveStyle.backgroundColor,
      fontSize: fontSize ?? effectiveStyle.fontSize,
      fontWeight: fontWeight ?? effectiveStyle.fontWeight,
      fontStyle: fontStyle ?? effectiveStyle.fontStyle,
      letterSpacing: letterSpacing ?? effectiveStyle.letterSpacing,
      wordSpacing: wordSpacing ?? effectiveStyle.wordSpacing,
      textBaseline: textBaseline ?? effectiveStyle.textBaseline,
      height: height ?? effectiveStyle.height,
      locale: locale ?? effectiveStyle.locale,
      foreground: foreground ?? effectiveStyle.foreground,
      background: background ?? effectiveStyle.background,
      shadows: shadows ?? effectiveStyle.shadows,
      fontFeatures: fontFeatures ?? effectiveStyle.fontFeatures,
      decoration: decoration ?? effectiveStyle.decoration,
      decorationColor: decorationColor ?? effectiveStyle.decorationColor,
      decorationStyle: decorationStyle ?? effectiveStyle.decorationStyle,
      decorationThickness: decorationThickness ?? effectiveStyle.decorationThickness,
    );
  }

  /// Light weight (FontWeight.w300) - Segoe UI Light, the quintessential airy and elegant Metro header font.
  static TextStyle light({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
  }) {
    return segoe(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: FontWeight.w300,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// SemiLight weight (FontWeight.w400) - Segoe UI Semilight, the refined reading font of Windows 8 / Phone 8.
  static TextStyle semiLight({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
  }) {
    return segoe(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
