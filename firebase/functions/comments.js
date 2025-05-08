const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

/**
 * Cloud function to delete a comment and all its replies
 * Only the post owner can delete comments on their post
 */
exports.deleteComment = functions.https.onRequest(async (req, res) => {
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
                    message: 'You must be logged in to delete comments'
                }
            });
        }

        const idToken = authHeader.split('Bearer ')[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);

        // Get the comment ID from the request body
        const data = req.body.data || {};
        const commentId = data.commentId;

        if (!commentId) {
            return res.status(400).json({
                error: {
                    code: 'invalid-argument',
                    message: 'Comment ID is required'
                }
            });
        }

        // Get the comment document
        const commentRef = admin.firestore().collection('comments').doc(commentId);
        const commentSnap = await commentRef.get();

        if (!commentSnap.exists) {
            return res.status(404).json({
                error: {
                    code: 'not-found',
                    message: 'Comment not found'
                }
            });
        }

        const commentData = commentSnap.data();
        const postRef = commentData.postref;

        if (!postRef) {
            return res.status(400).json({
                error: {
                    code: 'failed-precondition',
                    message: 'Comment does not have an associated post'
                }
            });
        }

        // Get post data to check ownership
        const postSnap = await postRef.get();

        if (!postSnap.exists) {
            return res.status(404).json({
                error: {
                    code: 'not-found',
                    message: 'Associated post not found'
                }
            });
        }

        const postData = postSnap.data();
        let postOwnerId;

        // Handle different post data structures
        if (postData.userref) {
            postOwnerId = postData.userref.id;
        } else if (postData.poster) {
            postOwnerId = postData.poster.id;
        }

        // Check if current user is post owner
        if (postOwnerId !== decodedToken.uid) {
            return res.status(403).json({
                error: {
                    code: 'permission-denied',
                    message: 'Only the post owner can delete comments'
                }
            });
        }

        // Create a batch for bulk operations
        const batch = admin.firestore().batch();

        // Get all replies to this comment
        const repliesQuery = await admin.firestore()
            .collection('comments')
            .where('parentCommentRef', '==', commentRef)
            .get();

        // Add all replies to the batch deletion
        repliesQuery.docs.forEach(replyDoc => {
            batch.delete(replyDoc.ref);
        });

        // Add the comment itself to the batch deletion
        batch.delete(commentRef);

        // Commit the batch deletion
        await batch.commit();

        // Return success response
        return res.status(200).json({
            data: {
                success: true,
                message: "Comment and replies deleted successfully",
                deletedReplies: repliesQuery.docs.length
            }
        });
    } catch (error) {
        console.error("Error deleting comment:", error);
        return res.status(500).json({
            error: {
                code: 'internal',
                message: 'Error deleting comment: ' + error.message
            }
        });
    }
}); 