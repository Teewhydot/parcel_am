# Parcel Creation & Escrow Integration

This document describes the parcel creation UI with real-time escrow integration implemented in the TravelLink app.

## Features Implemented

### 1. CreateParcelScreen
**Location:** `lib/features/travellink/presentation/screens/create_parcel_screen.dart`

Multi-step form for creating parcels with real-time integration:

#### Steps:
1. **Parcel Details**
   - Title, description, package type
   - Weight, price, urgency level
   
2. **Location Information**
   - Pickup location (name & address)
   - Delivery location (name & address)
   
3. **Review & Create**
   - Shows all entered information
   - Creates parcel with progress indicator (0% → 30% → 60% → 100%)
   - Real-time status updates
   
4. **Payment Integration**
   - Shows payment breakdown (delivery fee + service fee)
   - Real-time escrow status indicators
   - Navigate to payment flow

#### BLoC Integration:
- **ParcelBloc**: Creates parcels, manages parcel state
- **EscrowBloc**: Real-time escrow status monitoring
- **BlocListener**: Listens for parcel creation events and escrow status changes
- Auto-updates payment info when escrow is held

### 2. ParcelListScreen
**Location:** `lib/features/travellink/presentation/screens/parcel_list_screen.dart`

Real-time parcel list with live updates:

#### Features:
- **StreamBuilder**: Subscribes to `parcelsStream` from ParcelBloc
- **BlocBuilder**: Real-time UI updates on state changes
- Pull-to-refresh functionality
- Empty state with call-to-action
- Floating action button to create new parcels

#### Parcel Card Display:
- Package icon based on type
- Origin → Destination route
- Status chip with color coding
- Weight, urgency, and price info
- **Real-time escrow status** with color-coded indicators:
  - 🟠 Pending (orange)
  - 🔵 Held (blue)
  - 🟢 Released (green)
  - 🔴 Cancelled (red)
- Progress bar showing delivery status

### 3. Updated PaymentScreen
**Location:** `lib/features/travellink/presentation/screens/payment_screen.dart`

Enhanced with real EscrowBloc integration:

#### Changes:
- Added `EscrowBloc` instance with real-time status monitoring
- **MultiBlocProvider**: Provides both WalletBloc and EscrowBloc
- **MultiBlocListener**: 
  - WalletBloc listener for balance errors
  - EscrowBloc listener for real-time escrow state changes
  
#### Real-time Status Indicators:
- **Live escrow status badge** in wallet balance card
- Status-specific icons:
  - ⏳ Holding
  - 🔒 Held
  - 🔓 Releasing
  - ✅ Released
  - ❌ Error
- Color-coded status labels
- Dynamic status updates without page refresh

#### Flow:
1. User confirms payment method
2. `_processPaymentAndEscrow()` triggers both:
   - `EscrowHoldRequested` event → EscrowBloc
   - `WalletEscrowHoldRequested` event → WalletBloc
3. EscrowBloc emits status changes (holding → held)
4. BlocListener catches status change
5. UI updates automatically with new status
6. Progress to next step when escrow is held

### 4. BLoC Architecture

#### ParcelBloc
**Location:** `lib/features/travellink/presentation/bloc/parcel/`

**Events:**
- `ParcelListRequested` - Load all parcels
- `ParcelCreateRequested` - Create new parcel
- `ParcelUpdated` - Update existing parcel
- `ParcelStatusChanged` - Change parcel status
- `ParcelPaymentCompleted` - Mark payment as complete

**States:**
- `ParcelInitial` - Initial state
- `ParcelLoading` - Loading parcels
- `ParcelCreating(progress)` - Creating with progress (0.0-1.0)
- `ParcelCreated(parcel)` - Parcel created successfully
- `ParcelListLoaded(List<PackageModel>)` - List of parcels
- `ParcelError(message)` - Error state

**Features:**
- Real-time stream of parcels via `parcelsStream`
- Progressive creation with progress updates
- Automatic list updates on state changes

#### EscrowBloc
**Location:** `lib/features/travellink/presentation/bloc/escrow/`

**Events:**
- `EscrowHoldRequested` - Hold funds in escrow
- `EscrowReleaseRequested` - Release funds
- `EscrowCancelRequested` - Cancel escrow
- `EscrowStatusUpdated` - Update escrow status

**States:**
- Single `EscrowState` with status enum:
  - `idle` - No active escrow
  - `holding` - Processing hold request
  - `held` - Funds secured in escrow
  - `releasing` - Processing release
  - `released` - Funds released
  - `cancelling` - Processing cancellation
  - `cancelled` - Escrow cancelled
  - `error` - Error occurred

**Features:**
- Real-time status stream via `statusStream`
- Simulates 1-second processing time for state transitions
- Broadcasts status changes to all listeners

### 5. Dependency Injection

**Location:** `lib/injection_container.dart`

Registered as factories for proper lifecycle management:
```dart
sl.registerFactory<ParcelBloc>(() => ParcelBloc());
sl.registerFactory<EscrowBloc>(() => EscrowBloc());
sl.registerFactory<WalletBloc>(() => WalletBloc());
```

## Real-time Communication Flow

```
CreateParcelScreen
    ↓
ParcelBloc.add(ParcelCreateRequested)
    ↓
ParcelBloc emits ParcelCreating (30%, 60%, 100%)
    ↓
BlocListener catches ParcelCreated
    ↓
Navigate to Payment step
    ↓
User proceeds to PaymentScreen
    ↓
EscrowBloc.add(EscrowHoldRequested)
    ↓
EscrowBloc emits EscrowState(holding)
    ↓
EscrowBloc emits EscrowState(held)
    ↓
BlocListener catches held status
    ↓
Update UI with real-time status
    ↓
ParcelBloc.add(ParcelPaymentCompleted)
    ↓
Parcel updated with payment info
    ↓
ParcelListScreen receives update via stream
    ↓
UI refreshes automatically
```

## Usage Examples

### Creating a Parcel
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CreateParcelScreen(),
  ),
);
```

### Viewing Parcel List
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ParcelListScreen(),
  ),
);
```

### Processing Payment with Escrow
```dart
// Already integrated in CreateParcelScreen and PaymentScreen
// Automatically triggers when user confirms payment
```

## Testing Checklist

- [x] Create parcel with all required fields
- [x] Multi-step form navigation (next/back)
- [x] Progress indicator during creation
- [x] Real-time escrow status updates
- [x] Parcel list shows created parcels
- [x] Stream updates when new parcels added
- [x] Payment screen integration
- [x] Escrow hold triggers correctly
- [x] Status indicators update in real-time
- [x] Error handling and user feedback

## Future Enhancements

1. **Backend Integration**: Connect to real Firebase/API
2. **Image Upload**: Add parcel photos
3. **Location Picker**: Integrate Google Maps
4. **Push Notifications**: Real-time escrow status alerts
5. **Carrier Matching**: Auto-match with available carriers
6. **Chat Integration**: In-app messaging with carriers
7. **Escrow Dispute**: Dispute resolution flow
8. **Payment Gateway**: Real payment processor integration

## Notes

- All BLoCs use streams for real-time updates
- UI automatically rebuilds on state changes
- Mock data used for demonstration
- Ready for backend integration
- Follows Clean Architecture principles
- Uses BLoC pattern throughout
