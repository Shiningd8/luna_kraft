module.exports = {
    root: true,
    env: {
        es6: true,
        node: true,
    },
    extends: [
        "eslint:recommended",
        "plugin:promise/recommended",
    ],
    rules: {
        // Turned off for Cloud Functions for Firebase
        "no-unused-vars": "off",
        "no-undef": "off",
        // Allow console for Cloud Functions
        "no-console": "off",
        // Other rules
        "max-len": ["warn", { "code": 120 }],
        "promise/always-return": "off",
        "promise/no-nesting": "off"
    },
}; 