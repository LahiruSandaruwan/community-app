import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();

  // Initialize FCM
  Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // Save token to user profile
        if (_authService.currentUser != null) {
          await _authService.updateFcmToken(
            _authService.currentUser!.uid,
            token,
          );
        }
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
        if (_authService.currentUser != null) {
          _authService.updateFcmToken(
            _authService.currentUser!.uid,
            newToken,
          );
        }
      });

      // Configure foreground notification presentation
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } else {
      print('User declined or has not accepted permission');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received:');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // You can show a local notification or update UI here
    // For now, we'll just log it
  }

  // Handle notification tap (when app is in background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped:');
    print('Data: ${message.data}');

    // Navigate to specific screen based on notification data
    // Example: Navigate to chat screen if groupChatId is present
    if (message.data.containsKey('groupChatId')) {
      String groupChatId = message.data['groupChatId'];
      print('Navigate to group chat: $groupChatId');
      // TODO: Implement navigation to chat screen
    }
  }

  // Send notification (would typically be done from backend/Cloud Functions)
  // This is just a placeholder to show the structure
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // In a real app, you would call a Cloud Function to send the notification
    // using the Firebase Admin SDK on the backend
    print('Would send notification to user: $userId');
    print('Title: $title');
    print('Body: $body');
    print('Data: $data');

    // Example Cloud Function code (to be implemented in Firebase):
    /*
    exports.sendNotification = functions.firestore
      .document('groupChats/{groupChatId}/messages/{messageId}')
      .onCreate(async (snap, context) => {
        const message = snap.data();
        const groupChatId = context.params.groupChatId;

        // Get group chat members
        const groupChat = await admin.firestore()
          .collection('groupChats')
          .doc(groupChatId)
          .get();

        const memberIds = groupChat.data().memberIds;

        // Get FCM tokens for all members except sender
        const tokens = [];
        for (const memberId of memberIds) {
          if (memberId !== message.senderId) {
            const user = await admin.firestore()
              .collection('users')
              .doc(memberId)
              .get();
            if (user.data().fcmToken) {
              tokens.push(user.data().fcmToken);
            }
          }
        }

        // Send notification
        if (tokens.length > 0) {
          await admin.messaging().sendMulticast({
            tokens: tokens,
            notification: {
              title: message.senderName,
              body: message.content,
            },
            data: {
              groupChatId: groupChatId,
              messageId: context.params.messageId,
            },
          });
        }
      });
    */
  }

  // Subscribe to topic (for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }
}
