import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parcel_am/core/widgets/app_button.dart';
import 'package:parcel_am/core/widgets/kyc_blocked_action.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_bloc.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/auth/auth_data.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/user_entity.dart';
import 'package:parcel_am/core/domain/entities/kyc_status.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';

import 'app_button_kyc_test.mocks.dart';

@GenerateMocks([AuthBloc])
void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    // Provide dummy states
    provideDummy<BaseState<AuthData>>(
      const InitialState<AuthData>(),
    );
  });

  // Helper function to create a test user with specified KYC status
  UserEntity createTestUser({KycStatus kycStatus = KycStatus.notStarted}) {
    return UserEntity(
      uid: 'test-user-123',
      email: 'test@example.com',
      displayName: 'Test User',
      isVerified: false,
      verificationStatus: 'unverified',
      kycStatus: kycStatus,
      createdAt: DateTime.now(),
      additionalData: {},
    );
  }

  Widget createTestWidget({
    required Widget child,
    required BaseState<AuthData> authState,
  }) {
    when(mockAuthBloc.state).thenReturn(authState);
    when(mockAuthBloc.stream).thenAnswer((_) => Stream.value(authState));

    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: child,
        ),
      ),
    );
  }

  group('AppButton KYC Protection Tests', () {
    testWidgets(
      'should execute onPressed when requiresKyc=false and user is not verified',
      (WidgetTester tester) async {
        // Arrange
        bool callbackExecuted = false;
        final user = createTestUser(kycStatus: KycStatus.notStarted);
        final authState = LoadedState<AuthData>(
          data: AuthData(user: user),
          lastUpdated: DateTime.now(),
        );

        final button = AppButton.primary(
          onPressed: () {
            callbackExecuted = true;
          },
          requiresKyc: false,
          child: const Text('Test Button'),
        );

        // Act
        await tester.pumpWidget(createTestWidget(
          child: button,
          authState: authState,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Test Button'));
        await tester.pumpAndSettle();

        // Assert
        expect(callbackExecuted, true);
      },
    );

    testWidgets(
      'should block onPressed when requiresKyc=true and user is not verified',
      (WidgetTester tester) async {
        // Arrange
        bool callbackExecuted = false;
        final user = createTestUser(kycStatus: KycStatus.notStarted);
        final authState = LoadedState<AuthData>(
          data: AuthData(user: user),
          lastUpdated: DateTime.now(),
        );

        final button = AppButton.primary(
          onPressed: () {
            callbackExecuted = true;
          },
          requiresKyc: true,
          kycBlockedAction: KycBlockedAction.showSnackbar,
          child: const Text('Protected Button'),
        );

        // Act
        await tester.pumpWidget(createTestWidget(
          child: button,
          authState: authState,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Protected Button'));
        await tester.pumpAndSettle();

        // Assert
        expect(callbackExecuted, false);
      },
    );

    testWidgets(
      'should execute onPressed when requiresKyc=true and user is verified',
      (WidgetTester tester) async {
        // Arrange
        bool callbackExecuted = false;
        final user = createTestUser(kycStatus: KycStatus.approved);
        final authState = LoadedState<AuthData>(
          data: AuthData(user: user),
          lastUpdated: DateTime.now(),
        );

        final button = AppButton.primary(
          onPressed: () {
            callbackExecuted = true;
          },
          requiresKyc: true,
          child: const Text('Protected Button'),
        );

        // Act
        await tester.pumpWidget(createTestWidget(
          child: button,
          authState: authState,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Protected Button'));
        await tester.pumpAndSettle();

        // Assert
        expect(callbackExecuted, true);
      },
    );

    testWidgets(
      'should update access in realtime when KYC status changes',
      (WidgetTester tester) async {
        // Arrange
        int callbackExecutionCount = 0;
        final unverifiedUser = createTestUser(kycStatus: KycStatus.notStarted);
        final verifiedUser = createTestUser(kycStatus: KycStatus.approved);

        // Start with unverified state
        final initialState = LoadedState<AuthData>(
          data: AuthData(user: unverifiedUser),
          lastUpdated: DateTime.now(),
        );

        final verifiedState = LoadedState<AuthData>(
          data: AuthData(user: verifiedUser),
          lastUpdated: DateTime.now(),
        );

        when(mockAuthBloc.state).thenReturn(initialState);
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.fromIterable([
            initialState,
            verifiedState,
          ]),
        );

        final button = AppButton.primary(
          onPressed: () {
            callbackExecutionCount++;
          },
          requiresKyc: true,
          child: const Text('Protected Button'),
        );

        // Act - Initial state (unverified)
        await tester.pumpWidget(createTestWidget(
          child: button,
          authState: initialState,
        ));
        await tester.pumpAndSettle();

        // Try to tap while unverified
        await tester.tap(find.text('Protected Button'));
        await tester.pumpAndSettle();
        expect(callbackExecutionCount, 0);

        // Stream emits verified state
        await tester.pumpAndSettle();

        // Try to tap after verification
        await tester.tap(find.text('Protected Button'));
        await tester.pumpAndSettle();

        // Assert - Should execute after KYC approval
        expect(callbackExecutionCount, 1);
      },
    );

    testWidgets(
      'should work with all button variants - primary',
      (WidgetTester tester) async {
        // Arrange
        bool callbackExecuted = false;
        final user = createTestUser(kycStatus: KycStatus.approved);
        final authState = LoadedState<AuthData>(
          data: AuthData(user: user),
          lastUpdated: DateTime.now(),
        );

        final button = AppButton.primary(
          onPressed: () {
            callbackExecuted = true;
          },
          requiresKyc: true,
          child: const Text('Primary'),
        );

        // Act
        await tester.pumpWidget(createTestWidget(
          child: button,
          authState: authState,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Primary'));
        await tester.pumpAndSettle();

        // Assert
        expect(callbackExecuted, true);
      },
    );

    testWidgets(
      'should work with all button variants - secondary',
      (WidgetTester tester) async {
        // Arrange
        bool callbackExecuted = false;
        final user = createTestUser(kycStatus: KycStatus.approved);
        final authState = LoadedState<AuthData>(
          data: AuthData(user: user),
          lastUpdated: DateTime.now(),
        );

        final button = AppButton.secondary(
          onPressed: () {
            callbackExecuted = true;
          },
          requiresKyc: true,
          child: const Text('Secondary'),
        );

        // Act
        await tester.pumpWidget(createTestWidget(
          child: button,
          authState: authState,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Secondary'));
        await tester.pumpAndSettle();

        // Assert
        expect(callbackExecuted, true);
      },
    );

    testWidgets(
      'should work with all button variants - outline',
      (WidgetTester tester) async {
        // Arrange
        bool callbackExecuted = false;
        final user = createTestUser(kycStatus: KycStatus.approved);
        final authState = LoadedState<AuthData>(
          data: AuthData(user: user),
          lastUpdated: DateTime.now(),
        );

        final button = AppButton.outline(
          onPressed: () {
            callbackExecuted = true;
          },
          requiresKyc: true,
          child: const Text('Outline'),
        );

        // Act
        await tester.pumpWidget(createTestWidget(
          child: button,
          authState: authState,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Outline'));
        await tester.pumpAndSettle();

        // Assert
        expect(callbackExecuted, true);
      },
    );

    testWidgets(
      'should work with all button variants - text',
      (WidgetTester tester) async {
        // Arrange
        bool callbackExecuted = false;
        final user = createTestUser(kycStatus: KycStatus.approved);
        final authState = LoadedState<AuthData>(
          data: AuthData(user: user),
          lastUpdated: DateTime.now(),
        );

        final button = AppButton.text(
          onPressed: () {
            callbackExecuted = true;
          },
          requiresKyc: true,
          child: const Text('Text'),
        );

        // Act
        await tester.pumpWidget(createTestWidget(
          child: button,
          authState: authState,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Text'));
        await tester.pumpAndSettle();

        // Assert
        expect(callbackExecuted, true);
      },
    );

    testWidgets(
      'should handle null onPressed gracefully',
      (WidgetTester tester) async {
        // Arrange
        final user = createTestUser(kycStatus: KycStatus.approved);
        final authState = LoadedState<AuthData>(
          data: AuthData(user: user),
          lastUpdated: DateTime.now(),
        );

        final button = AppButton.primary(
          onPressed: null,
          requiresKyc: true,
          child: const Text('Disabled Button'),
        );

        // Act
        await tester.pumpWidget(createTestWidget(
          child: button,
          authState: authState,
        ));
        await tester.pumpAndSettle();

        // Assert - Button should be disabled
        final elevatedButton =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(elevatedButton.onPressed, null);
      },
    );

    testWidgets(
      'should respect loading state even when KYC verified',
      (WidgetTester tester) async {
        // Arrange
        bool callbackExecuted = false;
        final user = createTestUser(kycStatus: KycStatus.approved);
        final authState = LoadedState<AuthData>(
          data: AuthData(user: user),
          lastUpdated: DateTime.now(),
        );

        final button = AppButton.primary(
          onPressed: () {
            callbackExecuted = true;
          },
          requiresKyc: true,
          loading: true,
          child: const Text('Loading Button'),
        );

        // Act
        await tester.pumpWidget(createTestWidget(
          child: button,
          authState: authState,
        ));
        await tester.pumpAndSettle();

        // Assert - Loading indicator should be visible
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'should work with fullWidth option',
      (WidgetTester tester) async {
        // Arrange
        final user = createTestUser(kycStatus: KycStatus.approved);
        final authState = LoadedState<AuthData>(
          data: AuthData(user: user),
          lastUpdated: DateTime.now(),
        );

        final button = AppButton.primary(
          onPressed: () {},
          requiresKyc: true,
          fullWidth: true,
          child: const Text('Full Width'),
        );

        // Act
        await tester.pumpWidget(createTestWidget(
          child: button,
          authState: authState,
        ));
        await tester.pumpAndSettle();

        // Assert - Button should have full width
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.width, double.infinity);
      },
    );

    testWidgets(
      'should work with leading and trailing icons',
      (WidgetTester tester) async {
        // Arrange
        final user = createTestUser(kycStatus: KycStatus.approved);
        final authState = LoadedState<AuthData>(
          data: AuthData(user: user),
          lastUpdated: DateTime.now(),
        );

        final button = AppButton.primary(
          onPressed: () {},
          requiresKyc: true,
          leadingIcon: const Icon(Icons.add),
          trailingIcon: const Icon(Icons.arrow_forward),
          child: const Text('With Icons'),
        );

        // Act
        await tester.pumpWidget(createTestWidget(
          child: button,
          authState: authState,
        ));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      },
    );
  });
}
