import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../domain/entities/passkey_entity.dart';
import '../../bloc/passkey_data.dart';
import '../passkey_list_item.dart';
import 'passkey_empty_state.dart';

/// Widget displaying the list of registered passkeys
class PasskeysList extends StatelessWidget {
  const PasskeysList({
    super.key,
    required this.passkeyData,
    required this.isLoading,
    required this.onRemove,
  });

  final PasskeyData passkeyData;
  final bool isLoading;
  final void Function(PasskeyEntity passkey) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              'Your Passkeys',
              variant: TextVariant.titleMedium,
              fontSize: AppFontSize.xl,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
          ],
        ),
        AppSpacing.verticalSpacing(SpacingSize.md),
        if (passkeyData.passkeys.isEmpty && !isLoading)
          const PasskeyEmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: passkeyData.passkeys.length,
            itemBuilder: (context, index) {
              final passkey = passkeyData.passkeys[index];
              return PasskeyListItem(
                passkey: passkey,
                isLoading: isLoading,
                onRemove: () => onRemove(passkey),
              );
            },
          ),
      ],
    );
  }
}
