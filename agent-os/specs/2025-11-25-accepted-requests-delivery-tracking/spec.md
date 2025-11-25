`# Specification: Accepted Requests Delivery Tracking

## Goal
Enable couriers to view and manage their accepted delivery requests with real-time status tracking and communication features, improving delivery workflow efficiency and transparency for all parties involved.

## User Stories
- As a courier, I want to view all my accepted delivery requests in a dedicated tab so that I can easily manage my active deliveries
- As a courier, I want to update the delivery status through clear progression stages so that senders and receivers stay informed
- As a courier, I want to quickly access chat with the parcel owner so that I can communicate about pickup and delivery details

## Specific Requirements

**Two-Tab Interface on Browse Requests Screen**
- Add TabBar with two tabs: "Available" and "My Deliveries"
- Available tab shows existing browse requests functionality (parcels with status "created" or "paid")
- My Deliveries tab shows parcels where current user is the traveler (travelerId matches current user ID)
- Use DefaultTabController pattern similar to tracking_screen.dart implementation
- Preserve existing search and filter functionality on Available tab
- Add status-based filtering on My Deliveries tab (Active, Completed)
- Include real-time stream updates for My Deliveries list using watchUserParcels with traveler filtering

**Delivery Status Progression System**
- Extend ParcelStatus enum to include new delivery stages: pickedUp, inTransit, arrived, delivered
- Display current status prominently on each delivery card in My Deliveries tab
- Create status update button/action sheet that shows only the next valid status in progression
- Status flow: paid -> pickedUp -> inTransit -> arrived -> delivered
- Prevent status regression (cannot move backwards in the flow)
- Update Firestore document status field with timestamp tracking for each status change
- Show visual status indicator (colored badge/chip) similar to tracking_screen.dart implementation

**Delivery Card UI for My Deliveries Tab**
- Display package category, price, route (origin to destination), and current status
- Show receiver contact information (name, phone) for delivery coordination
- Include sender name and quick chat access button
- Display estimated delivery date with urgency indicator if within 48 hours
- Add prominent "Update Status" button that opens action sheet with next status option
- Use card layout similar to browse_requests_screen.dart with additional delivery-specific information
- Include package weight and dimensions for reference during delivery

**Status Update Action Sheet**
- Bottom sheet modal with status progression options
- Show current status with checkmark
- Display next available status as primary action button
- Include confirmation dialog for status changes with brief description of what each status means
- Disable delivered status until arrived status is confirmed
- Show loading indicator during status update
- Display success snackbar after successful update

**Chat Navigation from Accepted Request**
- Add chat icon button on each delivery card in My Deliveries tab
- Navigate to ChatScreen with sender information (chatId, otherUserId, otherUserName, otherUserAvatar)
- Generate or retrieve existing chatId between courier and sender using format: "{userId1}_{userId2}" (sorted alphabetically)
- Use existing chat functionality without modifications
- Include sender details from parcel.sender entity

**BLoC Events and States**
- Add ParcelWatchAcceptedParcelsRequested event to watch parcels where user is traveler
- Add ParcelAcceptedListUpdated event to update accepted parcels list in state
- Extend ParcelData state to include acceptedParcels: List<ParcelEntity>
- Reuse existing ParcelUpdateStatusRequested event for status updates
- Add AsyncLoadingState overlay during status updates without hiding current data

**Data Model Changes**
- Add deliveryStatusHistory map to ParcelEntity metadata field to track status timestamps
- Extend ParcelStatus enum with: pickedUp, inTransit, arrived
- Add lastStatusUpdate DateTime field to ParcelEntity for sorting recent updates
- Add courierNotes optional String field to ParcelEntity for delivery notes
- Ensure travelerId and travelerName fields are properly set when request is accepted

**Firestore Schema Updates**
- Update parcels collection with new status values in status field
- Add deliveryStatusHistory subcollection or map field with structure: {status: timestamp}
- Add lastStatusUpdate timestamp field for efficient querying and sorting
- Create composite index on (travelerId, status) for efficient My Deliveries queries
- Add courierNotes field (optional) for delivery-specific notes

**Real-time Updates**
- Use Firestore streams (watchUserParcels) filtered by travelerId for My Deliveries tab
- Update UI automatically when sender makes changes to parcel details
- Show real-time status changes from other devices if courier uses multiple devices
- Implement optimistic updates for status changes with rollback on error

**Error Handling**
- Display error message if status update fails with retry option
- Handle offline scenarios gracefully with cached data and queue updates
- Validate status progression before sending to backend
- Show appropriate error messages for network failures
- Implement retry mechanism for failed status updates with exponential backoff

## Existing Code to Leverage

**tracking_screen.dart TabBar Implementation**
- Use TabController with TickerProviderStateMixin pattern for managing two tabs
- Implement TabBar and TabBarView structure for Available and My Deliveries tabs
- Apply similar visual styling for tab indicators and selected states
- Use same approach for handling tab state persistence across navigation

**browse_requests_screen.dart Card Layout**
- Reuse _buildRequestCard widget structure for consistency across Available and My Deliveries tabs
- Adapt existing filter and search functionality for My Deliveries tab
- Use same empty state patterns for when no deliveries are active
- Apply consistent card styling, spacing, and animations using flutter_staggered_animations

**ChatScreen Navigation Pattern**
- Use existing navigation service pattern from browse_requests_screen.dart
- Pass required arguments (chatId, otherUserId, otherUserName, otherUserAvatar) using Get.arguments map
- Generate chatId using format: sorted userId combination separated by underscore
- Leverage existing chat infrastructure without modifications

**ParcelBloc Stream Handling**
- Follow emit.forEach pattern from _onLoadRequested for real-time My Deliveries updates
- Use existing watchUserParcels stream with additional traveler filtering
- Implement AsyncLoadingState pattern for non-blocking status updates
- Maintain current data in state during loading operations

**ParcelEntity and Status Management**
- Extend existing ParcelStatus enum with new delivery stages
- Use existing copyWith method for creating updated parcel entities
- Apply consistent status color coding from tracking_screen.dart
- Leverage existing status display name mapping pattern

## Out of Scope
- Multi-package batch status updates (update only one parcel at a time)
- GPS tracking or live location sharing during delivery
- Proof of delivery photo capture (implement in future iteration)
- Delivery signature collection
- Automated status updates based on geolocation
- Delivery route optimization or navigation
- Package scanning with QR/barcode
- Delivery time slot scheduling
- Customer rating system for completed deliveries
- Delivery history analytics or reports beyond basic list view
