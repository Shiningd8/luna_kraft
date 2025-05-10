const admin = require("firebase-admin");
admin.initializeApp();

// Import v1 functions
exports.auth = require('./v1/auth');
exports.comments = require('./v1/comments');
exports.admin = require('./v1/admin');
exports.posts = require('./v1/posts');
exports.notifications = require('./v1/notifications');

// Import v2 functions
exports.gemini = require('./v2/gemini');

// Import scheduled cleanup functions
const scheduledCleanup = require('./scheduled-cleanup');

// Export all scheduled cleanup functions
exports.cleanupMarkedPosts = scheduledCleanup.cleanupMarkedPosts;
exports.manualCleanup = scheduledCleanup.manualCleanup;
