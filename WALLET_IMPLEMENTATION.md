# Wallet Balance Card Implementation

## Overview
Added WalletBalanceCard widget to dashboard with real-time balance updates using BLoC pattern.

## Files Created

### BLoC Layer
- `lib/features/travellink/presentation/bloc/wallet/wallet_bloc.dart` - Main BLoC with 30s auto-refresh
- `lib/features/travellink/presentation/bloc/wallet/wallet_event.dart` - Events: LoadRequested, RefreshRequested, BalanceUpdated
- `lib/features/travellink/presentation/bloc/wallet/wallet_state.dart` - States: Initial, Loading, Loaded, Error

### Widget
- `lib/features/travellink/presentation/widgets/wallet_balance_card.dart` - WalletBalanceCard with BlocBuilder

### Updates
- `lib/features/travellink/presentation/screens/dashboard_screen.dart` - Added WalletBalanceCard to _HeaderSection
- `lib/features/travellink/domain/entities/user_entity.dart` - Added availableBalance & pendingBalance fields
- `lib/features/travellink/data/models/user_model.dart` - Updated to support new balance fields
- `lib/injection_container.dart` - Registered WalletBloc

### Test
- `test/features/travellink/presentation/bloc/wallet/wallet_bloc_test.dart` - Unit tests for WalletBloc

## Features
- Real-time balance display (Available & Pending)
- Auto-refresh every 30 seconds
- Manual refresh button
- Total balance calculation
- Error handling with retry
- Loading states
- Formatted currency display (₦)
- Relative time display (last updated)

## Usage
WalletBloc is automatically provided in DashboardScreen with initial load event. WalletBalanceCard uses BlocBuilder for reactive UI updates.
