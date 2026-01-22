import 'package:flutter/material.dart';
import '../../../../core/widgets/app_pin_input.dart';

/// A 6-digit code input widget for TOTP verification
///
/// This is a thin wrapper around [AppPinInput] configured for TOTP codes.
class TotpCodeInputWidget extends StatefulWidget {
  /// Callback when the code changes
  final ValueChanged<String>? onChanged;

  /// Callback when all 6 digits are entered
  final ValueChanged<String>? onCompleted;

  /// Whether the input is enabled
  final bool enabled;

  /// Error message to display
  final String? errorMessage;

  /// Auto-focus on mount
  final bool autoFocus;

  const TotpCodeInputWidget({
    super.key,
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.errorMessage,
    this.autoFocus = true,
  });

  @override
  State<TotpCodeInputWidget> createState() => TotpCodeInputWidgetState();
}

class TotpCodeInputWidgetState extends State<TotpCodeInputWidget> {
  final GlobalKey<AppPinInputState> _pinInputKey = GlobalKey<AppPinInputState>();

  /// Clear the input
  void clear() {
    _pinInputKey.currentState?.clear();
  }

  /// Get the current code
  String get currentCode => _pinInputKey.currentState?.currentCode ?? '';

  @override
  Widget build(BuildContext context) {
    return AppPinInput(
      key: _pinInputKey,
      length: 6,
      onChanged: widget.onChanged,
      onCompleted: widget.onCompleted,
      enabled: widget.enabled,
      errorMessage: widget.errorMessage,
      autoFocus: widget.autoFocus,
      showSeparator: true,
    );
  }
}
