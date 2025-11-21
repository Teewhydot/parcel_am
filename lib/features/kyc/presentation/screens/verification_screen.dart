import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import '../../../../core/domain/entities/kyc_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_container.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../widgets/verification_widgets.dart';
import '../../../parcel_am_core/presentation/bloc/auth/auth_bloc.dart';
import '../../../parcel_am_core/presentation/bloc/auth/auth_event.dart';
import '../../../parcel_am_core/presentation/bloc/auth/auth_data.dart';
import '../bloc/kyc_bloc.dart';
import '../bloc/kyc_event.dart';
import '../bloc/kyc_data.dart';
import '../../../parcel_am_core/data/constants/verification_constants.dart';
import '../../domain/models/verification_model.dart';
import '../../../../core/bloc/base/base_state.dart';

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
  final Map<String, DocumentUpload> _uploadedDocuments = {};
  final Map<String, String> _uploadedDocumentUrls = {}; // documentType -> Firebase URL

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is DataState<AuthData> && authState.data?.user != null) {
      final user = authState.data!.user!;
      final additionalData = user.additionalData;
      
      _firstNameController.text = additionalData['firstName'] ?? '';
      _lastNameController.text = additionalData['lastName'] ?? '';
      _dobController.text = additionalData['dateOfBirth'] ?? '';
      _selectedGender = additionalData['gender'] ?? 'Male';
      _addressController.text = additionalData['address'] ?? '';
      _cityController.text = additionalData['city'] ?? '';
      _stateController.text = additionalData['state'] ?? '';
      _ninController.text = additionalData['nin'] ?? '';
      _bvnController.text = additionalData['bvn'] ?? '';
      
      if (user.kycStatus == KycStatus.incomplete) {
        final savedStep = additionalData['kycCurrentStep'] as int?;
        if (savedStep != null && savedStep < VerificationStep.steps.length) {
          _currentStep = savedStep;
        }
      }
    }
  }

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
      listener: (context, state) {
        // Handle success state (document uploaded or KYC submitted)
        if (state.isSuccess) {
          setState(() => _isSubmitting = false);

          // If KYC was fully submitted, show success dialog
          if (state.data?.status == 'pending') {
            if (mounted) _showSuccessDialog();
          }
        }

        // Handle loaded state (document uploaded)
        if (state.isLoaded && state.data != null) {
          final kycData = state.data!;
          // Update local uploaded documents map
          setState(() {
            _uploadedDocumentUrls.addAll(kycData.uploadedDocuments);
          });
        }

        // Handle loading state
        if (state.isLoading) {
          setState(() => _isSubmitting = true);
        }

        // Handle error state
        if (state.isError) {
          setState(() => _isSubmitting = false);
        }
      },
      showResultSuccessNotifications: true,
      showResultErrorNotifications: true,
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
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildPersonalInfoStep();
      case 1: return _buildIdentityVerificationStep();
      case 2: return _buildAddressVerificationStep();
      case 3: return _buildReviewStep();
      default: return Container();
    }
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Tell us about yourself'),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          
          Row(
            children: [
              Expanded(
                child: AppInput(
                  controller: _firstNameController,
                  label: 'First Name *',
                  hintText: 'John',
                ),
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: AppInput(
                  controller: _lastNameController,
                  label: 'Last Name *',
                  hintText: 'Doe',
                ),
              ),
            ],
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: _phoneController,
            label: 'Phone Number *',
            hintText: '080 6878 7087',
            keyboardType: TextInputType.phone,
          ),

          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: _dobController,
            label: 'Date of Birth *',
            hintText: 'Select date',
            readOnly: true,
            suffixIcon: const Icon(Icons.calendar_today),
            onTap: _selectDateOfBirth,
          ),

          AppSpacing.verticalSpacing(SpacingSize.md),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(
              labelText: 'Gender *',
              border: OutlineInputBorder(),
            ),
            items: VerificationConstants.genderOptions.map((gender) {
              return DropdownMenuItem(value: gender, child: Text(gender));
            }).toList(),
            onChanged: (value) => setState(() => _selectedGender = value!),
          ),
          
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppText.titleMedium('Government IDs'),
          AppSpacing.verticalSpacing(SpacingSize.md),
          
          AppInput(
            controller: _ninController,
            label: 'NIN (National Identity Number)',
            hintText: '12345678901',
            keyboardType: TextInputType.number,
            maxLength: 11,
          ),
          
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: _bvnController,
            label: 'BVN (Bank Verification Number)',
            hintText: '12345678901',
            keyboardType: TextInputType.number,
            maxLength: 11,
          ),
          
          AppSpacing.verticalSpacing(SpacingSize.lg),
          const InfoCard(
            title: 'Privacy Notice',
            content: VerificationConstants.privacyNotice,
            color: AppColors.primary,
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityVerificationStep() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Upload Identity Documents'),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText.bodyMedium(
            'Please upload clear, readable photos of your documents',
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          
          DocumentUploadCard(
            title: 'Government ID',
            description: 'Upload your NIN slip, Driver\'s License, or International Passport',
            documentKey: 'government_id',
            uploadedDocument: _uploadedDocuments['government_id'],
            onUpload: (document) {
              setState(() => _uploadedDocuments['government_id'] = document);
              _uploadDocumentToFirebase('government_id', document.filePath);
            },
          ),

          AppSpacing.verticalSpacing(SpacingSize.md),
          DocumentUploadCard(
            title: 'Selfie with ID',
            description: 'Upload a photo holding your government ID next to your face',
            documentKey: 'selfie_with_id',
            uploadedDocument: _uploadedDocuments['selfie_with_id'],
            onUpload: (document) {
              setState(() => _uploadedDocuments['selfie_with_id'] = document);
              _uploadDocumentToFirebase('selfie_with_id', document.filePath);
            },
            isCamera: false,
          ),
          
          AppSpacing.verticalSpacing(SpacingSize.lg),
          const TipsCard(
            title: 'Tips for better photos',
            tips: VerificationConstants.photoTips,
            color: AppColors.accent,
            icon: Icons.lightbulb_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressVerificationStep() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Address Information'),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          
          AppInput(
            controller: _addressController,
            label: 'Street Address *',
            hintText: '123 Main Street, Victoria Island',
            maxLines: 2,
          ),
          
          AppSpacing.verticalSpacing(SpacingSize.md),
          Row(
            children: [
              Expanded(
                child: AppInput(
                  controller: _cityController,
                  label: 'City *',
                  hintText: 'Lagos',
                ),
              ),
              AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _stateController.text.isNotEmpty ? _stateController.text : null,
                  decoration: const InputDecoration(
                    labelText: 'State *',
                    border: OutlineInputBorder(),
                  ),
                  items: VerificationConstants.nigerianStates.map((state) {
                    return DropdownMenuItem(value: state, child: Text(state));
                  }).toList(),
                  onChanged: (value) => _stateController.text = value!,
                ),
              ),
            ],
          ),

          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: _postalCodeController,
            label: 'Postal Code *',
            hintText: '100001',
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),

          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppText.titleMedium('Address Verification Document'),
          AppSpacing.verticalSpacing(SpacingSize.md),

          DocumentUploadCard(
            title: 'Proof of Address',
            description: 'Upload utility bill, bank statement, or tenancy agreement (dated within last 3 months)',
            documentKey: 'proof_of_address',
            uploadedDocument: _uploadedDocuments['proof_of_address'],
            onUpload: (document) {
              setState(() => _uploadedDocuments['proof_of_address'] = document);
              _uploadDocumentToFirebase('proof_of_address', document.filePath);
            },
          ),
          
          AppSpacing.verticalSpacing(SpacingSize.lg),
          const TipsCard(
            title: 'Accepted Documents',
            tips: VerificationConstants.acceptedAddressDocuments,
            color: AppColors.primary,
            icon: Icons.description,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Review Your Information'),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppText.bodyMedium(
            'Please review all information before submitting',
            color: AppColors.onSurfaceVariant,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          
          _buildPersonalInfoSummary(),
          AppSpacing.verticalSpacing(SpacingSize.md),
          _buildAddressSummary(),
          AppSpacing.verticalSpacing(SpacingSize.md),
          _buildDocumentsSummary(),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          
          const InfoCard(
            title: 'Verification Process',
            content: VerificationConstants.verificationProcessInfo,
            color: AppColors.primary,
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSummary() {
    return AppContainer(
      variant: ContainerVariant.outlined,
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Personal Information'),
          AppSpacing.verticalSpacing(SpacingSize.md),
          ReviewRow(label: 'Full Name', value: '${_firstNameController.text} ${_lastNameController.text}'),
          ReviewRow(label: 'Date of Birth', value: _dobController.text),
          ReviewRow(label: 'Gender', value: _selectedGender),
          ReviewRow(label: 'NIN', value: _ninController.text.isNotEmpty ? _ninController.text : 'Not provided'),
          ReviewRow(label: 'BVN', value: _bvnController.text.isNotEmpty ? _bvnController.text : 'Not provided'),
        ],
      ),
    );
  }

  Widget _buildAddressSummary() {
    return AppContainer(
      variant: ContainerVariant.outlined,
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Address Information'),
          AppSpacing.verticalSpacing(SpacingSize.md),
          ReviewRow(label: 'Address', value: _addressController.text),
          ReviewRow(label: 'City', value: _cityController.text),
          ReviewRow(label: 'State', value: _stateController.text),
        ],
      ),
    );
  }

  Widget _buildDocumentsSummary() {
    return AppContainer(
      variant: ContainerVariant.outlined,
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Uploaded Documents'),
          AppSpacing.verticalSpacing(SpacingSize.md),
          DocumentReviewRow(title: 'Government ID', isUploaded: _uploadedDocuments['government_id'] != null),
          DocumentReviewRow(title: 'Selfie with ID', isUploaded: _uploadedDocuments['selfie_with_id'] != null),
          DocumentReviewRow(title: 'Proof of Address', isUploaded: _uploadedDocuments['proof_of_address'] != null),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return AppContainer(
      padding: AppSpacing.paddingXL,
      variant: ContainerVariant.outlined,
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: AppButton.outline(
                onPressed: _isSubmitting ? null : _goToPreviousStep,
                child: AppText.labelMedium('Back'),
              ),
            ),
          if (_currentStep > 0) AppSpacing.horizontalSpacing(SpacingSize.md),
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: AppButton.primary(
              onPressed: _isSubmitting ? null : _goToNextStep,
              loading: _isSubmitting,
              child: AppText.labelMedium(
                _currentStep == VerificationStep.steps.length - 1 ? 'Submit' : 'Next',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
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

  void _uploadDocumentToFirebase(String documentType, String filePath) {
    final authState = context.read<AuthBloc>().state;
    if (authState is DataState<AuthData> && authState.data?.user != null) {
      final userId = authState.data!.user!.uid;
      context.read<KycBloc>().add(KycDocumentUploadRequested(
        userId: userId,
        documentType: documentType,
        filePath: filePath,
      ));
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
    final authBloc = context.read<AuthBloc>();
    final currentState = authBloc.state;
    
    Map<String, dynamic> additionalData = {};
    if (currentState is DataState<AuthData> && currentState.data?.user != null) {
      additionalData = Map.from(currentState.data!.user!.additionalData);
    }
    
    authBloc.add(AuthUserProfileUpdateRequested(
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
    ));
  }

  DateTime _parseDateOfBirth() {
    try {
      // Parse date from DD/MM/YYYY format
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
      final authState = context.read<AuthBloc>().state;

      if (authState is DataState<AuthData> && authState.data?.user != null) {
        final user = authState.data!.user!;

        // Submit KYC to Firebase through KycBloc
        context.read<KycBloc>().add(KycFinalSubmitRequested(
          userId: user.uid,
          fullName: '${_firstNameController.text} ${_lastNameController.text}',
          dateOfBirth: _parseDateOfBirth(),
          phoneNumber: _phoneController.text,
          email: user.email,
          address: _addressController.text,
          city: _cityController.text,
          country: 'Nigeria', // Default to Nigeria, can be made dynamic later
          postalCode: _postalCodeController.text,
          governmentIdNumber: _ninController.text.isNotEmpty ? _ninController.text : _bvnController.text,
          idType: _ninController.text.isNotEmpty ? 'NIN' : 'BVN',
          governmentIdUrl: _uploadedDocumentUrls['government_id'],
          selfieWithIdUrl: _uploadedDocumentUrls['selfie_with_id'],
          proofOfAddressUrl: _uploadedDocumentUrls['proof_of_address'],
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('Verification submission failed: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 64, color: AppColors.success),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.titleMedium('Verification Submitted!', textAlign: TextAlign.center),
              AppSpacing.verticalSpacing(SpacingSize.xs),
              AppText.bodyMedium(VerificationConstants.successMessage, textAlign: TextAlign.center),
            ],
          ),
          actions: [
            AppButton.primary(
              onPressed: () {
                Navigator.of(context).pop();
                sl<NavigationService>().goBack();
              },
              child: AppText.labelMedium('Continue', color: Colors.white),
            ),
          ],
        );
      },
    );
  }
}
