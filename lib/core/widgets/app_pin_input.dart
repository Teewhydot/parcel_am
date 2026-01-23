import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'app_spacing.dart';
import 'app_text.dart';

/// A PIN/OTP code input widget with individual digit boxes
///
/// Used for TOTP verification, OTP input, and similar use cases
/// where each digit needs its own input box.
class AppPinInput extends StatefulWidget {
  /// Number of digits (default: 6)
  final int length;

  /// Callback when the code changes
  final ValueChanged<String>? onChanged;

  /// Callback when all digits are entered
  final ValueChanged<String>? onCompleted;

  /// Whether the input is enabled
  final bool enabled;

  /// Error message to display
  final String? errorMessage;

  /// Auto-focus on mount
  final bool autoFocus;

  /// Width of each digit box
  final double boxWidth;

  /// Height of each digit box
  final double boxHeight;

  /// Whether to show a separator in the middle (for 6-digit codes: XXX-XXX)
  final bool showSeparator;

  const AppPinInput({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.errorMessage,
    this.autoFocus = true,
    this.boxWidth = 44,
    this.boxHeight = 52,
    this.showSeparator = false,
  });

  @override
  State<AppPinInput> createState() => AppPinInputState();
}

class AppPinInputState extends State<AppPinInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (_) => FocusNode());

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get currentCode {
    return _controllers.map((c) => c.text).join();
  }

  /// Clear all input fields
  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    widget.onChanged?.call('');
  }

  /// Set the code programmatically
  void setCode(String code) {
    final digits = code.replaceAll(RegExp(r'[^0-9]'), '');
    for (int i = 0; i < widget.length && i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }
    widget.onChanged?.call(currentCode);
    if (currentCode.length == widget.length) {
      widget.onCompleted?.call(currentCode);
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      _handlePaste(value);
      return;
    }

    widget.onChanged?.call(currentCode);

    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (currentCode.length == widget.length) {
      widget.onCompleted?.call(currentCode);
    }
  }

  void _handlePaste(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;

    for (int i = 0; i < widget.length && i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }

    final lastIndex = (digits.length < widget.length) ? digits.length : widget.length - 1;
    _focusNodes[lastIndex].requestFocus();

    widget.onChanged?.call(currentCode);

    if (currentCode.length == widget.length) {
      widget.onCompleted?.call(currentCode);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      widget.onChanged?.call(currentCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorMessage != null;
    final separatorIndex = widget.showSeparator ? widget.length ~/ 2 : -1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length * 2 - 1, (i) {
            // Even indices are input boxes, odd indices are spacers
            if (i.isOdd) {
              // Check if this is where separator goes
              final boxIndex = i ~/ 2;
              if (boxIndex == separatorIndex - 1 && widget.showSeparator) {
                return Padding(
                  padding: AppSpacing.horizontalPaddingXS,
                  child: AppText.titleLarge('-', color: AppColors.outline),
                );
              }
              return const SizedBox(width: 6);
            }

            final index = i ~/ 2;
            return Expanded(
              child: SizedBox(
                height: widget.boxHeight,
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) => _onKeyEvent(index, event),
                  child: TextFormField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    enabled: widget.enabled,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.sm,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.sm,
                        borderSide: BorderSide(
                          color: hasError
                              ? AppColors.error
                              : AppColors.outline,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.sm,
                        borderSide: BorderSide(
                          color: hasError
                              ? AppColors.error
                              : AppColors.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: AppRadius.sm,
                        borderSide: const BorderSide(
                          color: AppColors.error,
                        ),
                      ),
                      filled: true,
                      fillColor: widget.enabled
                          ? AppColors.surface
                          : AppColors.surfaceVariant,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    onChanged: (value) => _onDigitChanged(index, value),
                  ),
                ),
              ),
            );
          }),
        ),
        if (hasError) ...[
          AppSpacing.verticalSpacing(SpacingSize.xs),
          AppText.bodySmall(
            widget.errorMessage!,
            color: AppColors.error,
          ),
        ],
      ],
    );
  }
}
