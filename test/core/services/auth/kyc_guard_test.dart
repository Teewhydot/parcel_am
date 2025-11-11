import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_am/core/services/auth/kyc_guard.dart';
import 'package:parcel_am/features/travellink/domain/entities/user_entity.dart';
import 'package:parcel_am/core/routes/routes.dart';

void main() {
  group('KycStatus', () {
    test('fromString returns correct status', () {
      expect(KycStatus.fromString('approved'), KycStatus.approved);
      expect(KycStatus.fromString('pending'), KycStatus.pending);
      expect(KycStatus.fromString('rejected'), KycStatus.rejected);
      expect(KycStatus.fromString('not_started'), KycStatus.notStarted);
      expect(KycStatus.fromString('notstarted'), KycStatus.notStarted);
      expect(KycStatus.fromString('incomplete'), KycStatus.incomplete);
      expect(KycStatus.fromString('under_review'), KycStatus.underReview);
      expect(KycStatus.fromString('invalid'), KycStatus.notStarted);
    });

    test('fromString is case insensitive', () {
      expect(KycStatus.fromString('APPROVED'), KycStatus.approved);
      expect(KycStatus.fromString('Pending'), KycStatus.pending);
      expect(KycStatus.fromString('REJECTED'), KycStatus.rejected);
    });
  });

  group('KycGuard', () {
    test('instance returns singleton', () {
      final instance1 = KycGuard.instance;
      final instance2 = KycGuard.instance;
      expect(instance1, same(instance2));
    });

    test('requiresKyc identifies KYC-protected routes', () {
      final guard = KycGuard.instance;
      
      expect(guard.requiresKyc(Routes.payment), true);
      expect(guard.requiresKyc(Routes.browseRequests), true);
      expect(guard.requiresKyc(Routes.dashboard), false);
      expect(guard.requiresKyc(Routes.login), false);
    });
  });
}
