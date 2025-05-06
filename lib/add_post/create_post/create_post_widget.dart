import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide getCurrentTimestamp;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/widgets/lottie_background.dart';
import '/services/app_state.dart' as custom_app_state;
import 'package:lottie/lottie.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:ui';

// Add import for DreamPostedMessage component
import '/components/dream_posted_message.dart';
import '/components/premium_upload_dialog.dart';
import '/components/remaining_uploads_card.dart';
import '/services/dream_upload_service.dart';

class CreatePostWidget extends StatefulWidget {
  const CreatePostWidget({
    super.key,
    String? generatedText,
  }) : this.generatedText = generatedText ?? '';

  final String generatedText;

  static String routeName = 'CreatePost';
  static String routePath = '/createPost';

  @override
  State<CreatePostWidget> createState() => _CreatePostWidgetState();
}

class _CreatePostWidgetState extends State<CreatePostWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _tagsFocusNode = FocusNode();
  final List<String> _tags = [];
  bool _showHashtagWarning = false;
  Map<String, int> _tagPostCounts = {};
  Timer? _tagSearchDebounce;
  int _maxTags = 15;
  String _errorMessage = '';

  // Add missing variables
  int _wordCount = 0;
  int _minWordCount = 25; // Changing from 5 to 25 words required
  int _lunaCoins = 0;
  int _remainingFreeUploads = 0;

  bool _isLoading = false;
  String _selectedBackground = '';
  bool _isPrivate = false;

  // Upload limits
  bool _uploadsChecked = false;

  // Add the backgrounds array
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

  // Word count tracking
  void _updateWordCount() {
    final text = _contentController.text.trim();
    // Split by whitespace and filter out empty strings
    final words =
        text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();

    setState(() {
      _wordCount = words.length;
    });
  }

  // Check how many free uploads are available
  Future<void> _checkUploadAvailability() async {
    try {
      final result = await DreamUploadService.checkUploadAvailability();
      setState(() {
        _uploadsChecked = true;
        _remainingFreeUploads = result['remainingFreeUploads'];
        _lunaCoins = result['lunaCoins'];
      });
    } catch (e) {
      print('Error checking upload availability: $e');
    }
  }

  // Improved tag post count retrieval with more accurate counting
  Future<void> _checkTagPostCount(String tag) async {
    if (tag.isEmpty) return;

    // Cancel any existing debounce timer
    _tagSearchDebounce?.cancel();

    // Create a new debounce timer
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

  // Add a method to add the current tag to the list
  void _addCurrentTagIfNeeded() {
    final currentTag = _tagsController.text.trim();
    if (currentTag.isNotEmpty && _tags.length < _maxTags) {
      if (!_tags.contains(currentTag)) {
        setState(() {
          _tags.add(currentTag);
          _tagsController.clear();
        });
      } else {
        _tagsController.clear();
      }
    }
  }

  // Add a method to handle tag input
  void _handleTagInput(String value) {
    if (value.contains(' ')) {
      // Space pressed - add the tag
      final currentTag = value.split(' ')[0].trim();
      if (currentTag.isNotEmpty && _tags.length < _maxTags) {
        if (!_tags.contains(currentTag)) {
          setState(() {
            _tags.add(currentTag);
            _tagsController.clear();
          });
        } else {
          _tagsController.clear();
        }
      } else {
        _tagsController.text = value.split(' ')[0];
        _tagsController.selection = TextSelection.fromPosition(
          TextPosition(offset: _tagsController.text.length),
        );
      }
    } else if (value.contains('#')) {
      // Show warning and remove the # character
      setState(() {
        _showHashtagWarning = true;
        _tagsController.text = value.replaceAll('#', '');
        _tagsController.selection = TextSelection.fromPosition(
          TextPosition(offset: _tagsController.text.length),
        );
      });

      // Hide warning after a delay
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showHashtagWarning = false;
          });
        }
      });
    } else {
      // Check post count for the current tag
      _checkTagPostCount(value);
    }
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check minimum word count
    if (_wordCount < _minWordCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Please write at least $_minWordCount words to share your dream.'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    // Check if user can upload for free
    final availabilityCheck =
        await DreamUploadService.checkUploadAvailability();
    final canUploadForFree = availabilityCheck['canUploadForFree'];
    final lunaCoins = availabilityCheck['lunaCoins'];

    // If cannot upload for free, show premium dialog
    if (!canUploadForFree) {
      final purchaseSuccess = await PremiumUploadDialog.show(
        context,
        lunaCoins: lunaCoins,
        onPurchase: (success) {
          // Update luna coins in state if purchase was successful
          if (success) {
            setState(() {
              _lunaCoins -= DreamUploadService.LUNA_COINS_COST;
            });
          }
        },
      );

      // If they cancelled or purchase failed, don't continue
      if (purchaseSuccess != true) {
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Prepare tags for Firestore - convert tags list to comma-separated string
      final String formattedTags =
          _tags.map((tag) => tag.toLowerCase()).join(', ');

      final postData = {
        'title': _titleController.text,
        'dream': _contentController.text,
        'tags': formattedTags,
        'date': getCurrentTimestamp,
        'post_is_edited': false,
        'poster': currentUserReference,
        'userref': currentUserReference,
        'likes': [],
        'Post_saved_by': [],
        'video_background_url': _selectedBackground,
        'video_background_opacity': 0.75,
        'is_private': _isPrivate,
      };

      await FirebaseFirestore.instance.collection('posts').add(postData);

      // Increment the user's daily dream count
      await DreamUploadService.incrementDreamUploadCount();

      // Get updated remaining uploads for the message
      final updatedAvailability =
          await DreamUploadService.checkUploadAvailability();
      final remainingFreeUploads = updatedAvailability['remainingFreeUploads'];

      // Update state to show correct count
      setState(() {
        _remainingFreeUploads = remainingFreeUploads;
      });

      if (mounted) {
        // Show success message with remaining uploads info
        DreamPostedMessage.show(
          context,
          message: 'Dream shared successfully!',
          remainingUploads: remainingFreeUploads,
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
      if (mounted) {
        setState(() {
          _errorMessage = 'Error posting dream: $e';
          _isLoading = false;
        });

        // Show error message with the new component
        DreamPostedMessage.show(
          context,
          isError: true,
          errorMessage: _errorMessage,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Word count indicator widget
  Widget _buildWordCountIndicator() {
    final bool isAtLeastMinimum = _wordCount >= _minWordCount;

    return Container(
      decoration: BoxDecoration(
        color: isAtLeastMinimum
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            isAtLeastMinimum ? Icons.check_circle : Icons.info_outline,
            color: isAtLeastMinimum ? Colors.green : Colors.red.shade300,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              isAtLeastMinimum
                  ? 'Great! Your dream description is detailed enough.'
                  : 'Please write at least $_minWordCount words to share your dream.',
              style: TextStyle(
                color: isAtLeastMinimum ? Colors.green : Colors.red.shade300,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isAtLeastMinimum
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$_wordCount/${_minWordCount}',
              style: TextStyle(
                color: isAtLeastMinimum ? Colors.green : Colors.red.shade300,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modify the tag input field to show post counts in a dropdown
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
              // Display selected tags as chips
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

              // Input field for new tags
              if (_tags.length < _maxTags)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _tagsController,
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
                        suffixIcon: _tagsController.text.isNotEmpty
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

                    // Display tag suggestions with post counts
                    if (_tagsController.text.isNotEmpty)
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
                                  entry.key.startsWith(_tagsController.text) &&
                                  entry.key != _tagsController.text &&
                                  entry.value > 0)
                              .take(5)
                              .toList();

                          return Column(
                            children: [
                              // Show current tag with count if available
                              if (_tagPostCounts
                                  .containsKey(_tagsController.text))
                                _buildTagSuggestion(
                                  _tagsController.text,
                                  _tagPostCounts[_tagsController.text] ?? 0,
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
                                  (!_tagPostCounts
                                          .containsKey(_tagsController.text) &&
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

              // Show tag limit indicator
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

  // Add a helper method to build tag suggestions
  Widget _buildTagSuggestion(String tag, int count) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _tagsController.text = tag;
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
                tag, // Remove the # since it's already shown in the icon
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
  void initState() {
    super.initState();
    _contentController.text = widget.generatedText;
    _checkUploadAvailability();

    // Initialize word count and listen for changes
    _updateWordCount();
    _contentController.addListener(_updateWordCount);

    _tagsFocusNode.addListener(() {
      if (!_tagsFocusNode.hasFocus) {
        _addCurrentTagIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _tagsFocusNode.dispose();
    _tagSearchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the custom app state
    context.watch<custom_app_state.AppState>();

    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: LottieBackground(
        child: SafeArea(
          child: SingleChildScrollView(
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
                            'Create New Post',
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

                      SizedBox(height: 24),

                      // Remaining uploads card
                      if (_uploadsChecked)
                        RemainingUploadsCard(
                          remainingUploads: _remainingFreeUploads,
                        ).animate().fadeIn(
                            duration: Duration(milliseconds: 400),
                            curve: Curves.easeOut),

                      SizedBox(height: 24),

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
                          controller: _titleController,
                          style:
                              FlutterFlowTheme.of(context).bodyLarge.override(
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

                      // Word count indicator in separate container
                      Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _wordCount >= _minWordCount
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.shade400.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _wordCount >= _minWordCount
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.shade400.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _wordCount >= _minWordCount
                                  ? Icons.check_circle_outline
                                  : Icons.info_outline,
                              color: _wordCount >= _minWordCount
                                  ? Colors.green
                                  : Colors.red.shade400,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _wordCount >= _minWordCount
                                    ? 'Great! Your dream description is detailed enough.'
                                    : 'Please write at least $_minWordCount words to share your dream.',
                                style: TextStyle(
                                  color: _wordCount >= _minWordCount
                                      ? Colors.green
                                      : Colors.red.shade400,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _wordCount >= _minWordCount
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.shade400.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$_wordCount/$_minWordCount',
                                style: TextStyle(
                                  color: _wordCount >= _minWordCount
                                      ? Colors.green
                                      : Colors.red.shade400,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                          delay: Duration(milliseconds: 300),
                          duration: Duration(milliseconds: 600),
                          curve: Curves.easeOut),

                      // Dream content field
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
                          controller: _contentController,
                          maxLines: 8,
                          minLines: 5,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
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
                            hintText: 'Describe your dream in detail...',
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

                            // Check word count in validator
                            final wordCount = value
                                .trim()
                                .split(RegExp(r'\s+'))
                                .where((word) => word.isNotEmpty)
                                .length;

                            if (wordCount < _minWordCount) {
                              return 'Please write at least $_minWordCount words';
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
                                      _selectedBackground == background['path'];
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedBackground =
                                            background['path'];
                                      });
                                    },
                                    child: Container(
                                      width: 160,
                                      margin: EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? FlutterFlowTheme.of(context)
                                                  .primary
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.asset(
                                              background['path'],
                                              fit: BoxFit.cover,
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black
                                                        .withOpacity(0.7),
                                                  ],
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  background['name'],
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
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

                      // Privacy toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Private Post',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Figtree',
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                              ),
                              Switch(
                                value: _isPrivate,
                                onChanged: (value) {
                                  setState(() {
                                    _isPrivate = value;
                                  });
                                },
                                activeColor:
                                    FlutterFlowTheme.of(context).primary,
                                activeTrackColor: FlutterFlowTheme.of(context)
                                    .primary
                                    .withOpacity(0.5),
                              ),
                            ],
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
                            onTap: _isLoading ? null : _createPost,
                            child: Container(
                              width: double.infinity,
                              height: 60,
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                      'Share Post',
                                      style: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            fontFamily: 'Figtree',
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}
