const admin = require("firebase-admin");
admin.initializeApp();

// Import v1 functions
exports.auth = require('./v1/auth');

// Import v2 functions
exports.gemini = require('./v2/gemini');
