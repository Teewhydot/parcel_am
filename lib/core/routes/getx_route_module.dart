import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:get/get.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/core/widgets/navigation_shell.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/dashboard_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/login_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/onboarding_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/payment_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/request_details_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/tracking_screen.dart';
import 'package:parcel_am/features/kyc/presentation/screens/verification_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/browse_requests_screen.dart';
import 'package:parcel_am/features/kyc/presentation/screens/kyc_blocked_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/wallet_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/withdrawal_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/withdrawal_status_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/bank_account_list_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/add_bank_account_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/create_parcel_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/profile_edit_screen.dart';
import 'package:parcel_am/features/chat/presentation/screens/chats_list_screen.dart';
import 'package:parcel_am/features/chat/presentation/screens/chat_screen.dart';
import 'package:parcel_am/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/settings_screen.dart';
import 'package:parcel_am/features/payments/presentation/screens/wallet_funding_payment_screen.dart';
import 'package:parcel_am/features/payments/presentation/screens/wallet_funding_success_screen.dart';
import 'package:parcel_am/injection_container.dart';

import '../../features/parcel_am_core/data/datasources/bank_account_remote_data_source.dart';
import '../../features/parcel_am_core/data/datasources/withdrawal_remote_data_source.dart';
import '../../features/parcel_am_core/data/repositories/bank_account_repository_impl.dart';
import '../../features/parcel_am_core/data/repositories/withdrawal_repository_impl.dart';
import '../../features/parcel_am_core/presentation/bloc/bank_account/bank_account_bloc.dart';
import '../../features/parcel_am_core/presentation/bloc/withdrawal/withdrawal_bloc.dart';
import '../../features/parcel_am_core/presentation/screens/splash_screen.dart';
import '../services/auth/auth_guard.dart';
import '../services/connectivity_service.dart';

