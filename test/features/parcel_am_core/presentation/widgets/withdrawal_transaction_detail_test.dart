import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:parcel_am/features/parcel_am_core/presentation/screens/withdrawal_transaction_detail_screen.dart';
import 'package:parcel_am/features/parcel_am_core/domain/entities/withdrawal_order_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WithdrawalTransactionDetailScreen Tests', () {
    late WithdrawalOrderEntity testWithdrawalOrder;

    setUp(() {
      testWithdrawalOrder = WithdrawalOrderEntity(
        id: 'WTH-1234567890-abc123',
        userId: 'user123',
        amount: 5000.0,
        bankAccount: const BankAccountInfo(
          id: 'bank-account-123',
          accountNumber: '0123456789',
          accountName: 'John Doe',
          bankCode: '058',
          bankName: 'GTBank',
        ),
        status: WithdrawalStatus.success,
        recipientCode: 'RCP_test123',
        transferCode: 'TRF_test123',
        createdAt: DateTime(2025, 11, 30, 10, 0),
        updatedAt: DateTime(2025, 11, 30, 10, 5),
        processedAt: DateTime(2025, 11, 30, 10, 5),
        metadata: {'transactionId': 'trans123'},
      );
    });

    testWidgets('should display withdrawal details correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: WithdrawalTransactionDetailScreen(
              withdrawalOrder: testWithdrawalOrder,
            ),
          ),
        ),
      );

      // Verify amount is displayed
      expect(find.text('₦5,000.00'), findsOneWidget);

      // Verify bank account name is displayed
      expect(find.text('John Doe'), findsOneWidget);

      // Verify bank name is displayed
      expect(find.text('GTBank'), findsOneWidget);

      // Verify status is displayed
      expect(find.text('Success'), findsOneWidget);
    });

    testWidgets('should show failure reason for failed withdrawal',
        (WidgetTester tester) async {
      final failedWithdrawal = testWithdrawalOrder.copyWith(
        status: WithdrawalStatus.failed,
        failureReason: 'Insufficient funds in Paystack account',
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: WithdrawalTransactionDetailScreen(
              withdrawalOrder: failedWithdrawal,
            ),
          ),
        ),
      );

      // Verify failure reason is displayed
      expect(find.text('Insufficient funds in Paystack account'),
          findsOneWidget);
    });

    testWidgets('should show reversal reason for reversed withdrawal',
        (WidgetTester tester) async {
      final reversedWithdrawal = testWithdrawalOrder.copyWith(
        status: WithdrawalStatus.reversed,
        reversalReason: 'Bank account invalid',
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: WithdrawalTransactionDetailScreen(
              withdrawalOrder: reversedWithdrawal,
            ),
          ),
        ),
      );

      // Verify reversal reason is displayed
      expect(find.text('Bank account invalid'), findsOneWidget);
    });

    testWidgets('should copy reference on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: WithdrawalTransactionDetailScreen(
              withdrawalOrder: testWithdrawalOrder,
            ),
          ),
        ),
      );

      // Find and tap the copy icon
      final copyButton = find.byIcon(Icons.copy);
      await tester.tap(copyButton.first);
      await tester.pumpAndSettle();

      // Verify snackbar appears
      expect(find.text('Reference ID copied to clipboard'), findsOneWidget);
    });

    testWidgets('should show retry button for failed withdrawal',
        (WidgetTester tester) async {
      final failedWithdrawal = testWithdrawalOrder.copyWith(
        status: WithdrawalStatus.failed,
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: WithdrawalTransactionDetailScreen(
              withdrawalOrder: failedWithdrawal,
            ),
          ),
        ),
      );

      // Verify retry button is present
      expect(find.text('Retry Withdrawal'), findsOneWidget);
    });

    testWidgets('should not show retry button for successful withdrawal',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: WithdrawalTransactionDetailScreen(
              withdrawalOrder: testWithdrawalOrder,
            ),
          ),
        ),
      );

      // Verify retry button is not present
      expect(find.text('Retry Withdrawal'), findsNothing);
    });

    testWidgets('should display timeline for processing states',
        (WidgetTester tester) async {
      final processingWithdrawal = testWithdrawalOrder.copyWith(
        status: WithdrawalStatus.processing,
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: WithdrawalTransactionDetailScreen(
              withdrawalOrder: processingWithdrawal,
            ),
          ),
        ),
      );

      // Verify timeline elements
      expect(find.text('Initiated'), findsOneWidget);
      expect(find.text('Processing'), findsOneWidget);
    });
  });
}
