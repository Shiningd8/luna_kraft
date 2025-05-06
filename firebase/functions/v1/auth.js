const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

// v1 auth triggers
exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
    let firestore = admin.firestore();
    await firestore.collection("User").doc(user.uid).delete();
}); 