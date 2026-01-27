import 'package:flutter/material.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import 'review_item.dart';

class ReviewStep extends StatelessWidget {
  const ReviewStep({
    super.key,
    required this.title,
    required this.description,
    required this.packageType,
    required this.weight,
    required this.price,
    required this.urgency,
    required this.pickupName,
    required this.deliveryName,
    required this.receiverPhone,
  });

  final String title;
  final String description;
  final String packageType;
  final String weight;
  final String price;
  final String urgency;
  final String pickupName;
  final String deliveryName;
  final String receiverPhone;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.headlineSmall(
            'Review Parcel',
            fontWeight: FontWeight.bold,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppCard.elevated(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReviewItem(label: 'Title', value: title),
                ReviewItem(label: 'Description', value: description),
                ReviewItem(label: 'Type', value: packageType),
                ReviewItem(label: 'Weight', value: '$weight kg'),
                ReviewItem(label: 'Price', value: '₦$price'),
                ReviewItem(label: 'Urgency', value: urgency),
              ],
            ),
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppCard.elevated(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(
                  'Locations',
                  fontWeight: FontWeight.w600,
                ),
                AppSpacing.verticalSpacing(SpacingSize.md),
                ReviewItem(label: 'Pickup', value: pickupName),
                ReviewItem(label: 'Delivery', value: deliveryName),
                ReviewItem(label: 'Receiver Phone', value: receiverPhone),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
