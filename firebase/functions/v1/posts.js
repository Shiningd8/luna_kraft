const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

/**
 * Cloud function to delete a post
 * This bypasses Firestore security rules
 */
exports.deletePost = functions.https.onCall(async (data, context) => {
    // Ensure user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "You must be logged in to delete a post"
        );
    }

    try {
        const { postId } = data;

        if (!postId) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Post ID is required"
            );
        }

        // Get the post document
        const postRef = admin.firestore().collection('posts').doc(postId);
        const postDoc = await postRef.get();

        if (!postDoc.exists) {
            throw new functions.https.HttpsError(
                "not-found",
                "Post not found"
            );
        }

        const postData = postDoc.data();
        console.log(`Post data: ${JSON.stringify(postData)}`);

        // Check if user is the owner of the post
        const userId = context.auth.uid;
        const ownerId =
            (postData.userref && postData.userref.id) ||
            (postData.poster && postData.poster.id);

        console.log(`User ID: ${userId}, Owner ID: ${ownerId}`);

        if (userId !== ownerId) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "You do not have permission to delete this post"
            );
        }

        // Delete the post
        await postRef.delete();

        return { success: true, message: "Post deleted successfully" };
    } catch (error) {
        console.error("Error deleting post:", error);

        if (error instanceof functions.https.HttpsError) {
            throw error;
        }

        throw new functions.https.HttpsError(
            "internal",
            "Error deleting post: " + error.message
        );
    }
}); 