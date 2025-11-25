# Real-time Updates Testing Guide

## Overview
This document provides comprehensive testing procedures for verifying Firestore stream updates, optimistic UI updates, and cross-device synchronization for the "My Deliveries" feature.

---

## Test Group 4.3.1: Firestore Stream Updates

### Objective
Verify that the accepted parcels list updates in real-time when Firestore data changes.

### Prerequisites
- Firebase project configured
- At least 3 test parcels in Firestore
- Courier user logged in
- Firebase Console access for direct database updates

---

### Test 1.1: Initial Stream Connection

**Purpose:** Verify stream initializes and loads existing data.

#### Steps:
1. Open app and log in as courier
2. Navigate to Browse Requests → "My Deliveries" tab
3. Observe initial data load

#### Expected Results:
- ✅ Loading skeleton appears initially
- ✅ List populates with accepted parcels (if any exist)
- ✅ Parcels sorted by `lastStatusUpdate` (most recent first)
- ✅ No error messages displayed

#### Firebase Console Verification:
```firestore
Collection: parcels
Query: where travelerId == {currentUserId}
OrderBy: lastStatusUpdate desc
```

---

### Test 1.2: Stream Updates on Status Change

**Purpose:** Verify stream emits new data when parcel status changes in Firestore.

#### Steps:
1. App open on "My Deliveries" tab
2. Note a parcel with status "paid" (e.g., ParcelID: `test_parcel_1`)
3. **Via Firebase Console:**
   - Navigate to `parcels/{test_parcel_1}`
   - Update `status` field to `"picked_up"`
   - Update `lastStatusUpdate` to current timestamp
4. Return to app (do NOT refresh manually)
5. Observe the list within 3 seconds

#### Expected Results:
- ✅ Parcel status badge updates to "Picked Up" (orange)
- ✅ Update occurs automatically without manual refresh
- ✅ Parcel moves to top of list (most recent update)
- ✅ No UI flicker or jarring transitions

#### Data Verification:
```json
// Before update
{
  "id": "test_parcel_1",
  "status": "paid",
  "lastStatusUpdate": "2025-11-25T10:00:00.000Z"
}

// After update
{
  "id": "test_parcel_1",
  "status": "picked_up",
  "lastStatusUpdate": "2025-11-25T12:30:00.000Z",
  "metadata": {
    "deliveryStatusHistory": {
      "paid": "2025-11-25T10:00:00.000Z",
      "picked_up": "2025-11-25T12:30:00.000Z"
    }
  }
}
```

---

### Test 1.3: Stream Updates on New Parcel Acceptance

**Purpose:** Verify stream updates when a new parcel is assigned to the courier.

#### Steps:
1. App open on "My Deliveries" tab with N parcels displayed
2. **Via Firebase Console:**
   - Create or update a parcel
   - Set `travelerId` to current user's UID
   - Set `travelerName` to courier's name
   - Set `status` to `"paid"`
3. Observe the list within 3 seconds

#### Expected Results:
- ✅ New parcel appears in the list
- ✅ List count updates from N to N+1
- ✅ New parcel positioned correctly by `lastStatusUpdate`
- ✅ Card displays all parcel information correctly

---

### Test 1.4: Stream Reconnection After Network Interruption

**Purpose:** Verify stream reconnects and syncs after temporary network loss.

#### Steps:
1. App open on "My Deliveries" tab
2. Enable airplane mode on device
3. **Via Firebase Console:** Update a parcel status
4. Wait 5 seconds
5. Disable airplane mode
6. Observe the list within 10 seconds of reconnection

#### Expected Results:
- ✅ Offline indicator displayed during network loss
- ✅ App shows cached data while offline
- ✅ "Back Online" snackbar appears upon reconnection
- ✅ List updates with latest Firestore data after reconnect
- ✅ No duplicate entries or stale data

#### Technical Verification:
```dart
// Check ParcelBloc logs for stream reconnection
// Should see:
// "Connectivity stream emitting: false" (offline)
// "Connectivity stream emitting: true" (back online)
// "Stream reconnected successfully"
```

