import 'package:flutter/material.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/widgets/app_input.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class LocationStep extends StatelessWidget {
  const LocationStep({
    super.key,
    required this.originNameController,
    required this.originAddressController,
    required this.destNameController,
    required this.destPhoneController,
    required this.destAddressController,
  });

  final TextEditingController originNameController;
  final TextEditingController originAddressController;
  final TextEditingController destNameController;
  final TextEditingController destPhoneController;
  final TextEditingController destAddressController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.headlineSmall(
            'Pickup & Delivery',
            fontWeight: FontWeight.bold,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          const AppText(
            'Pickup Location',
            variant: TextVariant.titleMedium,
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w600,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: originNameController,
            label: 'Location Name',
            hintText: 'e.g., My Office',
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput.multiline(
            controller: originAddressController,
            label: 'Address',
            hintText: 'Enter full address',
            maxLines: 2,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          const AppText(
            'Delivery Location',
            variant: TextVariant.titleMedium,
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w600,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: destNameController,
            label: 'Location Name',
            hintText: 'e.g., Client Office',
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput.phone(
            controller: destPhoneController,
            label: 'Receiver Phone',
            hintText: 'e.g., +234...',
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput.multiline(
            controller: destAddressController,
            label: 'Address',
            hintText: 'Enter full address',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
