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
import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _tagsFocusNode = FocusNode();
  final List<String> _tags = [];
  bool _showHashtagWarning = false;
  Map<String, int> _tagPostCounts = {};
  Timer? _tagSearchDebounce;
  int _maxTags = 15;

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

    _tagsFocusNode.addListener(() {
      if (!_tagsFocusNode.hasFocus) {
        _addCurrentTagIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _tagsFocusNode.dispose();
    _tagSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _checkTagPostCount(String tag) async {
    if (tag.isEmpty) return;

    _tagSearchDebounce?.cancel();

    _tagSearchDebounce = Timer(Duration(milliseconds: 300), () async {
      try {
        final String searchTag = tag.toLowerCase().trim();

        // Simpler query that doesn't require composite index - just get public posts
        final publicPostsQuery = await FirebaseFirestore.instance
            .collection('posts')
            .where('is_private', isEqualTo: false)
            .limit(100) // Reasonable limit to avoid too many reads
            .get();

        // Reset counts
        Map<String, int> tagCounts = {};

        for (var doc in publicPostsQuery.docs) {
          // Get tags string from document
          final String tagsString = doc.data()['tags'] as String? ?? '';

          // Split tags, normalize and filter empty ones
          final List<String> tagList = tagsString
              .toLowerCase()
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();

          // Count exact matches and similar tags
          for (var postTag in tagList) {
            // Increment count for this tag
            tagCounts[postTag] = (tagCounts[postTag] ?? 0) + 1;
          }
        }

        // If searchTag isn't found, ensure it exists with 0 count
        if (!tagCounts.containsKey(searchTag)) {
          tagCounts[searchTag] = 0;
        }

        // Update the UI with the tag counts
        if (mounted) {
          setState(() {
            _tagPostCounts = tagCounts;
          });
        }
      } catch (e) {
        print('Error checking tag post count: $e');
      }
    });
  }

  void _addCurrentTagIfNeeded() {
    final currentTag = _model.textController3!.text.trim();
    if (currentTag.isNotEmpty && _tags.length < _maxTags) {
      if (!_tags.contains(currentTag)) {
        setState(() {
          _tags.add(currentTag);
          _model.textController3!.clear();
        });
      } else {
        _model.textController3!.clear();
      }
    }
  }

  void _handleTagInput(String value) {
    if (value.contains(' ')) {
      final currentTag = value.split(' ')[0].trim();
      if (currentTag.isNotEmpty && _tags.length < _maxTags) {
        if (!_tags.contains(currentTag)) {
          setState(() {
            _tags.add(currentTag);
            _model.textController3!.clear();
          });
        } else {
          _model.textController3!.clear();
        }
      } else {
        _model.textController3!.text = value.split(' ')[0];
        _model.textController3!.selection = TextSelection.fromPosition(
          TextPosition(offset: _model.textController3!.text.length),
        );
      }
    } else if (value.contains('#')) {
      setState(() {
        _showHashtagWarning = true;
        _model.textController3!.text = value.replaceAll('#', '');
        _model.textController3!.selection = TextSelection.fromPosition(
          TextPosition(offset: _model.textController3!.text.length),
        );
      });

      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showHashtagWarning = false;
          });
        }
      });
    } else {
      _checkTagPostCount(value);
    }
  }

  Future<void> _updatePost(PostsRecord postRecord) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String formattedTags =
          _tags.map((tag) => tag.toLowerCase()).join(', ');

      final Map<String, dynamic> postData = {
        'title': _model.textController1!.text,
        'dream': _model.textController2!.text,
        'tags': formattedTags,
        'post_is_edited': true,
      };

      if (_selectedBackground.isNotEmpty) {
        postData['video_background_url'] = _selectedBackground;
        postData['video_background_opacity'] = 0.75;
      }

      await postRecord.reference.update(postData);

      if (mounted) {
        DreamPostedMessage.show(
          context,
          message: 'Post Updated Successfully',
        );

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

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              if (_tags.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              FlutterFlowTheme.of(context)
                                  .primary
                                  .withOpacity(0.6),
                              FlutterFlowTheme.of(context)
                                  .secondary
                                  .withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() {
                                _tags.remove(tag);
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '#$tag',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Figtree',
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              if (_tags.length < _maxTags)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _model.textController3,
                      focusNode: _tagsFocusNode,
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            fontFamily: 'Figtree',
                            color: Colors.white,
                            fontSize: 16,
                          ),
                      decoration: InputDecoration(
                        labelText: _tags.isEmpty ? 'Tags (Optional)' : null,
                        hintText: 'Type and press space to add a tag',
                        labelStyle:
                            FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Figtree',
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 16,
                                ),
                        hintStyle:
                            FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontFamily: 'Figtree',
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 16,
                                ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(20),
                        suffixIcon: _model.textController3!.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.add_circle_outline,
                                    color: Colors.white),
                                onPressed: () {
                                  _addCurrentTagIfNeeded();
                                },
                              )
                            : null,
                      ),
                      onChanged: _handleTagInput,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        _addCurrentTagIfNeeded();
                      },
                    ),
                    if (_model.textController3!.text.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: FlutterFlowTheme.of(context)
                                .primary
                                .withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Builder(builder: (context) {
                          // Get similar tags with posts > 0, except the exact match
                          final similarTagsWithPosts = _tagPostCounts.entries
                              .where((entry) =>
                                  entry.key.startsWith(
                                      _model.textController3!.text) &&
                                  entry.key != _model.textController3!.text &&
                                  entry.value > 0)
                              .take(5)
                              .toList();

                          return Column(
                            children: [
                              // Show current tag with count if available
                              if (_tagPostCounts
                                  .containsKey(_model.textController3!.text))
                                _buildTagSuggestion(
                                  _model.textController3!.text,
                                  _tagPostCounts[
                                          _model.textController3!.text] ??
                                      0,
                                ),

                              // Add header if we have similar tags with posts
                              if (similarTagsWithPosts.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    'Similar tags:',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          fontFamily: 'Figtree',
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                  ),
                                ),

                              // Show the similar tags with posts > 0
                              ...similarTagsWithPosts
                                  .map((entry) => _buildTagSuggestion(
                                      entry.key, entry.value))
                                  .toList(),

                              // If no tags found, show a message
                              if (_tagPostCounts.isEmpty ||
                                  (!_tagPostCounts.containsKey(
                                          _model.textController3!.text) &&
                                      similarTagsWithPosts.isEmpty))
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No matching tags found. Create a new one!',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Figtree',
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          );
                        }),
                      ),
                  ],
                ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_showHashtagWarning)
                      Expanded(
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'No need to add # - hashtags are added automatically',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Figtree',
                                      color: Colors.amber,
                                    ),
                          ),
                        ),
                      )
                    else
                      Text(
                        '${_tags.length}/$_maxTags tags',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Figtree',
                              color: _tags.length >= _maxTags
                                  ? FlutterFlowTheme.of(context).error
                                  : Colors.white.withOpacity(0.5),
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(
        delay: Duration(milliseconds: 400),
        duration: Duration(milliseconds: 600),
        curve: Curves.easeOut);
  }

  Widget _buildTagSuggestion(String tag, int count) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _model.textController3!.text = tag;
            _addCurrentTagIfNeeded();
          });
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.tag,
                color: FlutterFlowTheme.of(context).primary,
                size: 18,
              ),
              SizedBox(width: 12),
              Text(
                tag,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Figtree',
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$count ' + (count == 1 ? 'post' : 'posts'),
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Figtree',
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PostsRecord>(
      stream: PostsRecord.getDocument(widget.postPara!),
      builder: (context, snapshot) {
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

        _model.textController1 ??=
            TextEditingController(text: editPagePostsRecord.title);
        _model.textController2 ??=
            TextEditingController(text: editPagePostsRecord.dream);
        _model.textController3 ??= TextEditingController();

        if (_tags.isEmpty &&
            editPagePostsRecord.hasTags() &&
            editPagePostsRecord.tags.isNotEmpty) {
          final tagsString = editPagePostsRecord.tags;
          if (tagsString.isNotEmpty) {
            final tagsList = tagsString.contains(',')
                ? tagsString
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList()
                : tagsString.split(' ').where((t) => t.isNotEmpty).toList();
            _tags.addAll(tagsList);
          }
        }

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
                              _buildTagsField(),
                              SizedBox(height: 24),
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
