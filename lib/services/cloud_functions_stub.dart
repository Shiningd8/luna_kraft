// Stub implementation for cloud_functions
// This provides enough of the API to prevent compile errors

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseFunctions {
  static FirebaseFunctions get instance => _instance;
  static final FirebaseFunctions _instance = FirebaseFunctions._();
  FirebaseFunctions._();

  static FirebaseFunctions instanceFor({required String region}) {
    debugPrint('[STUB] FirebaseFunctions.instanceFor() called with region: $region');
    return _instance;
  }

  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    debugPrint('[STUB] FirebaseFunctions.httpsCallable() called for function: $name');
    return HttpsCallable._(name);
  }
}

class HttpsCallable {
  final String functionName;
  HttpsCallable._(this.functionName);

  Future<HttpsCallableResult> call([dynamic parameters]) async {
    debugPrint('[STUB] HttpsCallable.call() called for function: $functionName with parameters: $parameters');
    
    // Special handling for geminiAI function - check both names
    if ((functionName == 'geminiAI' || functionName == 'posts-geminiAI') && parameters is Map) {
      debugPrint('[STUB] 🔍 Detected geminiAI function! Processing with special handler...');
      return _handleGeminiAI(parameters);
    }
    
    // Special handling for deletePost function
    if (functionName == 'deletePost' && parameters is Map) {
      return _handleDeletePost(parameters);
    }
    
    debugPrint('[STUB] ⚠️ No special handler found for function: $functionName');
    return HttpsCallableResult._({'success': false, 'message': 'Stub implementation for $functionName not implemented'});
  }
  
  Future<HttpsCallableResult> _handleGeminiAI(Map parameters) async {
    try {
      debugPrint('[STUB] Handling geminiAI call with parameters: $parameters');
      
      // Get the API key from the environment or use a default one
      final apiKey = 'AIzaSyBD12Lf4b9UB_ZhinHFvNx3JT63u41sa_s'; // Your Gemini API key
      
      // Extract the user input text
      final callName = parameters['callName'] as String?;
      final variables = parameters['variables'] as Map?;
      final userInputText = variables?['userInputText'] as String?;
      
      debugPrint('[STUB] 📝 Extracted parameters: callName=$callName, userInputText=${userInputText?.substring(0, userInputText.length > 50 ? 50 : userInputText.length)}...');
      
      if (callName != 'GeminiAPICall' || userInputText == null) {
        debugPrint('[STUB] ❌ Invalid parameters for geminiAI: callName=$callName, userInputText=$userInputText');
        return HttpsCallableResult._({
          'success': false,
          'message': 'Invalid parameters'
        });
      }
      
      // Create the prompt with the user input - NO TEMPLATE INTERPOLATION, use direct string
      final promptText = 'You are a helpful dream-writing assistant. A user has shared fragments of a dream they remember. Your task is to weave these fragments into a complete dream narrative (200-220 words) using first person narration. The fragments should be integrated naturally throughout the story, not just used as a starting point. Create a coherent dream that incorporates all elements the user mentioned without adding any new characters, places, or names beyond what they provided. Keep your writing simple and straightforward while making the dream feel authentic. Also use simple english thats easy to understand. The dream fragments are: ' + userInputText;
      
      debugPrint('[STUB] Making HTTP request to Gemini API with prompt: ${promptText.substring(0, promptText.length > 100 ? 100 : promptText.length)}...');
      
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': promptText
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.05,
          'maxOutputTokens': 300,
          'topP': 0.7,
          'topK': 20
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };
      
      debugPrint('[STUB] Request body: ${jsonEncode(requestBody).substring(0, 200)}...');
      
      // Make the HTTP request to the Gemini API - switched to gemini-1.5-flash
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      debugPrint('[STUB] Gemini API response status code: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        debugPrint('[STUB] Error from Gemini API: ${response.body}');
        return HttpsCallableResult._({
          'success': false,
          'message': 'Error from Gemini API: ${response.statusCode}, ${response.body}'
        });
      }
      
      // Parse the response
      final responseJson = jsonDecode(response.body);
      debugPrint('[STUB] Successfully received Gemini API response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      
      // Extract the generated text directly
      String? generatedText;
      
      try {
        if (responseJson['candidates'] is List && 
            responseJson['candidates'].isNotEmpty &&
            responseJson['candidates'][0]['content'] is Map &&
            responseJson['candidates'][0]['content']['parts'] is List &&
            responseJson['candidates'][0]['content']['parts'].isNotEmpty) {
          generatedText = responseJson['candidates'][0]['content']['parts'][0]['text'];
          debugPrint('[STUB] Successfully extracted text: ${generatedText?.substring(0, generatedText!.length > 100 ? 100 : generatedText.length)}...');
        }
      } catch (e) {
        debugPrint('[STUB] Error extracting text: $e');
      }
      
      if (generatedText == null) {
        debugPrint('[STUB] Could not extract text from response. Full response: $responseJson');
        return HttpsCallableResult._({
          'success': false,
          'message': 'Could not extract text from response'
        });
      }
      
      // Return a simple response with the extracted text
      debugPrint('[STUB] Returning successful response with generated text');
      return HttpsCallableResult._({
        'success': true,
        'statusCode': 200,
        'generatedText': generatedText,
        'jsonBody': responseJson  // Add the full JSON response for compatibility with the API call handler
      });
    } catch (e) {
      debugPrint('[STUB] Error handling geminiAI: $e');
      return HttpsCallableResult._({
        'success': false,
        'message': 'Error handling geminiAI: $e'
      });
    }
  }
  
