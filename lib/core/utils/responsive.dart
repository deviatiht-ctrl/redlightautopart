import 'package:flutter/material.dart';

/// Klas ki jere responsive layout pou Redlight Autoparts:
/// Mobil (< 650px), Tablet (650px - 1024px), Laptop/Desktop (>= 1024px).
class Responsive {
  static const double mobileBreakpoint = 650;
  static const double tabletBreakpoint = 1024;
  static const double maxContentWidth = 1200;
  static const double maxFormWidth = 600;
  static const double maxDetailWidth = 1100;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobileBreakpoint && w < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileBreakpoint;

  /// Kalkile kantite kolòn pou griy pwodwi yo selon lajè ekran an
  static int productGridColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 480) return 2;
    if (w < 768) return 3;
    if (w < 1100) return 4;
    if (w < 1400) return 5;
    return 6;
  }

  /// Kalkile kantite kolòn pou kategori yo
  static int categoryColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 650) return 1;
    if (w < 1024) return 2;
    return 3;
  }

  /// Padding orizontal adaptif
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 650) return 16;
    if (w < 1024) return 24;
    return 32;
  }
}

/// Widget ki santre kontni an ak yon lajè maksimòm pou ekran gwo
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxContentWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
