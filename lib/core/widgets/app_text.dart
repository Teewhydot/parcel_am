import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum TextVariant {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

enum TextArrangement {
  left,
  right,
  center,
  justify,
  start,
  end,
}

enum TextWrap {
  noWrap,
  wrap,
  ellipsis,
  fade,
  clip,
  visible,
}

class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.variant = TextVariant.bodyMedium,
    this.color,
    this.textAlign,
    this.arrangement,
    this.wrap = TextWrap.wrap,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    this.fontSize,
    this.height,
    this.letterSpacing,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.decorationThickness,
    this.fontStyle,
    this.textBaseline,
    this.textDirection,
    this.softWrap,
    this.textScaler,
    this.onTap,
    this.selectable = false,
    this.width,
    this.padding,
    this.margin,
  });

  factory AppText.displayLarge(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    TextArrangement? arrangement,
    TextWrap wrap = TextWrap.wrap,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    VoidCallback? onTap,
    double? width,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AppText(
      text,
      key: key,
      variant: TextVariant.displayLarge,
      color: color,
      textAlign: textAlign,
      arrangement: arrangement,
      wrap: wrap,
      maxLines: maxLines,
      overflow: overflow,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      onTap: onTap,
      width: width,
      padding: padding,
      margin: margin,
    );
  }

  factory AppText.headlineLarge(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    TextArrangement? arrangement,
    TextWrap wrap = TextWrap.wrap,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    VoidCallback? onTap,
    double? width,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AppText(
      text,
      key: key,
      variant: TextVariant.headlineLarge,
      color: color,
      textAlign: textAlign,
      arrangement: arrangement,
      wrap: wrap,
      maxLines: maxLines,
      overflow: overflow,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      onTap: onTap,
      width: width,
      padding: padding,
      margin: margin,
    );
  }

  factory AppText.titleLarge(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    TextArrangement? arrangement,
    TextWrap wrap = TextWrap.wrap,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    VoidCallback? onTap,
    double? width,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AppText(
      text,
      key: key,
      variant: TextVariant.titleLarge,
      color: color,
      textAlign: textAlign,
      arrangement: arrangement,
      wrap: wrap,
      maxLines: maxLines,
      overflow: overflow,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      onTap: onTap,
      width: width,
      padding: padding,
      margin: margin,
    );
  }

  factory AppText.titleMedium(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    TextArrangement? arrangement,
    TextWrap wrap = TextWrap.wrap,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    VoidCallback? onTap,
    double? width,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AppText(
      text,
      key: key,
      variant: TextVariant.titleMedium,
      color: color,
      textAlign: textAlign,
      arrangement: arrangement,
      wrap: wrap,
      maxLines: maxLines,
      overflow: overflow,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      onTap: onTap,
      width: width,
      padding: padding,
      margin: margin,
    );
  }

  factory AppText.headlineSmall(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    TextArrangement? arrangement,
    TextWrap wrap = TextWrap.wrap,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    VoidCallback? onTap,
    double? width,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AppText(
      text,
      key: key,
      variant: TextVariant.headlineSmall,
      color: color,
      textAlign: textAlign,
      arrangement: arrangement,
      wrap: wrap,
      maxLines: maxLines,
      overflow: overflow,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      onTap: onTap,
      width: width,
      padding: padding,
      margin: margin,
    );
  }

  factory AppText.bodyLarge(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    TextArrangement? arrangement,
    TextWrap wrap = TextWrap.wrap,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    VoidCallback? onTap,
    double? width,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AppText(
      text,
      key: key,
      variant: TextVariant.bodyLarge,
      color: color,
      textAlign: textAlign,
      arrangement: arrangement,
      wrap: wrap,
      maxLines: maxLines,
      overflow: overflow,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      onTap: onTap,
      width: width,
      padding: padding,
      margin: margin,
    );
  }

  factory AppText.bodyMedium(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    TextArrangement? arrangement,
    TextWrap wrap = TextWrap.wrap,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    VoidCallback? onTap,
    double? width,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AppText(
      text,
      key: key,
      variant: TextVariant.bodyMedium,
      color: color,
      textAlign: textAlign,
      arrangement: arrangement,
      wrap: wrap,
      maxLines: maxLines,
      overflow: overflow,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      onTap: onTap,
      width: width,
      padding: padding,
      margin: margin,
    );
  }

  factory AppText.labelMedium(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    TextArrangement? arrangement,
    TextWrap wrap = TextWrap.wrap,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    VoidCallback? onTap,
    double? width,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AppText(
      text,
      key: key,
      variant: TextVariant.labelMedium,
      color: color,
      textAlign: textAlign,
      arrangement: arrangement,
      wrap: wrap,
      maxLines: maxLines,
      overflow: overflow,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      onTap: onTap,
      width: width,
      padding: padding,
      margin: margin,
    );
  }

  factory AppText.labelSmall(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    TextArrangement? arrangement,
    TextWrap wrap = TextWrap.wrap,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    VoidCallback? onTap,
    double? width,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AppText(
      text,
      key: key,
      variant: TextVariant.labelSmall,
      color: color,
      textAlign: textAlign,
      arrangement: arrangement,
      wrap: wrap,
      maxLines: maxLines,
      overflow: overflow,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      onTap: onTap,
      width: width,
      padding: padding,
      margin: margin,
    );
  }

  factory AppText.centered(
    String text, {
    Key? key,
    TextVariant variant = TextVariant.bodyMedium,
    Color? color,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? fontSize,
    double? height,
    double? letterSpacing,
    VoidCallback? onTap,
    double? width,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AppText(
      text,
      key: key,
      variant: variant,
      color: color,
      arrangement: TextArrangement.center,
      textAlign: TextAlign.center,
      maxLines: maxLines,
      overflow: overflow,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      onTap: onTap,
      width: width,
      padding: padding,
      margin: margin,
    );
  }

  factory AppText.bodySmall(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    TextArrangement? arrangement,
    TextWrap wrap = TextWrap.wrap,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    VoidCallback? onTap,
    double? width,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AppText(
      text,
      key: key,
      variant: TextVariant.bodySmall,
      color: color,
      textAlign: textAlign,
      arrangement: arrangement,
      wrap: wrap,
      maxLines: maxLines,
      overflow: overflow,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      onTap: onTap,
      width: width,
      padding: padding,
      margin: margin,
    );
  }

  factory AppText.labelLarge(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    TextArrangement? arrangement,
    TextWrap wrap = TextWrap.wrap,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    VoidCallback? onTap,
    double? width,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AppText(
      text,
      key: key,
      variant: TextVariant.labelLarge,
      color: color,
      textAlign: textAlign,
      arrangement: arrangement,
      wrap: wrap,
      maxLines: maxLines,
      overflow: overflow,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      onTap: onTap,
      width: width,
      padding: padding,
      margin: margin,
    );
  }

  factory AppText.headlineMedium(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    TextArrangement? arrangement,
    TextWrap wrap = TextWrap.wrap,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    VoidCallback? onTap,
    double? width,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AppText(
      text,
      key: key,
      variant: TextVariant.headlineMedium,
      color: color,
      textAlign: textAlign,
      arrangement: arrangement,
      wrap: wrap,
      maxLines: maxLines,
      overflow: overflow,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      onTap: onTap,
      width: width,
      padding: padding,
      margin: margin,
    );
  }

  final String text;
  final TextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final TextArrangement? arrangement;
  final TextWrap wrap;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;
  final double? fontSize;
  final double? height;
  final double? letterSpacing;
  final double? wordSpacing;
  final TextDecoration? decoration;
  final Color? decorationColor;
  final TextDecorationStyle? decorationStyle;
  final double? decorationThickness;
  final FontStyle? fontStyle;
  final TextBaseline? textBaseline;
  final TextDirection? textDirection;
  final bool? softWrap;
  final TextScaler? textScaler;
  final VoidCallback? onTap;
  final bool selectable;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final textStyle = _getTextStyle(context).copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      fontStyle: fontStyle,
      textBaseline: textBaseline,
    );

    // Determine text alignment
    final effectiveTextAlign = textAlign ?? _getTextAlignFromArrangement();
    
    // Determine overflow behavior
    final effectiveOverflow = overflow ?? _getOverflowFromWrap();
    
    // Determine soft wrap
    final effectiveSoftWrap = softWrap ?? _getSoftWrapFromWrap();

    Widget textWidget;
    
    if (selectable) {
      textWidget = SelectableText(
        text,
        style: textStyle,
        textAlign: effectiveTextAlign,
        maxLines: maxLines,
        textDirection: textDirection,
        textScaler: textScaler,
      );
    } else {
      textWidget = Text(
        text,
        style: textStyle,
        textAlign: effectiveTextAlign,
        maxLines: maxLines,
        overflow: effectiveOverflow,
        softWrap: effectiveSoftWrap,
        textDirection: textDirection,
        textScaler: textScaler,
      );
    }

    // Apply width constraint if specified
    if (width != null) {
      textWidget = SizedBox(
        width: width,
        child: textWidget,
      );
    }

    // Apply padding if specified
    if (padding != null) {
      textWidget = Padding(
        padding: padding!,
        child: textWidget,
      );
    }

    // Apply margin if specified
    if (margin != null) {
      textWidget = Container(
        margin: margin,
        child: textWidget,
      );
    }

    // Apply tap handler
    if (onTap != null) {
      textWidget = GestureDetector(
        onTap: onTap,
        child: textWidget,
      );
    }

    // Apply arrangement-specific wrapping
    if (arrangement == TextArrangement.center) {
      textWidget = Center(child: textWidget);
    } else if (arrangement == TextArrangement.right || arrangement == TextArrangement.end) {
      textWidget = Align(
        alignment: Alignment.centerRight,
        child: textWidget,
      );
    } else if (arrangement == TextArrangement.left || arrangement == TextArrangement.start) {
      textWidget = Align(
        alignment: Alignment.centerLeft,
        child: textWidget,
      );
    }

    return textWidget;
  }

  TextAlign? _getTextAlignFromArrangement() {
    if (arrangement == null) return null;
    switch (arrangement!) {
      case TextArrangement.left:
        return TextAlign.left;
      case TextArrangement.right:
        return TextAlign.right;
      case TextArrangement.center:
        return TextAlign.center;
      case TextArrangement.justify:
        return TextAlign.justify;
      case TextArrangement.start:
        return TextAlign.start;
      case TextArrangement.end:
        return TextAlign.end;
    }
  }

  TextOverflow? _getOverflowFromWrap() {
    switch (wrap) {
      case TextWrap.noWrap:
        return TextOverflow.clip;
      case TextWrap.wrap:
        return null;
      case TextWrap.ellipsis:
        return TextOverflow.ellipsis;
      case TextWrap.fade:
        return TextOverflow.fade;
      case TextWrap.clip:
        return TextOverflow.clip;
      case TextWrap.visible:
        return TextOverflow.visible;
    }
  }

  bool _getSoftWrapFromWrap() {
    switch (wrap) {
      case TextWrap.noWrap:
        return false;
      case TextWrap.wrap:
        return true;
      case TextWrap.ellipsis:
      case TextWrap.fade:
      case TextWrap.clip:
      case TextWrap.visible:
        return false;
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (variant) {
      case TextVariant.displayLarge:
        return theme.textTheme.displayLarge ?? const TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: AppColors.onBackground,
        );
      case TextVariant.displayMedium:
        return theme.textTheme.displayMedium ?? const TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: AppColors.onBackground,
        );
      case TextVariant.displaySmall:
        return theme.textTheme.displaySmall ?? const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: AppColors.onBackground,
        );
      case TextVariant.headlineLarge:
        return theme.textTheme.headlineLarge ?? const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: AppColors.onBackground,
        );
      case TextVariant.headlineMedium:
        return theme.textTheme.headlineMedium ?? const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: AppColors.onBackground,
        );
      case TextVariant.headlineSmall:
        return theme.textTheme.headlineSmall ?? const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: AppColors.onBackground,
        );
      case TextVariant.titleLarge:
        return theme.textTheme.titleLarge ?? const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.onBackground,
        );
      case TextVariant.titleMedium:
        return theme.textTheme.titleMedium ?? const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.onBackground,
        );
      case TextVariant.titleSmall:
        return theme.textTheme.titleSmall ?? const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onBackground,
        );
      case TextVariant.bodyLarge:
        return theme.textTheme.bodyLarge ?? const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        );
      case TextVariant.bodyMedium:
        return theme.textTheme.bodyMedium ?? const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        );
      case TextVariant.bodySmall:
        return theme.textTheme.bodySmall ?? const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        );
      case TextVariant.labelLarge:
        return theme.textTheme.labelLarge ?? const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        );
      case TextVariant.labelMedium:
        return theme.textTheme.labelMedium ?? const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        );
      case TextVariant.labelSmall:
        return theme.textTheme.labelSmall ?? const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        );
    }
  }
}