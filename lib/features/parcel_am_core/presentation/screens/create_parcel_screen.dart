import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/core/bloc/managers/bloc_manager.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/wallet/wallet_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../../core/bloc/base/base_state.dart';
import '../../../../core/routes/routes.dart';
import '../../../../core/services/navigation_service/nav_config.dart';
import '../../../../injection_container.dart';
import 'package:parcel_am/features/kyc/domain/entities/kyc_status.dart';
import '../../../../core/helpers/user_extensions.dart';
import '../bloc/parcel/parcel_cubit.dart';
import '../bloc/parcel/parcel_state.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/escrow/escrow_cubit.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_data.dart';
import '../../domain/entities/parcel_entity.dart' hide RouteInformation;
import '../../domain/entities/parcel_entity.dart' as parcel_entity;
import '../widgets/create_parcel/step_indicator.dart';
import '../widgets/create_parcel/parcel_details_step.dart';
import '../widgets/create_parcel/location_step.dart';
import '../widgets/create_parcel/review_step.dart';
import '../widgets/create_parcel/payment_step.dart';
import '../widgets/create_parcel/navigation_buttons.dart';

class CreateParcelScreen extends StatefulWidget {
  const CreateParcelScreen({super.key});

  @override
  State<CreateParcelScreen> createState() => _CreateParcelScreenState();
}

class _CreateParcelScreenState extends State<CreateParcelScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  late ParcelCubit _parcelBloc;
  late EscrowCubit _escrowBloc;

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
    _parcelBloc = ParcelCubit();
    _escrowBloc = EscrowCubit();
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
    final walletState = context.read<WalletCubit>().state;
    final authState = context.read<AuthCubit>().state;
    if (authState is! DataState<AuthData> || authState.data?.user == null) {
      context.showSnackbar(
        message: 'User not authenticated',
        color: AppColors.error,
      );
      return false;
    }

    final currentUser = authState.data!.user!;
    final userBalance = walletState.data?.availableBalance;

    if (currentUser.kycStatus != KycStatus.approved) {
      context.showSnackbar(
        message: 'Please complete KYC verification before creating a parcel',
        color: AppColors.error,
        duration: 4,
      );
      sl<NavigationService>().navigateTo(Routes.verification);
      return false;
    }

    final parcelPrice = double.tryParse(_priceController.text) ?? 0.0;
    const serviceFee = 150.0;
    final totalAmount = parcelPrice + serviceFee;

    if (userBalance == null || userBalance < totalAmount) {
      context.showErrorMessage('Insufficient balance');
      return false;
    }

    return true;
  }

  void _createParcel() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! DataState<AuthData> || authState.data?.user == null) {
      return;
    }

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
      id: '',
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

    _parcelBloc.createParcel(parcel);
  }

  void _handleCreateParcel() {
    if (_validateParcelCreation()) {
      _createParcel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.titleLarge('Create Parcel'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocManager<ParcelCubit, BaseState<ParcelData>>(
        bloc: _parcelBloc,
        onSuccess: (context, state) {
          context.showSnackbar(
            message: 'Parcel created successfully',
            color: AppColors.success,
          );
          sl<NavigationService>().goBack();
        },
        onError: (context, state) {
          context.showSnackbar(
            message: 'Error creating parcel',
            color: AppColors.error,
          );
        },
        child: Column(
          children: [
            StepIndicator(currentStep: _currentStep),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ParcelDetailsStep(
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    weightController: _weightController,
                    priceController: _priceController,
                    packageType: _packageType,
                    urgency: _urgency,
                    packageTypes: _packageTypes,
                    urgencyLevels: _urgencyLevels,
                    onPackageTypeChanged: (value) =>
                        setState(() => _packageType = value),
                    onUrgencyChanged: (value) =>
                        setState(() => _urgency = value),
                  ),
                  LocationStep(
                    originNameController: _originNameController,
                    originAddressController: _originAddressController,
                    destNameController: _destNameController,
                    destPhoneController: _destPhoneController,
                    destAddressController: _destAddressController,
                  ),
                  ReviewStep(
                    title: _titleController.text,
                    description: _descriptionController.text,
                    packageType: _packageType,
                    weight: _weightController.text,
                    price: _priceController.text,
                    urgency: _urgency,
                    pickupName: _originNameController.text,
                    deliveryName: _destNameController.text,
                    receiverPhone: _destPhoneController.text,
                  ),
                  PaymentStep(createdParcel: _createdParcel),
                ],
              ),
            ),
            NavigationButtons(
              currentStep: _currentStep,
              parcelBloc: _parcelBloc,
              onNext: _nextStep,
              onPrevious: _previousStep,
              onCreateParcel: _handleCreateParcel,
              isCreating: _parcelBloc.state is LoadingState<ParcelData> ||
                  _parcelBloc.state is AsyncLoadingState<ParcelData>,
            ),
          ],
        ),
      ),
    );
  }
}
