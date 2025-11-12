import 'dart:io';

void main() {
  
  final checks = <String, bool>{};
  
  // Check 1: UserEntity has kycStatus field
  checks['UserEntity has kycStatus field'] = _checkFileContains(
    'lib/features/travellink/domain/entities/user_entity.dart',
    ['final String kycStatus', 'kycStatus = \'not_submitted\'']
  );
  
  // Check 2: UserModel handles kycStatus
  checks['UserModel handles kycStatus'] = _checkFileContains(
    'lib/features/travellink/data/models/user_model.dart',
    ['kycStatus', 'super.kycStatus']
  );
  
  // Check 3: AuthBloc has KYC integration
  checks['AuthBloc has KYC integration'] = _checkFileContains(
    'lib/features/travellink/presentation/bloc/auth/auth_bloc.dart',
    ['WatchKycStatusUseCase', '_kycStatusSubscription', 'AuthKycStatusUpdated', '_subscribeToKycStatus']
  );
  
  // Check 4: AuthRemoteDataSource syncs KYC status
  checks['AuthRemoteDataSource syncs KYC'] = _checkFileContains(
    'lib/features/travellink/data/datasources/auth_remote_data_source.dart',
    ['syncKycStatus', '_mapFirebaseUserToModelWithKyc']
  );
  
  // Check 5: KycBloc exists
  checks['KycBloc exists'] = File('lib/features/travellink/presentation/bloc/kyc/kyc_bloc.dart').existsSync();
  
  // Check 6: KycBloc has all states
  checks['KycBloc has all states'] = _checkFileContains(
    'lib/features/travellink/presentation/bloc/kyc/kyc_state.dart',
    ['KycInitial', 'KycLoading', 'KycSubmitted', 'KycApproved', 'KycRejected', 'KycError']
  );
  
  // Check 7: KycBloc has all events
  checks['KycBloc has all events'] = _checkFileContains(
    'lib/features/travellink/presentation/bloc/kyc/kyc_event.dart',
    ['KycSubmitRequested', 'KycStatusRequested', 'KycStatusUpdated', 'KycResubmitRequested']
  );
  
  // Check 8: Dependency injection configured
  checks['DI configured'] = _checkFileContains(
    'lib/injection_container.dart',
    ['KycBloc', 'WatchKycStatusUseCase', 'KycRemoteDataSource', 'FirebaseStorage']
  );
  
  // Check 9: Tests exist
  checks['Tests exist'] = File('test/features/travellink/presentation/bloc/kyc_bloc_test.dart').existsSync() &&
                          File('test/features/travellink/presentation/bloc/auth_bloc_kyc_test.dart').existsSync();
  
  // Print results
  
  int passed = 0;
  int total = checks.length;
  
  checks.forEach((check, result) {
    final icon = result ? '✅' : '❌';
    if (result) passed++;
  });
  
  
  if (passed == total) {
    exit(0);
  } else {
    exit(1);
  }
}

bool _checkFileContains(String filePath, List<String> patterns) {
  try {
    final file = File(filePath);
    if (!file.existsSync()) return false;
    
    final content = file.readAsStringSync();
    return patterns.every((pattern) => content.contains(pattern));
  } catch (e) {
    return false;
  }
}
