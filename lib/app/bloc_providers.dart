import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/kyc/kyc_bloc.dart';

import '../features/notifications/presentation/bloc/notification_bloc.dart';
import '../features/travellink/presentation/bloc/auth/auth_bloc.dart';
import '../features/travellink/presentation/bloc/dashboard/dashboard_bloc.dart';
import '../features/travellink/presentation/bloc/parcel/parcel_bloc.dart';
import '../features/travellink/presentation/bloc/wallet/wallet_bloc.dart';
import '../features/travellink/presentation/bloc/wallet/wallet_event.dart';

final List<BlocProvider> blocs = [
  BlocProvider<AuthBloc>(
    create: (_) => AuthBloc(),
  ),
  BlocProvider<DashboardBloc>(
    create: (context) => DashboardBloc(),
  ),
  BlocProvider<WalletBloc>(
    create: (_) => WalletBloc()..add(const WalletLoadRequested()),
  ),
  BlocProvider<NotificationBloc>(
    create: (_) => NotificationBloc(),
  ),
  BlocProvider<ParcelBloc>(
    create: (_) => ParcelBloc(),
  ),
  BlocProvider<KycBloc>(
    create: (_) => KycBloc(),
  ),
  // BlocProvider<LoginBloc>(create: (context) => LoginBloc()),
  // BlocProvider<ForgotPasswordBloc>(create: (context) => ForgotPasswordBloc()),
  // BlocProvider<RegisterBloc>(create: (context) => RegisterBloc()),
  // BlocProvider<VerificationBloc>(create: (context) => VerificationBloc()),
  // BlocProvider<LocationBloc>(create: (context) => LocationBloc()),
  // BlocProvider<RecentKeywordsCubit>(create: (context) => RecentKeywordsCubit()),
  // BlocProvider<CartCubit>(create: (context) => CartCubit()),
  // BlocProvider<UserProfileCubit>(
  //   create: (context) => UserProfileCubit()..loadUserProfile(),
  // ),
  // BlocProvider<AddressCubit>(
  //   create: (context) => AddressCubit()..loadAddresses(),
  // ),
  // BlocProvider<NotificationCubit>(
  //   create: (context) => NotificationCubit()..loadNotifications(),
  // ),
  // BlocProvider<ChatsCubit>(
  //   create: (context) =>
  //       ChatsCubit(chatUseCase: GetIt.instance<ChatUseCase>())..loadChats(),
  // ),
  // BlocProvider<MessagingBloc>(
  //   create: (context) =>
  //       MessagingBloc(chatUseCase: GetIt.instance<ChatUseCase>()),
  // ),
  // BlocProvider<VerifyEmailBloc>(create: (context) => VerifyEmailBloc()),
  // BlocProvider<DeleteAccountBloc>(create: (context) => DeleteAccountBloc()),
  // BlocProvider<EmailVerificationBloc>(
  //   create: (context) => EmailVerificationBloc(),
  // ),
  // BlocProvider<ForgotPasswordBloc>(create: (context) => ForgotPasswordBloc()),
  // BlocProvider<SignOutBloc>(create: (context) => SignOutBloc()),
  //
  // // Home feature Cubits (migrated from BLoCs)
  // BlocProvider<RestaurantCubit>(
  //   create: (context) =>
  //       RestaurantCubit(restaurantUseCase: GetIt.instance<RestaurantUseCase>()),
  // ),
  // BlocProvider<FoodCubit>(
  //   create: (context) => FoodCubit(foodUseCase: GetIt.instance<FoodUseCase>()),
  // ),
  // BlocProvider<SearchBloc>(
  //   create: (context) => SearchBloc(
  //     foodUseCase: GetIt.instance<FoodUseCase>(),
  //     restaurantUseCase: GetIt.instance<RestaurantUseCase>(),
  //   ),
  // ),
  //
  // // Payment feature BLoCs
  // BlocProvider<PaymentBloc>(
  //   create: (context) =>
  //       PaymentBloc(paymentUseCase: GetIt.instance<PaymentUseCase>()),
  // ),
  // BlocProvider<OrderBloc>(
  //   create: (context) =>
  //       OrderBloc(orderUseCase: GetIt.instance<OrderUseCase>()),
  // ),
];
