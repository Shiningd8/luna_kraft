import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Makes a call to a Firebase Cloud Function
/// Supports both callable functions and HTTP functions
Future<Map<String, dynamic>> makeCloudCall(
  String callName,
  Map<String, dynamic> input,
) async {
  try {
    // First try using the callable function method
    try {
      final response =
          await FirebaseFunctions.instanceFor(region: 'us-central1')
              .httpsCallable(callName, options: HttpsCallableOptions())
              .call(input);
      return response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : {};
    } on FirebaseFunctionsException catch (e) {
      print('Callable function error: ${e.message}. Trying HTTP method...');

      // If the callable function fails, try using the HTTP method as fallback
      String? idToken =
          await FirebaseAuth.instance.currentUser?.getIdToken(true);
      print(
          'JWT token refreshed: ${idToken != null ? 'Token present' : 'No token'}');

      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      // Use a dynamic function URL based on the function name
      final url =
          'https://us-central1-luna-kraft-7dsjjb.cloudfunctions.net/$callName';
      print('Making HTTP request to: $url');

      final requestData = jsonEncode({'data': input});
      print('Request data: $requestData');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: requestData,
      );

      print('HTTP Response status: ${response.statusCode}');
      print('HTTP Response body: ${response.body}');

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

      try {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data'] is Map
            ? Map<String, dynamic>.from(jsonResponse['data'] as Map)
            : {'success': true};
      } catch (e) {
        print('Error parsing JSON response: $e');
        throw Exception('Invalid response format: ${response.body}');
      }
    }
  } catch (e) {
    print('Cloud call error: $e');
    return {'error': e.toString()};
  }
}
