import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/helpers/user_extensions.dart';
import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/navigation_service/nav_config.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_font_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_input.dart';
import '../../../../../core/widgets/app_spacing.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../../injection_container.dart';
import '../../../../payments/domain/use_cases/paystack_payment_usecase.dart';
import '../../bloc/wallet/wallet_cubit.dart';
import '../../bloc/wallet/wallet_data.dart';

class FundingModal extends StatefulWidget {
  final String userId;
  final String transactionId;
  final String email;

  const FundingModal({
    super.key,
    required this.userId,
    required this.transactionId,
    required this.email,
  });

  static void show(BuildContext context, {required String userId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => FundingModal(
        userId: userId,
        email: context.user.email,
        transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
    );
  }

  @override
  State<FundingModal> createState() => _FundingModalState();
}

class _FundingModalState extends State<FundingModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  final _paystackPaymentUseCase = PaystackPaymentUseCase();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }

    if (amount < 100) {
      return 'Minimum amount is 100';
    }

    if (amount > 1000000) {
      return 'Maximum amount is 1,000,000';
    }

    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text);

    setState(() {
      _isLoading = true;
    });

    try {
      if (!mounted) return;
      final result = await _paystackPaymentUseCase.initializeWalletFunding(
        transactionId: widget.transactionId,
        amount: amount,
        email: widget.email,
      );

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
          });
          if (!mounted) return;
          context.showErrorMessage(failure.failureMessage);
        },
        (transaction) {
          setState(() {
            _isLoading = false;
          });
          if (!mounted) return;

          sl<NavigationService>().goBack();
          sl<NavigationService>().navigateTo(
            Routes.walletFundingPayment,
            arguments: {
              'authorizationUrl': transaction.authorizationUrl ?? '',
              'reference': transaction.reference,
              'transactionId': widget.transactionId,
              'userId': widget.userId,
              'amount': amount,
            },
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText.bodyMedium(
            'Failed to initialize payment: $e',
            color: AppColors.white,
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletData =
        context.read<WalletCubit>().state.data ?? const WalletData();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: AppSpacing.paddingXL,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DragHandle(),
                    _ModalHeader(),
                    AppSpacing.verticalSpacing(SpacingSize.md),
                    _CurrentBalanceInfo(walletData: walletData),
                    AppSpacing.verticalSpacing(SpacingSize.lg),
                    AppInput(
                      controller: _amountController,
                      label: 'Amount',
                      hintText: 'Enter amount to add (${walletData.currency})',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: _validateAmount,
                      enabled: !_isLoading,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.sm),
                    AppText.bodySmall(
                      'Minimum: 100 • Maximum: 1,000,000',
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.xl),
                    _ActionButtons(
                      isLoading: _isLoading,
                      onCancel: () => Navigator.of(context).pop(),
                      onSubmit: _handleSubmit,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
          borderRadius: AppRadius.xs,
        ),
      ),
    );
  }
}

class _ModalHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          'Add Money to Wallet',
          variant: TextVariant.titleLarge,
          fontSize: AppFontSize.xxl,
          fontWeight: FontWeight.bold,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class _CurrentBalanceInfo extends StatelessWidget {
  const _CurrentBalanceInfo({required this.walletData});

  final WalletData walletData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText.bodyMedium(
            'Current Balance:',
          ),
          AppText.bodySmall(
            '${walletData.currency} ${walletData.availableBalance.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isLoading,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton.secondary(
            onPressed: isLoading ? null : onCancel,
            child: const AppText('Cancel', color: AppColors.onSurface),
          ),
        ),
        AppSpacing.horizontalSpacing(SpacingSize.md),
        Expanded(
          child: AppButton.primary(
            onPressed: isLoading ? null : onSubmit,
            leadingIcon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.add, color: AppColors.white),
            requiresKyc: true,
            child: AppText(
              isLoading ? 'Processing...' : 'Add Money',
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}
