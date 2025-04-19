import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/components/dream_posted_message.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'edit_page_model.dart';
export 'edit_page_model.dart';

class EditPageWidget extends StatefulWidget {
  const EditPageWidget({
    super.key,
    required this.postPara,
  });

  final DocumentReference? postPara;

  static String routeName = 'EditPage';
  static String routePath = '/editPage';

  @override
  State<EditPageWidget> createState() => _EditPageWidgetState();
}

class _EditPageWidgetState extends State<EditPageWidget> {
  late EditPageModel _model;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _selectedBackground = '';

  final List<Map<String, dynamic>> backgrounds = [
    {
      'name': 'Love',
      'path': 'assets/images/bg/love.png',
    },
    {
      'name': 'Sad',
      'path': 'assets/images/bg/sad.png',
    },
    {
      'name': 'Fantasy',
      'path': 'assets/images/bg/fantasy.png',
    },
    {
      'name': 'Space',
      'path': 'assets/images/bg/night.png',
    },
    {
      'name': 'Horror',
      'path': 'assets/images/bg/horror.png',
    },
    {
      'name': 'Future',
      'path': 'assets/images/bg/future.png',
    },
    {
      'name': 'Happy',
      'path': 'assets/images/bg/happy.png',
    },
    {
      'name': 'Old',
      'path': 'assets/images/bg/old.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditPageModel());
    _model.textFieldFocusNode1 ??= FocusNode();
    _model.textFieldFocusNode2 ??= FocusNode();
    _model.textFieldFocusNode3 ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _updatePost(PostsRecord postRecord) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare update data
      final postData = createPostsRecordData(
        title: _model.textController1!.text,
        dream: _model.textController2!.text,
        tags: _model.textController3!.text,
        postIsEdited: true,
      );

      // Only update the background if a new one was selected
      if (_selectedBackground.isNotEmpty) {
        postData['video_background_url'] = _selectedBackground;
        postData['video_background_opacity'] = 0.75;
      }

      // Update the post
      await postRecord.reference.update(postData);

      if (mounted) {
        // Show success message
        DreamPostedMessage.show(
          context,
          message: 'Post Updated Successfully',
        );

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
      }
    } catch (e) {
      print('Error updating post: $e');
      if (mounted) {
        // Show error message
        DreamPostedMessage.show(
          context,
          isError: true,
          errorMessage: 'Failed to update post',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PostsRecord>(
      stream: PostsRecord.getDocument(widget.postPara!),
      builder: (context, snapshot) {
        // Loading state
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ),
          );
        }

        final editPagePostsRecord = snapshot.data!;

        // Initialize controllers with existing data
        _model.textController1 ??=
            TextEditingController(text: editPagePostsRecord.title);
        _model.textController2 ??=
            TextEditingController(text: editPagePostsRecord.dream);
        _model.textController3 ??=
            TextEditingController(text: editPagePostsRecord.tags);

        // Initialize selected background
        if (_selectedBackground.isEmpty &&
            editPagePostsRecord.videoBackgroundUrl != null) {
          _selectedBackground = editPagePostsRecord.videoBackgroundUrl;
        }

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background with gradient and Lottie animation
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1A1A2E),
                          Color(0xFF16213E),
                        ],
                      ),
                    ),
                    child: Lottie.asset(
                      'assets/jsons/Animation_-_1739171323302.json',
                      fit: BoxFit.cover,
                      animate: true,
                      frameRate: FrameRate(60),
                    ),
                  ),

                  // Main content
                  SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header section with back button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    'Edit Post',
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
                              ).animate().fadeIn(
                                  duration: Duration(milliseconds: 400),
                                  curve: Curves.easeOut),

                              SizedBox(height: 32),

                              // Title field with glassmorphism
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _model.textController1,
                                  focusNode: _model.textFieldFocusNode1,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .override(
                                        fontFamily: 'Figtree',
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Title',
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Figtree',
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 16,
                                        ),
                                    hintText: 'Give your post a title',
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
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a title';
                                    }
                                    return null;
                                  },
                                ),
                              ).animate().fadeIn(
                                  delay: Duration(milliseconds: 200),
                                  duration: Duration(milliseconds: 600),
                                  curve: Curves.easeOut),

                              SizedBox(height: 24),

                              // Content field with glassmorphism
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _model.textController2,
                                  focusNode: _model.textFieldFocusNode2,
                                  maxLines: 6,
                                  minLines: 2,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .override(
                                        fontFamily: 'Figtree',
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Your Dream',
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Figtree',
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 16,
                                        ),
                                    hintText: 'Describe your dream...',
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
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please describe your dream';
                                    }
                                    return null;
                                  },
                                ),
                              ).animate().fadeIn(
                                  delay: Duration(milliseconds: 400),
                                  duration: Duration(milliseconds: 600),
                                  curve: Curves.easeOut),

                              SizedBox(height: 24),

                              // Background selection
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select Background',
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            fontFamily: 'Figtree',
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    SizedBox(height: 16),
                                    Container(
                                      height: 120,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: backgrounds.length,
                                        itemBuilder: (context, index) {
                                          final background = backgrounds[index];
                                          final isSelected =
                                              _selectedBackground ==
                                                  background['path'];
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedBackground =
                                                    background['path'];
                                              });
                                            },
                                            child: Container(
                                              width: 160,
                                              margin:
                                                  EdgeInsets.only(right: 12),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? FlutterFlowTheme.of(
                                                              context)
                                                          .primary
                                                      : Colors.transparent,
                                                  width: 2,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    Image.asset(
                                                      background['path'],
                                                      fit: BoxFit.cover,
                                                    ),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          begin: Alignment
                                                              .topCenter,
                                                          end: Alignment
                                                              .bottomCenter,
                                                          colors: [
                                                            Colors.transparent,
                                                            Colors.black
                                                                .withOpacity(
                                                                    0.7),
                                                          ],
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          background['name'],
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(
                                  delay: Duration(milliseconds: 600),
                                  duration: Duration(milliseconds: 600),
                                  curve: Curves.easeOut),

                              SizedBox(height: 24),

                              // Tags field with glassmorphism
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _model.textController3,
                                  focusNode: _model.textFieldFocusNode3,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .override(
                                        fontFamily: 'Figtree',
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Tags (Optional)',
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Figtree',
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 16,
                                        ),
                                    hintText: 'Add tags separated by commas',
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
                                  ),
                                ),
                              ).animate().fadeIn(
                                  delay: Duration(milliseconds: 400),
                                  duration: Duration(milliseconds: 600),
                                  curve: Curves.easeOut),

                              SizedBox(height: 24),

                              // Submit button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF6448FE),
                                      Color(0xFF9747FF),
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
                                    onTap: _isLoading
                                        ? null
                                        : () =>
                                            _updatePost(editPagePostsRecord),
                                    child: Container(
                                      width: double.infinity,
                                      height: 60,
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 24),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (_isLoading)
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          else
                                            Text(
                                              'Update Post',
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .override(
                                                        fontFamily: 'Figtree',
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                            ),
                                          if (!_isLoading) ...[
                                            SizedBox(width: 12),
                                            Icon(
                                              Icons.send_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(
                                  delay: Duration(milliseconds: 1000),
                                  duration: Duration(milliseconds: 600),
                                  curve: Curves.easeOut),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
