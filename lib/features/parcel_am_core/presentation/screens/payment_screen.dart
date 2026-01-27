import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../escrow/domain/entities/escrow_status.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/wallet/wallet_cubit.dart';
import '../bloc/wallet/wallet_data.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/escrow/escrow_cubit.dart';
import '../bloc/escrow/escrow_state.dart';
import '../../domain/entities/package_entity.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../widgets/payment/confirm_order_step.dart';
import '../widgets/payment/select_payment_step.dart';
import '../widgets/payment/escrow_deposit_step.dart';
import '../widgets/payment/payment_complete_step.dart';

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
  WalletCubit get _walletBloc => context.read<WalletCubit>();
  EscrowCubit get _escrowBloc => context.read<EscrowCubit>();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _walletBloc.loadWallet();
    });
  }

  @override
  void dispose() {
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
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge('Secure Payment'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => sl<NavigationService>().goBack(),
        ),
      ),
      body: BlocManager<WalletCubit, BaseState<WalletData>>(
        bloc: context.read<WalletCubit>(),
        showLoadingIndicator: false,
        showResultErrorNotifications: true,
        child: BlocManager<EscrowCubit, BaseState<EscrowData>>(
          bloc: context.read<EscrowCubit>(),
          showLoadingIndicator: false,
          showResultErrorNotifications: true,
          listener: (context, state) {
            final escrow = state.data?.currentEscrow;
            if (escrow?.status == EscrowStatus.held && currentStep == 2) {
              setState(() {
                currentStep = 3;
                _paymentInfo = _paymentInfo?.copyWith(escrowStatus: 'held');
              });
            }
          },
          child: Column(
            children: [
              _ProgressSteps(
                steps: steps,
                currentStep: currentStep,
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
                      currentStep == 0
                          ? 'Proceed to Payment'
                          : currentStep == 1
                              ? 'Confirm Payment Method'
                              : 'Complete Payment',
                      color: AppColors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return ConfirmOrderStep(packageDetails: packageDetails);
      case 1:
        return SelectPaymentStep(
          paymentMethods: paymentMethods,
          selectedPaymentMethod: paymentMethod,
          onPaymentMethodChanged: (value) => setState(() => paymentMethod = value),
          accountNumberController: _accountNumberController,
          bankNameController: _bankNameController,
        );
      case 2:
        return EscrowDepositStep(totalAmount: packageDetails['total']!);
      case 3:
        return PaymentCompleteStep(
          totalAmount: packageDetails['total']!,
          onTrackPackage: () {},
          onMessageTraveler: () {},
        );
      default:
        return const SizedBox();
    }
  }
}

class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps({
    required this.steps,
    required this.currentStep,
  });

  final List<Map<String, dynamic>> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLG,
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= currentStep ? AppColors.primary : AppColors.surfaceVariant,
                  ),
                  child: Icon(
                    i < currentStep ? Icons.check : steps[i]['icon'] as IconData,
                    color: i <= currentStep ? AppColors.white : AppColors.onSurfaceVariant,
                    size: 18,
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: AppSpacing.horizontalPaddingSM,
                      color: i < currentStep ? AppColors.primary : AppColors.outline,
                    ),
                  ),
              ],
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.sm),
          AppText.bodyMedium(
            steps[currentStep]['title'],
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}
