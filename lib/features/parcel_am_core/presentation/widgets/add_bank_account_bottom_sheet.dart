import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base/base_state.dart';
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
import 'bank_account/add_bank_header.dart';
import 'bank_account/bank_account_notice.dart';
import 'bank_account/banks_loading_indicator.dart';
import 'bank_account/verified_account_display.dart';
import 'bank_account/verify_account_button.dart';

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
      backgroundColor: AppColors.transparent,
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
        color: AppColors.white,
        borderRadius: AppRadius.topXl,
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
              _isVerified &&
              state.data?.verificationResult == null) {
            setState(() {
              _accountSaved = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText.bodyMedium('Bank account added successfully', color: AppColors.white),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
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
          final bankList = data.bankList;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AddBankHeader(onClose: _clearAndClose),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: AppSpacing.paddingLG,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BankAccountNotice(),
                          AppSpacing.verticalSpacing(SpacingSize.lg),

                          // Bank Selection
                          AppText.bodyMedium(
                            'Select Bank',
                            fontWeight: FontWeight.w500,
                          ),
                          AppSpacing.verticalSpacing(SpacingSize.sm),

                          if (bankList.isEmpty)
                            const BanksLoadingIndicator()
                          else
                            DropdownButtonFormField<BankInfoEntity>(
                              value: _selectedBank,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: 'Select your bank',
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.sm,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                              ),
                              items: bankList.map((bank) {
                                return DropdownMenuItem(
                                  value: bank,
                                  child: AppText.bodyMedium(
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

                          VerifyAccountButton(
                            isVerified: _isVerified,
                            isVerifying: isVerifying,
                            isDisabled: bankList.isEmpty,
                            onPressed: _verifyAccount,
                          ),

                          if (_isVerified) ...[
                            AppSpacing.verticalSpacing(SpacingSize.lg),
                            VerifiedAccountDisplay(
                              accountName: _accountNameController.text,
                            ),
                            AppSpacing.verticalSpacing(SpacingSize.xl),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: AppButton.primary(
                                onPressed: isSaving ? null : _saveAccount,
                                loading: isSaving,
                                child: AppText.bodyMedium(
                                  'Save Bank Account',
                                  color: AppColors.white,
                                ),
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