---

## Test Group 4.3.2: Optimistic Updates

### Objective
Verify UI updates immediately on status change with proper rollback on failure.

---

### Test 2.1: Immediate UI Update

**Purpose:** Verify optimistic update provides instant feedback.

#### Steps:
1. App on "My Deliveries" tab
2. Select parcel with status "paid"
3. Tap "Update Status" button
4. Select "Mark as Picked Up"
5. Confirm action
6. **Immediately observe** the UI (within 100ms)

#### Expected Results:
- ✅ Status badge changes to "Picked Up" instantly
- ✅ Card shows loading overlay briefly
- ✅ Haptic feedback triggers (vibration)
- ✅ Card repositions to top of list
- ✅ Success snackbar appears after server confirms (~500ms)

#### Technical Flow:
```dart
// Timeline of optimistic update
0ms:    User confirms status change
10ms:   HapticHelper.success() triggers
20ms:   Optimistic UI update applied
50ms:   AsyncLoadingState emitted (overlay shown)
500ms:  Server update completes
520ms:  LoadedState with server data emitted
540ms:  Success snackbar displayed
```

---

### Test 2.2: Rollback on Server Failure

**Purpose:** Verify UI reverts to original state when update fails.

#### Steps:
1. **Simulate server failure:**
   - Disconnect from internet after tapping "Update Status"
   - OR use Firebase Console to set security rules to deny update
2. Select parcel with status "paid"
3. Tap "Update Status" → "Mark as Picked Up"
4. Confirm action
5. Observe UI behavior over next 5 seconds

#### Expected Results:
- ✅ Status badge shows "Picked Up" initially (optimistic)
- ✅ Loading overlay appears
- ✅ Retry attempts occur (3 total with exponential backoff)
  - 1st retry: 500ms delay
  - 2nd retry: 1000ms delay
  - 3rd retry: 2000ms delay
- ✅ After final retry failure:
  - Status badge reverts to "Paid"
  - Error snackbar appears: "Failed to update status. Please try again."
  - Retry button shown in snackbar
- ✅ Parcel returns to original position in list

#### Retry Verification:
```dart
// Expected log sequence
"Attempting status update (attempt 1/3)"
"Update failed: NetworkFailure"
"Retrying in 500ms..."
"Attempting status update (attempt 2/3)"
"Update failed: NetworkFailure"
"Retrying in 1000ms..."
"Attempting status update (attempt 3/3)"
"Update failed: NetworkFailure"
"All retry attempts exhausted. Rolling back..."
"Optimistic update rolled back to original state"
```

---

### Test 2.3: Final State Matches Server

**Purpose:** Verify optimistic update is replaced by authoritative server data.

#### Steps:
1. Select parcel with status "paid"
2. Update to "Picked Up"
3. **Via Firebase Console** (immediately after app update):
   - Verify server data includes exact timestamp
   - Check `metadata.deliveryStatusHistory` includes both statuses
4. Compare app UI with Firestore document

#### Expected Results:
- ✅ App status matches Firestore `status` field
- ✅ Timestamp in app matches Firestore `lastStatusUpdate`
- ✅ Delivery history includes both "paid" and "picked_up" timestamps
- ✅ No discrepancies between app and server state

#### Data Consistency Check:
```json
// Firestore document after update
{
  "id": "parcel_123",
  "status": "picked_up",
  "lastStatusUpdate": {
    "_seconds": 1732540800,
    "_nanoseconds": 0
  },
  "metadata": {
    "deliveryStatusHistory": {
      "paid": "2025-11-25T10:00:00.000Z",
      "picked_up": "2025-11-25T12:00:00.000Z"
    }
  }
}
```

---

### Test 2.4: Concurrent Updates Handling

**Purpose:** Verify multiple status updates don't conflict.

#### Steps:
1. App showing 2 parcels: Parcel A (paid), Parcel B (paid)
2. Quickly in succession (within 2 seconds):
   - Update Parcel A to "Picked Up"
   - Update Parcel B to "Picked Up"
