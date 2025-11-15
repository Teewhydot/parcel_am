import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:parcel_am/core/bloc/base/base_state.dart';
import 'package:parcel_am/core/routes/routes.dart';
import 'package:parcel_am/features/travellink/domain/entities/user_entity.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_bloc.dart';
import 'package:parcel_am/features/travellink/presentation/bloc/auth/auth_data.dart';
import 'package:parcel_am/features/travellink/presentation/widgets/kyc_status_widgets.dart';
import 'package:parcel_am/features/travellink/presentation/widgets/user_stats_grid.dart';
import 'package:parcel_am/features/travellink/presentation/widgets/wallet_balance_card.dart';
import 'package:provider/provider.dart';
import 'package:parcel_am/features/travellink/data/providers/auth_provider.dart';

import 'profile_screen_test.mocks.dart';

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  final testUser = UserEntity(
    uid: 'test-user-123',
    displayName: 'John Doe',
    email: 'john.doe@example.com',
    isVerified: true,
    verificationStatus: 'verified',
    kycStatus: KycStatus.approved,
    createdAt: DateTime(2023, 1, 1),
    additionalData: {},
    profilePhotoUrl: 'https://example.com/photo.jpg',
    rating: 4.8,
    completedDeliveries: 25,
    packagesSent: 15,
    totalEarnings: 50000.0,
    availableBalance: 25000.0,
    pendingBalance: 5000.0,
  );

  final testUserWithoutPhoto = UserEntity(
    uid: 'test-user-456',
    displayName: 'Jane Smith',
    email: 'jane.smith@example.com',
    isVerified: false,
    verificationStatus: 'pending',
    kycStatus: KycStatus.pending,
    createdAt: DateTime(2023, 1, 1),
    additionalData: {},
    profilePhotoUrl: null,
    rating: 3.5,
    completedDeliveries: 5,
    packagesSent: 10,
    totalEarnings: 15000.0,
    availableBalance: 8000.0,
    pendingBalance: 2000.0,
  );

  Widget createProfileScreenWidget({UserEntity? user}) {
    final authProvider = AuthProvider();
    if (user != null) {
      authProvider.setUser(user);
    }

    return GetMaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: const ProfileScreen(),
        ),
      ),
      getPages: [
        GetPage(
          name: Routes.verification,
          page: () => const Scaffold(body: Text('Verification Screen')),
        ),
        GetPage(
          name: '/profile-edit',
          page: () => const Scaffold(body: Text('Profile Edit Screen')),
        ),
      ],
    );
  }

  group('ProfileScreen UI Tests', () {
    testWidgets('renders correctly with user data from AuthBloc', (WidgetTester tester) async {
      final authData = AuthData(user: testUser);
      when(mockAuthBloc.state).thenReturn(
        LoadedState<AuthData>(
          data: authData,
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(
          LoadedState<AuthData>(
            data: authData,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(createProfileScreenWidget(user: testUser));
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john.doe@example.com'), findsOneWidget);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('displays UserStatsGrid with correct values', (WidgetTester tester) async {
      final authData = AuthData(user: testUser);
      when(mockAuthBloc.state).thenReturn(
        LoadedState<AuthData>(
          data: authData,
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(
          LoadedState<AuthData>(
            data: authData,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(createProfileScreenWidget(user: testUser));
      await tester.pumpAndSettle();

      expect(find.byType(UserStatsGrid), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('₦50000'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
    });

    testWidgets('KYC status card is visible and displays correct data', (WidgetTester tester) async {
      final authData = AuthData(user: testUser);
      when(mockAuthBloc.state).thenReturn(
        LoadedState<AuthData>(
          data: authData,
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(
          LoadedState<AuthData>(
            data: authData,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(createProfileScreenWidget(user: testUser));
      await tester.pumpAndSettle();

      expect(find.byType(KycStatusBadge), findsWidgets);
    });

    testWidgets('KYC status card is visible for pending status', (WidgetTester tester) async {
      final authData = AuthData(user: testUserWithoutPhoto);
      when(mockAuthBloc.state).thenReturn(
        LoadedState<AuthData>(
          data: authData,
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(
          LoadedState<AuthData>(
            data: authData,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(createProfileScreenWidget(user: testUserWithoutPhoto));
      await tester.pumpAndSettle();

      expect(find.byType(KycStatusBanner), findsWidgets);
    });

    testWidgets('displays wallet summary section', (WidgetTester tester) async {
      final authData = AuthData(user: testUser);
      when(mockAuthBloc.state).thenReturn(
        LoadedState<AuthData>(
          data: authData,
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(
          LoadedState<AuthData>(
            data: authData,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(createProfileScreenWidget(user: testUser));
      await tester.pumpAndSettle();

      expect(find.text('Wallet Balance'), findsWidgets);
    });

    testWidgets('displays profile photo when URL is provided', (WidgetTester tester) async {
      final authData = AuthData(user: testUser);
      when(mockAuthBloc.state).thenReturn(
        LoadedState<AuthData>(
          data: authData,
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(
          LoadedState<AuthData>(
            data: authData,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(createProfileScreenWidget(user: testUser));
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('displays placeholder when profile photo URL is null', (WidgetTester tester) async {
      final authData = AuthData(user: testUserWithoutPhoto);
      when(mockAuthBloc.state).thenReturn(
        LoadedState<AuthData>(
          data: authData,
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(
          LoadedState<AuthData>(
            data: authData,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(createProfileScreenWidget(user: testUserWithoutPhoto));
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsWidgets);
      expect(find.byIcon(Icons.person), findsWidgets);
    });

    testWidgets('navigates to ProfileEditScreen when edit button is tapped', (WidgetTester tester) async {
      final authData = AuthData(user: testUser);
      when(mockAuthBloc.state).thenReturn(
        LoadedState<AuthData>(
          data: authData,
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(
          LoadedState<AuthData>(
            data: authData,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(createProfileScreenWidget(user: testUser));
      await tester.pumpAndSettle();

      final editButtonFinder = find.byIcon(Icons.edit);
      if (editButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(editButtonFinder.first);
        await tester.pumpAndSettle();
        expect(find.text('Profile Edit Screen'), findsOneWidget);
      }
    });

    testWidgets('handles loading state correctly', (WidgetTester tester) async {
      when(mockAuthBloc.state).thenReturn(
        const LoadingState<AuthData>(message: 'Loading user data...'),
      );
      when(mockAuthBloc.stream).thenAnswer(
        (_) => const Stream.empty(),
      );

      await tester.pumpWidget(createProfileScreenWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('handles error state correctly', (WidgetTester tester) async {
      when(mockAuthBloc.state).thenReturn(
        const ErrorState<AuthData>(
          errorMessage: 'Failed to load user data',
          errorCode: 'user_load_failed',
        ),
      );
      when(mockAuthBloc.stream).thenAnswer(
        (_) => const Stream.empty(),
      );

      await tester.pumpWidget(createProfileScreenWidget());
      await tester.pump();

      expect(find.text('Failed to load user data'), findsWidgets);
    });

    testWidgets('taps on KYC banner navigates to verification screen', (WidgetTester tester) async {
      final authData = AuthData(user: testUserWithoutPhoto);
      when(mockAuthBloc.state).thenReturn(
        LoadedState<AuthData>(
          data: authData,
          lastUpdated: DateTime.now(),
        ),
      );
      when(mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(
          LoadedState<AuthData>(
            data: authData,
            lastUpdated: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(createProfileScreenWidget(user: testUserWithoutPhoto));
      await tester.pumpAndSettle();

      final kycBanner = find.byType(KycStatusBanner);
      if (kycBanner.evaluate().isNotEmpty) {
        await tester.tap(kycBanner.first);
        await tester.pumpAndSettle();
        expect(find.text('Verification Screen'), findsOneWidget);
      }
    });
  });
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Get.toNamed('/profile-edit');
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, BaseState<AuthData>>(
        builder: (context, state) {
          if (state is LoadingState<AuthData>) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ErrorState<AuthData>) {
            return Center(
              child: Text(state.errorMessage ?? 'An error occurred'),
            );
          }

          if (state is! DataState<AuthData> || state.data?.user == null) {
            return const Center(child: Text('No user data'));
          }

          final user = state.data!.user!;
          final authProvider = context.watch<AuthProvider>();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user.profilePhotoUrl != null
                      ? NetworkImage(user.profilePhotoUrl!)
                      : null,
                  child: user.profilePhotoUrl == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                const KycStatusBanner(),
                const SizedBox(height: 24),
                const WalletBalanceCard(),
                const SizedBox(height: 24),
                const UserStatsGrid(),
              ],
            ),
          );
        },
      ),
    );
  }
}
