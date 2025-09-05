import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'app_text.dart';
import 'app_spacing.dart';

class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.initialValue,
    this.filled = true,
    this.borderRadius,
    this.contentPadding,
  });

  factory AppInput.email({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hintText = 'Enter your email address',
    String? helperText,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
    bool readOnly = false,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    VoidCallback? onTap,
    FocusNode? focusNode,
    String? initialValue,
  }) {
    return AppInput(
      key: key,
      controller: controller,
      label: label,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon ?? const Icon(Icons.email_outlined),
      suffixIcon: suffixIcon,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      focusNode: focusNode,
      initialValue: initialValue,
    );
  }

  factory AppInput.phone({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hintText = 'Enter phone number',
    String? helperText,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
    bool readOnly = false,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    VoidCallback? onTap,
    FocusNode? focusNode,
    String? initialValue,
  }) {
    return AppInput(
      key: key,
      controller: controller,
      label: label,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon ?? const Icon(Icons.phone_outlined),
      suffixIcon: suffixIcon,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      focusNode: focusNode,
      initialValue: initialValue,
    );
  }

  factory AppInput.password({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hintText = 'Enter your password',
    String? helperText,
    String? errorText,
    bool enabled = true,
    bool readOnly = false,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    VoidCallback? onTap,
    FocusNode? focusNode,
    String? initialValue,
  }) {
    return AppInput(
      key: key,
      controller: controller,
      label: label,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: const Icon(Icons.lock_outlined),
      enabled: enabled,
      readOnly: readOnly,
      obscureText: true,
      textInputAction: TextInputAction.done,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      focusNode: focusNode,
      initialValue: initialValue,
    );
  }

  factory AppInput.multiline({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hintText,
    String? helperText,
    String? errorText,
    bool enabled = true,
    bool readOnly = false,
    int maxLines = 3,
    int? minLines,
    int? maxLength,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    VoidCallback? onTap,
    FocusNode? focusNode,
    String? initialValue,
  }) {
    return AppInput(
      key: key,
      controller: controller,
      label: label,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      focusNode: focusNode,
      initialValue: initialValue,
    );
  }

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final String? initialValue;
  final bool filled;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  bool _isObscured = false;
  late bool _showPasswordToggle;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
    _showPasswordToggle = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          AppText.labelMedium(
            widget.label!,
            fontWeight: FontWeight.w600,
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          focusNode: widget.focusNode,
          obscureText: _isObscured,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: _buildSuffixIcon(),
            filled: widget.filled,
            fillColor: widget.filled ? AppColors.surfaceVariant : null,
            border: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              borderSide: widget.filled ? BorderSide.none : const BorderSide(color: AppColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              borderSide: widget.filled ? BorderSide.none : const BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: widget.contentPadding ?? AppSpacing.paddingLG,
            counterText: '',
          ),
        ),
        if (widget.helperText != null || widget.errorText != null) ...[
          AppSpacing.verticalSpacing(SpacingSize.xs),
          AppText.bodySmall(
            widget.errorText ?? widget.helperText!,
            color: widget.errorText != null ? AppColors.error : AppColors.onSurfaceVariant,
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (_showPasswordToggle) {
      return IconButton(
        icon: Icon(
          _isObscured ? Icons.visibility : Icons.visibility_off,
          color: AppColors.onSurfaceVariant,
        ),
        onPressed: () {
          setState(() {
            _isObscured = !_isObscured;
          });
        },
      );
    }
    return widget.suffixIcon;
  }
}