3. Observe both updates complete

#### Expected Results:
- ✅ Both parcels show optimistic updates immediately
- ✅ Both show loading overlays
- ✅ Both updates succeed independently
- ✅ Both parcels show success snackbars
- ✅ Final state of both parcels is "Picked Up"
- ✅ No race conditions or conflicts
- ✅ Firestore shows both updates with different timestamps

---

## Test Group 4.3.3: Cross-Device Synchronization

### Objective
Verify updates sync correctly across multiple devices in real-time.

**Note:** Refer to `cross-device-testing-guide.md` for detailed multi-device tests.

---

### Test 3.1: Device 2 Receives Device 1 Update

**Purpose:** Verify Firestore streams propagate updates to all listening devices.

#### Steps:
1. Device 1: Navigate to "My Deliveries" tab
2. Device 2: Navigate to "My Deliveries" tab
3. Both devices show Parcel A (status: "paid")
4. Device 1: Update Parcel A to "Picked Up"
5. Observe Device 2 within 5 seconds

#### Expected Results:
- ✅ Device 1: Instant optimistic update
- ✅ Device 2: Receives stream update within 3 seconds
- ✅ Both devices show identical final state
- ✅ Timestamps match exactly
- ✅ No manual refresh required on Device 2

#### Network Trace:
```
Device 1:
T+0ms:     User taps "Confirm"
T+20ms:    Optimistic UI update
T+50ms:    Firestore write initiated
T+300ms:   Firestore write confirmed
T+320ms:   Stream update received (Device 1)

Device 2:
T+300ms:   Firestore write occurs (Device 1)
T+320ms:   Stream update received (Device 2)
T+340ms:   UI updates with new status
```

---

### Test 3.2: Rapid Multi-Device Updates

**Purpose:** Verify rapid updates from different devices sync correctly.

#### Steps:
1. Device 1 & Device 2: Both on "My Deliveries" tab
2. List shows: Parcel A (paid), Parcel B (paid), Parcel C (paid)
3. Rapid sequence:
   - Device 1: Update Parcel A to "Picked Up" (T+0s)
   - Device 2: Update Parcel B to "Picked Up" (T+1s)
   - Device 1: Update Parcel A to "In Transit" (T+3s)
4. Wait 5 seconds
5. Compare final states on both devices

#### Expected Results:
- ✅ Both devices show:
  - Parcel A: "In Transit"
  - Parcel B: "Picked Up"
  - Parcel C: "Paid"
- ✅ Order by most recent update:
  1. Parcel A (most recent)
  2. Parcel B
  3. Parcel C (least recent)
- ✅ No lost updates or stale data
- ✅ No UI conflicts or errors

---

### Test 3.3: Different Network Speeds

**Purpose:** Verify sync works with asymmetric network conditions.

#### Steps:
1. Device 1: Connected to WiFi (fast)
2. Device 2: Connected to 4G/LTE (slower)
3. Device 1: Update Parcel A status
4. Measure time until Device 2 receives update

#### Expected Results:
- ✅ Device 1 update completes in ~300ms
- ✅ Device 2 receives update within 10 seconds
- ✅ Final states match exactly
- ✅ No data corruption despite speed difference

---

## Performance Benchmarks

| Metric | Target | Acceptable | Notes |
|--------|--------|------------|-------|
| Optimistic UI Update | < 100ms | < 200ms | Immediate user feedback |
| Server Update Time | < 500ms | < 1000ms | With good network |
| Stream Update Propagation | < 2s | < 5s | To other devices |
| Retry Backoff (1st) | 500ms | 500ms | Fixed delay |
| Retry Backoff (2nd) | 1000ms | 1000ms | Exponential |
| Retry Backoff (3rd) | 2000ms | 2000ms | Exponential |
| Offline Sync After Reconnect | < 5s | < 10s | Auto-sync queued updates |
| Cross-Device Sync | < 3s | < 10s | Depending on network |

---

## Testing Checklist

