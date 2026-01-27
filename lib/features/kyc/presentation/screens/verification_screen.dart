import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/core/helpers/user_extensions.dart';
import 'package:parcel_am/features/file_upload/domain/entities/uploaded_file_entity.dart';
import 'package:parcel_am/features/file_upload/domain/use_cases/file_upload_usecase.dart';
import '../../domain/entities/kyc_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../widgets/verification_widgets.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_cubit.dart';
import '../../../parcel_am_core/presentation/bloc/auth/auth_data.dart';
import '../bloc/kyc_bloc.dart';
import '../bloc/kyc_event.dart';
import '../bloc/kyc_data.dart';
import '../../domain/models/verification_model.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../widgets/verification/personal_info_step.dart';
import '../widgets/verification/identity_verification_step.dart';
import '../widgets/verification/address_verification_step.dart';
import '../widgets/verification/review_step.dart';
import '../widgets/verification/verification_bottom_actions.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _bvnController = TextEditingController();
  final _ninController = TextEditingController();

  String _selectedGender = 'Male';
  final Map<String, UploadedFileEntity> _uploadedDocuments = {};
  final Map<String, String> _uploadedDocumentUrls = {};

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _bvnController.dispose();
    _ninController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocManager<KycBloc, BaseState<KycData>>(
      bloc: context.read<KycBloc>(),
      showLoadingIndicator: false,
      showResultSuccessNotifications: false,
      showResultErrorNotifications: true,
      listener: (context, state) {
        if (state is SuccessState<KycData>) {
          context.showSnackbar(message: state.successMessage);
          sl<NavigationService>().goBack();
        }
      },
      child: AppScaffold(
        title: 'KYC Verification',
        appBarBackgroundColor: AppColors.background,
        body: Column(
          children: [
            ProgressIndicatorWidget(
              currentStep: _currentStep,
              steps: VerificationStep.steps,
            ),
            Expanded(child: _buildStepContent()),
            VerificationBottomActions(
              currentStep: _currentStep,
              totalSteps: VerificationStep.steps.length,
              isSubmitting: _isSubmitting,
              onBack: _goToPreviousStep,
              onNext: _goToNextStep,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    final fileUploadUseCase = FileUploadUseCase();

    switch (_currentStep) {
      case 0:
        return PersonalInfoStep(
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          phoneController: _phoneController,
          dobController: _dobController,
          ninController: _ninController,
          bvnController: _bvnController,
          selectedGender: _selectedGender,
          onGenderChanged: (value) => setState(() => _selectedGender = value!),
          onDateOfBirthTap: _selectDateOfBirth,
        );
      case 1:
        return IdentityVerificationStep(
          isGovernmentIdUploaded: _uploadedDocumentUrls['government_id'] != null,
          isSelfieWithIdUploaded: _uploadedDocumentUrls['selfie_with_id'] != null,
          onGovernmentIdUpload: (document) async {
            final result = await fileUploadUseCase.uploadFile(
              userId: context.currentUserId!,
              file: document.file,
              folder: 'government_id',
            );
            result.fold(
              (failure) => context.showErrorMessage(failure.failureMessage),
              (doc) => setState(() {
                _uploadedDocumentUrls['government_id'] = doc.url;
                _uploadedDocuments['government_id'] = doc;
              }),
            );
          },
          onSelfieWithIdUpload: (document) async {
            final result = await fileUploadUseCase.uploadFile(
              userId: context.currentUserId!,
              file: document.file,
              folder: 'selfie_with_id',
            );
            result.fold(
              (failure) => context.showErrorMessage(failure.failureMessage),
              (doc) => setState(() {
                _uploadedDocumentUrls['selfie_with_id'] = doc.url;
                _uploadedDocuments['selfie_with_id'] = doc;
              }),
            );
          },
        );
      case 2:
        return AddressVerificationStep(
          addressController: _addressController,
          cityController: _cityController,
          stateController: _stateController,
          postalCodeController: _postalCodeController,
          isProofOfAddressUploaded:
              _uploadedDocumentUrls['proof_of_address'] != null,
          onProofOfAddressUpload: (document) async {
            final result = await fileUploadUseCase.uploadFile(
              userId: context.currentUserId!,
              file: document.file,
              folder: 'proof_of_address',
            );
            result.fold(
              (failure) => context.showErrorMessage(failure.failureMessage),
              (doc) => setState(() {
                _uploadedDocumentUrls['proof_of_address'] = doc.url;
                _uploadedDocuments['proof_of_address'] = doc;
              }),
            );
          },
        );
      case 3:
        return ReviewStep(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          dateOfBirth: _dobController.text,
          gender: _selectedGender,
          nin: _ninController.text,
          bvn: _bvnController.text,
          address: _addressController.text,
          city: _cityController.text,
          state: _stateController.text,
          hasGovernmentId: _uploadedDocuments['government_id'] != null,
          hasSelfieWithId: _uploadedDocuments['selfie_with_id'] != null,
          hasProofOfAddress: _uploadedDocuments['proof_of_address'] != null,
        );
      default:
        return Container();
    }
  }

  Future<void> _selectDateOfBirth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)),
    );
    if (date != null) {
      _dobController.text = '${date.day}/${date.month}/${date.year}';
    }
  }

  void _goToNextStep() async {
    if (!_validateCurrentStep()) return;

    if (_currentStep < VerificationStep.steps.length - 1) {
      setState(() => _currentStep++);
      _saveProgress();
    } else {
      await _submitVerification();
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_firstNameController.text.isEmpty ||
            _lastNameController.text.isEmpty ||
            _phoneController.text.isEmpty ||
            _dobController.text.isEmpty) {
          _showError('Please fill in all required fields');
          return false;
        }
        break;
      case 1:
        if (_uploadedDocuments['government_id'] == null ||
            _uploadedDocuments['selfie_with_id'] == null) {
          _showError('Please upload all required documents');
          return false;
        }
        break;
      case 2:
        if (_addressController.text.isEmpty ||
            _cityController.text.isEmpty ||
            _stateController.text.isEmpty ||
            _postalCodeController.text.isEmpty) {
          _showError('Please fill in all address fields');
          return false;
        }
        break;
    }
    return true;
  }

  void _saveProgress() {
    final authCubit = context.read<AuthCubit>();
    final currentState = authCubit.state;

    Map<String, dynamic> additionalData = {};
    if (currentState is DataState<AuthData> &&
        currentState.data?.user != null) {
      additionalData = Map.from(currentState.data!.user!.additionalData);
    }

    authCubit.updateUserProfileWithKyc(
      displayName: '${_firstNameController.text} ${_lastNameController.text}',
      kycStatus: KycStatus.incomplete,
      additionalData: {
        ...additionalData,
        'kycCurrentStep': _currentStep,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'dateOfBirth': _dobController.text,
        'gender': _selectedGender,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'nin': _ninController.text,
        'bvn': _bvnController.text,
        'uploadedDocuments': _uploadedDocuments.keys.toList(),
      },
    );
  }

  DateTime _parseDateOfBirth() {
    try {
      final parts = _dobController.text.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Fallback to a default date if parsing fails
    }
    return DateTime(1990, 1, 1);
  }

  Future<void> _submitVerification() async {
    setState(() => _isSubmitting = true);

    try {
      final authState = context.read<AuthCubit>().state;

      if (authState is DataState<AuthData> && authState.data?.user != null) {
        final user = authState.data!.user!;

        context.read<KycBloc>().add(
              KycFinalSubmitRequested(
                userId: user.uid,
                fullName:
                    '${_firstNameController.text} ${_lastNameController.text}',
                dateOfBirth: _parseDateOfBirth(),
                phoneNumber: _phoneController.text,
                email: user.email,
                address: _addressController.text,
                city: _cityController.text,
                country: 'Nigeria',
                postalCode: _postalCodeController.text,
                governmentIdNumber: _ninController.text.isNotEmpty
                    ? _ninController.text
                    : _bvnController.text,
                idType: _ninController.text.isNotEmpty ? 'NIN' : 'BVN',
                governmentIdUrl: _uploadedDocumentUrls['government_id'],
                selfieWithIdUrl: _uploadedDocumentUrls['selfie_with_id'],
                proofOfAddressUrl: _uploadedDocumentUrls['proof_of_address'],
              ),
            );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('Verification submission failed: $e');
      }
    }
  }

  void _showError(String message) {
    context.showSnackbar(
      message: message,
      color: AppColors.error,
    );
  }
}
