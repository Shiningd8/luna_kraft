const axios = require("axios").default;
const qs = require("qs");

async function _geminiAPICall(context, ffVariables) {
  var userInputText = ffVariables["userInputText"];

  var url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=AIzaSyBD12Lf4b9UB_ZhinHFvNx3JT63u41sa_s`;
  var headers = { "Content-Type": `application/json` };
  var params = {};

  // Create the request body as a JavaScript object instead of a string template
  const requestBody = {
    contents: [
      {
        parts: [
          {
            text: "You are a helpful dream-writing assistant. A user has shared fragments of a dream they remember. Your task is to weave these fragments into a complete dream narrative (200-220 words) using first person narration. The fragments should be integrated naturally throughout the story, not just used as a starting point. Create a coherent dream that incorporates all elements the user mentioned without adding any new characters, places, or names beyond what they provided. Keep your writing simple and straightforward while making the dream feel authentic. Also use simple english thats easy to understand. The dream fragments are: ${escapeStringForJson(userInputText)}"
          }
        ]
      }
    ],
    generationConfig: {
      temperature: 0.05, // Much lower temperature for more precise, literal responses
      maxOutputTokens: 300,
      topP: 0.7,
      topK: 20
    },
    safetySettings: [
      {
        category: "HARM_CATEGORY_HARASSMENT",
        threshold: "BLOCK_MEDIUM_AND_ABOVE"
      },
      {
        category: "HARM_CATEGORY_HATE_SPEECH",
        threshold: "BLOCK_MEDIUM_AND_ABOVE"
      },
      {
        category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
        threshold: "BLOCK_MEDIUM_AND_ABOVE"
      },
      {
        category: "HARM_CATEGORY_DANGEROUS_CONTENT",
        threshold: "BLOCK_MEDIUM_AND_ABOVE"
      }
    ]
  };

  return makeApiRequest({
    method: "post",
    url,
    headers,
    params,
    body: requestBody,
    returnBody: true,
    isStreamingApi: false,
  });
}

/// Helper functions to route to the appropriate API Call.

async function makeApiCall(context, data) {
  var callName = data["callName"] || "";
  var variables = data["variables"] || {};

  const callMap = {
    GeminiAPICall: _geminiAPICall,
  };

  if (!(callName in callMap)) {
    return {
      statusCode: 400,
      error: `API Call "${callName}" not defined as private API.`,
    };
  }

  var apiCall = callMap[callName];
  var response = await apiCall(context, variables);
  return response;
}

async function makeApiRequest({
  method,
  url,
  headers,
  params,
  body,
  returnBody,
  isStreamingApi,
}) {
  return axios
    .request({
      method: method,
      url: url,
      headers: headers,
      params: params,
      responseType: isStreamingApi ? "stream" : "json",
      ...(body && { data: body }),
    })
    .then((response) => {
      return {
        statusCode: response.status,
        headers: response.headers,
        ...(returnBody && { body: response.data }),
        isStreamingApi: isStreamingApi,
      };
    })
    .catch(function (error) {
      return {
        statusCode: error.response.status,
        headers: error.response.headers,
        ...(returnBody && { body: error.response.data }),
        error: error.message,
      };
    });
}

const _unauthenticatedResponse = {
  statusCode: 401,
  headers: {},
  error: "API call requires authentication",
};

function createBody({ headers, params, body, bodyType }) {
  switch (bodyType) {
    case "JSON":
      headers["Content-Type"] = "application/json";
      return body;
    case "TEXT":
      headers["Content-Type"] = "text/plain";
      return body;
    case "X_WWW_FORM_URL_ENCODED":
      headers["Content-Type"] = "application/x-www-form-urlencoded";
      return qs.stringify(params);
  }
}
function escapeStringForJson(val) {
  if (typeof val !== "string") {
    return val;
  }
  return val
    .replace(/[\\]/g, "\\\\")
    .replace(/["]/g, '\\"')
    .replace(/[\n]/g, "\\n")
    .replace(/[\t]/g, "\\t");
}

module.exports = { makeApiCall };
