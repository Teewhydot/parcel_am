# Specification: Parcel Request Acceptance Push Notifications

## Goal
Implement push notifications to alert parcel senders when their parcel send request is accepted by a traveler, leveraging the existing FCM infrastructure to enable real-time awareness and seamless navigation to request details.

## User Stories
- As a parcel sender, I want to receive a push notification when someone accepts my parcel request, so that I am immediately aware of the acceptance
- As a parcel sender, I want to tap the notification to view the accepted request details and the traveler information, so that I can quickly see who will transport my parcel

## Specific Requirements

**Extend NotificationType Enum**
- Add new notification type `parcelRequestAccepted` to the existing NotificationType enum in `/lib/core/enums/notification_type.dart`
- Update NotificationTypeExtension with mapping for 'parcel_request_accepted' string value
- Follow the existing pattern used for chatMessage, systemAlert, announcement, and reminder types

**Notification Payload Structure for Parcel Acceptance**
- Define FCM data payload with keys: type='parcel_request_accepted', parcelId, travelerId, travelerName, origin, destination, price, category
- Include title formatted as "Request Accepted!" and body formatted as "{travelerName} accepted your parcel request from {origin} to {destination}"
- Ensure payload includes all necessary data for navigation and display without requiring additional Firestore queries
- Follow the same JSON structure pattern used in existing chat notifications with data and notification sections

**Trigger Notification from assignTraveler Backend Operation**
- Create Cloud Function or backend trigger that fires when `assignTraveler` method updates parcel document with travelerId
- Extract sender userId from parcel document's `sender.userId` field to identify notification recipient
- Query Firestore users collection to retrieve sender's FCM tokens from `fcmTokens` array field
- Send FCM notification to all registered tokens for multi-device support using Firebase Admin SDK
- Include comprehensive error handling for cases where sender has no FCM tokens or tokens are invalid

**Extend NotificationService for Parcel Notifications**
- Add new notification channel 'parcel_updates' for Android with high priority, sound, and vibration enabled
- Configure channel alongside existing 'chat_messages' channel in `_configureAndroidChannels` method
- Update `handleForegroundMessage` to detect parcel_request_accepted type and display appropriate local notification
- Ensure background handler `firebaseMessagingBackgroundHandler` can process parcel acceptance notifications when app is terminated

**Navigation Handling for Parcel Notification Tap**
- Update `handleNotificationTap` method in NotificationService to parse parcelId from payload
- Navigate to RequestDetailsScreen using Routes.requestDetails with parcelId argument when notification type is parcel_request_accepted
- Mark notification as read in Firestore notifications collection upon tap
- Update badge count after navigation using existing `_updateBadgeCount` method

**Update NotificationEntity and NotificationModel**
- Add optional field `parcelId` to NotificationEntity alongside existing chatId field
- Update NotificationModel.fromRemoteMessage to extract parcelId from FCM data payload
- Ensure toJson and fromJson methods handle parcelId serialization for Firestore storage
- Maintain backward compatibility with existing notification documents that lack parcelId field

**Store Parcel Notifications in Firestore**
- Save parcel acceptance notifications to 'notifications' collection with userId index for querying
- Include fields: userId (sender's ID), type (parcel_request_accepted), title, body, parcelId, travelerId, travelerName, timestamp, isRead=false
- Leverage existing NotificationRemoteDataSource.saveNotification method from chat notification implementation
- Apply same 30-day TTL cleanup policy using Firestore lifecycle rules

**Backend Trigger Implementation Approach**
- Create Firebase Cloud Function triggered onUpdate for parcels collection documents
- Check if travelerId field changed from null to a value and status changed to 'paid' indicating acceptance
- Retrieve sender's userId and FCM tokens, construct notification payload, and send via Firebase Admin SDK sendMulticast
- Log notification delivery status and handle token refresh for invalid tokens using existing patterns
- Deploy function to Firebase project and test with parcel acceptance flow

## Existing Code to Leverage

**NotificationService in /lib/core/services/notification_service.dart**
- Reuse initialize, handleForegroundMessage, handleNotificationTap, and _displayLocalNotification methods
- Extend _configureAndroidChannels to add 'parcel_updates' channel alongside 'chat_messages'
- Follow the same pattern for parsing payload JSON and extracting navigation data from NotificationResponse
- Use existing badge count management and Firestore integration patterns

**NotificationEntity and NotificationModel from /lib/features/notifications/domain/entities/**
- Extend existing entity with optional parcelId field following the same pattern as chatId field
- Reuse fromJson, toJson, and copyWith methods with parcelId parameter added
- Leverage NotificationModel.fromRemoteMessage factory to map FCM payload to model instance

**ParcelEntity and assignTraveler Operation**
- Use existing ParcelEntity structure with sender.userId, travelerId, travelerName, route.origin, route.destination, price, category fields
- Trigger notification after successful assignTraveler operation in ParcelRemoteDataSourceImpl updates parcel document
- Access parcel data from Firestore snapshot in Cloud Function trigger to extract all notification details

**Existing FCM Infrastructure from Chat Notifications**
- Reuse Firebase Cloud Messaging configuration, token management, and multi-device support patterns
- Follow same notification channels setup for Android and iOS notification presentation settings
- Use existing NotificationRemoteDataSource for saving notifications to Firestore and marking as read

**RequestDetailsScreen Navigation Pattern**
- Navigate to existing RequestDetailsScreen at `/lib/features/parcel_am_core/presentation/screens/request_details_screen.dart`
- Pass parcelId as argument using Routes.requestDetails route following same pattern as chat navigation with chatId
- Screen already displays traveler information, route details, and acceptance status requiring no UI changes

## Out of Scope
- Notifications for parcel status changes beyond initial acceptance (in-transit, delivered, cancelled updates)
- In-app notification banners or toast messages when receiving parcel acceptance notifications
- Notification preferences or settings to disable parcel acceptance notifications
- Rich media notifications with parcel images or map previews
- Action buttons in notifications for quick actions like contacting traveler
- Notification grouping or bundling multiple parcel acceptances
- Email or SMS notifications as alternatives to push notifications
- Analytics or tracking of notification delivery rates and open rates
- Notification sound customization or user-selectable notification tones
- Silent background notifications for data synchronization without user alerts
