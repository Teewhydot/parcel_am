import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parcel_am/features/file_upload/domain/use_cases/file_upload_usecase.dart';
import 'package:parcel_am/features/kyc/domain/usecases/kyc_usecase.dart';
import 'package:parcel_am/features/kyc/presentation/bloc/kyc_bloc.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/escrow/escrow_cubit.dart';
import 'package:parcel_am/features/passkey/presentation/bloc/passkey_bloc.dart';
import '../features/chat/presentation/bloc/chat_cubit.dart';
import '../features/notifications/domain/repositories/notification_settings_repository.dart';
import '../features/notifications/presentation/bloc/notification_cubit.dart';
import '../features/notifications/presentation/bloc/notification_settings_bloc.dart';
import '../features/parcel_am_core/presentation/bloc/auth/auth_cubit.dart';
import '../features/parcel_am_core/presentation/bloc/dashboard/dashboard_bloc.dart';
import '../features/parcel_am_core/presentation/bloc/parcel/parcel_cubit.dart';
import '../features/parcel_am_core/presentation/bloc/wallet/wallet_cubit.dart';
import '../features/totp_2fa/domain/usecases/totp_usecase.dart';
import '../features/totp_2fa/presentation/bloc/totp_cubit.dart';
import '../injection_container.dart';



final List<BlocProvider> blocs = [
  BlocProvider<AuthCubit>(
    create: (_) => AuthCubit(),
  ),
  BlocProvider<DashboardBloc>(
    create: (context) => DashboardBloc(),
  ),
  BlocProvider<WalletCubit>(
    create: (_) => WalletCubit(),
  ),
  BlocProvider<NotificationCubit>(
    create: (_) => NotificationCubit(),
  ),
  BlocProvider<ParcelCubit>(
    create: (_) => ParcelCubit(),
  ),
  BlocProvider<KycBloc>(
    create: (_) => KycBloc(
      kycUseCase: KycUseCase(),
      fileUploadUseCase: FileUploadUseCase(),
    ),
  ),
  BlocProvider<EscrowCubit>(create:(_)=> EscrowCubit()),
  BlocProvider<PasskeyBloc>(create: (_) => PasskeyBloc()),
  BlocProvider<ChatCubit>(create: (_) => ChatCubit()),
  BlocProvider<NotificationSettingsBloc>(
    create: (_) => NotificationSettingsBloc(
      repository: sl<NotificationSettingsRepository>(),
    ),
  ),
  BlocProvider<TotpCubit>(
    create: (_) => TotpCubit(totpUseCase: TotpUseCase()),
  ),
];
