import 'package:flutter/material.dart';
import '../../../../../core/widgets/app_input.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';

class ParcelDetailsStep extends StatelessWidget {
  const ParcelDetailsStep({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.weightController,
    required this.priceController,
    required this.packageType,
    required this.urgency,
    required this.packageTypes,
    required this.urgencyLevels,
    required this.onPackageTypeChanged,
    required this.onUrgencyChanged,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController weightController;
  final TextEditingController priceController;
  final String packageType;
  final String urgency;
  final List<String> packageTypes;
  final List<String> urgencyLevels;
  final ValueChanged<String> onPackageTypeChanged;
  final ValueChanged<String> onUrgencyChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.headlineSmall(
            'Parcel Details',
            fontWeight: FontWeight.bold,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppInput(
            controller: titleController,
            label: 'Parcel Title',
            hintText: 'e.g., Business Documents',
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput.multiline(
            controller: descriptionController,
            label: 'Description',
            hintText: 'Provide details about your parcel',
            maxLines: 3,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          DropdownButtonFormField<String>(
            value: packageType,
            decoration: const InputDecoration(
              labelText: 'Package Type',
              border: OutlineInputBorder(),
            ),
            items: packageTypes
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: AppText.bodyMedium(type),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) onPackageTypeChanged(value);
            },
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: weightController,
            label: 'Weight (kg)',
            hintText: 'Enter weight',
            keyboardType: TextInputType.number,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: priceController,
            label: 'Offered Price (₦)',
            hintText: 'Enter price',
            keyboardType: TextInputType.number,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          DropdownButtonFormField<String>(
            value: urgency,
            decoration: const InputDecoration(
              labelText: 'Urgency',
              border: OutlineInputBorder(),
            ),
            items: urgencyLevels
                .map((level) => DropdownMenuItem(
                      value: level,
                      child: AppText.bodyMedium(level),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) onUrgencyChanged(value);
            },
          ),
        ],
      ),
    );
  }
}
