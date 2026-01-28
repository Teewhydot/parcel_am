import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/widgets/app_scaffold.dart';

import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../injection_container.dart';
import '../widgets/splash/feature_icon.dart';
import '../widgets/splash/loading_dots.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_data.dart';
import '../../../../core/bloc/base/base_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          context.read<AuthCubit>().checkCurrentUser();
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return BlocManager<AuthCubit, BaseState<AuthData>>(
      bloc: context.read<AuthCubit>(),
    showResultErrorNotifications: false,
    showResultSuccessNotifications: false,
    showLoadingIndicator: false,
      onError: (context, state) => sl<NavigationService>().navigateAndReplace(Routes.login),
      onSuccess: (context, state) => sl<NavigationService>().navigateAndReplace(Routes.home),
      child: AppScaffold(
        safeAreaBottom: false,
        safeAreaTop: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            AppContainer(
                              width: 96,
                              height: 96,
                              variant: ContainerVariant.filled,
                              color: AppColors.white,
                              borderRadius: AppRadius.pill,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: 0.785398, // 45 degrees in radians
                                    child: const Icon(
                                      Icons.flight_takeoff,
                                      size: 40,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                 
                                ],
                              ),
                            ),
                            // Animated pulse dot
                           
                          ],
                        ),
        
                        AppSpacing.verticalSpacing(SpacingSize.xxl),
        
                        // App Name
                        AppText.headlineLarge(
                          'ParcelAm',
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        AppText.bodyLarge(
                          'Secure package delivery across Nigeria',
                          color: AppColors.white.withValues(alpha: 0.8),
                          textAlign: TextAlign.center,
                        ),
        
                        AppSpacing.verticalSpacing(SpacingSize.xxl),
                        AppSpacing.verticalSpacing(SpacingSize.lg),
        
                        // Feature Icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const FeatureIcon(
                              icon: Icons.security,
                              title: 'Escrow Safe',
                            ),
                            const FeatureIcon(
                              icon: Icons.verified_user,
                              title: 'Verified Users',
                            ),
                            const FeatureIcon(
                              icon: Icons.flight_takeoff,
                              title: 'Fast Delivery',
                            ),
                          ],
                        ),
        
                        AppSpacing.verticalSpacing(SpacingSize.xxl),
                        AppSpacing.verticalSpacing(SpacingSize.lg),
        
                        // Loading Indicator
                        const LoadingDots(),
                      ],
                    ),
                  ),
        
                  // Bottom Tagline
                  Padding(
                    padding: AppSpacing.paddingLG,
                    child: AppText.bodySmall(
                      'Connecting Nigeria, One Package at a Time',
                      color: AppColors.white.withValues(alpha: 0.6),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
    );
  }
}
