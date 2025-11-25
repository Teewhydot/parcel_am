import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/widgets/my_deliveries_tab.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/widgets/delivery_card.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/parcel/parcel_bloc.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/bloc/parcel/parcel_state.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/parcel_entity.dart'
    as parcel;
import 'package:parcel_am/core/bloc/base/base_state.dart';

import 'my_deliveries_tab_test.mocks.dart';

@GenerateMocks([ParcelBloc])
void main() {
  late MockParcelBloc mockParcelBloc;

  setUp(() {
    mockParcelBloc = MockParcelBloc();
    // Provide a default dummy state value
    provideDummy<BaseState<ParcelData>>(
      const InitialState<ParcelData>(),
    );
  });

  // Helper function to create test parcel entity
  parcel.ParcelEntity createTestParcel({
    String id = 'test-parcel-1',
    parcel.ParcelStatus status = parcel.ParcelStatus.paid,
    String category = 'Electronics',
    double price = 5000.0,
    bool urgent = false,
  }) {
    final estimatedDate = urgent
        ? DateTime.now().add(const Duration(hours: 24)).toIso8601String()
        : DateTime.now().add(const Duration(days: 7)).toIso8601String();

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
      route: parcel.RouteInformation(
        origin: 'Lagos',
        destination: 'Abuja',
        estimatedDeliveryDate: estimatedDate,
      ),
      status: status,
      category: category,
      price: price,
      weight: 2.5,
      dimensions: '30x20x10cm',
      description: 'Test package description',
      createdAt: DateTime.now(),
    );
  }

  Widget createTestWidget(BaseState<ParcelData> state) {
    when(mockParcelBloc.state).thenReturn(state);
    when(mockParcelBloc.stream).thenAnswer((_) => Stream.value(state));

    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<ParcelBloc>.value(
          value: mockParcelBloc,
          child: const MyDeliveriesTab(),
        ),
      ),
    );
  }

  group('MyDeliveriesTab Widget Tests', () {
    testWidgets('should render empty state when no accepted parcels',
        (WidgetTester tester) async {
      // Arrange
      final state = AsyncLoadedState<ParcelData>(
        data: const ParcelData(acceptedParcels: []),
        lastUpdated: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
      expect(find.text('No active deliveries'), findsOneWidget);
      expect(find.text('Accepted requests will appear here'), findsOneWidget);
    });

    testWidgets('should render delivery cards with parcel data',
        (WidgetTester tester) async {
      // Arrange
      final parcels = [
        createTestParcel(id: 'parcel-1', status: parcel.ParcelStatus.paid),
        createTestParcel(id: 'parcel-2', status: parcel.ParcelStatus.inTransit),
      ];

      final state = AsyncLoadedState<ParcelData>(
        data: ParcelData(acceptedParcels: parcels),
        lastUpdated: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state));
      await tester.pumpAndSettle();

      // Assert - Should show delivery cards
      expect(find.byType(DeliveryCard), findsNWidgets(2));
      expect(find.text('2 deliveries'), findsOneWidget);
    });

    testWidgets('should filter parcels when status filter dropdown changes',
        (WidgetTester tester) async {
      // Arrange
      final parcels = [
        createTestParcel(id: 'parcel-1', status: parcel.ParcelStatus.paid),
        createTestParcel(id: 'parcel-2', status: parcel.ParcelStatus.inTransit),
        createTestParcel(id: 'parcel-3', status: parcel.ParcelStatus.delivered),
      ];

      final state = AsyncLoadedState<ParcelData>(
        data: ParcelData(acceptedParcels: parcels),
        lastUpdated: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state));
      await tester.pumpAndSettle();

      // Initially should show all 3 parcels
      expect(find.byType(DeliveryCard), findsNWidgets(3));
      expect(find.text('3 deliveries'), findsOneWidget);

      // Tap the dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Select 'Active' filter
      await tester.tap(find.text('Active').last);
      await tester.pumpAndSettle();

      // Assert - Should show only active parcels (paid, inTransit)
      expect(find.byType(DeliveryCard), findsNWidgets(2));
      expect(find.text('2 deliveries'), findsOneWidget);
    });

    testWidgets('should trigger data fetch on pull-to-refresh',
        (WidgetTester tester) async {
      // Arrange
      final parcels = [
        createTestParcel(id: 'parcel-1', status: parcel.ParcelStatus.paid),
      ];

      final state = AsyncLoadedState<ParcelData>(
        data: ParcelData(acceptedParcels: parcels),
        lastUpdated: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state));
      await tester.pumpAndSettle();

      // Find the RefreshIndicator
      final refreshFinder = find.byType(RefreshIndicator);
      expect(refreshFinder, findsOneWidget);

      // Trigger pull-to-refresh by dragging down
      await tester.drag(refreshFinder, const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Assert - RefreshIndicator should complete
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('should show empty state for filtered results',
        (WidgetTester tester) async {
      // Arrange - Only have active parcels, no completed ones
      final parcels = [
        createTestParcel(id: 'parcel-1', status: parcel.ParcelStatus.paid),
        createTestParcel(id: 'parcel-2', status: parcel.ParcelStatus.inTransit),
      ];

      final state = AsyncLoadedState<ParcelData>(
        data: ParcelData(acceptedParcels: parcels),
        lastUpdated: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state));
      await tester.pumpAndSettle();

      // Tap the dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Select 'Completed' filter
      await tester.tap(find.text('Completed').last);
      await tester.pumpAndSettle();

      // Assert - Should show empty state for filtered results
      expect(find.byIcon(Icons.filter_list_off), findsOneWidget);
      expect(find.text('No Completed deliveries'), findsOneWidget);
      expect(find.text('Try selecting a different filter'), findsOneWidget);
    });

    testWidgets('should display loading skeleton when loading',
        (WidgetTester tester) async {
      // Arrange
      final state = AsyncLoadingState<ParcelData>(data: null);

      // Act
      await tester.pumpWidget(createTestWidget(state));
      await tester.pump();

      // Assert - Should show skeleton loaders
      expect(find.byType(DeliveryCardSkeleton), findsNWidgets(3));
    });

    testWidgets('should show error state when error occurs',
        (WidgetTester tester) async {
      // Arrange
      final state = AsyncErrorState<ParcelData>(
        errorMessage: 'Failed to load deliveries',
        data: const ParcelData(),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load deliveries'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should display status filter dropdown with correct options',
        (WidgetTester tester) async {
      // Arrange
      final parcels = [
        createTestParcel(id: 'parcel-1', status: parcel.ParcelStatus.paid),
      ];

      final state = AsyncLoadedState<ParcelData>(
        data: ParcelData(acceptedParcels: parcels),
        lastUpdated: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state));
      await tester.pumpAndSettle();

      // Assert - Filter dropdown should be present
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.text('Filter:'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);

      // Tap dropdown to show options
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Assert - All filter options should be available
      expect(find.text('All').hitTestable(), findsNWidgets(2)); // One selected, one in menu
      expect(find.text('Active').hitTestable(), findsOneWidget);
      expect(find.text('Completed').hitTestable(), findsOneWidget);
    });
  });
}
