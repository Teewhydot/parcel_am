import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentScreen = 0;
  
  final List<OnboardingScreenModel> _onboardingScreens = [
    OnboardingScreenModel(
      icon: Icons.security,
      title: "Secure Escrow System",
      description: "Your money is protected until your package is safely delivered. Peace of mind guaranteed.",
      color: AppColors.primary,
    ),
    OnboardingScreenModel(
      icon: Icons.location_on,
      title: "Nigeria-Wide Delivery",
      description: "Connect with verified travelers going to Lagos, Abuja, Kano, Port Harcourt and 32+ other states.",
      color: AppColors.secondary,
    ),
    OnboardingScreenModel(
      icon: Icons.people,
      title: "Verified Community",
      description: "All users are verified with government ID and bank details. Rate and review for trust.",
      color: AppColors.accent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextScreen() {
    if (_currentScreen < _onboardingScreens.length - 1) {
      setState(() {
        _currentScreen++;
      });
    }
  }

  void _prevScreen() {
    if (_currentScreen > 0) {
      setState(() {
        _currentScreen--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = _onboardingScreens[_currentScreen];
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: AppSpacing.paddingLG,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppButton.text(
                    onPressed: _currentScreen == 0 ? null : _prevScreen,
                    child: Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: _currentScreen == 0 ? Colors.grey.withValues(alpha: 0.5) : Colors.grey,
                    ),
                  ),
                  Row(
                    children: List.generate(_onboardingScreens.length, (index) {
                      return AppContainer(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        variant: ContainerVariant.filled,
                        color: index == _currentScreen 
                            ? AppColors.primary 
                            : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      );
                    }),
                  ),
                  AppButton.text(
                    onPressed: () {
                      sl<NavigationService>().navigateAndReplace(Routes.login);
                    },
                    child: AppText.bodyMedium(
                      'Skip',
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: AppSpacing.paddingXL,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: AppContainer(
                        key: ValueKey(_currentScreen),
                        width: 128,
                        height: 128,
                        variant: ContainerVariant.filled,
                        color: screen.color,
                        borderRadius: BorderRadius.circular(64),
                        alignment: Alignment.center,
                        child: Icon(
                          screen.icon,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    AppSpacing.verticalSpacing(SpacingSize.xxl),
                    
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: AppText.headlineMedium(
                        key: ValueKey('${_currentScreen}_title'),
                        screen.title,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                        color: Colors.black,
                      ),
                    ),
                    
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: AppText.bodyLarge(
                        key: ValueKey('${_currentScreen}_desc'),
                        screen.description,
                        textAlign: TextAlign.center,
                        color: Colors.grey.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                    
                    AppSpacing.verticalSpacing(SpacingSize.xxl),
                    AppSpacing.verticalSpacing(SpacingSize.xl),
                  ],
                ),
              ),
            ),
            
            // Footer
            Padding(
              padding: AppSpacing.paddingXL,
              child: Column(
                children: [
                  if (_currentScreen == _onboardingScreens.length - 1) ...[
                    AppButton.primary(
                      onPressed: () {
                        sl<NavigationService>().navigateAndReplace(Routes.login);
                      },
                      child: AppText.bodyLarge(
                        'Get Started',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.md),
                    AppButton.outline(
                      onPressed: () {
                        sl<NavigationService>().navigateAndReplace(Routes.login, arguments: {'showSignIn': true});
                      },
                      child: AppText.bodyLarge(
                        'Sign In Instead',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.primary(
                            onPressed: _nextScreen,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppText.bodyLarge(
                                  'Continue',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                AppSpacing.horizontalSpacing(SpacingSize.sm),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class OnboardingScreenModel {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingScreenModel({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}