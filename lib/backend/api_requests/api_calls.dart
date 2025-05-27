import 'dart:convert';
import '../cloud_functions/cloud_functions.dart';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'geminiAI';

class GeminiAPICall {
  static Future<ApiCallResponse> call({
    String? userInputText,
  }) async {
    userInputText ??= '';

    try {
      print('Calling Gemini API with text: ${userInputText.substring(0, userInputText.length > 20 ? 20 : userInputText.length)}...');
      
      final response = await makeCloudCall(
        _kPrivateApiFunctionName,
        {
          'callName': 'GeminiAPICall',
          'variables': {
            'userInputText': userInputText,
          },
        },
      );
      
      print('Gemini API response received: ${response.toString().substring(0, response.toString().length > 100 ? 100 : response.toString().length)}...');
      
      // Ensure the response has the correct fields for the UI to work with
      if (response is Map && response['generatedText'] != null && response['generatedText'] is String) {
        print('Response contains generatedText, adding to jsonBody');
        // Create jsonBody if it doesn't exist or if it's not a map
        if (response['jsonBody'] == null || !(response['jsonBody'] is Map)) {
          response['jsonBody'] = {
            'success': true,
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': response['generatedText']
                    }
                  ]
                }
              }
            ]
          };
        } else if (response['jsonBody'] is Map) {
          // Make sure the jsonBody has the candidates field
          final jsonBody = response['jsonBody'] as Map;
          if (jsonBody['candidates'] == null) {
            jsonBody['candidates'] = [
              {
                'content': {
                  'parts': [
                    {
                      'text': response['generatedText']
                    }
                  ]
                }
              }
            ];
          }
        }
      }
      
      return ApiCallResponse.fromCloudCallResponse(response);
    } catch (e) {
      print('Error calling Gemini API: $e');
      rethrow;
    }
  }

  static String? aiGeneratedText(dynamic response) {
    try {
      // First try to extract directly from generatedText field if available
      if (response is Map && response['generatedText'] != null) {
        final text = response['generatedText'];
        print('Found text directly from generatedText field: ${text != null ? (text.toString().substring(0, text.toString().length > 50 ? 50 : text.toString().length)) : "null"}...');
        if (text != null) {
          return text.toString();
        }
      }
      
      // If response is a string directly, return it
      if (response is String) {
        return response;
      }
      
      // Print the entire response to help debug
      print('Examining response for text extraction: ${response.toString().substring(0, response.toString().length > 200 ? 200 : response.toString().length)}...');
      
      // Check if response is the direct candidates array
      if (response is Map && response['candidates'] != null) {
        final candidates = response['candidates'];
        if (candidates is List && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          if (content is Map && content['parts'] is List && content['parts'].isNotEmpty) {
            final text = content['parts'][0]['text'];
            print('Found text directly in response: ${text != null ? (text.toString().substring(0, text.toString().length > 50 ? 50 : text.toString().length)) : 'null'}...');
            return text?.toString();
          }
        }
      }
      
      // Try using the getJsonField function to extract text
      final rawText = getJsonField(
        response,
        r'''$.candidates[:].content.parts[:].text''',
      );
      
      print('Extracted text using JSON path: ${rawText != null ? (rawText.toString().substring(0, rawText.toString().length > 50 ? 50 : rawText.toString().length)) : 'null'}...');
      
      // If the standard path doesn't work, try alternative paths
      if (rawText == null) {
        // Try alternative paths
        final alternativePaths = [
          r'''$.body.candidates[:].content.parts[:].text''',
          r'''$.candidates[0].content.parts[0].text''',
          r'''$.body.candidates[0].content.parts[0].text''',
          r'''$.data.candidates[:].content.parts[:].text''',
          r'''$.data.candidates[0].content.parts[0].text''',
        ];
        
        for (final path in alternativePaths) {
          final alternativeText = getJsonField(response, path);
          if (alternativeText != null) {
            print('Found text using alternative path $path: ${alternativeText.toString().substring(0, alternativeText.toString().length > 50 ? 50 : alternativeText.toString().length)}...');
            return castToType<String>(alternativeText);
          }
        }
        
        // If we still don't have text, try parsing as raw JSON
        try {
          // Try to see if there's a raw_response field
          if (response is Map && response['raw_response'] != null) {
            final rawResponse = response['raw_response'];
            if (rawResponse is String) {
              final jsonData = json.decode(rawResponse);
              if (jsonData is Map && 
                  jsonData['candidates'] is List && 
                  jsonData['candidates'].isNotEmpty) {
                final candidate = jsonData['candidates'][0];
                if (candidate is Map && 
                    candidate['content'] is Map && 
                    candidate['content']['parts'] is List && 
                    candidate['content']['parts'].isNotEmpty) {
                  final text = candidate['content']['parts'][0]['text'];
                  print('Found text in raw_response: ${text != null ? text.toString().substring(0, text.toString().length > 50 ? 50 : text.toString().length) : 'null'}...');
                  return text?.toString();
                }
              }
            }
          }
        } catch (e) {
          print('Error parsing raw_response: $e');
        }
        
        print('Failed to extract text from response using all methods');
        return null;
      }
      
      // Return the complete text including any markers
      return castToType<String>(rawText);
    } catch (e) {
      print('Error extracting text from Gemini response: $e');
      return null;
    }
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  if (item is DocumentReference) {
    return item.path;
  }
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
