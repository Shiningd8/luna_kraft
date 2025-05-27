import 'dart:convert';
// We won't use the cloud_functions package since it's causing issues
// import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Makes a call to a Firebase Cloud Function
/// Directly uses HTTP to call Firebase Functions instead of using the cloud_functions package
Future<Map<String, dynamic>> makeCloudCall(
  String callName,
  Map<String, dynamic> input,
) async {
  try {
    if (kDebugMode) {
      print('⚡ makeCloudCall: Starting direct HTTP call to function: $callName');
      print('Function input: ${input.toString().substring(0, input.toString().length > 50 ? 50 : input.toString().length)}...');
    }
    
    // Get the current user's ID token for authentication
    String? idToken;
    try {
      idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (kDebugMode) {
        print('🔑 JWT token refreshed: ${idToken != null ? 'Token present' : 'No token'}');
      }
    } catch (authError) {
      if (kDebugMode) {
        print('❌ Error getting auth token: $authError. Proceeding without authentication.');
      }
    }

    // Use a dynamic function URL based on the function name
    final url = 'https://us-central1-luna-kraft-7dsjjb.cloudfunctions.net/$callName';
    if (kDebugMode) {
      print('📡 Making HTTP request to: $url');
    }

    // Prepare the request body and headers
    final requestData = jsonEncode({'data': input});
    if (kDebugMode) {
      print('📦 Request data: ${requestData.substring(0, requestData.length > 50 ? 50 : requestData.length)}...');
    }

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    // Add authentication if available
    if (idToken != null) {
      headers['Authorization'] = 'Bearer $idToken';
    }

    // Make the HTTP request
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: requestData,
    );

    if (kDebugMode) {
      print('📥 HTTP Response status: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('📄 HTTP Response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      } else {
        print('📄 HTTP Response body is empty');
      }
    }

    // Handle the response
    if (response.statusCode == 204) {
      // No content response is valid for some operations
      return {'success': true};
    }

    if (response.statusCode != 200) {
      throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
    }

    if (response.body.isEmpty) {
      return {'success': true};
    }

    // Parse the JSON response
    try {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse is Map) {
        if (jsonResponse['data'] is Map) {
          return Map<String, dynamic>.from(jsonResponse['data'] as Map);
        } else if (jsonResponse['result'] is Map) {
          return Map<String, dynamic>.from(jsonResponse['result'] as Map);
        } else {
          return {'success': true, 'data': jsonResponse};
        }
      } else {
        return {'success': true, 'raw_response': response.body};
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing JSON response: $e');
      }
      return {'success': true, 'raw_response': response.body};
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Cloud call error: $e');
    }
    return {'error': e.toString()};
  }
}
