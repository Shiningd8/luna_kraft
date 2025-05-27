import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/cloud_functions/cloud_functions.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/add_post/create_post/create_post_widget.dart';
import '/widgets/lottie_background.dart';
import '/services/app_state.dart' as custom_app_state;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'add_post1_model.dart';
import '/utils/serialization_helpers.dart';
import 'package:luna_kraft/backend/backend.dart';
export 'add_post1_model.dart';

class AddPost1Widget extends StatefulWidget {
  const AddPost1Widget({super.key});

  static String routeName = 'AddPost1';
  static String routePath = '/addPost1';

  @override
  State<AddPost1Widget> createState() => _AddPost1WidgetState();
}

class _AddPost1WidgetState extends State<AddPost1Widget>
    with TickerProviderStateMixin {
  late AddPost1Model _model;
  bool _isLoading = false;
  bool _isGenerating = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddPost1Model());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    // Add listener to text controller
    _model.textController?.addListener(() {
      setState(() {}); // Trigger rebuild when text changes
    });

    // Initialize glow animation controller
    _glowController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    );

    // Create color animation with pulsing effect
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation
    _glowController.repeat();

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.ms,
            duration: 600.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });

    // Important: Don't auto-generate the dream when the page is first loaded
    // The user should explicitly click the "Generate Dream" button
    _model.apiResponse = '';
    
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    _glowController.stop();
    _glowController.dispose();
    super.dispose();
  }

  Color _getGlowColor() {
    final value = _glowAnimation.value;
    if (value < 0.25) {
      return Color.lerp(Color(0xFF6448FE), Color(0xFF9747FF), value * 4)!;
    } else if (value < 0.5) {
      return Color.lerp(
          Color(0xFF9747FF), Color(0xFF20B6EB), (value - 0.25) * 4)!;
    } else if (value < 0.75) {
      return Color.lerp(
          Color(0xFF20B6EB), Color(0xFF036257), (value - 0.5) * 4)!;
    } else {
      return Color.lerp(
          Color(0xFF036257), Color(0xFF6448FE), (value - 0.75) * 4)!;
    }
  }

  double _getGlowOpacity() {
    return 0.4 + (0.3 * (1 - (_glowAnimation.value - 0.5).abs() * 2));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    // Access the custom app state
    context.watch<custom_app_state.AppState>();

    // Make sure apiResponse is reset when component is built initially
    if (_model.apiResponse == null) {
      _model.apiResponse = '';
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: LottieBackground(
          child: SafeArea(
            top: true,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Header section
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => context.safePop(),
                                child: Icon(
                                  Icons.arrow_back_ios_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            'AI Dream Assistant',
                            style: FlutterFlowTheme.of(context)
                                .titleMedium
                                .override(
                                  fontFamily: 'Figtree',
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(width: 48),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),

                    // Dream input section
                    if (_model.apiResponse == null ||
                        _model.apiResponse == '')
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share Your Dream Fragment',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tell us what you remember, and we\'ll help complete your dream story',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 16,
                                  ),
                            ),
                            SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isGenerating
                                      ? Colors.transparent
                                      : Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                                boxShadow: _isGenerating
                                    ? [
                                        BoxShadow(
                                          color: _getGlowColor()
                                              .withOpacity(_getGlowOpacity()),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                        BoxShadow(
                                          color: _getGlowColor().withOpacity(
                                              _getGlowOpacity() * 0.7),
                                          blurRadius: 30,
                                          spreadRadius: 4,
                                        ),
                                        BoxShadow(
                                          color: _getGlowColor().withOpacity(
                                              _getGlowOpacity() * 0.5),
                                          blurRadius: 40,
                                          spreadRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: TextFormField(
                                controller: _model.textController,
                                focusNode: _model.textFieldFocusNode,
                                maxLines: null,
                                minLines: 4,
                                maxLength: 400,
                                enabled: !_isGenerating,
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Figtree',
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Start dreaming here... (min. 45 words)',
                                  hintStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Figtree',
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 16,
                                      ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.all(20),
                                  counterStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Figtree',
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.tips_and_updates,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          'How to Write Effective Dream Prompts',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Figtree',
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Container(
                                    height: 100,
                                    child: PageView(
                                      controller: PageController(
                                        initialPage: 0,
                                        viewportFraction: 1.0,
                                      ),
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        _buildTipCard(
                                            context,
                                            'Keep it simple and specific',
                                            'Include only what you remember - don\'t add details you aren\'t sure about.',
                                            Icons.auto_awesome),
                                        _buildTipCard(
                                            context,
                                            'Be precise',
                                            'Mention colors, sensations, and settings exactly as you recall them.',
                                            Icons.colorize),
                                        _buildTipCard(
                                            context,
                                            'Example: Good Format',
                                            'I was in a blue room. The door opened and I saw a garden with tall trees.',
                                            Icons.thumb_up_outlined),
                                        _buildTipCard(
                                            context,
                                            'Example: Avoid Interpretation',
                                            'Write "I saw a snake" instead of "I saw a snake which represents my fear"',
                                            Icons.thumb_down_outlined),
                                        _buildTipCard(
                                            context,
                                            'Include sensory details',
                                            'Mention sounds, smells, textures, and how things felt physically in your dream.',
                                            Icons.sensors),
                                        _buildTipCard(
                                            context,
                                            'Describe transitions',
                                            'If you don\'t remember how you moved between scenes, simply say "somehow I was now at..."',
                                            Icons.swap_horiz),
                                        _buildTipCard(
                                            context,
                                            'Example: Good Fragment',
                                            'I was running in a dark forest. The trees were tall with red leaves. Suddenly I was at my childhood home.',
                                            Icons.format_quote),
                                        _buildTipCard(
                                            context,
                                            'Avoid assumptions',
                                            'If you\'re unsure if something was a person or creature, describe only what you saw without naming it.',
                                            Icons.psychology),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.swipe,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Swipe for more tips',
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              fontFamily: 'Figtree',
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                              fontSize: 12,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                          delay: 200.ms,
                          duration: 600.ms,
                          curve: Curves.easeOut),

                    // Next button
                    if (_model.apiResponse == null || _model.apiResponse == '')
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: Column(
                          children: [
                            // Word count indicator
                            if (!_isGenerating)
                              Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${_model.textController.text.split(' ').where((word) => word.isNotEmpty).length}/45 words minimum',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            fontFamily: 'Figtree',
                                            color: _model.textController.text
                                                        .split(' ')
                                                        .where((word) =>
                                                            word.isNotEmpty)
                                                        .length >=
                                                    45
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.8),
                                            fontSize: 12,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _model.textController.text
                                                .split(' ')
                                                .where(
                                                    (word) => word.isNotEmpty)
                                                .length >=
                                            45
                                        ? Color(0xFF6448FE)
                                        : Color(0xFF6448FE).withOpacity(0.5),
                                    _model.textController.text
                                                .split(' ')
                                                .where(
                                                    (word) => word.isNotEmpty)
                                                .length >=
                                            45
                                        ? Color(0xFF9747FF)
                                        : Color(0xFF9747FF).withOpacity(0.5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF9747FF).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _model.textController.text
                                                  .split(' ')
                                                  .where(
                                                      (word) => word.isNotEmpty)
                                                  .length >=
                                              45 &&
                                          !_isGenerating
                                      ? () async {
                                          if (_model.textController.text
                                                  .split(' ')
                                                  .where((word) =>
                                                      word.isNotEmpty)
                                                  .length <
                                              45) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Please enter at least 45 words.',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                duration: Duration(seconds: 2),
                                                backgroundColor:
                                                    Colors.red.shade400,
                                              ),
                                            );
                                            return;
                                          }

                                          setState(() {
                                            _isGenerating = true;
                                            _isLoading = true;
                                          });
                                          safeSetState(() {});

                                          try {
                                            print('===== DEBUG: About to call Gemini API with REAL FIREBASE FUNCTION =====');
                                            print('🤖 Calling Gemini API with Direct HTTP - Input length: ${_model.textController.text.length} characters');
                                            
                                            final userText = _model.textController.text.trim();
                                            print('📝 First 100 chars of input: ${userText.substring(0, userText.length > 100 ? 100 : userText.length)}...');
                                            
                                            print('🔥 Making direct HTTP call to Firebase function: geminiAI');
                                            // Call directly without helper
                                            final response = await makeCloudCall(
                                              'geminiAI',
                                              {
                                                'callName': 'GeminiAPICall',
                                                'variables': {
                                                  'userInputText': userText,
                                                },
                                              },
                                            );
                                            
                                            print('===== DEBUG: Received response from Gemini API =====');
                                            print('Response received. Type: ${response.runtimeType}, Keys: ${response is Map ? (response as Map).keys.toList() : "not a map"}');
                                            
                                            String extractedText = '';
                                            
                                            // Handle response - check for direct generatedText field first
                                            if (response is Map) {
                                              // Check if debugging is on to print more details
                                              if (kDebugMode) {
                                                print('Response map: ${response.toString().substring(0, response.toString().length > 200 ? 200 : response.toString().length)}...');
                                              }
                                              
                                              // Try most likely path first - our updated field generatedText
                                              if (response['generatedText'] is String) {
                                                extractedText = response['generatedText'];
                                                print('Found text from generatedText: ${extractedText.substring(0, extractedText.length > 50 ? 50 : extractedText.length)}...');
                                              } 
                                              // Handle response structure directly from Gemini API
                                              else if (response['jsonBody'] is Map && (response['jsonBody'] as Map)['candidates'] is List) {
                                                final jsonBody = response['jsonBody'] as Map;
                                                final candidates = jsonBody['candidates'] as List;
                                                
                                                if (candidates.isNotEmpty) {
                                                  final candidate = candidates[0] as Map;
                                                  if (candidate['content'] is Map) {
                                                    final content = candidate['content'] as Map;
                                                    if (content['parts'] is List && (content['parts'] as List).isNotEmpty) {
                                                      final parts = content['parts'] as List;
                                                      extractedText = parts[0]['text']?.toString() ?? '';
                                                      print('Found text from jsonBody.candidates: ${extractedText.substring(0, extractedText.length > 50 ? 50 : extractedText.length)}...');
                                                    }
                                                  }
                                                }
                                              }
                                              // Try various other response formats
                                              else if (response['candidates'] is List && (response['candidates'] as List).isNotEmpty) {
                                                final candidates = response['candidates'] as List;
                                                final candidate = candidates[0];
                                                
                                                if (candidate is Map && candidate['content'] is Map) {
                                                  final content = candidate['content'] as Map;
                                                  if (content['parts'] is List && (content['parts'] as List).isNotEmpty) {
                                                    final parts = content['parts'] as List;
                                                    extractedText = parts[0]['text']?.toString() ?? '';
                                                    print('Found text from direct candidates: ${extractedText.substring(0, extractedText.length > 50 ? 50 : extractedText.length)}...');
                                                  }
                                                }
                                              }
                                              // Try looking in body if nested
                                              else if (response['body'] is Map) {
                                                final body = response['body'] as Map;
                                                if (body['candidates'] is List && (body['candidates'] as List).isNotEmpty) {
                                                  final candidate = (body['candidates'] as List)[0];
                                                  if (candidate is Map && candidate['content'] is Map) {
                                                    final content = candidate['content'] as Map;
                                                    if (content['parts'] is List && (content['parts'] as List).isNotEmpty) {
                                                      extractedText = (content['parts'] as List)[0]['text']?.toString() ?? '';
                                                      print('Found text from body.candidates: ${extractedText.substring(0, extractedText.length > 50 ? 50 : extractedText.length)}...');
                                                    }
                                                  }
                                                }
                                              }
                                              // Last resort if nothing else worked
                                              else if (response['data'] is Map) {
                                                final dataMap = response['data'] as Map;
                                                print('Looking in data field, keys: ${dataMap.keys.toList()}');
                                                
                                                // Try to find text directly or through possible paths
                                                if (dataMap['text'] is String) {
                                                  extractedText = dataMap['text'];
                                                } else if (dataMap['content'] is String) {
                                                  extractedText = dataMap['content'];
                                                } else if (dataMap['message'] is String) {
                                                  extractedText = dataMap['message'];
                                                }
                                              }
                                            }
                                            
                                            if (extractedText.isEmpty) {
                                              print('SIMPLIFIED VERSION - No text found in response');
                                              setState(() {
                                                _isGenerating = false;
                                                _isLoading = false;
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Failed to generate dream. Please try again.',
                                                    style: TextStyle(color: Colors.white),
                                                  ),
                                                  backgroundColor: Colors.red.shade400,
                                                  duration: Duration(seconds: 3),
                                                ),
                                              );
                                              return;
                                            }
                                            
                                            _model.apiResponse = extractedText;
                                            print('SIMPLIFIED VERSION - Setting API response: ${_model.apiResponse.substring(0, _model.apiResponse.length > 50 ? 50 : _model.apiResponse.length)}...');
                                            
                                            // Save the API result to the model for UI use
                                            _model.apiResultssd = ApiCallResponse(
                                              {'text': extractedText},
                                              {},
                                              200,
                                            );
                                          } catch (e) {
                                            print('Error generating dream: $e');
                                            setState(() {
                                              _isGenerating = false;
                                              _isLoading = false;
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to generate dream: $e',
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                                backgroundColor: Colors.red.shade400,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                            return;
                                          } finally {
                                          setState(() {
                                            _isLoading = false;
                                            _isGenerating = false;
                                          });
                                          safeSetState(() {});
                                          }
                                        }
                                      : null,
                                  child: Container(
                                    width: double.infinity,
                                    height: 60,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 24),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _isGenerating
                                              ? 'Generating...'
                                              : 'Generate Dream',
                                          style: FlutterFlowTheme.of(context)
                                              .titleSmall
                                              .override(
                                                fontFamily: 'Figtree',
                                                color: _model.textController
                                                                .text
                                                                .split(' ')
                                                                .where((word) =>
                                                                    word
                                                                        .isNotEmpty)
                                                                .length >=
                                                            45 &&
                                                        !_isGenerating
                                                    ? Colors.white
                                                    : Colors.white
                                                        .withOpacity(0.7),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        SizedBox(width: 12),
                                        if (!_isGenerating)
                                          Icon(
                                            Icons.auto_awesome,
                                            color: _model.textController.text
                                                        .split(' ')
                                                        .where((word) =>
                                                            word.isNotEmpty)
                                                        .length >=
                                                    45
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.7),
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                          delay: 400.ms,
                          duration: 600.ms,
                          curve: Curves.easeOut),

                    // Loading Animation
                    if (_isGenerating)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              child: Lottie.asset(
                                'assets/jsons/loading.json',
                                fit: BoxFit.contain,
                                animate: true,
                                frameRate: FrameRate(60),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Hang on...',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut),

                    // AI Generated Content
                    if (_model.apiResponse != null && _model.apiResponse != '' && _model.apiResponse != 'unset')
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.auto_awesome,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Text(
                                        'AI Generated Dream',
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              fontFamily: 'Figtree',
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 24),
                                  Text(
                                    _model.apiResponse,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Figtree',
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          setState(() {
                                            _isGenerating = false;
                                            _model.apiResponse = '';
                                            _model.apiResultssd = null;
                                          });
                                          safeSetState(() {});
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.refresh,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Try Again',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Figtree',
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF6448FE),
                                          Color(0xFF9747FF),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF9747FF)
                                              .withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          context.pushNamed(
                                            CreatePostWidget.routeName,
                                            queryParameters: {
                                              'generatedText': serializeParam(
                                                _model.apiResponse,
                                                ParamType.String,
                                              ),
                                            }.withoutNulls,
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Use This',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Figtree',
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                          delay: 600.ms,
                          duration: 800.ms,
                          curve: Curves.easeOut),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(
      BuildContext context, String title, String description, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Color(0xFF9747FF),
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Figtree',
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Figtree',
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
