import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/kyc_status.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../widgets/kyc_blocked/kyc_status_icon.dart';
import '../widgets/kyc_blocked/kyc_title.dart';
import '../widgets/kyc_blocked/kyc_description.dart';
import '../widgets/kyc_blocked/kyc_action_button.dart';
import '../widgets/kyc_blocked/kyc_secondary_button.dart';

class KycBlockedScreen extends StatelessWidget {
  const KycBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments as Map<String, dynamic>?;
    final KycStatus status = arguments?['status'] ?? KycStatus.notStarted;

    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KycStatusIcon(status: status),
              AppSpacing.verticalSpacing(SpacingSize.xl),
              KycTitle(status: status),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              KycDescription(status: status),
              AppSpacing.verticalSpacing(SpacingSize.xxxl),
              KycActionButton(status: status),
              if (status != KycStatus.pending) ...[
                AppSpacing.verticalSpacing(SpacingSize.lg),
                const KycSecondaryButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