class GetXRouteModule {
  static const Transition _transition = Transition.rightToLeft;
  static const Duration _transitionDuration = Duration(milliseconds: 300);
  static final List<GetPage> routes = [
    GetPage(
      name: Routes.initial,
      page: () => const SplashScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.dashboard,
      page: () => const DashboardScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: false,
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    // Main navigation shell with floating bottom nav bar
    AuthGuard.createProtectedRoute(
      name: Routes.home,
      page: () {
        // Get initial tab index from route arguments
        final initialIndex = Get.arguments as int? ?? 0;
        return NavigationShell(initialIndex: initialIndex);
      },
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: false,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.payment,
      page: () => const PaymentScreen(),
      requireKyc: true,
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.requestDetails,
      page: () {
        // Support both direct String argument and Map with parcelId
        final arguments = Get.arguments;
        String requestId = "";

        if (arguments is String) {
          requestId = arguments;
        } else if (arguments is Map<String, dynamic>) {
          requestId = arguments['parcelId'] as String? ?? "";
        }

        return RequestDetailsScreen(requestId: requestId);
      },
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.tracking,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        final packageId = args['packageId'] as String? ?? "";
        return TrackingScreen(packageId: packageId);
      },
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.verification,
      page: () => const VerificationScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.browseRequests,
      page: () => const BrowseRequestsScreen(),
      requireKyc: true,
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    GetPage(
      name: Routes.kycBlocked,
      page: () => const KycBlockedScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.walletFundingPayment,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        final authorizationUrl = args['authorizationUrl'] as String? ?? '';
        final reference = args['reference'] as String? ?? '';
        final transactionId = args['transactionId'] as String? ?? '';
        final userId = args['userId'] as String? ?? '';
        final amount = args['amount'] as double? ?? 0.0;
        return WalletFundingPaymentScreen(
          authorizationUrl: authorizationUrl,
          reference: reference,
          transactionId: transactionId,
          userId: userId,
          amount: amount,
        );
      },
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.walletFundingSuccess,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        final transactionId = args['transactionId'] as String? ?? '';
        final reference = args['reference'] as String? ?? '';
        final amount = args['amount'] as double? ?? 0.0;
        final userId = args['userId'] as String? ?? '';
        return WalletFundingSuccessScreen(
          transactionId: transactionId,
          reference: reference,
          amount: amount,
          userId: userId,
        );
      },
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.withdrawal,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        final userId = args['userId'] as String? ?? '';
        final availableBalance = args['availableBalance'] as double? ?? 0.0;

        // Create data sources
        final bankAccountDataSource = BankAccountRemoteDataSourceImpl(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
          connectivityService: sl<ConnectivityService>(),
        );
        final withdrawalDataSource = WithdrawalRemoteDataSourceImpl(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
          connectivityService: sl<ConnectivityService>(),
        );

        // Create repositories
        final bankAccountRepository = BankAccountRepositoryImpl(
          remoteDataSource: bankAccountDataSource,
        );
        final withdrawalRepository = WithdrawalRepositoryImpl(
          remoteDataSource: withdrawalDataSource,
        );

        return MultiBlocProvider(
          providers: [
            BlocProvider<BankAccountBloc>(
              create: (_) => BankAccountBloc(repository: bankAccountRepository),
            ),
            BlocProvider<WithdrawalBloc>(
              create: (_) => WithdrawalBloc(repository: withdrawalRepository),
            ),
          ],
          child: WithdrawalScreen(
            userId: userId,
            availableBalance: availableBalance,
          ),
        );
      },
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.withdrawalStatus,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        final withdrawalId = args['withdrawalId'] as String? ?? '';
        return WithdrawalStatusScreen(withdrawalId: withdrawalId);
      },
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.addBankAccount,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        final userId = args['userId'] as String? ?? '';

        // Create data source and repository for bank accounts
        final bankAccountDataSource = BankAccountRemoteDataSourceImpl(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
          connectivityService: sl<ConnectivityService>(),
        );
        final bankAccountRepository = BankAccountRepositoryImpl(
          remoteDataSource: bankAccountDataSource,
        );

        return BlocProvider<BankAccountBloc>(
          create: (_) => BankAccountBloc(repository: bankAccountRepository),
          child: AddBankAccountScreen(userId: userId),
        );
      },
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.bankAccounts,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        final userId = args['userId'] as String? ?? '';

        // Create data source and repository for bank accounts
        final bankAccountDataSource = BankAccountRemoteDataSourceImpl(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
          connectivityService: sl<ConnectivityService>(),
        );
        final bankAccountRepository = BankAccountRepositoryImpl(
          remoteDataSource: bankAccountDataSource,
        );

        return BlocProvider<BankAccountBloc>(
          create: (_) => BankAccountBloc(repository: bankAccountRepository),
          child: BankAccountListScreen(userId: userId),
        );
      },
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    // Wallet route comes AFTER wallet sub-routes for proper GetX matching
    AuthGuard.createProtectedRoute(
      name: Routes.wallet,
      page: () {
        // Get current user ID from auth service or pass via route arguments
        final userId = Get.arguments as String? ?? '';
        return WalletScreen(userId: userId);
      },
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.createParcel,
      page: () => const CreateParcelScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: true,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.profile,
      page: () => const ProfileEditScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: false,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.chatsList,
      page: () {
        // Get userId from route arguments (should be passed by navigation)
        final userId = Get.arguments as String? ?? '';
        return ChatsListScreen(currentUserId: userId);
      },
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: false,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.chat,
      page: () {
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        final chatId = args['chatId'] as String? ?? '';
        final otherUserId = args['otherUserId'] as String? ?? '';
        final otherUserName = args['otherUserName'] as String? ?? 'User';
        final otherUserAvatar = args['otherUserAvatar'] as String?;
        return ChatScreen(
          chatId: chatId,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserAvatar: otherUserAvatar,
        );
      },
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: false,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.notifications,
      page: () {
        // Get current user ID from Firebase Auth
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return NotificationsScreen(userId: userId);
      },
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: false,
    ),
    AuthGuard.createProtectedRoute(
      name: Routes.settings,
      page: () => const SettingsScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
      requiresKyc: false,
    ),
  ];
}
