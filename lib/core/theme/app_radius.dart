import 'package:flutter/material.dart';

/// Standardized border radius values for consistent UI throughout the app.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: AppRadius.md,
///   ),
/// )
/// ```
class AppRadius {
  AppRadius._();

  // Raw radius values
  static const double _xs = 4.0;
  static const double _sm = 8.0;
  static const double _md = 12.0;
  static const double _lg = 16.0;
  static const double _xl = 20.0;
  static const double _xxl = 24.0;
  static const double _pill = 100.0;

  // BorderRadius constants
  static const BorderRadius none = BorderRadius.zero;
  static const BorderRadius xs = BorderRadius.all(Radius.circular(_xs));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(_sm));
  static const BorderRadius md = BorderRadius.all(Radius.circular(_md));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(_lg));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(_xl));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(_xxl));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(_pill));

  // Circular radius for individual corners
  static const Radius circularXs = Radius.circular(_xs);
  static const Radius circularSm = Radius.circular(_sm);
  static const Radius circularMd = Radius.circular(_md);
  static const Radius circularLg = Radius.circular(_lg);
  static const Radius circularXl = Radius.circular(_xl);
  static const Radius circularXxl = Radius.circular(_xxl);

  // Top-only rounded corners
  static const BorderRadius topSm = BorderRadius.vertical(top: Radius.circular(_sm));
  static const BorderRadius topMd = BorderRadius.vertical(top: Radius.circular(_md));
  static const BorderRadius topLg = BorderRadius.vertical(top: Radius.circular(_lg));
  static const BorderRadius topXl = BorderRadius.vertical(top: Radius.circular(_xl));
  static const BorderRadius topXxl = BorderRadius.vertical(top: Radius.circular(_xxl));

  // Bottom-only rounded corners
  static const BorderRadius bottomSm = BorderRadius.vertical(bottom: Radius.circular(_sm));
  static const BorderRadius bottomMd = BorderRadius.vertical(bottom: Radius.circular(_md));
  static const BorderRadius bottomLg = BorderRadius.vertical(bottom: Radius.circular(_lg));
  static const BorderRadius bottomXl = BorderRadius.vertical(bottom: Radius.circular(_xl));

  // Card and dialog radius (commonly used)
  static const BorderRadius card = md;
  static const BorderRadius dialog = lg;
  static const BorderRadius button = md;
  static const BorderRadius input = md;
  static const BorderRadius chip = sm;
  static const BorderRadius bottomSheet = topXxl;

  // Helper methods for custom radius
  static BorderRadius circular(double radius) => BorderRadius.circular(radius);
  static BorderRadius only({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomLeft: Radius.circular(bottomLeft),
      bottomRight: Radius.circular(bottomRight),
    );
  }
}
