const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

// Scheduled function to clean up posts marked for deletion
// Runs once per day
exports.cleanupMarkedPosts = functions.pubsub
    .schedule('every 24 hours')
    .onRun(async (context) => {
        console.log('Starting scheduled cleanup of posts marked for deletion');

        try {
            // Get all posts marked for deletion
            const snapshot = await admin.firestore()
                .collection('posts')
                .where('pendingDeletion', '==', true)
                .get();

            console.log(`Found ${snapshot.docs.length} posts marked for deletion`);

            if (snapshot.empty) {
                console.log('No posts to clean up');
                return null;
            }

            // Create a batch for bulk operations
            const batch = admin.firestore().batch();

            // Add each post to the deletion batch
            snapshot.docs.forEach(doc => {
                console.log(`Adding post ${doc.id} to deletion batch`);
                batch.delete(doc.ref);
            });

            // Commit the batch deletion
            await batch.commit();
            console.log(`Successfully deleted ${snapshot.docs.length} posts`);

            return null;
        } catch (error) {
            console.error('Error cleaning up posts:', error);
            return null;
        }
    });

// HTTP function to manually trigger cleanup (for admin use)
exports.manualCleanup = functions.https.onCall(async (data, context) => {
    // Check if the user is an admin
    if (!context.auth || !context.auth.token.admin) {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Only admins can perform manual cleanup'
        );
    }

    try {
        // Get all posts marked for deletion
        const snapshot = await admin.firestore()
            .collection('posts')
            .where('pendingDeletion', '==', true)
            .get();

        if (snapshot.empty) {
            return { success: true, message: 'No posts to clean up', count: 0 };
        }

        // Create a batch for bulk operations
        const batch = admin.firestore().batch();

        // Add each post to the deletion batch
        snapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });

        // Commit the batch deletion
        await batch.commit();

        return {
            success: true,
            message: `Successfully deleted ${snapshot.docs.length} posts`,
            count: snapshot.docs.length
        };
    } catch (error) {
        console.error('Error in manual cleanup:', error);
        throw new functions.https.HttpsError(
            'internal',
            'Error performing manual cleanup',
            error.message
        );
    }
}); 