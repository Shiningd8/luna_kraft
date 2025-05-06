const { onRequest, onCall } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const { pipeline } = require("node:stream/promises");
const apiManager = require("../api_manager");

setGlobalOptions({ region: "us-central1" });

async function verifyAuthHeader(request) {
    const authorization = request.header("authorization");
    if (!authorization) {
        return null;
    }
    const idToken = authorization.includes("Bearer ")
        ? authorization.split("Bearer ")[1]
        : null;
    if (!idToken) {
        return null;
    }
    try {
        const authResult = await admin.auth().verifyIdToken(idToken);
        return authResult;
    } catch (err) {
        return null;
    }
}

exports.geminiAI = onCall(
    {
        minInstances: 0,
        timeoutSeconds: 120,
    },
    async (request) => {
        try {
            console.log(`Making API call for ${request.data["callName"]}`);
            var response = await apiManager.makeApiCall(request, request.data);
            console.log(`Done making API Call! Status: ${response.statusCode}`);
            return response;
        } catch (err) {
            console.error(`Error performing API call: ${err}`);
            return {
                statusCode: 400,
                error: `${err}`,
            };
        }
    }
);

exports.geminiAIV2 = onRequest(
    {
        cors: true,
        minInstances: 0,
        timeoutSeconds: 120,
        memory: '1GB',
        region: 'us-central1',
        invoker: 'public'
    },
    async (req, res) => {
        try {
            const context = {
                auth: await verifyAuthHeader(req),
            };
            const data = req.body.data;
            console.log(`Making API call for ${data["callName"]}`);
            var endpointResponse = await apiManager.makeApiCall(context, data);
            console.log(
                `Done making API Call! Status: ${endpointResponse.statusCode}`,
            );
            res.set(endpointResponse.headers);
            res.status(endpointResponse.statusCode);
            await pipeline(endpointResponse.body, res);
        } catch (err) {
            console.error(`Error performing API call: ${err}`);
            res.status(400).send(`${err}`);
        }
    }
); 