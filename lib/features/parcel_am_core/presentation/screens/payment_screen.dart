import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../escrow/domain/entities/escrow_status.dart';
import '../widgets/bottom_navigation.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/wallet/wallet_cubit.dart';
import '../bloc/wallet/wallet_data.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/escrow/escrow_cubit.dart';
import '../bloc/escrow/escrow_state.dart';
import '../../domain/entities/package_entity.dart';
import '../../../../core/helpers/user_extensions.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int currentStep = 0;
  String paymentMethod = 'bank';
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  late WalletCubit _walletBloc;
  late EscrowCubit _escrowBloc;
  PaymentEntity? _paymentInfo;

  final List<Map<String, dynamic>> steps = [
    {'id': 'confirm', 'title': 'Confirm Order', 'icon': Icons.shield},
    {'id': 'payment', 'title': 'Select Payment', 'icon': Icons.credit_card},
    {'id': 'escrow', 'title': 'Escrow Deposit', 'icon': Icons.lock},
    {'id': 'complete', 'title': 'Payment Secured', 'icon': Icons.check_circle},
  ];

  final Map<String, String> packageDetails = {
    'title': 'Important Business Documents',
    'route': 'Lagos → Abuja',
    'price': '₦3,500',
    'traveler': 'Sarah A.',
    'deliveryFee': '₦3,500',
    'serviceFee': '₦150',
    'total': '₦3,650'
  };

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'bank',
      'name': 'Bank Transfer',
      'description': 'Direct transfer from your Nigerian bank account',
      'icon': Icons.account_balance,
      'popular': true
    },
    {
      'id': 'card',
      'name': 'Debit/Credit Card',
      'description': 'Pay with your Verve, Visa, or Mastercard',
      'icon': Icons.credit_card,
      'popular': false
    },
    {
      'id': 'mobile',
      'name': 'Mobile Money',
      'description': 'Pay with your mobile wallet',
      'icon': Icons.phone_android,
      'popular': false
    }
  ];

  @override
  void initState() {
    super.initState();
    _walletBloc = WalletCubit();
    _escrowBloc = EscrowCubit();
    _walletBloc.loadWallet();
  }

  @override
  void dispose() {
    _walletBloc.close();
    _escrowBloc.close();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  void nextStep() {
    if (currentStep < steps.length - 1) {
      if (currentStep == 1) {
        _processPaymentAndEscrow();
      } else {
        setState(() {
          currentStep++;
        });
      }
    }
  }

  void _processPaymentAndEscrow() {
    final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
    final totalAmount = 3650.0;

    _paymentInfo = PaymentEntity(
      transactionId: transactionId,
      status: 'processing',
      amount: 3500.0,
      serviceFee: 150.0,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      paidAt: DateTime.now(),
      isEscrow: true,
      escrowStatus: 'holding',
      escrowHeldAt: DateTime.now(),
    );

    // Use transactionId as placeholder escrowId
    _escrowBloc.holdEscrow(transactionId);

    _walletBloc.holdEscrowBalance(
      amount: totalAmount,
      packageId: 'PKG_001',
    );

    setState(() {
      currentStep++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _walletBloc),
        BlocProvider.value(value: _escrowBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: AppText.titleLarge('Secure Payment'),
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<WalletCubit, BaseState<WalletData>>(
              listener: (context, state) {
                if (state is ErrorState<WalletData>) {
                  context.showSnackbar(
                    message: state.errorMessage,
                    color: AppColors.error,
                  );
                }
              },
            ),
            BlocListener<EscrowCubit, BaseState<EscrowData>>(
              listener: (context, state) {
                final escrow = state.data?.currentEscrow;
                if (escrow?.status == EscrowStatus.held && currentStep == 2) {
                  setState(() {
                    currentStep = 3;
                    _paymentInfo = _paymentInfo?.copyWith(escrowStatus: 'held');
                  });
                } else if (state is ErrorState<EscrowData>) {
                  context.showSnackbar(
                    message: state.errorMessage,
                    color: AppColors.error,
                  );
                }
              },
            ),
          ],
          child: Column(
        children: [
          // Progress Steps
          Container(
            padding: AppSpacing.paddingLG,
            color: AppColors.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    for (int i = 0; i < steps.length; i++) ...
                      [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i <= currentStep
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                          ),
                          child: Icon(
                            i < currentStep
                                ? Icons.check
                                : steps[i]['icon'] as IconData,
                            color: i <= currentStep
                                ? Colors.white
                                : AppColors.onSurfaceVariant,
                            size: 18,
                          ),
                        ),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              margin: AppSpacing.horizontalPaddingSM,
                              color: i < currentStep
                                  ? AppColors.primary
                                  : AppColors.outline,
                            ),
                          ),
                      ]
                  ],
                ),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                AppText.bodyMedium(
                  steps[currentStep]['title'],
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingLG,
              child: _buildStepContent(),
            ),
          ),

          if (currentStep < steps.length - 1)
            Container(
              padding: AppSpacing.paddingLG,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.outline),
                ),
              ),
              child: AppButton.primary(
                onPressed: nextStep,
                fullWidth: true,
                child: AppText.bodyLarge(
                  currentStep == 0 ? 'Proceed to Payment' :
                  currentStep == 1 ? 'Confirm Payment Method' :
                  'Complete Payment',
                  color: Colors.white,
                ),
              ),
            ),
        ],
          ),
        ),
        bottomNavigationBar: const BottomNavigation(currentIndex: 1),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildConfirmOrderStep();
      case 1:
        return _buildSelectPaymentStep();
      case 2:
        return _buildEscrowDepositStep();
      case 3:
        return _buildPaymentCompleteStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildConfirmOrderStep() {
    return Column(
      children: [
        // Order Summary Card
        AppCard.elevated(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Order Summary',
                variant: TextVariant.titleMedium,
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: SpacingSize.massive.value,
                    height: SpacingSize.massive.value,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.md,
                    ),
                    child: const Icon(
                      Icons.description,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  AppSpacing.horizontalSpacing(SpacingSize.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.bodyLarge(
                          packageDetails['title']!,
                          fontWeight: FontWeight.w600,
                        ),
                        AppText.bodyMedium(
                          packageDetails['route']!,
                          color: AppColors.onSurfaceVariant,
                        ),
                        AppText.bodyMedium(
                          'Traveler: ${packageDetails['traveler']}',
                          color: AppColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  AppText(
                    packageDetails['price']!,
                    variant: TextVariant.titleMedium,
                    fontSize: AppFontSize.xl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),

        AppSpacing.verticalSpacing(SpacingSize.lg),

        // Price Breakdown Card
        AppCard.elevated(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Price Breakdown',
                variant: TextVariant.titleMedium,
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.bodyMedium(
                    'Delivery Fee',
                    color: AppColors.onSurfaceVariant,
                  ),
                  AppText.bodyMedium(packageDetails['deliveryFee']!),
                ],
              ),
              AppSpacing.verticalSpacing(SpacingSize.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.bodyMedium(
                    'Service Fee',
                    color: AppColors.onSurfaceVariant,
                  ),
                  AppText.bodyMedium(packageDetails['serviceFee']!),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText(
                    'Total',
                    variant: TextVariant.titleMedium,
                    fontSize: AppFontSize.xl,
                    fontWeight: FontWeight.bold,
                  ),
                  AppText(
                    packageDetails['total']!,
                    variant: TextVariant.titleMedium,
                    fontSize: AppFontSize.xl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),

        AppSpacing.verticalSpacing(SpacingSize.lg),

        // Escrow Protection Notice
        Container(
          padding: AppSpacing.paddingLG,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppRadius.md,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield,
                color: AppColors.primary,
                size: 20,
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyMedium(
                      'Escrow Protection',
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    AppText.bodySmall(
                      'Your payment will be securely held until delivery is confirmed by both parties.',
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectPaymentStep() {
    return Column(
      children: [
        AppCard.elevated(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Select Payment Method',
                variant: TextVariant.titleMedium,
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              for (var method in paymentMethods) ...
                [
                  GestureDetector(
                    onTap: () => setState(() => paymentMethod = method['id']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: AppSpacing.paddingLG,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: paymentMethod == method['id']
                              ? AppColors.primary
                              : AppColors.outline,
                          width: 2,
                        ),
                        borderRadius: AppRadius.md,
                        color: paymentMethod == method['id']
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: method['id'],
                            groupValue: paymentMethod,
                            onChanged: (value) =>
                                setState(() => paymentMethod = value!),
                          ),
                          Icon(
                            method['icon'] as IconData,
                            color: AppColors.onSurfaceVariant,
                            size: 24,
                          ),
                          AppSpacing.horizontalSpacing(SpacingSize.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText.bodyLarge(
                                  method['name'],
                                  fontWeight: FontWeight.w600,
                                ),
                                AppText.bodyMedium(
                                  method['description'],
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                          if (method['popular'])
                            Container(
                              padding: AppSpacing.verticalPaddingXS + AppSpacing.horizontalPaddingSM,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: AppRadius.md,
                              ),
                              child: AppText.bodySmall(
                                'Popular',
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ]
            ],
          ),
        ),

        if (paymentMethod == 'bank') ...
          [
            AppSpacing.verticalSpacing(SpacingSize.lg),
            AppCard.elevated(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyLarge(
                    'Bank Account Details',
                    fontWeight: FontWeight.bold,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  AppInput(
                    controller: _accountNumberController,
                    label: 'Account Number',
                    hintText: '0123456789',
                    keyboardType: TextInputType.number,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  AppInput(
                    controller: _bankNameController,
                    label: 'Bank Name',
                    hintText: 'Select your bank',
                  ),
                ],
              ),
            ),
          ]
      ],
    );
  }

  Widget _buildEscrowDepositStep() {
    return BlocBuilder<EscrowCubit, BaseState<EscrowData>>(
      builder: (context, escrowState) {
        final escrowStatus = escrowState.data?.currentEscrow?.status;
        return BlocBuilder<WalletCubit, BaseState<WalletData>>(
          builder: (context, walletState) {
            return Column(
              children: [
                if (walletState is LoadedState<WalletData> && walletState.data != null) ...[
                  AppCard.elevated(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppText.bodyLarge(
                              'Wallet Balance',
                              fontWeight: FontWeight.bold,
                            ),
                            const Spacer(),
                            Icon(
                              _getEscrowStatusIcon(escrowStatus),
                              color: _getEscrowStatusColor(escrowStatus),
                              size: 20,
                            ),
                            AppSpacing.horizontalSpacing(SpacingSize.xs),
                            AppText(
                              _getEscrowStatusLabel(escrowStatus),
                              variant: TextVariant.bodySmall,
                              fontWeight: FontWeight.w600,
                              color: _getEscrowStatusColor(escrowStatus),
                            ),
                          ],
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText.bodyMedium(
                              'Available Balance',
                              color: AppColors.onSurfaceVariant,
                            ),
                            AppText.bodyLarge(
                              '₦${walletState.data!.availableBalance.toStringAsFixed(2)}',
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                        AppSpacing.verticalSpacing(SpacingSize.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText.bodyMedium(
                              'Pending (Escrow)',
                              color: AppColors.onSurfaceVariant,
                            ),
                            AppText.bodyLarge(
                              '₦${walletState.data!.pendingBalance.toStringAsFixed(2)}',
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                ],
            AppCard.elevated(
              padding: AppSpacing.paddingXXL,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadius.pill,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  const AppText(
                    'Securing Your Payment',
                    variant: TextVariant.titleMedium,
                    fontSize: AppFontSize.xl,
                    fontWeight: FontWeight.bold,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.sm),
                  AppText.bodyMedium(
                    'Your ${packageDetails['total']} is being deposited into our secure escrow system',
                    textAlign: TextAlign.center,
                    color: AppColors.onSurfaceVariant,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.xxl),
                  LinearProgressIndicator(
                    value: 0.75,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.lg),
                  AppText.bodySmall(
                    'Processing payment...',
                    color: AppColors.onSurfaceVariant,
                  ),
            ],
          ),
        ),

        AppSpacing.verticalSpacing(SpacingSize.lg),

        // How Escrow Works Card
        AppCard.elevated(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyLarge(
                'How Escrow Protection Works',
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              _buildEscrowStep(
                1,
                'Payment Secured',
                'Your money is held safely in escrow',
                AppColors.primary,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              _buildEscrowStep(
                2,
                'Package Delivered',
                'Traveler delivers your package',
                AppColors.secondary,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              _buildEscrowStep(
                3,
                'Payment Released',
                'Money is released to traveler',
                AppColors.accent,
              ),
            ],
          ),
        ),
          ],
            );
          },
        );
      },
    );
  }

  IconData _getEscrowStatusIcon(EscrowStatus? status) {
    if (status == null) return Icons.shield;
    switch (status) {
      case EscrowStatus.holding:
        return Icons.hourglass_bottom;
      case EscrowStatus.held:
        return Icons.lock;
      case EscrowStatus.releasing:
        return Icons.lock_open;
      case EscrowStatus.released:
        return Icons.check_circle;
      case EscrowStatus.error:
        return Icons.error;
      default:
        return Icons.shield;
    }
  }

  Color _getEscrowStatusColor(EscrowStatus? status) {
    if (status == null) return AppColors.onSurfaceVariant;
    return switch (status) {
      EscrowStatus.holding => AppColors.pending,
      EscrowStatus.held => AppColors.processing,
      EscrowStatus.releasing => AppColors.reversed,
      EscrowStatus.released => AppColors.success,
      EscrowStatus.error => AppColors.error,
      _ => AppColors.onSurfaceVariant,
    };
  }

  String _getEscrowStatusLabel(EscrowStatus? status) {
    if (status == null) return 'IDLE';
    switch (status) {
      case EscrowStatus.holding:
        return 'HOLDING';
      case EscrowStatus.held:
        return 'HELD';
      case EscrowStatus.releasing:
        return 'RELEASING';
      case EscrowStatus.released:
        return 'RELEASED';
      case EscrowStatus.error:
        return 'ERROR';
      default:
        return 'IDLE';
    }
  }

  Widget _buildEscrowStep(int step, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.md,
          ),
          child: Center(
            child: AppText.bodySmall(
              step.toString(),
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        AppSpacing.horizontalSpacing(SpacingSize.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(
                title,
                fontWeight: FontWeight.w600,
              ),
              AppText.bodySmall(
                description,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCompleteStep() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: AppRadius.pill,
          ),
          child: Icon(
            Icons.check_circle,
            color: AppColors.white,
            size: 40,
          ),
        ),
        AppText.headlineSmall(
          'Payment Secured!',
          fontWeight: FontWeight.bold,
        ),
        AppSpacing.verticalSpacing(SpacingSize.sm),
        AppText.bodyMedium(
          'Your ${packageDetails['total']} has been successfully deposited into escrow',
          textAlign: TextAlign.center,
          color: AppColors.onSurfaceVariant,
        ),
        AppSpacing.verticalSpacing(SpacingSize.xxl),

        AppCard.elevated(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyLarge(
                'What\'s Next?',
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              Container(
                padding: AppSpacing.paddingMD,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.sm,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyMedium(
                            'Waiting for traveler confirmation',
                            fontWeight: FontWeight.w500,
                          ),
                          AppText.bodySmall(
                            'You\'ll be notified when accepted',
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              Container(
                padding: AppSpacing.paddingMD,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.sm,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyMedium(
                            'Track your package',
                            fontWeight: FontWeight.w500,
                          ),
                          AppText.bodySmall(
                            'Real-time updates via SMS & app',
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        AppSpacing.verticalSpacing(SpacingSize.xxl),

        Column(
          children: [
            AppButton.primary(
              onPressed: () {
                // Navigate to tracking screen
              },
              fullWidth: true,
              child: AppText.bodyLarge(
                'Track Package',
                color: Colors.white,
              ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            AppButton.outline(
              onPressed: () {
                // Message traveler
              },
              fullWidth: true,
              child: AppText.bodyLarge(
                'Message Traveler',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}