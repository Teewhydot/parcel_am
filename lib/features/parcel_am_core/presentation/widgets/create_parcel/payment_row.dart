import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/widgets/app_text.dart';

class PaymentRow extends StatelessWidget {
  const PaymentRow({
    super.key,
    required this.label,
    required this.amount,
    this.isBold = false,
  });

  final String label;
  final String amount;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            label,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? AppFontSize.xl : null,
          ),
          AppText(
            amount,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? AppFontSize.xl : null,
            color: isBold ? AppColors.primary : null,
          ),
        ],
      ),
    );
  }
}
