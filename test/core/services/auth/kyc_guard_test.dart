import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:parcel_am/core/services/auth/kyc_guard.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_data.dart';
import 'package:parcel_am/features/travellink/domain/entities/user_entity.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/routes/routes.dart';

void main() {
  group('KycStatus', () {
    test('fromString returns correct status', () {
      expect(KycStatus.fromString('verified'), KycStatus.verified);
      expect(KycStatus.fromString('pending'), KycStatus.pending);
      expect(KycStatus.fromString('rejected'), KycStatus.rejected);
      expect(KycStatus.fromString('not_started'), KycStatus.notStarted);
      expect(KycStatus.fromString('notstarted'), KycStatus.notStarted);
      expect(KycStatus.fromString('unknown'), KycStatus.unknown);
      expect(KycStatus.fromString('invalid'), KycStatus.unknown);
    });

    test('fromString is case insensitive', () {
      expect(KycStatus.fromString('VERIFIED'), KycStatus.verified);
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
