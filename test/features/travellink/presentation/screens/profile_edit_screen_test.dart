import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/features/travellink/domain/entities/user_entity.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_data.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_event.dart';
import 'package:parcel_am/features/travellink/presentation/screens/profile_edit_screen.dart';

import 'profile_edit_screen_test.mocks.dart';
void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const ProfileEditScreen(),
      ),
    );
  }

  final testUser = UserEntity(
    uid: 'test-uid',
    email: 'test@example.com',
    displayName: 'Test User',
    kycStatus: KycStatus.none,
    additionalData: const {},
  );

  group('ProfileEditScreen', () {
    group('Initial State and UI', () {
      testWidgets('renders correctly with initial data', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Edit Profile'), findsOneWidget);
        expect(find.byKey(const Key('displayNameField')), findsOneWidget);
        expect(find.byKey(const Key('emailField')), findsOneWidget);
        expect(find.byKey(const Key('saveButton')), findsOneWidget);
        expect(find.byKey(const Key('cancelButton')), findsOneWidget);
      });

      testWidgets('loads existing user data into form fields', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final displayNameField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('displayNameField')),
            matching: find.byType(TextField),
          ),
        );
        expect(displayNameField.controller?.text, 'Test User');

        final emailField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('emailField')),
            matching: find.byType(TextField),
          ),
        );
        expect(emailField.controller?.text, 'test@example.com');
      });
    });

    group('Form Validation', () {
      testWidgets('validates displayName is not empty', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final displayNameField = find.descendant(
          of: find.byKey(const Key('displayNameField')),
          matching: find.byType(TextField),
        );
        await tester.enterText(displayNameField, '');
        await tester.tap(find.byKey(const Key('saveButton')));
        await tester.pumpAndSettle();

        expect(find.text('Display name is required'), findsOneWidget);
        verifyNever(mockAuthBloc.add(any));
      });

      testWidgets('validates displayName minimum length', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final displayNameField = find.descendant(
          of: find.byKey(const Key('displayNameField')),
          matching: find.byType(TextField),
        );
        await tester.enterText(displayNameField, 'AB');
        await tester.tap(find.byKey(const Key('saveButton')));
        await tester.pumpAndSettle();

        expect(find.text('Display name must be at least 3 characters'), findsOneWidget);
        verifyNever(mockAuthBloc.add(any));
      });

      testWidgets('validates email is not empty', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final emailField = find.descendant(
          of: find.byKey(const Key('emailField')),
          matching: find.byType(TextField),
        );
        await tester.enterText(emailField, '');
        await tester.tap(find.byKey(const Key('saveButton')));
        await tester.pumpAndSettle();

        expect(find.text('Email is required'), findsOneWidget);
        verifyNever(mockAuthBloc.add(any));
      });

      testWidgets('validates email format', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final emailField = find.descendant(
          of: find.byKey(const Key('emailField')),
          matching: find.byType(TextField),
        );
        await tester.enterText(emailField, 'invalid-email');
        await tester.tap(find.byKey(const Key('saveButton')));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a valid email'), findsOneWidget);
        verifyNever(mockAuthBloc.add(any));
      });

      testWidgets('passes validation with valid inputs', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final displayNameField = find.descendant(
          of: find.byKey(const Key('displayNameField')),
          matching: find.byType(TextField),
        );
        await tester.enterText(displayNameField, 'Valid Name');

        final emailField = find.descendant(
          of: find.byKey(const Key('emailField')),
          matching: find.byType(TextField),
        );
        await tester.enterText(emailField, 'valid@example.com');

        await tester.tap(find.byKey(const Key('saveButton')));
        await tester.pumpAndSettle();

        verify(mockAuthBloc.add(argThat(
          isA<AuthUserProfileUpdateRequested>()
              .having((e) => e.displayName, 'displayName', 'Valid Name')
              .having((e) => e.email, 'email', 'valid@example.com'),
        ))).called(1);
      });
    });

    group('Image Picker Integration', () {
      testWidgets('displays image picker button', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('imagePickerButton')), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
        expect(find.text('Change Photo'), findsOneWidget);
      });

      testWidgets('tapping image picker opens camera_alt icon', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      });
    });

    group('Save Button and Events', () {
      testWidgets('save button triggers AuthUserProfileUpdateRequested with correct data', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final displayNameField = find.descendant(
          of: find.byKey(const Key('displayNameField')),
          matching: find.byType(TextField),
        );
        await tester.enterText(displayNameField, 'Updated Name');

        final emailField = find.descendant(
          of: find.byKey(const Key('emailField')),
          matching: find.byType(TextField),
        );
        await tester.enterText(emailField, 'updated@example.com');

        await tester.tap(find.byKey(const Key('saveButton')));
        await tester.pumpAndSettle();

        verify(mockAuthBloc.add(argThat(
          isA<AuthUserProfileUpdateRequested>()
              .having((e) => e.displayName, 'displayName', 'Updated Name')
              .having((e) => e.email, 'email', 'updated@example.com'),
        ))).called(1);
      });

      testWidgets('save button is disabled during submission', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            const LoadingState<AuthData>(message: 'Updating profile...'),
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final saveButton = tester.widget<ElevatedButton>(
          find.descendant(
            of: find.byKey(const Key('saveButton')),
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(saveButton.enabled, false);
      });
    });

    group('Loading State', () {
      testWidgets('displays loading indicator during profile update', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            const LoadingState<AuthData>(message: 'Updating profile...'),
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('disables form inputs during loading', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            const LoadingState<AuthData>(message: 'Updating profile...'),
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump();

        final saveButton = tester.widget<ElevatedButton>(
          find.descendant(
            of: find.byKey(const Key('saveButton')),
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(saveButton.enabled, false);

        final cancelButton = tester.widget<OutlinedButton>(
          find.descendant(
            of: find.byKey(const Key('cancelButton')),
            matching: find.byType(OutlinedButton),
          ),
        );
        expect(cancelButton.enabled, false);
      });
    });

    group('Success Message Display', () {
      testWidgets('displays success snackbar on successful update', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.fromIterable([
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
            const SuccessState<AuthData>(
              successMessage: 'Profile updated successfully',
            ),
          ]),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byKey(const Key('successSnackBar')), findsOneWidget);
        expect(find.text('Profile updated successfully'), findsOneWidget);
      });

      testWidgets('displays default success message when none provided', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.fromIterable([
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
            const SuccessState<AuthData>(),
          ]),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Profile updated successfully'), findsOneWidget);
      });
    });

    group('Error Message Display', () {
      testWidgets('displays error snackbar on update failure', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.fromIterable([
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
            const ErrorState<AuthData>(
              errorMessage: 'Network error occurred',
            ),
          ]),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byKey(const Key('errorSnackBar')), findsOneWidget);
        expect(find.text('Network error occurred'), findsOneWidget);
      });

      testWidgets('displays default error message when none provided', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.fromIterable([
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
            const ErrorState<AuthData>(),
          ]),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Failed to update profile'), findsOneWidget);
      });
    });

    group('Cancel Button Navigation', () {
      testWidgets('cancel button pops navigation', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            LoadedState<AuthData>(
              data: AuthData(user: testUser),
              lastUpdated: DateTime.now(),
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider<AuthBloc>.value(
                          value: mockAuthBloc,
                          child: const ProfileEditScreen(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Profile Edit'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Profile Edit'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Profile'), findsOneWidget);

        await tester.tap(find.byKey(const Key('cancelButton')));
        await tester.pumpAndSettle();

        expect(find.text('Edit Profile'), findsNothing);
        expect(find.text('Open Profile Edit'), findsOneWidget);
      });

      testWidgets('cancel button is disabled during loading', (WidgetTester tester) async {
        when(mockAuthBloc.state).thenReturn(
          LoadedState<AuthData>(
            data: AuthData(user: testUser),
            lastUpdated: DateTime.now(),
          ),
        );
        when(mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(
            const LoadingState<AuthData>(message: 'Updating profile...'),
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump();

        final cancelButton = tester.widget<OutlinedButton>(
          find.descendant(
            of: find.byKey(const Key('cancelButton')),
            matching: find.byType(OutlinedButton),
          ),
        );
        expect(cancelButton.enabled, false);
      });
    });
  });
}
