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
            console.log(`Comment ${commentId} not found`);
            return res.status(404).json({
                error: {
                    code: 'not-found',
                    message: 'Comment not found'
                }
            });
        }

        const commentData = commentSnap.data();
        console.log("Comment data:", JSON.stringify(commentData, null, 2));

        // Check if current user is comment author
        const commentAuthorId = commentData.userref?.id;
        console.log(`Comment author ID: ${commentAuthorId}, Current user ID: ${decodedToken.uid}`);

        if (commentAuthorId === decodedToken.uid) {
            console.log("User is comment author, proceeding with soft deletion");
            // Create a batch for bulk operations
            const batch = admin.firestore().batch();

            // Get all replies to this comment
            const repliesQuery = await admin.firestore()
                .collection('comments')
                .where('parentCommentRef', '==', commentRef)
                .get();

            console.log(`Found ${repliesQuery.docs.length} replies to soft delete`);

            // Mark all replies as deleted
            repliesQuery.docs.forEach(replyDoc => {
                batch.update(replyDoc.ref, {
                    'deleted': true,
                    'deletedAt': admin.firestore.FieldValue.serverTimestamp(),
                    'deletedBy': decodedToken.uid,
                    'deletedAs': 'author',
                });

                // Add to deleted_comments collection for admin reference
                const deletedRef = admin.firestore().collection('deleted_comments').doc();
                batch.set(deletedRef, {
                    'commentId': replyDoc.id,
                    'commentRef': replyDoc.ref,
                    'deletedAt': admin.firestore.FieldValue.serverTimestamp(),
                    'deletedBy': decodedToken.uid,
                    'deletedAs': 'author',
                    'postId': commentData.postref?.id,
                    'comment': replyDoc.data().comment,
                    'isReply': true,
                    'parentCommentId': commentId,
                });
            });

            // Mark the comment itself as deleted
            batch.update(commentRef, {
                'deleted': true,
                'deletedAt': admin.firestore.FieldValue.serverTimestamp(),
                'deletedBy': decodedToken.uid,
                'deletedAs': 'author',
            });

            // Add to deleted_comments collection for admin reference
            const deletedRef = admin.firestore().collection('deleted_comments').doc();
            batch.set(deletedRef, {
                'commentId': commentId,
                'commentRef': commentRef,
                'deletedAt': admin.firestore.FieldValue.serverTimestamp(),
                'deletedBy': decodedToken.uid,
                'deletedAs': 'author',
                'postId': commentData.postref?.id,
                'comment': commentData.comment,
                'isReply': commentData.isReply || false,
                'parentCommentId': commentData.parentCommentRef?.id,
            });

            // Commit the batch operation
            await batch.commit();
            console.log("Comment and replies soft deleted successfully as author");

            return res.status(200).json({
                data: {
                    success: true,
                    message: "Comment and replies soft deleted successfully",
                    softDeletedReplies: repliesQuery.docs.length,
                    deletedAs: "author"
                }
            });
        }

        // If not comment author, check if user is post owner
        const postRef = commentData.postref;
        if (!postRef) {
            console.log("Comment does not have an associated post");
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
            console.log("Associated post not found");
            return res.status(404).json({
                error: {
                    code: 'not-found',
                    message: 'Associated post not found'
                }
            });
        }

        const postData = postSnap.data();
        console.log("Post data:", JSON.stringify(postData, null, 2));

        let postOwnerId;

        // Handle different post data structures
        if (postData.userref) {
            postOwnerId = postData.userref.id;
            console.log(`Post owner from userref: ${postOwnerId}`);
        } else if (postData.poster) {
            postOwnerId = postData.poster.id;
            console.log(`Post owner from poster: ${postOwnerId}`);
        }

        // Check if current user is post owner
        if (postOwnerId !== decodedToken.uid) {
            console.log("Permission denied: User is neither comment author nor post owner");
            return res.status(403).json({
                error: {
                    code: 'permission-denied',
                    message: 'Only the post owner or comment author can delete comments'
                }
            });
        }

        console.log("User is post owner, proceeding with soft deletion");
        // Create a batch for bulk operations
        const batch = admin.firestore().batch();

        // Get all replies to this comment
        const repliesQuery = await admin.firestore()
            .collection('comments')
            .where('parentCommentRef', '==', commentRef)
            .get();

        console.log(`Found ${repliesQuery.docs.length} replies to soft delete`);

        // Mark all replies as deleted
        repliesQuery.docs.forEach(replyDoc => {
            batch.update(replyDoc.ref, {
                'deleted': true,
                'deletedAt': admin.firestore.FieldValue.serverTimestamp(),
                'deletedBy': decodedToken.uid,
                'deletedAs': 'post_owner',
            });

            // Add to deleted_comments collection for admin reference
            const deletedRef = admin.firestore().collection('deleted_comments').doc();
            batch.set(deletedRef, {
                'commentId': replyDoc.id,
                'commentRef': replyDoc.ref,
                'deletedAt': admin.firestore.FieldValue.serverTimestamp(),
                'deletedBy': decodedToken.uid,
                'deletedAs': 'post_owner',
                'postId': commentData.postref?.id,
                'comment': replyDoc.data().comment,
                'isReply': true,
                'parentCommentId': commentId,
            });
        });

        // Mark the comment itself as deleted
        batch.update(commentRef, {
            'deleted': true,
            'deletedAt': admin.firestore.FieldValue.serverTimestamp(),
            'deletedBy': decodedToken.uid,
            'deletedAs': 'post_owner',
        });

        // Add to deleted_comments collection for admin reference
        const deletedRef = admin.firestore().collection('deleted_comments').doc();
        batch.set(deletedRef, {
            'commentId': commentId,
            'commentRef': commentRef,
            'deletedAt': admin.firestore.FieldValue.serverTimestamp(),
            'deletedBy': decodedToken.uid,
            'deletedAs': 'post_owner',
            'postId': commentData.postref?.id,
            'comment': commentData.comment,
            'isReply': commentData.isReply || false,
            'parentCommentId': commentData.parentCommentRef?.id,
        });

        // Commit the batch operation
        await batch.commit();
        console.log("Comment and replies soft deleted successfully as post owner");

        // Return success response
        return res.status(200).json({
            data: {
                success: true,
                message: "Comment and replies soft deleted successfully",
                softDeletedReplies: repliesQuery.docs.length,
                deletedAs: "post_owner"
            }
        });
    } catch (error) {
        console.error("Error soft deleting comment:", error);
        return res.status(500).json({
            error: {
                code: 'internal',
                message: 'Error soft deleting comment: ' + error.message
            }
        });
    }
}); 