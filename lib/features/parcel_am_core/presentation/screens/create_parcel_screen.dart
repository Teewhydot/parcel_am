import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/wallet/wallet_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import '../../../../core/domain/entities/kyc_status.dart';
import '../../../../core/helpers/user_extensions.dart';
import '../../../escrow/domain/entities/escrow_status.dart';
import '../bloc/parcel/parcel_bloc.dart';
import '../bloc/parcel/parcel_event.dart';
import '../bloc/parcel/parcel_state.dart';
import '../bloc/escrow/escrow_bloc.dart';
import '../bloc/escrow/escrow_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_data.dart';
import '../../domain/entities/parcel_entity.dart' hide RouteInformation;
import '../../domain/entities/parcel_entity.dart' as parcel_entity;

class CreateParcelScreen extends StatefulWidget {
  const CreateParcelScreen({super.key});

  @override
  State<CreateParcelScreen> createState() => _CreateParcelScreenState();
}

class _CreateParcelScreenState extends State<CreateParcelScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  late ParcelBloc _parcelBloc;
  late EscrowBloc _escrowBloc;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _originNameController = TextEditingController();
  final _originAddressController = TextEditingController();
  final _destNameController = TextEditingController();
  final _destPhoneController = TextEditingController();
  final _destAddressController = TextEditingController();

  String _packageType = 'Documents';
  String _urgency = 'Standard';
  ParcelEntity? _createdParcel;

  final List<String> _packageTypes = [
    'Documents',
    'Electronics',
    'Clothing',
    'Food',
    'Fragile',
    'Other',
  ];

  final List<String> _urgencyLevels = [
    'Standard',
    'Express',
    'Urgent',
  ];

  @override
  void initState() {
    super.initState();
    _parcelBloc = ParcelBloc();
    _escrowBloc = EscrowBloc();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _originNameController.dispose();
    _originAddressController.dispose();
    _destNameController.dispose();
    _destPhoneController.dispose();
    _destAddressController.dispose();
    _parcelBloc.close();
    _escrowBloc.close();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateParcelCreation() {
    // Get user from AuthBloc
    final walletState= context.read<WalletBloc>().state;
    final authState = context.read<AuthBloc>().state;
    if (authState is! DataState<AuthData> || authState.data?.user == null) {
      context.showSnackbar(
        message: 'User not authenticated',
        color: AppColors.error,
      );
      return false;
    }

    final currentUser = authState.data!.user!;
    final userBalance = walletState.data?.availableBalance;


    // Check KYC status
    if (currentUser.kycStatus != KycStatus.approved) {
      context.showSnackbar(
        message: 'Please complete KYC verification before creating a parcel',
        color: AppColors.error,
        duration: 4,
      );
      // Navigate to KYC screen
      sl<NavigationService>().navigateTo(Routes.verification);
      return false;
    }

    // Calculate total amount (parcel price + service fee)
    final parcelPrice = double.tryParse(_priceController.text) ?? 0.0;
    const serviceFee = 150.0;
    final totalAmount = parcelPrice + serviceFee;

    // Check balance
    if (userBalance == null || userBalance < totalAmount) {
      // Show snackbar with manual SnackBar to include action button
      context.showErrorMessage('Insufficient balance');
      return false;
    }

    return true;
  }

  void _createParcel() {
    // Get user from AuthBloc instead of Firebase directly
    final authState = context.read<AuthBloc>().state;
    if (authState is! DataState<AuthData> || authState.data?.user == null) return;

    final currentUser = authState.data!.user!;

    final sender = SenderDetails(
      userId: currentUser.uid,
      name: currentUser.displayName,
      phoneNumber: currentUser.additionalData['phoneNumber'] as String? ?? '',
      address: _originAddressController.text,
      email: currentUser.email,
    );

    final receiver = ReceiverDetails(
      name: _destNameController.text,
      phoneNumber: _destPhoneController.text,
      address: _destAddressController.text,
    );

    final route = parcel_entity.RouteInformation(
      origin: _originAddressController.text,
      destination: _destAddressController.text,
      originLat: 9.0820,
      originLng: 8.6753,
      destinationLat: 6.5244,
      destinationLng: 3.3792,
    );

    final parcel = ParcelEntity(
      id: '', // Will be generated by backend
      sender: sender,
      receiver: receiver,
      route: route,
      status: ParcelStatus.created,
      weight: double.tryParse(_weightController.text),
      category: _packageType,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text),
      currency: 'NGN',
      createdAt: DateTime.now(),
    );

    _parcelBloc.add(ParcelCreateRequested(parcel));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge('Create Parcel'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocManager<ParcelBloc,BaseState<ParcelData>>(
        bloc: _parcelBloc,
        onSuccess: (context, state){
          context.showSnackbar(message: 'Parcel created successfully', color: AppColors.success);
          sl<NavigationService>().goBack();
        },
        onError: (context, state){
          context.showSnackbar(message: "Error creating parcel", color: AppColors.error);
        },
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildParcelDetailsStep(),
                  _buildLocationStep(),
                  _buildReviewStep(),
                  _buildPaymentStep(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Details', 'Location', 'Review', 'Payment'];
    return Container(
      padding: AppSpacing.paddingLG,
      color: AppColors.surface,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? AppColors.primary
                              : AppColors.outline,
                        ),
                      ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isActive
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : AppText(
                                '${index + 1}',
                                color: isActive
                                    ? Colors.white
                                    : AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                      ),
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? AppColors.primary
                              : AppColors.outline,
                        ),
                      ),
                  ],
                ),
                AppSpacing.verticalSpacing(SpacingSize.xs),
                AppText.bodySmall(
                  steps[index],
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildParcelDetailsStep() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.headlineSmall(
            'Parcel Details',
            fontWeight: FontWeight.bold,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          AppInput(
            controller: _titleController,
            label: 'Parcel Title',
            hintText: 'e.g., Business Documents',
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput.multiline(
            controller: _descriptionController,
            label: 'Description',
            hintText: 'Provide details about your parcel',
            maxLines: 3,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          DropdownButtonFormField<String>(
            value: _packageType,
            decoration: const InputDecoration(
              labelText: 'Package Type',
              border: OutlineInputBorder(),
            ),
            items: _packageTypes
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: AppText.bodyMedium(type),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _packageType = value!),
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: _weightController,
            label: 'Weight (kg)',
            hintText: 'Enter weight',
            keyboardType: TextInputType.number,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: _priceController,
            label: 'Offered Price (₦)',
            hintText: 'Enter price',
            keyboardType: TextInputType.number,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          DropdownButtonFormField<String>(
            value: _urgency,
            decoration: const InputDecoration(
              labelText: 'Urgency',
              border: OutlineInputBorder(),
            ),
            items: _urgencyLevels
                .map((level) => DropdownMenuItem(
                      value: level,
                      child: AppText.bodyMedium(level),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _urgency = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.headlineSmall(
            'Pickup & Delivery',
            fontWeight: FontWeight.bold,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          const AppText(
            'Pickup Location',
            variant: TextVariant.titleMedium,
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w600,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: _originNameController,
            label: 'Location Name',
            hintText: 'e.g., My Office',
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput.multiline(
            controller: _originAddressController,
            label: 'Address',
            hintText: 'Enter full address',
            maxLines: 2,
          ),
          AppSpacing.verticalSpacing(SpacingSize.lg),
          const AppText(
            'Delivery Location',
            variant: TextVariant.titleMedium,
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w600,
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput(
            controller: _destNameController,
            label: 'Location Name',
            hintText: 'e.g., Client Office',
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput.phone(
            controller: _destPhoneController,
            label: 'Receiver Phone',
            hintText: 'e.g., +234...',
          ),
          AppSpacing.verticalSpacing(SpacingSize.md),
          AppInput.multiline(
            controller: _destAddressController,
            label: 'Address',
            hintText: 'Enter full address',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
          padding: AppSpacing.paddingLG,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.headlineSmall(
                'Review Parcel',
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              AppCard.elevated(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReviewItem('Title', _titleController.text),
                    _buildReviewItem(
                        'Description', _descriptionController.text),
                    _buildReviewItem('Type', _packageType),
                    _buildReviewItem('Weight', '${_weightController.text} kg'),
                    _buildReviewItem('Price', '₦${_priceController.text}'),
                    _buildReviewItem('Urgency', _urgency),
                  ],
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppCard.elevated(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyLarge(
                      'Locations',
                      fontWeight: FontWeight.w600,
                    ),
                    AppSpacing.verticalSpacing(SpacingSize.md),
                    _buildReviewItem(
                        'Pickup', _originNameController.text),
                    _buildReviewItem(
                        'Delivery', _destNameController.text),
                    _buildReviewItem(
                        'Receiver Phone', _destPhoneController.text),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: AppText.bodyMedium(
              label,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: AppText.bodyMedium(
              value,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    return BlocBuilder<EscrowBloc, BaseState<EscrowData>>(
      builder: (context, escrowState) {
        return SingleChildScrollView(
          padding: AppSpacing.paddingLG,
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 80,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              AppText.headlineSmall(
                'Parcel Created!',
                fontWeight: FontWeight.bold,
              ),
              AppSpacing.verticalSpacing(SpacingSize.md),
              AppText.bodyMedium(
                'Your parcel has been created successfully. Complete payment to proceed.',
                textAlign: TextAlign.center,
                color: AppColors.onSurfaceVariant,
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              if (_createdParcel != null)
                AppCard.elevated(
                  child: Column(
                    children: [
                      _buildPaymentRow(
                          'Delivery Fee', '₦${_createdParcel!.price}'),
                      _buildPaymentRow('Service Fee', '₦150'),
                      const Divider(),
                      _buildPaymentRow(
                        'Total',
                        '₦${(_createdParcel!.price ?? 0) + 150}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
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
                  children: [
                    Icon(
                      _getEscrowIcon(escrowState.data?.currentEscrow?.status),
                      color: AppColors.primary,
                    ),
                    AppSpacing.horizontalSpacing(SpacingSize.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyMedium(
                            _getEscrowStatusText(escrowState.data?.currentEscrow?.status),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          AppText.bodySmall(
                            _getEscrowDescriptionText(escrowState.data?.currentEscrow?.status),
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    if (escrowState.data?.currentEscrow?.status == EscrowStatus.holding)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              AppSpacing.verticalSpacing(SpacingSize.lg),
              AppButton.primary(
                onPressed: escrowState.data?.currentEscrow?.status == EscrowStatus.pending ||
                        escrowState.data?.currentEscrow?.status == EscrowStatus.error
                    ? () {
                        if (_createdParcel != null) {
                          // Navigate to existing payment screen
                          sl<NavigationService>().navigateTo(Routes.payment);
                        }
                      }
                    : null,
                fullWidth: true,
                child: AppText.bodyMedium('Proceed to Payment', color: Colors.white),
              ),
              if (escrowState.data?.currentEscrow?.status == EscrowStatus.held) ...[
                AppSpacing.verticalSpacing(SpacingSize.md),
                AppButton.outline(
                  onPressed: () => Navigator.of(context).pop(),
                  fullWidth: true,
                  child: AppText.bodyMedium('Done', color: AppColors.primary),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentRow(String label, String amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            label,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? AppFontSize.xl : null,
          ),
          AppText(
            amount,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? AppFontSize.xl : null,
            color: isBold ? AppColors.primary : null,
          ),
        ],
      ),
    );
  }

  IconData _getEscrowIcon(EscrowStatus? status) {
    if (status == null) return Icons.shield;
    switch (status) {
      case EscrowStatus.holding:
        return Icons.hourglass_bottom;
      case EscrowStatus.held:
        return Icons.lock;
      case EscrowStatus.releasing:
        return Icons.hourglass_bottom;
      case EscrowStatus.released:
        return Icons.check_circle;
      case EscrowStatus.error:
        return Icons.error;
      default:
        return Icons.shield;
    }
  }

  String _getEscrowStatusText(EscrowStatus? status) {
    if (status == null) return 'Escrow Protection';
    switch (status) {
      case EscrowStatus.holding:
        return 'Securing Payment...';
      case EscrowStatus.held:
        return 'Payment Secured';
      case EscrowStatus.releasing:
        return 'Releasing Payment...';
      case EscrowStatus.released:
        return 'Payment Released';
      case EscrowStatus.error:
        return 'Payment Error';
      default:
        return 'Escrow Protection';
    }
  }

  String _getEscrowDescriptionText(EscrowStatus? status) {
    if (status == null) return 'Your payment will be securely held until delivery';
    switch (status) {
      case EscrowStatus.holding:
        return 'Please wait while we secure your payment';
      case EscrowStatus.held:
        return 'Your payment is safely held in escrow';
      case EscrowStatus.releasing:
        return 'Releasing payment to carrier';
      case EscrowStatus.released:
        return 'Payment has been released successfully';
      case EscrowStatus.error:
        return 'An error occurred. Please try again';
      default:
        return 'Your payment will be securely held until delivery';
    }
  }

  Widget _buildNavigationButtons() {
    return BlocBuilder<ParcelBloc, BaseState<ParcelData>>(
      bloc: _parcelBloc,
      builder: (context, state) {
        final isCreating = state is LoadingState<ParcelData> ||
            state is AsyncLoadingState<ParcelData>;
        final isLastStep = _currentStep == 3;

        if (isLastStep) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: AppSpacing.paddingLG,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.outline)),
          ),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: AppButton.outline(
                    onPressed: isCreating ? null : _previousStep,
                    child: AppText.bodyMedium('Back', color: AppColors.primary),
                  ),
                ),
              if (_currentStep > 0) AppSpacing.horizontalSpacing(SpacingSize.md),
              Expanded(
                child: AppButton.primary(
                  onPressed: isCreating
                      ? null
                      : () {
                          if (_currentStep == 2) {
                            // Validate before creating parcel
                            if (_validateParcelCreation()) {
                              _createParcel();
                            }
                          } else {
                            _nextStep();
                          }
                        },
                  loading: isCreating && _currentStep == 2,
                  child: AppText.bodyMedium(_currentStep == 2 ? 'Create Parcel' : 'Next', color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
