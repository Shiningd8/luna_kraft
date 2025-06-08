exports.sendIOSTerminatedNotification = async (snapshot, context) => {
  try {
    const notificationId = context.params.notificationId;
    console.log(`Function triggered for document: ${notificationId}`);
    console.log('Snapshot type:', typeof snapshot);
    console.log('Snapshot keys:', Object.keys(snapshot));
    
    // Initialize Firebase Admin
    const admin = require('firebase-admin');
    if (!admin.apps.length) {
      admin.initializeApp();
    }
    
    // Directly fetch the notification document from Firestore
    console.log(`Fetching notification document directly from Firestore: ${notificationId}`);
    const notificationDoc = await admin.firestore()
      .collection('notifications')
      .doc(notificationId)
      .get();
    
    if (!notificationDoc.exists) {
      console.log(`Notification document not found in Firestore: ${notificationId}`);
      return null;
    }
    
    // Get the data directly from the document
    const notificationData = notificationDoc.data();
    console.log('Notification data from direct Firestore access:', JSON.stringify(notificationData));
    
    if (!notificationData || Object.keys(notificationData).length === 0) {
      console.log('No notification data found');
      return null;
    }
    
    // Check if notification is already read
    if (notificationData.is_read === true) {
      console.log('Notification is already read, skipping');
      return null;
    }
    
    // Check if notification has already been delivered
    if (notificationData.delivered === true) {
      console.log('Notification already delivered, skipping');
      return null;
    }
    
    // Get recipient user
    const recipientId = notificationData.made_to;
    if (!recipientId) {
      console.log('No recipient ID found');
      return null;
    }
    
    console.log(`Fetching user document for: ${recipientId}`);
    const recipientDoc = await admin.firestore().collection('User').doc(recipientId).get();
    
    if (!recipientDoc.exists) {
      console.log(`User document not found: ${recipientId}`);
      return null;
    }
    
    const recipientData = recipientDoc.data();
    
    // Check if app is in foreground
    if (recipientData.app_state === 'foreground') {
      console.log('User app is in foreground, skipping push notification');
      return null;
    }
    
    const fcmToken = recipientData.fcmToken;
    
    if (!fcmToken) {
      console.log(`No FCM token for user: ${recipientId}`);
      return null;
    }
    
    console.log(`Found FCM token: ${fcmToken.substring(0, 10)}...`);
    
    // Get notification sender's username from the notification data
    let senderUsername = notificationData.made_by_username || 'Someone';
    
    // If we don't have a username and have a made_by reference, try to get the username
    if (!senderUsername && notificationData.made_by) {
      try {
        let senderId;
        
        // Handle the reference format from the screenshot
        if (typeof notificationData.made_by === 'string') {
          // If it's a path like "/User/IJ5gCwmzDheIJRoudIHeW9e6fw1"
          if (notificationData.made_by.startsWith('/')) {
            const parts = notificationData.made_by.split('/');
            senderId = parts[parts.length - 1];
          } else {
            senderId = notificationData.made_by;
          }
        } else if (notificationData.made_by && notificationData.made_by.id) {
          // If it's a document reference with id property
          senderId = notificationData.made_by.id;
        } else if (notificationData.made_by && notificationData.made_by.path) {
          // If it's a document reference with path property
          const parts = notificationData.made_by.path.split('/');
          senderId = parts[parts.length - 1];
        }
        
        if (senderId) {
          console.log(`Looking up sender with ID: ${senderId}`);
          const senderDoc = await admin.firestore().collection('User').doc(senderId).get();
          
          if (senderDoc.exists) {
            const senderData = senderDoc.data();
            // Prioritize displayName over user_name
            senderUsername = senderData.displayName || senderData.user_name || 'Someone';
            console.log(`Found sender name: ${senderUsername}`);
          }
        }
      } catch (error) {
        console.error('Error fetching sender:', error);
        // Continue with default name if there's an error
      }
    }
    
    // Also try to get the sender's display name directly if we only have made_by_username
    if (senderUsername === notificationData.made_by_username && notificationData.made_by) {
      try {
        let senderId;
        
        // Similar logic to extract sender ID as above
        if (typeof notificationData.made_by === 'string') {
          if (notificationData.made_by.startsWith('/')) {
            const parts = notificationData.made_by.split('/');
            senderId = parts[parts.length - 1];
          } else {
            senderId = notificationData.made_by;
          }
        } else if (notificationData.made_by && notificationData.made_by.id) {
          senderId = notificationData.made_by.id;
        } else if (notificationData.made_by && notificationData.made_by.path) {
          const parts = notificationData.made_by.path.split('/');
          senderId = parts[parts.length - 1];
        }
        
        if (senderId) {
          const senderDoc = await admin.firestore().collection('User').doc(senderId).get();
          
          if (senderDoc.exists) {
            const senderData = senderDoc.data();
            // Always prefer displayName if available
            if (senderData.displayName) {
              senderUsername = senderData.displayName;
              console.log(`Using display name instead: ${senderUsername}`);
            }
          }
        }
      } catch (error) {
        console.error('Error fetching sender display name:', error);
        // Continue with what we have if there's an error
      }
    }
    
    // Create notification content
    let title, body, type;
    
    if (notificationData.is_a_like) {
      title = 'New Like';
      body = `${senderUsername} liked your post`;
      type = 'like';
    } else if (notificationData.is_follow_request) {
      title = 'Follow Request';
      body = `${senderUsername} wants to follow you`;
      type = 'follow';
    } else if (notificationData.is_reply) {
      title = 'New Reply';
      body = `${senderUsername} replied to your comment`;
      type = 'reply';
    } else {
      title = 'New Comment';
      body = `${senderUsername} commented on your post`;
      type = 'comment';
    }
    
    console.log(`Sending notification: ${title} - ${body}`);
    
    // Extract post ID if it's a reference path
    let postRef = '';
    if (notificationData.post_ref) {
      if (typeof notificationData.post_ref === 'string') {
        // If it's a path like "/posts/s5VwM29xjB40haL7FmkA"
        if (notificationData.post_ref.startsWith('/')) {
          postRef = notificationData.post_ref;
        } else {
          postRef = notificationData.post_ref;
        }
      } else if (notificationData.post_ref.path) {
        postRef = notificationData.post_ref.path;
      }
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
      token: fcmToken,
      
      notification: {
        title: title,
        body: body
      },
      
      data: {
        type: type,
        notification_id: notificationId,
        post_ref: postRef,
        is_a_like: String(notificationData.is_a_like || false),
        is_follow_request: String(notificationData.is_follow_request || false),
        is_reply: String(notificationData.is_reply || false),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      
      // iOS specific config
      apns: {
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert"
        },
        payload: {
          aps: {
            alert: {
              title: title,
              body: body
            },
            "content-available": 1,
            "mutable-content": 1,
            badge: unreadCount,
            sound: "default"
          }
        }
      },
      
      // Set as high priority
      android: {
        priority: "high"
      }
    };
    
    // Send the notification
    console.log("Sending FCM message...");
    const response = await admin.messaging().send(message);
    console.log("FCM message sent successfully:", response);
    
    // Update notification as delivered
    try {
      await admin.firestore()
        .collection('notifications')
        .doc(notificationId)
        .update({
          delivered: true,
          deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
          deliveryMethod: 'ios_terminated_notification'
        });
      console.log('Updated notification as delivered');
    } catch (updateError) {
      console.error('Error updating notification delivery status:', updateError);
    }
    
    return null;
  } catch (error) {
    console.error("Error sending iOS terminated notification:", error);
    return null;
  }
}; 