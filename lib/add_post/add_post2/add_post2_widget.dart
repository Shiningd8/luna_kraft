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
export 'add_post2_model.dart';

class AddPost2Widget extends StatefulWidget {
  const AddPost2Widget({
    super.key,
    String? generatedText,
  }) : this.generatedText = generatedText ?? '[aiResponse]';

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

    _model.textController2 ??=
        TextEditingController(text: FFAppState().aiGeneratedText);
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
                  padding:
                      EdgeInsetsDirectional.fromSTEB(20.0, 60.0, 20.0, 20.0),
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
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
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
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
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
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
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
                          'Select Theme',
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
                        // Carousel
                        Container(
                          height: 200.0,
                          child: CarouselSlider(
                            items: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  'https://picsum.photos/seed/368/600',
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  'https://picsum.photos/seed/795/600',
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  'https://picsum.photos/seed/101/600',
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                            carouselController: _model.carouselController ??=
                                CarouselSliderController(),
                            options: CarouselOptions(
                              initialPage: 1,
                              viewportFraction: 0.8,
                              enlargeCenterPage: true,
                              enlargeFactor: 0.25,
                              enableInfiniteScroll: true,
                              scrollDirection: Axis.horizontal,
                              autoPlay: false,
                              onPageChanged: (index, _) =>
                                  _model.carouselCurrentIndex = index,
                            ),
                          ),
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
                                  'Creating post with user: ${user.path}'); // Debug log
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
                                  'Post created successfully at: ${postRef.path}'); // Debug log

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
                                  'Analyze record created successfully at: ${analyzeRef.path}'); // Debug log

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
                                  'Error type: ${e.runtimeType}'); // Debug log
                              print(
                                  'Error details: ${e.toString()}'); // Debug log

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
                            iconPadding:
                                EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
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
}
