# Specification: Local and Push Notifications

## Goal
Implement a comprehensive notification system using Firebase Cloud Messaging (FCM) for push notifications and flutter_local_notifications for local notifications, enabling real-time chat message alerts across Android, iOS, and web platforms, even when the app is closed or terminated.

## User Stories
- As a user, I want to receive push notifications for new chat messages when the app is in the background or closed, so that I never miss important messages
- As a user, I want to see a notifications history screen showing all my notifications from Firebase, so that I can review past alerts
- As a user, I want to tap on a notification and be taken directly to the relevant chat conversation, so that I can quickly respond

## Specific Requirements

**FCM Push Notifications Setup**
- Add firebase_messaging package to pubspec.yaml dependencies
- Configure FCM for Android by adding google-services.json and updating AndroidManifest.xml with notification permissions and services
- Configure FCM for iOS by adding GoogleService-Info.plist, enabling push notifications capability, and requesting notification permissions
- Configure FCM for web by adding firebase-messaging-sw.js service worker and Firebase web config
- Store FCM device tokens in Firestore users collection under 'fcmTokens' array field for multi-device support
- Implement token refresh handler to update Firestore when FCM token changes
- Handle notification permissions requests on app launch with proper user prompts
- Configure notification channels for Android (chat messages, system alerts) with high priority and sound

**Local Notifications Integration**
- Leverage existing flutter_local_notifications package already in pubspec.yaml
- Extend ChatNotificationService to handle both local and push notifications
- Display local notifications when receiving FCM messages in foreground state
- Configure Android notification details with custom sound, vibration pattern, and large icon
- Configure iOS/Darwin notification details with badge updates, sound, and alert presentation
- Set notification payload with chat ID for tap navigation handling
- Implement notification grouping for multiple messages from same chat

**Background and Terminated Message Handling**
- Implement FirebaseMessaging.onBackgroundMessage handler as top-level function
- Handle FCM data-only messages when app is in background or terminated state
- Trigger local notifications from background message handler
- Extract chat details (sender name, message content, chat ID) from FCM payload
- Update app badge count based on total unread messages across all chats
- Ensure background handler is properly registered before runApp in main.dart

**Notification Data Models**
- Create NotificationModel extending base entity with fields: id, userId, type, title, body, data, timestamp, isRead, chatId
- Define NotificationType enum with values: chatMessage, systemAlert, announcement, reminder
- Implement fromJson and toJson methods for Firestore serialization
- Create NotificationEntity in domain layer following existing entity patterns
- Map FCM RemoteMessage to NotificationModel for storage in Firestore

**Firebase Notifications Collection**
- Store all notifications in Firestore 'notifications' collection with userId indexing
- Structure notification documents with fields: userId, type, title, body, data (map), timestamp, isRead, chatId, senderId, senderName
- Implement compound query on userId and timestamp for efficient pagination
- Add Firestore security rules to ensure users can only read their own notifications
- Set up automatic cleanup with TTL for notifications older than 30 days using Firestore lifecycle policies

**NotificationBloc State Management**
- Create NotificationBloc extending BaseBloC following existing chat BLoC pattern
- Define NotificationEvent sealed class with: LoadNotifications, MarkAsRead, MarkAllAsRead, DeleteNotification, ClearAll
- Define NotificationState sealed class with: NotificationInitial, NotificationsLoading, NotificationsLoaded, NotificationError
- Implement real-time Firestore stream subscription in LoadNotifications handler
- Handle StreamSubscription lifecycle in close method to prevent memory leaks
- Include unreadCount calculation in NotificationsLoaded state
- Emit loading and error states using BaseBloC helper methods

**Notification Repository and Use Cases**
- Create NotificationRepository interface in domain/repositories with methods: watchNotifications, markAsRead, markAllAsRead, deleteNotification, clearAll
- Implement NotificationRepositoryImpl in data/repositories using Firestore and NetworkInfo pattern from ChatRepository
- Create NotificationRemoteDataSource in data/datasources for Firestore operations
- Implement NotificationUseCase in domain/usecases with methods wrapping repository calls
- Return Either<Failure, T> types for error handling consistency
- Register repository, datasource, and usecase in injection_container.dart using GetIt

**NotificationsScreen UI Component**
- Create NotificationsScreen as StatefulWidget in features/notifications/presentation/screens
- Use BlocConsumer to listen to NotificationBloc states and rebuild UI
- Display notifications in grouped ListView by date (Today, Yesterday, This Week, Earlier)
- Implement pull-to-refresh with RefreshIndicator to reload notifications
- Show notification cards with icon, title, body, timestamp using timeago formatting, and unread indicator
- Add swipe-to-delete using flutter_slidable package following ChatsListScreen pattern
- Include mark-as-read action on notification tap and navigate to chat if chatId present
- Display empty state with icon and message when no notifications exist
- Add app bar actions for mark all as read and clear all with confirmation dialogs

**Notification Tap Handling and Navigation**
- Implement onDidReceiveNotificationResponse callback in flutter_local_notifications initialization
- Parse notification payload JSON to extract navigation data (chatId, screen)
- Use NavigationService from injection_container to navigate to ChatScreen with chatId parameter
- Handle navigation when app is in background or foreground states
- Update routes.dart to support deep linking to chat screen with ID parameter
- Mark notification as read in Firestore when user taps and navigates

**Chat System Integration**
- Update ChatRemoteDataSource sendMessage method to trigger FCM notification via Cloud Function
- Pass sender name, message preview, and chat ID in FCM data payload
- Modify ChatBloc to refresh notification badge count on new messages
- Integrate NotificationService initialization in AppConfig.init after Firebase initialization
- Request notification permissions on first app launch with explanation dialog
- Display in-app notification banner when receiving message while on different chat screen

**Service Layer Architecture**
- Create NotificationService singleton class managing FCM and local notifications
- Implement initialize method called from main.dart before runApp
- Handle FCM token retrieval and storage in Firestore users/{userId}/fcmTokens
- Subscribe to FirebaseMessaging.onMessage stream for foreground notifications
- Coordinate between FCM, local notifications, and NotificationBloc
- Provide methods: requestPermissions, getToken, subscribeToTopic, unsubscribeFromTopic
- Register NotificationService in injection_container as singleton

**Platform-Specific Configuration Files**
- Android: Update AndroidManifest.xml with POST_NOTIFICATIONS permission, INTERNET permission, and notification service metadata
- Android: Create notification icon drawables in res/drawable for different densities
- Android: Update android/app/build.gradle with google-services plugin and minimum SDK 21
- iOS: Update Info.plist with notification usage descriptions and background modes
- iOS: Enable Push Notifications capability in Xcode project settings
- Web: Create firebase-messaging-sw.js in web folder with Firebase SDK imports and message handler
- Web: Update web/index.html to include Firebase scripts and initialize messaging

**Testing Strategy**
- Unit test NotificationBloc events and state transitions using bloc_test
- Mock NotificationRepository in BLoC tests using mockito
- Test FCM token refresh and storage logic
- Test notification payload parsing and navigation logic
- Test background message handler with simulated FCM messages
- Integration test notification display when app is in different states (foreground, background, terminated)
- Test notification permissions flow on different platforms
- Verify Firestore security rules with authorized and unauthorized access attempts

## Out of Scope
- In-app notification banner customization with different styles or animations
- Notification sound customization or user-selectable ringtones
- Rich media notifications with images or action buttons
- Scheduled notifications or reminder features
- Notification preferences or settings screen for granular control
- Analytics or tracking of notification open rates
- Silent notifications for data sync without user alerts
- Notification categories or filtering by type in UI
- Export notifications history feature
- Notification search functionality
