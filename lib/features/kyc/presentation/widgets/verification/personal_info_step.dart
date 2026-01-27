import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_input.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../parcel_am_core/data/constants/verification_constants.dart';
import '../verification_widgets.dart';

class PersonalInfoStep extends StatelessWidget {
  const PersonalInfoStep({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.dobController,
    required this.ninController,
    required this.bvnController,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.onDateOfBirthTap,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController dobController;
  final TextEditingController ninController;
  final TextEditingController bvnController;
  final String selectedGender;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onDateOfBirthTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Tell us about yourself'),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          Row(
            children: [
              Expanded(
                child: AppInput(
                  controller: firstNameController,
                  label: 'First Name *',
                  hintText: 'John',
                ),
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: AppInput(
                  controller: lastNameController,
                  label: 'Last Name *',
                  hintText: 'Doe',
                ),
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: phoneController,
            label: 'Phone Number *',
            hintText: '080 6878 7087',
            keyboardType: TextInputType.phone,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: dobController,
            label: 'Date of Birth *',
            hintText: 'Select date',
            readOnly: true,
            suffixIcon: const Icon(Icons.calendar_today),
            onTap: onDateOfBirthTap,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          DropdownButtonFormField<String>(
            value: selectedGender,
            decoration: const InputDecoration(
              labelText: 'Gender *',
              border: OutlineInputBorder(),
            ),
            items: VerificationConstants.genderOptions.map((gender) {
              return DropdownMenuItem(
                value: gender,
                child: AppText.bodyMedium(gender),
              );
            }).toList(),
            onChanged: onGenderChanged,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppText.titleMedium('Government IDs'),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: ninController,
            label: 'NIN (National Identity Number)',
            hintText: '12345678901',
            keyboardType: TextInputType.number,
            maxLength: 11,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: bvnController,
            label: 'BVN (Bank Verification Number)',
            hintText: '12345678901',
            keyboardType: TextInputType.number,
            maxLength: 11,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          const InfoCard(
            title: 'Privacy Notice',
            content: VerificationConstants.privacyNotice,
            color: AppColors.primary,
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }
}
