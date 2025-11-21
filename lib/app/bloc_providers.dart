import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/features/kyc/presentation/bloc/kyc_bloc.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';
import '../features/parcel_am_core/presentation/bloc/auth/auth_bloc.dart';
import '../features/parcel_am_core/presentation/bloc/dashboard/dashboard_bloc.dart';
import '../features/parcel_am_core/presentation/bloc/parcel/parcel_bloc.dart';
import '../features/parcel_am_core/presentation/bloc/wallet/wallet_bloc.dart';
import '../features/parcel_am_core/presentation/bloc/wallet/wallet_event.dart';



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
];
