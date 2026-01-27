import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_input.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../parcel_am_core/data/constants/verification_constants.dart';
import '../../../domain/models/verification_model.dart';
import '../verification_widgets.dart';

class AddressVerificationStep extends StatelessWidget {
  const AddressVerificationStep({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.stateController,
    required this.postalCodeController,
    required this.isProofOfAddressUploaded,
    required this.onProofOfAddressUpload,
  });

  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController postalCodeController;
  final bool isProofOfAddressUploaded;
  final Future<void> Function(DocumentUpload) onProofOfAddressUpload;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Address Information'),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppInput(
            controller: addressController,
            label: 'Street Address *',
            hintText: '123 Main Street, Victoria Island',
            maxLines: 2,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: cityController,
            label: 'City *',
            hintText: 'Lagos',
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          DropdownButtonFormField<String>(
            value: stateController.text.isNotEmpty
                ? stateController.text
                : null,
            decoration: const InputDecoration(
              labelText: 'State *',
              border: OutlineInputBorder(),
            ),
            items: VerificationConstants.nigerianStates.map((state) {
              return DropdownMenuItem(
                value: state,
                child: AppText.bodyMedium(state),
              );
            }).toList(),
            onChanged: (value) => stateController.text = value ?? '',
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: postalCodeController,
            label: 'Postal Code *',
            hintText: '100001',
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppText.titleMedium('Address Verification Document'),
          AppSpacing.verticalSpacing(SpacingSize.md),
          DocumentUploadCard(
            title: 'Proof of Address',
            description:
                'Upload utility bill, bank statement, or tenancy agreement (dated within last 3 months)',
            documentKey: 'proof_of_address',
            isUploaded: isProofOfAddressUploaded,
            onUpload: onProofOfAddressUpload,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          const TipsCard(
            title: 'Accepted Documents',
            tips: VerificationConstants.acceptedAddressDocuments,
            color: AppColors.primary,
            icon: Icons.description,
          ),
        ],
      ),
    );
  }
}
