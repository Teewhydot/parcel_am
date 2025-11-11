import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../injection_container.dart';
import '../widgets/bottom_navigation.dart';
import '../bloc/wallet/wallet_bloc.dart';
import '../bloc/wallet/wallet_event.dart';
import '../bloc/wallet/wallet_data.dart';
import '../../domain/models/package_model.dart';

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
  late WalletBloc _walletBloc;
  PaymentInfo? _paymentInfo;

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
    _walletBloc = sl<WalletBloc>();
    _walletBloc.add(const WalletLoadRequested());
  }

  @override
  void dispose() {
    _walletBloc.close();
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

    _paymentInfo = PaymentInfo(
      transactionId: transactionId,
      status: 'processing',
      amount: 3500.0,
      serviceFee: 150.0,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      paidAt: DateTime.now(),
      isEscrow: true,
      escrowStatus: 'held',
      escrowHeldAt: DateTime.now(),
    );

    _walletBloc.add(WalletEscrowHoldRequested(
      transactionId: transactionId,
      amount: totalAmount,
      packageId: 'PKG_001',
    ));

    setState(() {
      currentStep++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _walletBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure Payment'),
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocListener<WalletBloc, BaseState<WalletData>>(
          listener: (context, state) {
            if (state is ErrorState<WalletData>) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'An error occurred'),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is LoadedState<WalletData> && currentStep == 2) {
              setState(() {
                currentStep = 3;
              });
            }
          },
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
                Text(
                  steps[currentStep]['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
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
              child: SizedBox(
                width: double.infinity,
                height: SpacingSize.massive.value,
                child: ElevatedButton(
                  onPressed: nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    currentStep == 0 ? 'Proceed to Payment' :
                    currentStep == 1 ? 'Confirm Payment Method' :
                    'Complete Payment',
                    style: const TextStyle(fontSize: 16),
                  ),
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
        Card(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                        borderRadius: BorderRadius.circular(12),
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
                          Text(
                            packageDetails['title']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            packageDetails['route']!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Traveler: ${packageDetails['traveler']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      packageDetails['price']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        AppSpacing.verticalSpacing(SpacingSize.lg),

        // Price Breakdown Card
        Card(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSpacing(SpacingSize.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delivery Fee',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                    Text(packageDetails['deliveryFee']!),
                  ],
                ),
                AppSpacing.verticalSpacing(SpacingSize.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Service Fee',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                    Text(packageDetails['serviceFee']!),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      packageDetails['total']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        AppSpacing.verticalSpacing(SpacingSize.lg),

        // Escrow Protection Notice
        Container(
          padding: AppSpacing.paddingLG,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
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
                    const Text(
                      'Escrow Protection',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Your payment will be securely held until delivery is confirmed by both parties.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
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
        Card(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                          borderRadius: BorderRadius.circular(12),
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
                                  Text(
                                    method['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    method['description'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (method['popular'])
                              Container(
                                padding: AppSpacing.verticalPaddingXS + AppSpacing.horizontalPaddingSM,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Popular',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
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
        ),

        if (paymentMethod == 'bank') ...
          [
            AppSpacing.verticalSpacing(SpacingSize.lg),
            Card(
              child: Padding(
                padding: AppSpacing.paddingLG,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bank Account Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    TextFormField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Account Number',
                        hintText: '0123456789',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    TextFormField(
                      controller: _bankNameController,
                      decoration: const InputDecoration(
                        labelText: 'Bank Name',
                        hintText: 'Select your bank',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
      ],
    );
  }

  Widget _buildEscrowDepositStep() {
    return BlocBuilder<WalletBloc, BaseState<WalletData>>(
      builder: (context, state) {
        return Column(
          children: [
            if (state is LoadedState<WalletData> && state.data != null) ...[
              Card(
                child: Padding(
                  padding: AppSpacing.paddingLG,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wallet Balance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Available Balance',
                            style: TextStyle(color: AppColors.onSurfaceVariant),
                          ),
                          Text(
                            '₦${state.data!.availableBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalSpacing(SpacingSize.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pending (Escrow)',
                            style: TextStyle(color: AppColors.onSurfaceVariant),
                          ),
                          Text(
                            '₦${state.data!.pendingBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
            ],
            Card(
              child: Padding(
                padding: AppSpacing.paddingXXL,
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    const Text(
                      'Securing Your Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.sm),
                    Text(
                      'Your ${packageDetails['total']} is being deposited into our secure escrow system',
                      textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                AppSpacing.verticalSpacing(SpacingSize.xxl),
                LinearProgressIndicator(
                  value: 0.75,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                AppSpacing.verticalSpacing(SpacingSize.lg),
                const Text(
                  'Processing payment...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        AppSpacing.verticalSpacing(SpacingSize.lg),

        // How Escrow Works Card
        Card(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How Escrow Protection Works',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
        ),
          ],
        );
      },
    );
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        AppSpacing.horizontalSpacing(SpacingSize.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
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
            color: Colors.green,
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 40,
          ),
        ),
        const Text(
          'Payment Secured!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.sm),
        Text(
          'Your ${packageDetails['total']} has been successfully deposited into escrow',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        AppSpacing.verticalSpacing(SpacingSize.xxl),

        Card(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What\'s Next?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSpacing(SpacingSize.lg),
                Container(
                  padding: AppSpacing.paddingMD,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
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
                            const Text(
                              'Waiting for traveler confirmation',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Text(
                              'You\'ll be notified when accepted',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
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
                    borderRadius: BorderRadius.circular(8),
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
                            const Text(
                              'Track your package',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Text(
                              'Real-time updates via SMS & app',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
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
        ),

        AppSpacing.verticalSpacing(SpacingSize.xxl),

        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: SpacingSize.massive.value,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to tracking screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Track Package',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            AppSpacing.verticalSpacing(SpacingSize.md),
            SizedBox(
              width: double.infinity,
              height: SpacingSize.massive.value,
              child: OutlinedButton(
                onPressed: () {
                  // Message traveler
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Message Traveler',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }
}