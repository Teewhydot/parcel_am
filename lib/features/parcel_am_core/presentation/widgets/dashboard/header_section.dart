import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_container.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../core/bloc/base/base_state.dart';
import '../../../../../injection_container.dart';
import '../../../../../core/helpers/user_extensions.dart';
import '../../../data/constants/verification_constants.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_data.dart';
import '../wallet_balance_card.dart';
import 'notification_button.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocManager<AuthCubit, BaseState<AuthData>>(
      bloc: context.read<AuthCubit>(),
      showLoadingIndicator: false,
      child: const SizedBox.shrink(),
      builder: (context, state) {
        final user = context.user;
        final displayName = user.displayName;
        final userName = displayName.isNotEmpty
            ? displayName.split(' ').firstOrNull ?? 'User'
            : 'User';
        final greeting = VerificationConstants.getTimeBasedGreeting();

        return AppContainer(
          color: AppColors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.bodyLarge(
                          '$greeting, $userName!',
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.xs),
                        AppText.bodyMedium(
                          'Ready to send or deliver today?',
                          color: AppColors.black,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.black,
                        ),
                        onPressed: () {
                          sl<NavigationService>().navigateTo(Routes.settings);
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.person_outline,
                          color: AppColors.black,
                        ),
                        onPressed: () {
                          sl<NavigationService>().navigateTo(Routes.profile);
                        },
                      ),
                      const NotificationButton(),
                    ],
                  ),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.xl),
              const WalletBalanceCard(),
              AppSpacing.verticalSpacing(SpacingSize.md),
            ],
          ),
        );
      },
    );
  }
}