  Future<HttpsCallableResult> _handleDeletePost(Map parameters) async {
    try {
      final String? postId = parameters['postId'];
      if (postId == null) {
        return HttpsCallableResult._({
          'success': false, 
          'message': 'Post ID is required'
        });
      }
      
      debugPrint('[STUB] Handling deletePost for post ID: $postId');
      
      // Get the current user ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return HttpsCallableResult._({
          'success': false, 
          'message': 'User must be logged in to delete a post'
        });
      }
      
      // Get the post reference
      final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
      final postDoc = await postRef.get();
      
      if (!postDoc.exists) {
        return HttpsCallableResult._({
          'success': false, 
          'message': 'Post not found'
        });
      }
      
      // Check if user is the owner
      final postData = postDoc.data();
      if (postData == null) {
        return HttpsCallableResult._({
          'success': false, 
          'message': 'Post data not found'
        });
      }
      
      // Extract owner ID from post data
      String? ownerId;
      if (postData['poster'] is DocumentReference) {
        ownerId = (postData['poster'] as DocumentReference).id;
      } else if (postData['userref'] is DocumentReference) {
        ownerId = (postData['userref'] as DocumentReference).id;
      }
      
      debugPrint('[STUB] Post owner ID: $ownerId, current user ID: ${user.uid}');
      
      if (ownerId != user.uid) {
        return HttpsCallableResult._({
          'success': false, 
          'message': 'You do not have permission to delete this post'
        });
      }
      
      // Delete the post
      await postRef.delete();
      
      return HttpsCallableResult._({
        'success': true, 
        'message': 'Post deleted successfully'
      });
    } catch (e) {
      debugPrint('[STUB] Error deleting post: $e');
      return HttpsCallableResult._({
        'success': false, 
        'message': 'Error deleting post: $e'
      });
    }
  }
}

class HttpsCallableResult {
  final dynamic data;
  HttpsCallableResult._(this.data);
}

class HttpsCallableOptions {
  final Duration? timeout;
  HttpsCallableOptions({this.timeout});
}

class FirebaseFunctionsException implements Exception {
  final String message;
  final String code;
  final dynamic details;

  FirebaseFunctionsException({
    required this.message,
    required this.code,
    this.details,
  });

  @override
  String toString() => 'FirebaseFunctionsException($code, $message)';
} 