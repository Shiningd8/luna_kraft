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

// Add a V1 gemini function to handle API calls to Gemini
const apiManager = require('../api_manager');

// Export a V1 function for Gemini API calls
exports.geminiAI = functions.https.onCall(async (data, context) => {
  try {
    console.log(`[V1] Making API call for ${data["callName"]} with data: ${JSON.stringify(data).substring(0, 200)}...`);
    
    // Validate input
    if (!data || !data["callName"]) {
      console.error("[V1] Invalid request: Missing callName");
      return {
        statusCode: 400,
        error: "Missing callName in request",
      };
    }
    
    var response = await apiManager.makeApiCall(context, data);
    console.log(`[V1] Done making API Call! Status: ${response.statusCode}`);
    
    // Extract and add generated text for easier access
    if (response.body && response.body.candidates && 
        response.body.candidates.length > 0 && 
        response.body.candidates[0].content && 
        response.body.candidates[0].content.parts && 
        response.body.candidates[0].content.parts.length > 0) {
      
      const generatedText = response.body.candidates[0].content.parts[0].text;
      if (generatedText) {
        response.generatedText = generatedText;
        console.log(`[V1] Generated text successfully extracted (first 100 chars): ${generatedText.substring(0, 100)}...`);
      }
    }
    
    return response;
  } catch (err) {
    console.error(`[V1] Error performing API call: ${err}`);
    console.error(`[V1] Stack trace: ${err.stack}`);
    return {
      statusCode: 400,
      error: `${err}`,
    };
  }
}); 