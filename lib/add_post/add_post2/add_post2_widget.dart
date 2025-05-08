import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide getCurrentTimestamp;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'add_post2_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/components/dream_posted_message.dart';
import 'dart:math';
import 'package:flutter/services.dart'; // For haptic feedback
import 'package:vector_math/vector_math_64.dart' as vector;
export 'add_post2_model.dart';

class AddPost2Widget extends StatefulWidget {
  const AddPost2Widget({super.key, String? generatedText})
      : this.generatedText = generatedText ?? '[aiResponse]';

  final String generatedText;

  static String routeName = 'AddPost2';
  static String routePath = '/addPost2';

  @override
  State<AddPost2Widget> createState() => _AddPost2WidgetState();
}

class _AddPost2WidgetState extends State<AddPost2Widget> {
  late AddPost2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddPost2Model());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController(
      text: FFAppState().aiGeneratedText,
    );
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              // Background Lottie animation
              Positioned.fill(
                child: Lottie.asset(
                  'assets/jsons/Animation_-_1739171323302.json',
                  fit: BoxFit.cover,
                  animate: true,
                ),
              ),
              // Main content
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    20.0,
                    60.0,
                    20.0,
                    20.0,
                  ),
                  child: Form(
                    key: _model.formKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title TextField
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(
                              context,
                            ).secondaryBackground,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          child: TextFormField(
                            controller: _model.textController1,
                            focusNode: _model.textFieldFocusNode1,
                            decoration: InputDecoration(
                              labelText: 'Add a title',
                              labelStyle:
                                  FlutterFlowTheme.of(context).labelMedium,
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              contentPadding: EdgeInsets.all(16.0),
                            ),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            validator: _model.textController1Validator
                                .asValidator(context),
                          ),
                        ),
                        SizedBox(height: 24.0),
                        // Dream TextField
                        Container(
                          width: double.infinity,
                          height: 200.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(
                              context,
                            ).secondaryBackground,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          child: TextFormField(
                            controller: _model.textController2,
                            focusNode: _model.textFieldFocusNode2,
                            maxLines: null,
                            decoration: InputDecoration(
                              labelText: 'Your Dream',
                              labelStyle:
                                  FlutterFlowTheme.of(context).labelMedium,
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              contentPadding: EdgeInsets.all(16.0),
                            ),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            validator: _model.textController2Validator
                                .asValidator(context),
                          ),
                        ),
                        SizedBox(height: 24.0),
                        // Tags TextField
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(
                              context,
                            ).secondaryBackground,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          child: TextFormField(
                            controller: _model.textController3,
                            focusNode: _model.textFieldFocusNode3,
                            decoration: InputDecoration(
                              labelText: 'Add Tags (Optional)',
                              labelStyle:
                                  FlutterFlowTheme.of(context).labelMedium,
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              contentPadding: EdgeInsets.all(16.0),
                            ),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            validator: _model.textController3Validator
                                .asValidator(context),
                          ),
                        ),
                        SizedBox(height: 24.0),
                        // Theme Selection
                        GradientText(
                          'Select Background',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Figtree',
                                    fontWeight: FontWeight.w600,
                                  ),
                          colors: [
                            FlutterFlowTheme.of(context).primary,
                            FlutterFlowTheme.of(context).secondary
                          ],
                        ),
                        SizedBox(height: 24.0),
                        // Background Grid Selection
                        Container(
                          height: 240.0,
                          child: _buildBackgroundSelector(context),
                        ),
                        SizedBox(height: 24.0),
                        // Share Button
                        FFButtonWidget(
                          onPressed: () async {
                            if (_model.formKey.currentState == null ||
                                !_model.formKey.currentState!.validate()) {
                              return;
                            }

                            final user = currentUserReference;
                            print('Current user: ${user?.path}'); // Debug log

                            if (user == null) {
                              print('No user found'); // Debug log
                              DreamPostedMessage.show(
                                context,
                                isError: true,
                                errorMessage: 'Please sign in to create a post',
                              );
                              return;
                            }

                            try {
                              print(
                                'Creating post with user: ${user.path}',
                              ); // Debug log
                              print('User ID: ${user.id}'); // Debug log

                              // Create the post data first
                              final postData = {
                                'Title': _model.textController1.text,
                                'Dream': _model.textController2.text,
                                'Tags': _model.textController3.text,
                                'date': getCurrentTimestamp,
                                'post_is_edited': false,
                                'poster': user,
                                'userref': user,
                              };

                              print('Post data: $postData'); // Debug log

                              // Create the post
                              final postRef = PostsRecord.collection.doc();
                              await postRef.set(postData);
                              print(
                                'Post created successfully at: ${postRef.path}',
                              ); // Debug log

                              // Create analyze record
                              print('Creating analyze record'); // Debug log
                              final analyzeData = {
                                'userref': user,
                                'timestamp': getCurrentTimestamp,
                                'user_dreams': [_model.textController2.text],
                              };

                              print('Analyze data: $analyzeData'); // Debug log

                              final analyzeRef = AnalyzeRecord.collection.doc();
                              await analyzeRef.set(analyzeData);
                              print(
                                'Analyze record created successfully at: ${analyzeRef.path}',
                              ); // Debug log

                              // Show the success message
                              DreamPostedMessage.show(context);

                              // Navigate to home page after a short delay
                              Future.delayed(Duration(milliseconds: 500), () {
                                context.pushNamed(
                                  HomePageWidget.routeName,
                                  extra: <String, dynamic>{
                                    kTransitionInfoKey: TransitionInfo(
                                      hasTransition: true,
                                      transitionType: PageTransitionType.fade,
                                    ),
                                  },
                                );
                              });
                            } catch (e, stackTrace) {
                              print('Error creating post: $e'); // Debug log
                              print('Stack trace: $stackTrace'); // Debug log
                              print(
                                'Error type: ${e.runtimeType}',
                              ); // Debug log
                              print(
                                'Error details: ${e.toString()}',
                              ); // Debug log

                              // Show error message with the new component
                              DreamPostedMessage.show(
                                context,
                                isError: true,
                                errorMessage: 'Failed to post dream',
                              );
                            }
                          },
                          text: 'Share',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 50.0,
                            padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                              0,
                              0,
                              0,
                              0,
                            ),
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(
                              context,
                            ).titleSmall.override(
                                  fontFamily: 'Figtree',
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                ),
                            elevation: 0.0,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Back button
              Positioned(
                top: 20.0,
                left: 15.0,
                child: InkWell(
                  onTap: () async {
                    context.safePop();
                  },
                  child: Icon(
                    Icons.arrow_back,
                    color: FlutterFlowTheme.of(context).primaryText,
                    size: 30.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Cosmic Background Selector Widget with 3D effects
  Widget _buildBackgroundSelector(BuildContext context) {
    // Background options with more descriptive names and aesthetic categorization
    final backgrounds = [
      {'url': 'https://picsum.photos/seed/368/600', 'name': 'Enchanted Dreams'},
      {'url': 'https://picsum.photos/seed/795/600', 'name': 'Cosmic Whispers'},
      {'url': 'https://picsum.photos/seed/101/600', 'name': 'Ethereal Journey'},
      {'url': 'https://picsum.photos/seed/222/600', 'name': 'Mystic Portal'},
      {'url': 'https://picsum.photos/seed/333/600', 'name': 'Celestial Voyage'},
    ];

    // Calculate the visible angle for each background based on the rotation value
    return Column(
      children: [
        // Main 3D cosmic selector
        Expanded(
          child: GestureDetector(
            onPanUpdate: (details) {
              // Update rotation based on horizontal drag
              setState(() {
                _model.rotationValue += details.delta.dx * 0.02;

                // When rotation passes certain thresholds, update the selected index
                int newIndex = (_model.rotationValue / (pi / 2.5)).round() %
                    backgrounds.length;
                if (newIndex < 0) newIndex += backgrounds.length;

                if (newIndex != _model.selectedBackgroundIndex) {
                  _model.selectedBackgroundIndex = newIndex;
                  _model.selectedBackgroundUrl =
                      backgrounds[newIndex]['url'] as String;

                  // Add haptic feedback when selection changes
                  HapticFeedback.mediumImpact();
                }
              });
            },
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cosmic particles background for added effect
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CustomPaint(
                        painter: StarfieldPainter(),
                      ),
                    ),
                  ),

                  // Main 3D background carousel
                  ...List.generate(backgrounds.length, (index) {
                    // Calculate position based on rotation
                    final angle = _model.rotationValue + (index * (pi / 2.5));
                    final z = cos(angle) * 120;
                    final x = sin(angle) * 220;
                    final scale = mapRange(z, -120, 120, 0.6, 1.0);
                    final opacity = mapRange(z, -120, 120, 0.3, 1.0);

                    final isSelected = _model.selectedBackgroundIndex == index;

                    // Apply a 3D transformation
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // perspective
                        ..translate(x, 0.0, z),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: opacity,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: 180 * scale,
                          height: 220 * scale,
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.0),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? FlutterFlowTheme.of(context)
                                        .primary
                                        .withOpacity(0.8)
                                    : Colors.black.withOpacity(0.3),
                                blurRadius: isSelected ? 20.0 : 8.0,
                                spreadRadius: isSelected ? 3.0 : 0.0,
                              ),
                            ],
                            border: Border.all(
                              color: isSelected
                                  ? FlutterFlowTheme.of(context).primary
                                  : Colors.white.withOpacity(0.2),
                              width: isSelected ? 3.0 : 1.0,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(
                                  backgrounds[index]['url'] as String),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black
                                    .withOpacity(isSelected ? 0.0 : 0.3),
                                BlendMode.darken,
                              ),
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Glowing border effect for selected item
                              if (isSelected)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16.0),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .primary
                                            .withOpacity(0.0),
                                        width: 3.0,
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          FlutterFlowTheme.of(context)
                                              .primary
                                              .withOpacity(0.2),
                                          Colors.transparent,
                                          FlutterFlowTheme.of(context)
                                              .secondary
                                              .withOpacity(0.2),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                              // Selection indicator
                              if (isSelected)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      boxShadow: [
                                        BoxShadow(
                                          color: FlutterFlowTheme.of(context)
                                              .primary
                                              .withOpacity(0.5),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),

                              // Background name with fancy styling
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                        Colors.black.withOpacity(0.8),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected)
                                        Container(
                                          margin: EdgeInsets.only(bottom: 4),
                                          width: 30,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                      Text(
                                        backgrounds[index]['name'] as String,
                                        textAlign: TextAlign.center,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .copyWith(
                                          color: Colors.white,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: isSelected ? 16 : 14,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Make the entire card tappable
                              Positioned.fill(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      setState(() {
                                        // Calculate the shortest rotation to reach the tapped item
                                        final currentAngle =
                                            _model.rotationValue % (2 * pi);
                                        final targetAngle =
                                            (index * (pi / 2.5)) % (2 * pi);
                                        var diff = targetAngle - currentAngle;

                                        // Find shortest path (clockwise or counterclockwise)
                                        if (diff > pi) diff -= 2 * pi;
                                        if (diff < -pi) diff += 2 * pi;

                                        _model.rotationValue += diff;
                                        _model.selectedBackgroundIndex = index;
                                        _model.selectedBackgroundUrl =
                                            backgrounds[index]['url'] as String;

                                        // Add haptic feedback
                                        HapticFeedback.selectionClick();
                                      });
                                    },
                                    splashColor: Colors.white.withOpacity(0.1),
                                    highlightColor: Colors.transparent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Navigation arrows for better usability
                  Positioned(
                    left: 0,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _model.rotationValue -= pi / 2.5;
                          final newIndex =
                              (_model.rotationValue / (pi / 2.5)).round() %
                                  backgrounds.length;
                          _model.selectedBackgroundIndex = newIndex < 0
                              ? newIndex + backgrounds.length
                              : newIndex;
                          _model.selectedBackgroundUrl =
                              backgrounds[_model.selectedBackgroundIndex]['url']
                                  as String;
                          HapticFeedback.lightImpact();
                        });
                      },
                    ),
                  ),

                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: FlutterFlowTheme.of(context).primary,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _model.rotationValue += pi / 2.5;
                          final newIndex =
                              (_model.rotationValue / (pi / 2.5)).round() %
                                  backgrounds.length;
                          _model.selectedBackgroundIndex = newIndex < 0
                              ? newIndex + backgrounds.length
                              : newIndex;
                          _model.selectedBackgroundUrl =
                              backgrounds[_model.selectedBackgroundIndex]['url']
                                  as String;
                          HapticFeedback.lightImpact();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Elegant indicator dots
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            backgrounds.length,
            (index) {
              final isSelected = _model.selectedBackgroundIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    // Calculate rotation to smoothly animate to the selected dot
                    final targetAngle = (index * (pi / 2.5));
                    final currentAngle = _model.rotationValue;
                    var diff = targetAngle - currentAngle;

                    // Find shortest path
                    if (diff > pi) diff -= 2 * pi;
                    if (diff < -pi) diff += 2 * pi;

                    _model.rotationValue += diff;
                    _model.selectedBackgroundIndex = index;
                    _model.selectedBackgroundUrl =
                        backgrounds[index]['url'] as String;
                    HapticFeedback.selectionClick();
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: isSelected ? 32.0 : 10.0,
                  height: 10.0,
                  margin: EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? FlutterFlowTheme.of(context).primary
                        : FlutterFlowTheme.of(context).primaryBackground,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: FlutterFlowTheme.of(context)
                                  .primary
                                  .withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                ),
              );
            },
          ),
        ),

        // Selected background name display
        SizedBox(height: 12),
        Text(
          backgrounds[_model.selectedBackgroundIndex]['name'] as String,
          style: FlutterFlowTheme.of(context).titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: FlutterFlowTheme.of(context).primary,
              ),
        ),
      ],
    );
  }
}

// Starfield background effect painter
class StarfieldPainter extends CustomPainter {
  final int starCount = 100;
  final List<Star> stars = [];

  StarfieldPainter() {
    // Generate random stars
    final random = Random();
    for (int i = 0; i < starCount; i++) {
      stars.add(Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 2 + 0.5,
        opacity: random.nextDouble() * 0.7 + 0.3,
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw stars
    for (var star in stars) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(star.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );

      // Draw glow around larger stars
      if (star.size > 1.5) {
        final glowPaint = Paint()
          ..color = Colors.white.withOpacity(star.opacity * 0.3)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(star.x * size.width, star.y * size.height),
          star.size * 2,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Star class for the starfield
class Star {
  final double x;
  final double y;
  final double size;
  final double opacity;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });
}

// Utility function to map values from one range to another
double mapRange(
    double value, double min1, double max1, double min2, double max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}
