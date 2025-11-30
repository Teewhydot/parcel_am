import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
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
        const SnackBar(
          content: Text('Please select a bank'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_accountNumberController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account number must be 10 digits'),
          backgroundColor: Colors.orange,
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
        const SnackBar(
          content: Text('Please verify the account first'),
          backgroundColor: Colors.orange,
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
        title: const Text('Add Bank Account'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocConsumer<BankAccountBloc, BaseState<BankAccountData>>(
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
                content: Text(
                  'Account verified: ${state.data?.verificationResult?.accountName ?? 'Unknown'}',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Handle save success
          if (state is LoadedState<BankAccountData> &&
              (state.data?.userBankAccounts.isNotEmpty ?? false) &&
              state.data?.verificationResult == null) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bank account added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Handle errors
          if (state is AsyncErrorState<BankAccountData>) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          final data = state.data ?? const BankAccountData();
          final isLoading = state.isLoading;
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
                  const Text(
                    'Select Bank',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.sm),
                  DropdownButtonFormField<BankInfoEntity>(
                    value: _selectedBank,
                    decoration: InputDecoration(
                      hintText: 'Select your bank',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                    ),
                    items: data.bankList.map((bank) {
                      return DropdownMenuItem(
                        value: bank,
                        child: Text(bank.name),
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

                  // Account Number Input
                  const Text(
                    'Account Number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AppSpacing.verticalSpacing(SpacingSize.sm),
                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter 10-digit account number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      counterText: '',
                    ),
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
                      child: Text(
                        _isVerified ? 'Verified' : 'Verify Account',
                      ),
                    ),
                  ),

                  if (_isVerified) ...[
                    AppSpacing.verticalSpacing(SpacingSize.lg),

                    // Account Name Display
                    const Text(
                      'Account Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.sm),
                    Container(
                      width: double.infinity,
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700),
                          AppSpacing.horizontalSpacing(SpacingSize.sm),
                          Expanded(
                            child: Text(
                              _accountNameController.text,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade900,
                              ),
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
                        child: const Text('Save Bank Account'),
                      ),
                    ),
                  ],

                  AppSpacing.verticalSpacing(SpacingSize.md),

                  // Info message
                  if (data.hasReachedMaxAccounts)
                    Container(
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700),
                          AppSpacing.horizontalSpacing(SpacingSize.sm),
                          Expanded(
                            child: Text(
                              'You have reached the maximum of 5 bank accounts',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          AppSpacing.horizontalSpacing(SpacingSize.sm),
                          Expanded(
                            child: Text(
                              'You can save up to ${data.remainingAccountSlots} more bank account(s)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade900,
                              ),
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
      ),
    );
  }
}