### 4.3.1: Firestore Stream Updates
- [ ] Initial stream connection loads data
- [ ] Status changes reflect in real-time
- [ ] New parcel assignments appear automatically
- [ ] Stream reconnects after network interruption

### 4.3.2: Optimistic Updates
- [ ] UI updates immediately (<100ms)
- [ ] Rollback works on server failure
- [ ] Final state matches server data
- [ ] Concurrent updates handled correctly

### 4.3.3: Cross-Device Synchronization
- [ ] Device 2 receives Device 1 updates
- [ ] Rapid multi-device updates sync properly
- [ ] Works with different network speeds
- [ ] Pull-to-refresh syncs latest data

---

## Troubleshooting

### Issue: Updates Not Appearing in Real-Time

**Symptoms:**
- Changes made in Firebase Console don't appear in app
- Other device updates not received

**Diagnosis Steps:**
1. Check app logs for stream initialization:
   ```
   "ParcelBloc: Watching accepted parcels for user: {userId}"
   "Stream initialized successfully"
   ```

2. Verify Firestore query in Firebase Console:
   ```firestore
   Collection: parcels
   Filter: travelerId == {userId}
   OrderBy: lastStatusUpdate DESC
   ```

3. Check composite index status:
   - Firebase Console → Firestore → Indexes
   - Verify index on `(travelerId, lastStatusUpdate)` is ENABLED

**Solutions:**
- Restart app to reinitialize stream
- Verify network connection
- Check Firebase security rules allow read access
- Ensure composite index created and active

---

### Issue: Optimistic Updates Not Rolling Back

**Symptoms:**
- UI shows updated status but Firestore shows original
- Stale data persists after failed update

**Diagnosis Steps:**
1. Check error logs for retry mechanism:
   ```
   "Update attempt 1/3 failed: {error}"
   "Retrying in 500ms..."
   ```

2. Verify rollback logic in BLoC:
   ```dart
   if (attempt >= 3) {
     // Should rollback optimistic update
     emit(LoadedState(data: dataWithOriginalParcel));
   }
   ```

**Solutions:**
- Verify retry mechanism active (3 attempts)
- Check for exceptions preventing rollback
- Restart app to clear optimistic state
- Manually refresh data

---

### Issue: Slow Cross-Device Sync

**Symptoms:**
- Updates take >10 seconds to appear on other devices
- Inconsistent sync times

**Diagnosis Steps:**
1. Test network speed on both devices
2. Check Firestore usage limits in Firebase Console
3. Verify no firewall blocking Firestore connections (port 443)
4. Check app logs for stream latency

**Solutions:**
- Improve network connection
- Verify not hitting Firestore quota limits
- Check for background apps consuming bandwidth
- Consider implementing pagination if many parcels

---

## Reporting Test Results

### Test Pass Criteria
- All 12 tests complete successfully
- Performance benchmarks met (target or acceptable)
- No critical issues found
- All checkboxes marked ✅

### Test Report Template

```markdown
## Real-time Updates Test Report

**Date:** {date}
**Tester:** {name}
**App Version:** {version}
**Device(s):** {device info}

### Test Results Summary
- Tests Passed: X/12
- Tests Failed: X/12
- Performance: Meets Target / Meets Acceptable / Below Acceptable

### Failed Tests
1. Test Name: {test}
   - Expected: {expected behavior}
   - Actual: {actual behavior}
   - Logs: {relevant logs or screenshots}

### Performance Metrics
| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Optimistic UI Update | <100ms | Xms | ✅/❌ |
| ... | ... | ... | ... |

### Issues Found
- Issue 1: {description, steps to reproduce, severity}
- Issue 2: ...

### Recommendations
- {any improvements or fixes needed}
```

---

## Conclusion

This testing guide ensures comprehensive verification of:
1. **Firestore stream updates** work reliably in real-time
2. **Optimistic updates** provide instant feedback with proper error handling
3. **Cross-device synchronization** maintains data consistency

All tests must pass before considering the real-time updates feature production-ready.
