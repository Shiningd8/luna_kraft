const admin = require("firebase-admin");
admin.initializeApp();

// Import v1 functions
exports.auth = require('./v1/auth');
exports.comments = require('./v1/comments');
exports.admin = require('./v1/admin');

// Import v2 functions
exports.gemini = require('./v2/gemini');
