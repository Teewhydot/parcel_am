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

class AddBankAccountBottomSheet extends StatefulWidget {
  final String userId;
  final BankAccountBloc bloc;

  const AddBankAccountBottomSheet({
    super.key,
    required this.userId,
    required this.bloc,
  });

  static Future<bool?> show(BuildContext context, {required String userId}) {
    final bloc = context.read<BankAccountBloc>();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AddBankAccountBottomSheet(userId: userId, bloc: bloc),
      ),
    );
  }

  @override
  State<AddBankAccountBottomSheet> createState() =>
      _AddBankAccountBottomSheetState();
}

class _AddBankAccountBottomSheetState extends State<AddBankAccountBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  BankInfoEntity? _selectedBank;
  bool _isVerified = false;
  bool _accountSaved = false;

  @override
  void initState() {
    super.initState();
    // Load bank list when modal opens
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

  void _clearAndClose() {
    context.read<BankAccountBloc>().add(const BankAccountVerificationCleared());
    Navigator.pop(context, _accountSaved);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: BlocConsumer<BankAccountBloc, BaseState<BankAccountData>>(
        listener: (context, state) {
          // Handle verification result
          if (state is LoadedState<BankAccountData> &&
              state.data?.verificationResult != null &&
              !_isVerified) {
            setState(() {
              _isVerified = true;
              _accountNameController.text =
                  state.data?.verificationResult?.accountName ?? '';
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
              _isVerified &&
              state.data?.verificationResult == null) {
            setState(() {
              _accountSaved = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bank account added successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
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
          final isVerifying = data.isVerifying;
          final isSaving = data.isSaving;
          final bankList = data.bankList;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.titleLarge(
                        'Add Bank Account',
                        fontWeight: FontWeight.w600,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _clearAndClose,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: AppSpacing.paddingLG,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Notice
                          Container(
                            width: double.infinity,
                            padding: AppSpacing.paddingMD,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.blue.shade700, size: 20),
                                AppSpacing.horizontalSpacing(SpacingSize.sm),
                                Expanded(
                                  child: Text(
                                    'You can only add bank accounts registered in your name.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          AppSpacing.verticalSpacing(SpacingSize.lg),

                          // Bank Selection
                          const Text(
                            'Select Bank',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.sm),

                          if (bankList.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: AppSpacing.paddingMD,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  AppSpacing.horizontalSpacing(SpacingSize.sm),
                                  Text(
                                    'Loading banks...',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<BankInfoEntity>(
                              value: _selectedBank,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: 'Select your bank',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                              ),
                              items: bankList.map((bank) {
                                return DropdownMenuItem(
                                  value: bank,
                                  child: Text(
                                    bank.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (bank) {
                                setState(() {
                                  _selectedBank = bank;
                                  _isVerified = false;
                                  _accountNameController.clear();
                                });
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
                              onPressed: _isVerified || isVerifying || bankList.isEmpty
                                  ? null
                                  : _verifyAccount,
                              loading: isVerifying,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isVerified)
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 20),
                                  if (_isVerified)
                                    AppSpacing.horizontalSpacing(SpacingSize.xs),
                                  Text(_isVerified ? 'Verified' : 'Verify Account'),
                                ],
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
                                  Icon(Icons.check_circle,
                                      color: Colors.green.shade700),
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

                          AppSpacing.verticalSpacing(SpacingSize.lg),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
