import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/widgets/status_update_action_sheet.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/parcel/parcel_cubit.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/parcel_entity.dart'
    as parcel;

import 'status_update_action_sheet_test.mocks.dart';

@GenerateMocks([ParcelCubit])
void main() {
  late MockParcelCubit mockParcelCubit;

  setUp(() {
    mockParcelCubit = MockParcelCubit();
  });

  // Helper function to create test parcel entity
  parcel.ParcelEntity createTestParcel({
    String id = 'test-parcel-1',
    parcel.ParcelStatus status = parcel.ParcelStatus.paid,
  }) {
    return parcel.ParcelEntity(
      id: id,
      sender: const parcel.SenderDetails(
        userId: 'sender-123',
        name: 'John Sender',
        phoneNumber: '+234 800 1234 567',
        address: 'Lagos, Nigeria',
      ),
      receiver: const parcel.ReceiverDetails(
        name: 'Jane Receiver',
        phoneNumber: '+234 800 7654 321',
        address: 'Abuja, Nigeria',
      ),
      route: const parcel.RouteInformation(
        origin: 'Lagos',
        destination: 'Abuja',
      ),
      status: status,
      category: 'Electronics',
      price: 5000.0,
      createdAt: DateTime.now(),
    );
  }

  Widget createTestWidget(parcel.ParcelEntity parcelEntity) {
    return MaterialApp(
      home: BlocProvider<ParcelCubit>.value(
        value: mockParcelCubit,
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => StatusUpdateActionSheet.show(context, parcelEntity),
              child: const Text('Show Sheet'),
            ),
          ),
        ),
      ),
    );
  }

  group('StatusUpdateActionSheet Widget Tests', () {
    testWidgets('should display current status correctly',
        (WidgetTester tester) async {
      // Arrange
      final parcelEntity = createTestParcel(status: parcel.ParcelStatus.paid);

      // Act
      await tester.pumpWidget(createTestWidget(parcelEntity));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Assert - Current status should be displayed
      expect(find.text('Current Status'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Payment confirmed, awaiting pickup'), findsOneWidget);
    });

    testWidgets('should show next status button with correct status',
        (WidgetTester tester) async {
      // Arrange
      final parcelEntity = createTestParcel(status: parcel.ParcelStatus.paid);

      // Act
      await tester.pumpWidget(createTestWidget(parcelEntity));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Assert - Next status button should show "Mark as Picked Up"
      expect(find.text('Mark as Picked Up'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag), findsOneWidget);
    });

    testWidgets('should disable button when parcel is already delivered',
        (WidgetTester tester) async {
      // Arrange
      final parcelEntity = createTestParcel(status: parcel.ParcelStatus.delivered);

      // Act
      await tester.pumpWidget(createTestWidget(parcelEntity));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Assert - Button should show "Already at Final Status" and be disabled
      expect(find.text('Already at Final Status'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);

      // Find the button and verify it's disabled
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Already at Final Status'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('should show confirmation dialog when next status button pressed',
        (WidgetTester tester) async {
      // Arrange
      final parcelEntity = createTestParcel(status: parcel.ParcelStatus.paid);

      // Act
      await tester.pumpWidget(createTestWidget(parcelEntity));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Tap the "Mark as Picked Up" button
      await tester.tap(find.text('Mark as Picked Up'));
      await tester.pumpAndSettle();

      // Assert - Confirmation dialog should appear
      expect(find.text('Confirm Status Update'), findsOneWidget);
      expect(find.text('Are you sure you want to mark this delivery as Picked Up?'),
          findsOneWidget);
      expect(find.text('Package collected from sender'), findsOneWidget);
      expect(find.text('Cancel'), findsWidgets); // Multiple cancel buttons possible
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('should dispatch ParcelUpdateStatusRequested event on confirm',
        (WidgetTester tester) async {
      // Arrange
      final parcelEntity = createTestParcel(status: parcel.ParcelStatus.paid);

      // Act
      await tester.pumpWidget(createTestWidget(parcelEntity));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Tap the "Mark as Picked Up" button
      await tester.tap(find.text('Mark as Picked Up'));
      await tester.pumpAndSettle();

      // Tap Confirm in the dialog
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Assert - Method should be called
      verify(mockParcelCubit.updateParcelStatus(
        parcelEntity.id,
        parcel.ParcelStatus.pickedUp,
      )).called(1);
    });

    testWidgets('should not dispatch event when cancel is pressed',
        (WidgetTester tester) async {
      // Arrange
      final parcelEntity = createTestParcel(status: parcel.ParcelStatus.paid);

      // Act
      await tester.pumpWidget(createTestWidget(parcelEntity));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Tap the "Mark as Picked Up" button
      await tester.tap(find.text('Mark as Picked Up'));
      await tester.pumpAndSettle();

      // Tap Cancel in the dialog
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      // Assert - Method should NOT be called
      verifyNever(mockParcelCubit.updateParcelStatus(any, any));
    });

    testWidgets('should display status progression timeline',
        (WidgetTester tester) async {
      // Arrange
      final parcelEntity = createTestParcel(status: parcel.ParcelStatus.inTransit);

      // Act
      await tester.pumpWidget(createTestWidget(parcelEntity));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Assert - Timeline labels should be visible
      expect(find.text('Delivery Progress'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Picked Up'), findsOneWidget);
      expect(find.text('In Transit'), findsOneWidget);
      expect(find.text('Arrived'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
    });

    testWidgets('should show drag handle at top of sheet',
        (WidgetTester tester) async {
      // Arrange
      final parcelEntity = createTestParcel(status: parcel.ParcelStatus.paid);

      // Act
      await tester.pumpWidget(createTestWidget(parcelEntity));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Assert - Drag handle should be present
      final dragHandle = find.byWidgetPredicate(
        (widget) => widget is Container &&
                    widget.decoration is BoxDecoration,
      );
      expect(dragHandle, findsWidgets);
    });
  });

  group('StatusUpdateActionSheet Status Progression Tests', () {
    testWidgets('should show correct next status for pickedUp',
        (WidgetTester tester) async {
      // Arrange
      final parcelEntity = createTestParcel(status: parcel.ParcelStatus.pickedUp);

      // Act
      await tester.pumpWidget(createTestWidget(parcelEntity));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Picked Up'), findsOneWidget); // Current status
      expect(find.text('Mark as In Transit'), findsOneWidget); // Next status
    });

    testWidgets('should show correct next status for inTransit',
        (WidgetTester tester) async {
      // Arrange
      final parcelEntity = createTestParcel(status: parcel.ParcelStatus.inTransit);

      // Act
      await tester.pumpWidget(createTestWidget(parcelEntity));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('In Transit'), findsOneWidget); // Current status
      expect(find.text('Mark as Arrived'), findsOneWidget); // Next status
    });

    testWidgets('should show correct next status for arrived',
        (WidgetTester tester) async {
      // Arrange
      final parcelEntity = createTestParcel(status: parcel.ParcelStatus.arrived);

      // Act
      await tester.pumpWidget(createTestWidget(parcelEntity));
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Arrived'), findsOneWidget); // Current status
      expect(find.text('Mark as Delivered'), findsOneWidget); // Next status
    });
  });
}
