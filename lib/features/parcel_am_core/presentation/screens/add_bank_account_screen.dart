import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/bloc/managers/bloc_manager.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../domain/entities/bank_info_entity.dart';
import '../bloc/bank_account/bank_account_bloc.dart';
import '../bloc/bank_account/bank_account_data.dart';
import '../bloc/bank_account/bank_account_event.dart';

class AddBankAccountScreen extends StatefulWidget {
  final String userId;

  const AddBankAccountScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AddBankAccountScreen> createState() => _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends State<AddBankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  BankInfoEntity? _selectedBank;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    // Load bank list when screen opens
    context.read<BankAccountBloc>().add(const BankListLoadRequested());
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  void _verifyAccount() {
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText.bodyMedium('Please select a bank', color: AppColors.white),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_accountNumberController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText.bodyMedium('Account number must be 10 digits', color: AppColors.white),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    context.read<BankAccountBloc>().add(
          BankAccountVerificationRequested(
            accountNumber: _accountNumberController.text,
            bankCode: _selectedBank!.code,
          ),
        );
  }

  void _saveAccount() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText.bodyMedium('Please verify the account first', color: AppColors.white),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    context.read<BankAccountBloc>().add(
          BankAccountAddRequested(
            userId: widget.userId,
            accountNumber: _accountNumberController.text,
            accountName: _accountNameController.text,
            bankCode: _selectedBank!.code,
            bankName: _selectedBank!.name,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge('Add Bank Account'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocManager<BankAccountBloc, BaseState<BankAccountData>>(
        bloc: context.read<BankAccountBloc>(),
        showLoadingIndicator: false,
        listener: (context, state) {
          // Handle verification result
          if (state is LoadedState<BankAccountData> &&
              state.data?.verificationResult != null &&
              !_isVerified) {
            setState(() {
              _isVerified = true;
              _accountNameController.text = state.data?.verificationResult?.accountName ?? '';
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText.bodyMedium(
                  'Account verified: ${state.data?.verificationResult?.accountName ?? 'Unknown'}',
                  color: AppColors.white,
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }

          // Handle save success
          if (state is LoadedState<BankAccountData> &&
              (state.data?.userBankAccounts.isNotEmpty ?? false) &&
              state.data?.verificationResult == null) {
            sl<NavigationService>().goBack<bool>(result: true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText.bodyMedium('Bank account added successfully', color: AppColors.white),
                backgroundColor: AppColors.success,
              ),
            );
          }

          // Handle errors
          if (state is AsyncErrorState<BankAccountData>) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText.bodyMedium(state.errorMessage, color: AppColors.white),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          final data = state.data ?? const BankAccountData();
          final isVerifying = data.isVerifying;
          final isSaving = data.isSaving;

          return SingleChildScrollView(
            padding: AppSpacing.paddingLG,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.titleMedium(
                    'Bank Account Details',
                    fontWeight: FontWeight.w600,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.md),

                  // Bank Selection Dropdown
                  AppText.bodyMedium(
                    'Select Bank',
                    fontWeight: FontWeight.w500,
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.sm),
                  DropdownButtonFormField<BankInfoEntity>(
                    value: _selectedBank,
                    decoration: InputDecoration(
                      hintText: 'Select your bank',
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.sm,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                    ),
                    items: data.bankList.map((bank) {
                      return DropdownMenuItem(
                        value: bank,
                        child: AppText.bodyMedium(bank.name),
                      );
                    }).toList(),
                    onChanged: (bank) {
                      setState(() {
                        _selectedBank = bank;
                        _isVerified = false;
                        _accountNameController.clear();
                      });
                      // Clear verification when bank changes
                      context.read<BankAccountBloc>().add(
                            const BankAccountVerificationCleared(),
                          );
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a bank';
                      }
                      return null;
                    },
                  ),

                  AppSpacing.verticalSpacing(SpacingSize.lg),

                  AppInput(
                    controller: _accountNumberController,
                    label: 'Account Number',
                    hintText: 'Enter 10-digit account number',
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      if (_isVerified) {
                        setState(() {
                          _isVerified = false;
                          _accountNameController.clear();
                        });
                        context.read<BankAccountBloc>().add(
                              const BankAccountVerificationCleared(),
                            );
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter account number';
                      }
                      if (value.length != 10) {
                        return 'Account number must be 10 digits';
                      }
                      return null;
                    },
                  ),

                  AppSpacing.verticalSpacing(SpacingSize.md),

                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.outline(
                      onPressed: _isVerified || isVerifying
                          ? null
                          : _verifyAccount,
                      loading: isVerifying,
                      child: AppText.bodyMedium(
                        _isVerified ? 'Verified' : 'Verify Account',
                      ),
                    ),
                  ),

                  if (_isVerified) ...[
                    AppSpacing.verticalSpacing(SpacingSize.lg),

                    // Account Name Display
                    AppText.bodyMedium(
                      'Account Name',
                      fontWeight: FontWeight.w500,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.sm),
                    Container(
                      width: double.infinity,
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: AppRadius.sm,
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.successDark),
                          AppSpacing.horizontalSpacing(SpacingSize.sm),
                          Expanded(
                            child: AppText.bodyLarge(
                              _accountNameController.text,
                              fontWeight: FontWeight.w600,
                              color: AppColors.successDark,
                            ),
                          ),
                        ],
                      ),
                    ),

                    AppSpacing.verticalSpacing(SpacingSize.xl),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        onPressed: isSaving ? null : _saveAccount,
                        loading: isSaving,
                        child: AppText.bodyMedium('Save Bank Account', color: AppColors.white),
                      ),
                    ),
                  ],

                  AppSpacing.verticalSpacing(SpacingSize.md),

                  // Info message
                  if (data.hasReachedMaxAccounts)
                    Container(
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: AppRadius.sm,
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.warningDark),
                          AppSpacing.horizontalSpacing(SpacingSize.sm),
                          Expanded(
                            child: AppText.bodyMedium(
                              'You have reached the maximum of 5 bank accounts',
                              color: AppColors.warningDark,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: AppRadius.sm,
                        border: Border.all(color: AppColors.info),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.infoDark),
                          AppSpacing.horizontalSpacing(SpacingSize.sm),
                          Expanded(
                            child: AppText.bodyMedium(
                              'You can save up to ${data.remainingAccountSlots} more bank account(s)',
                              color: AppColors.infoDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}
