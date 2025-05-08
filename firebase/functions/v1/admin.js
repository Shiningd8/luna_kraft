const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

/**
 * Admin function to permanently delete all soft-deleted comments
 * This function should be restricted to admin users only
 */
exports.purgeDeletedComments = functions.https.onRequest(async (req, res) => {
    // Enable CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    // Handle preflight requests
    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }

    // Verify authentication
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                error: {
                    code: 'unauthenticated',
                    message: 'You must be logged in as an admin to use this function'
                }
            });
        }

        const idToken = authHeader.split('Bearer ')[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);

        // Verify admin status - This is a simple example, you might want to check a specific admin collection
        // or use Firebase Auth custom claims for this
        const userDoc = await admin.firestore().collection('User').doc(decodedToken.uid).get();
        const userData = userDoc.data();

        if (!userData || !userData.isAdmin) {
            console.log(`User ${decodedToken.uid} attempted to access admin function but is not an admin`);
            return res.status(403).json({
                error: {
                    code: 'permission-denied',
                    message: 'You do not have permission to perform this action'
                }
            });
        }

        // Get parameters from request
        const data = req.body.data || {};
        const daysOld = data.daysOld || 30; // Default to deleting comments that are at least 30 days old
        const batchSize = data.batchSize || 100; // Default batch size

        console.log(`Beginning purge of deleted comments older than ${daysOld} days`);

        // Calculate the cutoff date
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - daysOld);

        // Query for soft-deleted comments older than the cutoff date
        const deletedCommentsQuery = await admin.firestore()
            .collection('comments')
            .where('deleted', '==', true)
            .where('deletedAt', '<', cutoffDate)
            .limit(batchSize)
            .get();

        console.log(`Found ${deletedCommentsQuery.docs.length} deleted comments to purge`);

        if (deletedCommentsQuery.empty) {
            return res.status(200).json({
                data: {
                    success: true,
                    message: "No deleted comments found to purge",
                    purgedCount: 0
                }
            });
        }

        // Create a batch for bulk operations
        const batch = admin.firestore().batch();
        let purgeCount = 0;

        // Add each comment to the deletion batch
        deletedCommentsQuery.docs.forEach(doc => {
            batch.delete(doc.ref);
            purgeCount++;
        });

        // Commit the batch operation
        await batch.commit();
        console.log(`Successfully purged ${purgeCount} deleted comments`);

        return res.status(200).json({
            data: {
                success: true,
                message: `Successfully purged ${purgeCount} deleted comments`,
                purgedCount: purgeCount
            }
        });
    } catch (error) {
        console.error("Error purging deleted comments:", error);
        return res.status(500).json({
            error: {
                code: 'internal',
                message: 'Error purging deleted comments: ' + error.message
            }
        });
    }
});

/**
 * Admin function to view all deleted comments
 * This can be used to monitor and manage deleted content
 */
exports.getDeletedComments = functions.https.onRequest(async (req, res) => {
    // Enable CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    // Handle preflight requests
    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }

    // Verify authentication
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                error: {
                    code: 'unauthenticated',
                    message: 'You must be logged in as an admin to use this function'
                }
            });
        }

        const idToken = authHeader.split('Bearer ')[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);

        // Verify admin status
        const userDoc = await admin.firestore().collection('User').doc(decodedToken.uid).get();
        const userData = userDoc.data();

        if (!userData || !userData.isAdmin) {
            console.log(`User ${decodedToken.uid} attempted to access admin function but is not an admin`);
            return res.status(403).json({
                error: {
                    code: 'permission-denied',
                    message: 'You do not have permission to perform this action'
                }
            });
        }

        // Get parameters from request
        const data = req.body.data || {};
        const limit = data.limit || 50; // Default limit
        const offset = data.offset || 0; // Default offset for pagination

        // Query the deleted_comments collection with pagination
        const deletedCommentsQuery = await admin.firestore()
            .collection('deleted_comments')
            .orderBy('deletedAt', 'desc')
            .offset(offset)
            .limit(limit)
            .get();

        console.log(`Retrieved ${deletedCommentsQuery.docs.length} deleted comments`);

        // Format the results
        const deletedComments = deletedCommentsQuery.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                commentId: data.commentId,
                comment: data.comment,
                deletedAt: data.deletedAt ? data.deletedAt.toDate() : null,
                deletedBy: data.deletedBy,
                deletedAs: data.deletedAs,
                postId: data.postId,
                isReply: data.isReply,
                parentCommentId: data.parentCommentId,
            };
        });

        return res.status(200).json({
            data: {
                deletedComments,
                count: deletedComments.length,
                hasMore: deletedCommentsQuery.docs.length === limit
            }
        });
    } catch (error) {
        console.error("Error retrieving deleted comments:", error);
        return res.status(500).json({
            error: {
                code: 'internal',
                message: 'Error retrieving deleted comments: ' + error.message
            }
        });
    }
}); 