import 'package:flutter/material.dart';

/// Responsive helper untuk berbagai screen size Android
class Responsive {
  static MediaQueryData? _mediaQueryData;
  static double _screenWidth = 0;
  static double _screenHeight = 0;

  /// Inisialisasi responsive data - panggil di main.dart atau di root widget
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    _screenWidth = _mediaQueryData!.size.width;
    _screenHeight = _mediaQueryData!.size.height;
  }

  /// Width sebagai percentage dari screen width
  static double width(double percent) {
    return _screenWidth * percent;
  }

  /// Height sebagai percentage dari screen height
  static double height(double percent) {
    return _screenHeight * percent;
  }

  /// Get screen width
  static double get screenWidth => _screenWidth;

  /// Get screen height
  static double get screenHeight => _screenHeight;

  /// Get isTablet
  static bool get isTablet => _screenWidth > 600;

  /// Get isPhone
  static bool get isPhone => _screenWidth <= 600;

  /// Get isSmallPhone
  static bool get isSmallPhone => _screenWidth < 360;

  /// Padding horizontal berdasarkan screen size
  static double get horizontalPadding {
    if (isTablet) return width(0.08);
    if (_screenWidth > 400) return width(0.06);
    return width(0.05);
  }

  /// Padding vertical
  static double get verticalPadding {
    if (isTablet) return height(0.04);
    return height(0.02);
  }

  /// Font size yang responsive
  static double fontSize(double baseSize) {
    if (isTablet) return baseSize * 1.2;
    if (_screenWidth > 360) return baseSize;
    return baseSize * 0.9;
  }

  /// Icon size yang responsive
  static double iconSize(double baseSize) {
    if (isTablet) return baseSize * 1.2;
    return baseSize;
  }

  /// Spacing yang responsive
  static double spacing(double baseSpacing) {
    if (isTablet) return baseSpacing * 1.3;
    if (_screenWidth > 360) return baseSpacing;
    return baseSpacing * 0.85;
  }

  /// Border radius yang responsive
  static double radius(double baseRadius) {
    if (isTablet) return baseRadius * 1.2;
    if (_screenWidth < 320) return baseRadius * 0.8;
    return baseRadius;
  }

  /// Button height yang responsive
  static double buttonHeight(double baseHeight) {
    if (_screenWidth < 320) return baseHeight * 0.9;
    if (_screenWidth > 400) return baseHeight;
    return baseHeight * 0.95;
  }

  /// Logo size yang responsive
  static double logoSize(double baseSize) {
    if (isTablet) return baseSize * 1.3;
    if (_screenWidth > 360) return baseSize;
    return baseSize * 0.85;
  }

  /// Card padding yang responsive
  static double cardPadding(double basePadding) {
    if (isTablet) return basePadding * 1.3;
    if (_screenWidth < 360) return basePadding * 0.85;
    return basePadding;
  }

  /// Feature item size yang responsive
  static double featureIconSize(double baseSize) {
    if (isTablet) return baseSize * 1.2;
    if (_screenWidth < 360) return baseSize * 0.85;
    return baseSize;
  }
}

/// Extension untuk context agar mudah akses responsive
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isTablet => screenWidth > 600;
  bool get isPhone => screenWidth <= 600;
  bool get isSmallPhone => screenWidth < 360;
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;
}

/// SizedBox dengan height responsive
class ResponsiveSpacing extends StatelessWidget {
  final double multiplier;

  const ResponsiveSpacing({super.key, this.multiplier = 1});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: Responsive.spacing(16) * multiplier);
  }
}

/// SizedBox dengan width responsive
class ResponsiveWidth extends StatelessWidget {
  final double multiplier;

  const ResponsiveWidth({super.key, this.multiplier = 1});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: Responsive.spacing(16) * multiplier);
  }
}
