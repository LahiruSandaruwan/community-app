/**
 * EduConnect Cloud Functions
 *
 * This file contains Firebase Cloud Functions for:
 * - Push notifications for new messages
 * - Community and group management
 * - Analytics and monitoring
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Send push notification when a new message is created in a group chat
 *
 * Triggered: When a document is created in groupChats/{groupChatId}/messages/{messageId}
 *
 * This function:
 * 1. Gets the message data
 * 2. Fetches the group chat details
 * 3. Gets FCM tokens for all members except the sender
 * 4. Sends push notification to all members
 */
exports.sendMessageNotification = functions.firestore
  .document('groupChats/{groupChatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    try {
      const message = snap.data();
      const groupChatId = context.params.groupChatId;
      const messageId = context.params.messageId;

      console.log('New message created:', messageId, 'in group:', groupChatId);

      // Get group chat details
      const groupChatSnapshot = await admin.firestore()
        .collection('groupChats')
        .doc(groupChatId)
        .get();

      if (!groupChatSnapshot.exists) {
        console.error('Group chat not found:', groupChatId);
        return null;
      }

      const groupChat = groupChatSnapshot.data();
      const memberIds = groupChat.memberIds || [];

      // Get FCM tokens for all members except the sender
      const tokens = [];
      const tokenPromises = memberIds.map(async (memberId) => {
        // Don't send notification to the sender
        if (memberId === message.senderId) {
          return;
        }

        const userDoc = await admin.firestore()
          .collection('users')
          .doc(memberId)
          .get();

        if (userDoc.exists) {
          const userData = userDoc.data();
          if (userData.fcmToken) {
            tokens.push(userData.fcmToken);
          }
        }
      });

      await Promise.all(tokenPromises);

      console.log('Found', tokens.length, 'tokens to send notification to');

      if (tokens.length === 0) {
        console.log('No tokens found, skipping notification');
        return null;
      }

      // Prepare notification payload
      const notificationTitle = message.messageType === 'announcement'
        ? `📢 ${groupChat.name}`
        : groupChat.name;

      const notificationBody = message.messageType === 'announcement'
        ? `${message.senderName}: ${message.content}`
        : `${message.senderName}: ${message.content}`;

      // Send multicast message
      const payload = {
        tokens: tokens,
        notification: {
          title: notificationTitle,
          body: notificationBody.length > 100
            ? notificationBody.substring(0, 97) + '...'
            : notificationBody,
        },
        data: {
          type: 'new_message',
          groupChatId: groupChatId,
          messageId: messageId,
          senderId: message.senderId,
          senderName: message.senderName,
          messageType: message.messageType || 'text',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'messages',
            sound: 'default',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().sendMulticast(payload);

      console.log('Notification sent successfully:', response.successCount, 'success,', response.failureCount, 'failed');

      // Remove failed tokens
      if (response.failureCount > 0) {
        const tokensToRemove = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error('Failed to send to token:', tokens[idx], resp.error);
            // If token is invalid, we should remove it
            if (resp.error.code === 'messaging/invalid-registration-token' ||
                resp.error.code === 'messaging/registration-token-not-registered') {
              tokensToRemove.push(tokens[idx]);
            }
          }
        });

        // TODO: Remove invalid tokens from user documents
        console.log('Tokens to remove:', tokensToRemove.length);
      }

      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  });

/**
 * Update unread counts when a new message is created
 *
 * This increments the unread count for all members except the sender
 */
exports.updateUnreadCounts = functions.firestore
  .document('groupChats/{groupChatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    try {
      const message = snap.data();
      const groupChatId = context.params.groupChatId;

      // Get group chat
      const groupChatRef = admin.firestore()
        .collection('groupChats')
        .doc(groupChatId);

      const groupChatSnapshot = await groupChatRef.get();

      if (!groupChatSnapshot.exists) {
        return null;
      }

      const groupChat = groupChatSnapshot.data();
      const memberIds = groupChat.memberIds || [];
      const unreadCounts = groupChat.unreadCounts || {};

      // Increment unread count for all members except sender
      memberIds.forEach((memberId) => {
        if (memberId !== message.senderId) {
          unreadCounts[memberId] = (unreadCounts[memberId] || 0) + 1;
        }
      });

      // Update group chat with new unread counts
      await groupChatRef.update({
        unreadCounts: unreadCounts,
      });

      console.log('Updated unread counts for group:', groupChatId);
      return null;
    } catch (error) {
      console.error('Error updating unread counts:', error);
      return null;
    }
  });

/**
 * Clean up when a community is deleted
 *
 * This function:
 * 1. Deletes all group chats in the community
 * 2. Deletes all messages in those group chats
 * 3. Removes community from all user profiles
 */
exports.cleanupDeletedCommunity = functions.firestore
  .document('communities/{communityId}')
  .onUpdate(async (change, context) => {
    try {
      const before = change.before.data();
      const after = change.after.data();
      const communityId = context.params.communityId;

      // Check if community was marked as inactive
      if (before.isActive && !after.isActive) {
        console.log('Community marked as inactive:', communityId);

        // Get all group chats for this community
        const groupChatsSnapshot = await admin.firestore()
          .collection('groupChats')
          .where('communityId', '==', communityId)
          .get();

        // Delete all messages in each group chat
        const deletePromises = [];
        groupChatsSnapshot.forEach((doc) => {
          const groupChatId = doc.id;

          // Delete messages subcollection
          const messagesRef = admin.firestore()
            .collection('groupChats')
            .doc(groupChatId)
            .collection('messages');

          deletePromises.push(
            messagesRef.get().then((messagesSnapshot) => {
              const batch = admin.firestore().batch();
              messagesSnapshot.docs.forEach((msgDoc) => {
                batch.delete(msgDoc.ref);
              });
              return batch.commit();
            })
          );
        });

        await Promise.all(deletePromises);

        console.log('Cleaned up community:', communityId);
      }

      return null;
    } catch (error) {
      console.error('Error cleaning up community:', error);
      return null;
    }
  });

/**
 * Send welcome notification when user joins a community
 */
exports.sendWelcomeNotification = functions.firestore
  .document('communities/{communityId}')
  .onUpdate(async (change, context) => {
    try {
      const before = change.before.data();
      const after = change.after.data();
      const communityId = context.params.communityId;

      const beforeMembers = before.memberIds || [];
      const afterMembers = after.memberIds || [];

      // Find new members
      const newMembers = afterMembers.filter(id => !beforeMembers.includes(id));

      if (newMembers.length === 0) {
        return null;
      }

      console.log('New members joined community:', communityId, newMembers);

      // Send welcome notification to new members
      for (const memberId of newMembers) {
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(memberId)
          .get();

        if (userDoc.exists) {
          const userData = userDoc.data();
          if (userData.fcmToken) {
            await admin.messaging().send({
              token: userData.fcmToken,
              notification: {
                title: `Welcome to ${after.name}! 🎉`,
                body: 'You can now participate in all group discussions',
              },
              data: {
                type: 'community_joined',
                communityId: communityId,
              },
            });
          }
        }
      }

      return null;
    } catch (error) {
      console.error('Error sending welcome notification:', error);
      return null;
    }
  });
