import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/widgets/app_scaffold.dart';

import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../injection_container.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
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
  bool _hasNavigated = false;

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
    
    context.read<AuthBloc>().add(const AuthStarted());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateBasedOnState(BaseState<AuthData> state) async {
    if (_hasNavigated || !mounted) return;
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted || _hasNavigated) return;
    
    _hasNavigated = true;
    
    if (state is DataState<AuthData> && 
        state.data != null && 
        state.data!.user != null) {
      sl<NavigationService>().navigateAndReplace(Routes.dashboard);
    } else if (state is InitialState || state is ErrorState) {
      sl<NavigationService>().navigateAndReplace(Routes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, BaseState<AuthData>>(
      listener: (context, state) {
        _navigateBasedOnState(state);
      },
      child: AppScaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(48),
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
                                    const Positioned(
                                      right: 16,
                                      bottom: 16,
                                      child: Icon(
                                        Icons.security,
                                        size: 24,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Animated pulse dot
                              Positioned(
                                right: -8,
                                top: -8,
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 1500),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: 0.5 + (value * 0.5),
                                      child: AppContainer(
                                        width: 24,
                                        height: 24,
                                        variant: ContainerVariant.filled,
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          AppSpacing.verticalSpacing(SpacingSize.xxl),

                          // App Name
                          AppText.headlineLarge(
                            'TravelLink',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.sm),
                          AppText.bodyLarge(
                            'Secure package delivery across Nigeria',
                            color: Colors.white.withValues(alpha: 0.8),
                            textAlign: TextAlign.center,
                          ),

                          AppSpacing.verticalSpacing(SpacingSize.xxl),
                          AppSpacing.verticalSpacing(SpacingSize.lg),

                          // Feature Icons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _FeatureIcon(
                                icon: Icons.security,
                                title: 'Escrow Safe',
                              ),
                              _FeatureIcon(
                                icon: Icons.verified_user,
                                title: 'Verified Users',
                              ),
                              _FeatureIcon(
                                icon: Icons.flight_takeoff,
                                title: 'Fast Delivery',
                              ),
                            ],
                          ),

                          AppSpacing.verticalSpacing(SpacingSize.xxl),
                          AppSpacing.verticalSpacing(SpacingSize.lg),

                          // Loading Indicator
                          _LoadingDots(),
                        ],
                      ),
                    ),

                    // Bottom Tagline
                    Padding(
                      padding: AppSpacing.paddingLG,
                      child: AppText.bodySmall(
                        'Connecting Nigeria, One Package at a Time',
                        color: Colors.white.withValues(alpha: 0.6),
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
    ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppContainer(
          width: 48,
          height: 48,
          variant: ContainerVariant.filled,
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        AppSpacing.verticalSpacing(SpacingSize.sm),
        AppText.labelSmall(
          title,
          color: Colors.white.withValues(alpha: 0.8),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.4,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: _animations[index].value,
                child: AppContainer(
                  width: 8,
                  height: 8,
                  variant: ContainerVariant.filled,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
