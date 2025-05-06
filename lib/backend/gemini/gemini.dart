import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '/flutter_flow/flutter_flow_util.dart';

const _kGeminiApiKey = 'AIzaSyBD12Lf4b9UB_ZhinHFvNx3JT63u41sa_s';

// Maximum retry attempts for network issues
const int _maxRetries = 3;

// Safety settings to ensure better responses
final List<Map<String, String>> _safetySettings = [
  {
    "category": "HARM_CATEGORY_HARASSMENT",
    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
  },
  {
    "category": "HARM_CATEGORY_HATE_SPEECH",
    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
  },
  {
    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
  },
  {
    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
  }
];

// Retry with exponential backoff
Future<T> _retryWithBackoff<T>({
  required Future<T> Function() operation,
  int maxRetries = _maxRetries,
}) async {
  int attempts = 0;

  while (true) {
    try {
      attempts++;
      return await operation();
    } catch (e) {
      if (attempts >= maxRetries) rethrow;

      // Exponential backoff: 400ms, 800ms, 1600ms, etc.
      final waitTime = Duration(milliseconds: 400 * (1 << (attempts - 1)));
      print('Gemini API retry attempt $attempts after $waitTime: $e');
      await Future.delayed(waitTime);
    }
  }
}

Future<String?> geminiGenerateText(
  BuildContext context,
  String prompt,
) async {
  try {
    return await _retryWithBackoff(
      operation: () async {
        // Create a model with advanced settings for better responses
        final model = GenerativeModel(
          model: 'gemini-1.5-pro',
          apiKey: _kGeminiApiKey,
          generationConfig: GenerationConfig(
            temperature: 0.6, // Lower temperature for more precise responses
            topP: 0.95,
            topK: 35,
            maxOutputTokens: 4096,
          ),
        );

        // Create enhanced prompt that encourages following instructions
        final enhancedPrompt = """
[SYSTEM: You must follow these instructions exactly]

$prompt

IMPORTANT GUIDELINES:
- Respond directly to what's asked without adding unnecessary information
- Stay focused on the specific request without tangents
- Be concise and precise
- Do not add explanations unless specifically requested
- Do not add disclaimers, notes, or commentary
""";

        // Create content with the prompt
        final content = [Content.text(enhancedPrompt)];

        // Log and send request
        print('Sending prompt to Gemini: $prompt');
        final response = await model.generateContent(content);

        // Verify response
        if (response.text == null || response.text!.isEmpty) {
          throw Exception('Empty response from Gemini API');
        }

        // Log and return response
        print(
            'Received response from Gemini: ${response.text?.substring(0, min(50, response.text!.length))}...');
        return response.text;
      },
    );
  } catch (e) {
    print('Gemini text generation error: $e');
    showSnackbar(
      context,
      'Unable to generate response. Please try again later: ${e.toString().substring(0, min(50, e.toString().length))}...',
    );
    return null;
  }
}

Future<String?> geminiCountTokens(
  BuildContext context,
  String prompt,
) async {
  try {
    return await _retryWithBackoff(
      operation: () async {
        final model = GenerativeModel(
          model: 'gemini-1.5-pro',
          apiKey: _kGeminiApiKey,
        );

        final content = [Content.text(prompt)];

        final response = await model.countTokens(content);
        return response.totalTokens.toString();
      },
    );
  } catch (e) {
    print('Gemini token counting error: $e');
    showSnackbar(
      context,
      'Unable to count tokens: ${e.toString()}',
    );
    return null;
  }
}

Future<Uint8List> loadImageBytesFromUrl(String imageUrl) async {
  try {
    return await _retryWithBackoff(
      operation: () async {
        final response = await http.get(Uri.parse(imageUrl));

        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          throw Exception('Failed to load image: HTTP ${response.statusCode}');
        }
      },
    );
  } catch (e) {
    print('Image loading error: $e');
    rethrow;
  }
}

Future<String?> geminiTextFromImage(
  BuildContext context,
  String prompt, {
  String? imageNetworkUrl = '',
  FFUploadedFile? uploadImageBytes,
}) async {
  assert(
    imageNetworkUrl != null || uploadImageBytes != null,
    'Either imageNetworkUrl or uploadImageBytes must be provided.',
  );

  try {
    return await _retryWithBackoff(
      operation: () async {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _kGeminiApiKey,
          generationConfig: GenerationConfig(
            temperature: 0.5, // Lower for more predictable responses
            maxOutputTokens: 4096,
          ),
        );

        late final Uint8List? imageBytes;

        try {
          imageBytes = uploadImageBytes != null
              ? uploadImageBytes.bytes
              : await loadImageBytesFromUrl(imageNetworkUrl!);
        } catch (e) {
          print('Error loading image: $e');
          throw Exception('Failed to load image: $e');
        }

        if (imageBytes == null) {
          throw Exception('Image bytes are null');
        }

        // Create enhanced prompt for image analysis with specific instruction framing
        final enhancedPrompt = """
[SYSTEM: You are an image analysis assistant that follows instructions precisely]

$prompt

IMPORTANT GUIDELINES:
- Focus ONLY on what is visible in the image
- Respond directly to the specific question about the image
- Do not guess or speculate about things not clearly visible
- Be concise and specific in your description
- Avoid unnecessary explanations unless specifically requested
""";

        // Create multimodal content with strong instruction
        final multimodalContent = [
          Content.multi([
            TextPart(enhancedPrompt),
            DataPart('image/jpeg', imageBytes),
          ])
        ];

        print('Sending image analysis prompt to Gemini: $prompt');
        final response = await model.generateContent(multimodalContent);

        if (response.text == null || response.text!.isEmpty) {
          throw Exception('Empty response from Gemini API');
        }

        print(
            'Received image analysis from Gemini: ${response.text?.substring(0, min(50, response.text!.length))}...');
        return response.text;
      },
    );
  } catch (e) {
    print('Gemini image analysis error: $e');
    showSnackbar(
      context,
      'Unable to analyze image: ${e.toString()}',
    );
    return null;
  }
}
