const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Send push notification when a new notification document is created
exports.sendOnCreate = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snapshot, context) => {
        try {
            const notificationData = snapshot.data();

            // Skip if notification is already read
            if (notificationData.is_read === true) {
                console.log('Notification is already marked as read, skipping push notification');
                return null;
            }

            // Get the recipient's user ID
            const recipientId = notificationData.made_to;
            if (!recipientId) {
                console.log('No recipient ID found in notification');
                return null;
            }

            // Get the recipient's FCM token from their user record
            const recipientDoc = await admin.firestore()
                .collection('User')
                .doc(recipientId)
                .get();

            if (!recipientDoc.exists) {
                console.log(`User document not found for ID: ${recipientId}`);
                return null;
            }

            const recipientData = recipientDoc.data();
            const fcmToken = recipientData.fcmToken;

            if (!fcmToken) {
                console.log(`No FCM token found for user: ${recipientId}`);
                return null;
            }

            // Get notification sender's username
            let senderUsername = notificationData.made_by_username || 'Someone';

            if (!senderUsername && notificationData.made_by) {
                try {
                    const senderDoc = await admin.firestore()
                        .collection('User')
                        .doc(notificationData.made_by.id)
                        .get();

                    if (senderDoc.exists) {
                        senderUsername = senderDoc.data().displayName || 'Someone';
                    }
                } catch (error) {
                    console.error('Error fetching sender details:', error);
                }
            }

            // Construct notification message based on type
            let title = 'New Notification';
            let body = '';

            if (notificationData.is_a_like) {
                title = 'New Like';
                body = `${senderUsername} liked your post`;
            } else if (notificationData.is_follow_request) {
                if (notificationData.status === 'pending') {
                    title = 'Follow Request';
                    body = `${senderUsername} requested to follow you`;
                } else {
                    title = 'New Follower';
                    body = `${senderUsername} started following you`;
                }
            } else if (notificationData.is_reply) {
                title = 'New Reply';
                body = `${senderUsername} replied to your comment`;
            } else {
                title = 'New Comment';
                body = `${senderUsername} commented on your post`;
            }

            // Calculate unread notification count for this user
            const unreadNotificationsQuery = await admin.firestore()
                .collection('notifications')
                .where('made_to', '==', recipientId)
                .where('is_read', '==', false)
                .get();
            
            const unreadCount = unreadNotificationsQuery.size;
            console.log(`User ${recipientId} has ${unreadCount} unread notifications`);

            // Construct the message
            const message = {
                notification: {
                    title: title,
                    body: body,
                },
                data: {
                    title: title,
                    body: body,
                    notification_id: context.params.notificationId,
                    post_ref: notificationData.post_ref ? notificationData.post_ref.path : '',
                    made_by: notificationData.made_by ? notificationData.made_by.path : '',
                    is_a_like: String(notificationData.is_a_like || false),
                    is_follow_request: String(notificationData.is_follow_request || false),
                    is_reply: String(notificationData.is_reply || false),
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    type: notificationData.is_a_like ? 'like' :
                        notificationData.is_follow_request ? 'follow' :
                            notificationData.is_reply ? 'reply' : 'comment',
                },
                token: fcmToken,
                // Use high priority for social interactions
                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'luna_kraft_channel',
                        icon: '@mipmap/ic_launcher',
                        color: '#2196F3',
                        priority: 'max',
                    }
                },
                apns: {
                    payload: {
                        aps: {
                            contentAvailable: true,
                            badge: unreadCount,
                            sound: 'default',
                        },
                    },
                },
            };

            // Send the message
            return admin.messaging().send(message)
                .then((response) => {
                    console.log('Successfully sent notification:', response);
                    return null;
                })
                .catch((error) => {
                    console.error('Error sending notification:', error);
                    return null;
                });

        } catch (error) {
            console.error('Error in sendNotificationOnCreate function:', error);
            return null;
        }
    });

// Update user's FCM token when they log in
exports.updateToken = functions.https.onCall(async (data, context) => {
    // Check if user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'You must be logged in to update your FCM token'
        );
    }

    const userId = context.auth.uid;
    const token = data.token;

    if (!token) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'FCM token is required'
        );
    }

    try {
        await admin.firestore()
            .collection('User')
            .doc(userId)
            .update({
                fcmToken: token,
                lastTokenUpdate: admin.firestore.FieldValue.serverTimestamp(),
            });

        return { success: true };
    } catch (error) {
        console.error('Error updating FCM token:', error);
        throw new functions.https.HttpsError(
            'internal',
            'Error updating FCM token',
            error
        );
    }
});

// Remove user's FCM token when they log out
exports.removeToken = functions.https.onCall(async (data, context) => {
    // Check if user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'You must be logged in to remove your FCM token'
        );
    }

    const userId = context.auth.uid;

    try {
        await admin.firestore()
            .collection('User')
            .doc(userId)
            .update({
                fcmToken: admin.firestore.FieldValue.delete(),
                lastTokenUpdate: admin.firestore.FieldValue.serverTimestamp(),
            });

        return { success: true };
    } catch (error) {
        console.error('Error removing FCM token:', error);
        throw new functions.https.HttpsError(
            'internal',
            'Error removing FCM token',
            error
        );
    }
}); 