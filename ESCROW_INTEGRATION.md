# Real-Time Escrow Integration with Delivery Workflow

## Overview
This implementation integrates real-time escrow functionality with the delivery workflow, providing live status updates, delivery confirmation, and dispute handling.

## Components Implemented

### 1. Package BLoC (`lib/features/travellink/presentation/bloc/package/`)
- **package_bloc.dart**: Manages package and escrow state with real-time Firestore streams
- **package_event.dart**: Events for package tracking, escrow release, disputes, and delivery confirmation
- **package_state.dart**: State management with escrow release status tracking

**Key Features:**
- Real-time package data streaming from Firestore
- Escrow release processing with status feedback
- Dispute creation and tracking
- Delivery confirmation handling

### 2. Package Remote Data Source (`lib/features/travellink/data/datasources/package_remote_data_source.dart`)
Provides Firestore integration for:
- Real-time package streams via `getPackageStream()`
- Active packages stream via `getActivePackagesStream()`
- Escrow release with transactional updates
- Dispute creation
- Delivery confirmation

### 3. Tracking Screen (`lib/features/travellink/presentation/screens/tracking_screen.dart`)
Enhanced with:
- **BlocBuilder** for real-time package and escrow status updates
- **Live escrow status banner** showing current state (held, released, disputed, cancelled)
- **Delivery confirmation UI** with code input and escrow release trigger
- **Dispute handling UI** with reason input and live status feedback
- **Real-time notifications** via SnackBar for escrow status changes

**UI Components:**
- Package header with real-time progress
- Escrow status banner with color-coded indicators
- Delivery confirmation card (shown when package is delivered and escrow is held)
- Dispute form (available when escrow is held)
- Real-time status feedback during processing

### 4. Dashboard Screen (`lib/features/travellink/presentation/screens/dashboard_screen.dart`)
Updated with:
- **Real-time active parcels stream** subscription
- **Escrow status indicators** on each parcel card
- **In-app notifications** for escrow status changes
- Live updates as Firestore data changes

**Features:**
- Stream subscription to active packages
- Escrow notification service integration
- Visual escrow status badges on package cards
- Tap-to-view functionality

### 5. Notification Service (`lib/core/services/notification_service.dart`)
New service for real-time escrow notifications:
- Subscribes to Firestore package changes
- Filters for escrow status updates
- Broadcasts escrow notifications app-wide
- Provides formatted notification messages

**Notification Types:**
- Escrow held
- Escrow released
- Escrow disputed
- Escrow cancelled

### 6. Wallet Data Enhancement (`lib/features/travellink/presentation/bloc/wallet/wallet_data.dart`)
Added `disputed` status to `EscrowStatus` enum for comprehensive status tracking.

## Workflow

### Escrow Release Flow
1. Package delivered → Delivery confirmation UI appears
2. User enters confirmation code
3. Triggers `DeliveryConfirmationRequested` event
4. Followed by `EscrowReleaseRequested` event
5. BLoC shows processing status
6. Firestore transaction updates package and transaction records
7. Success/failure feedback displayed
8. Dashboard receives real-time notification

### Dispute Flow
1. User identifies delivery issue
2. Enters dispute reason in form
3. Triggers `EscrowDisputeRequested` event
4. BLoC shows processing status
5. Dispute record created in Firestore
6. Package and transaction marked as disputed
7. Dispute ID returned and displayed
8. All stakeholders notified via real-time updates

## Firestore Structure

### Packages Collection
```
packages/{packageId}
  ├── paymentInfo
  │   ├── isEscrow: boolean
  │   ├── escrowStatus: string (held|released|disputed|cancelled)
  │   ├── escrowHeldAt: timestamp
  │   ├── escrowReleaseDate: timestamp
  │   └── ...
  └── ...
```

### Transactions Collection
```
transactions/{transactionId}
  ├── status: string
  ├── releasedAt: timestamp
  ├── disputeId: string
  └── ...
```

### Disputes Collection
```
disputes/{disputeId}
  ├── packageId: string
  ├── transactionId: string
  ├── reason: string
  ├── status: string
  ├── createdAt: timestamp
  └── ...
```

## Testing

Test file created: `test/escrow_integration_test.dart`
- Tests initial BLoC state
- Tests escrow release flow
- Tests dispute creation flow
- Mocks Firestore operations

## Usage

### In Tracking Screen
```dart
// Screen automatically subscribes to real-time updates
// No manual refresh needed

// Confirm delivery and release escrow
context.read<PackageBloc>().add(
  EscrowReleaseRequested(
    packageId: package.id,
    transactionId: transactionId,
  ),
);

// File a dispute
context.read<PackageBloc>().add(
  EscrowDisputeRequested(
    packageId: package.id,
    transactionId: transactionId,
    reason: disputeReason,
  ),
);
```

### In Dashboard
```dart
// Dashboard automatically displays active parcels
// With real-time escrow status indicators
// Tapping navigates to tracking screen
```

## Status Indicators

### Escrow Status Colors
- **Held**: Amber/Accent (🔒)
- **Released**: Green/Success (✓)
- **Disputed**: Red/Error (⚠)
- **Cancelled**: Grey (✕)
- **Pending**: Blue/Primary (⏳)

## Real-Time Updates
- Firestore snapshots() provide instant updates
- BLoC streams propagate changes to UI
- No polling or manual refresh required
- Automatic UI rebuilds on data changes
- Cross-device synchronization

## Error Handling
- Try-catch blocks in all async operations
- User-friendly error messages
- Failed status with explanatory text
- Transactional consistency in Firestore operations
