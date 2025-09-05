import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum SpacingSize {
  xs(4.0),
  sm(8.0),
  md(12.0),
  lg(16.0),
  xl(20.0),
  xxl(24.0),
  xxxl(32.0),
  huge(40.0),
  massive(48.0);

  const SpacingSize(this.value);
  final double value;
}

class AppSpacing {
  // Vertical Spacing
  static Widget verticalSpacing(SpacingSize size) =>
      SizedBox(height: size.value.h);

  // Horizontal Spacing
  static Widget horizontalSpacing(SpacingSize size) =>
      SizedBox(width: size.value.w);

  // Padding Values
  static const EdgeInsets paddingXS = EdgeInsets.all(4.0);
  static const EdgeInsets paddingSM = EdgeInsets.all(8.0);
  static const EdgeInsets paddingMD = EdgeInsets.all(12.0);
  static const EdgeInsets paddingLG = EdgeInsets.all(16.0);
  static const EdgeInsets paddingXL = EdgeInsets.all(20.0);
  static const EdgeInsets paddingXXL = EdgeInsets.all(24.0);
  static const EdgeInsets paddingXXXL = EdgeInsets.all(32.0);

  static const EdgeInsets horizontalPaddingXS = EdgeInsets.symmetric(
    horizontal: 4.0,
  );
  static const EdgeInsets horizontalPaddingSM = EdgeInsets.symmetric(
    horizontal: 8.0,
  );
  static const EdgeInsets horizontalPaddingMD = EdgeInsets.symmetric(
    horizontal: 12.0,
  );
  static const EdgeInsets horizontalPaddingLG = EdgeInsets.symmetric(
    horizontal: 16.0,
  );
  static const EdgeInsets horizontalPaddingXL = EdgeInsets.symmetric(
    horizontal: 20.0,
  );
  static const EdgeInsets horizontalPaddingXXL = EdgeInsets.symmetric(
    horizontal: 24.0,
  );
  static const EdgeInsets horizontalPaddingXXXL = EdgeInsets.symmetric(
    horizontal: 32.0,
  );
  static const EdgeInsets horizontalPaddingHuge = EdgeInsets.symmetric(
    horizontal: 40.0,
  );

  static const EdgeInsets verticalPaddingXS = EdgeInsets.symmetric(
    vertical: 4.0,
  );
  static const EdgeInsets verticalPaddingSM = EdgeInsets.symmetric(
    vertical: 8.0,
  );
  static const EdgeInsets verticalPaddingMD = EdgeInsets.symmetric(
    vertical: 12.0,
  );
  static const EdgeInsets verticalPaddingLG = EdgeInsets.symmetric(
    vertical: 16.0,
  );
  static const EdgeInsets verticalPaddingXL = EdgeInsets.symmetric(
    vertical: 20.0,
  );
  static const EdgeInsets verticalPaddingXXL = EdgeInsets.symmetric(
    vertical: 24.0,
  );

  // Screen Padding (for consistent screen margins)
  static const EdgeInsets screenPadding = EdgeInsets.all(20.0);
  static const EdgeInsets screenHorizontalPadding = EdgeInsets.symmetric(
    horizontal: 20.0,
  );
  static const EdgeInsets screenVerticalPadding = EdgeInsets.symmetric(
    vertical: 20.0,
  );
}
