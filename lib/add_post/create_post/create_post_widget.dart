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
import 'dart:math';
import 'package:flutter/services.dart';

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
    {'name': 'Healing', 'path': 'assets/images/lunathemes/HEALING.png'},
    {'name': 'Tragic', 'path': 'assets/images/lunathemes/TRAGIC.png'},
    {'name': 'Fantasy', 'path': 'assets/images/lunathemes/FANTASY.png'},
    {'name': 'Adventure', 'path': 'assets/images/lunathemes/ADVENTURE.png'},
    {'name': 'Horror', 'path': 'assets/images/lunathemes/HORROR.png'},
    {'name': 'Spiritual', 'path': 'assets/images/lunathemes/SPIRITUAL.png'},
    {
      'name': 'Apocalyptptic',
      'path': 'assets/images/lunathemes/APOCALYTPTIC.png'
    },
    {'name': 'Romantic', 'path': 'assets/images/lunathemes/ROMANTIC.png'},
    {'name': 'Scifi', 'path': 'assets/images/lunathemes/SCIFI.PNG'},
    {'name': 'Lucid', 'path': 'assets/images/lunathemes/LUCID.png'},
    {'name': 'Mysterious', 'path': 'assets/images/lunathemes/MYSTERIOUS.png'},
    {'name': 'Lively', 'path': 'assets/images/lunathemes/LIVELY.png'},
    {'name': 'Surreal', 'path': 'assets/images/lunathemes/SURREAL.png'},
    {'name': 'Drama', 'path': 'assets/images/lunathemes/DRAMA.png'},
    {'name': 'Historical', 'path': 'assets/images/lunathemes/HISTORICAL.png'},
    {'name': 'Comedy', 'path': 'assets/images/lunathemes/COMEDY.png'},
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

                      // Background selection - Clean Minimalist Design
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                // Current selection indicator
                                if (_selectedBackground.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          FlutterFlowTheme.of(context)
                                              .primary
                                              .withOpacity(0.8),
                                          FlutterFlowTheme.of(context)
                                              .secondary
                                              .withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          backgrounds.firstWhere(
                                            (bg) =>
                                                bg['path'] ==
                                                _selectedBackground,
                                            orElse: () => backgrounds[0],
                                          )['name'],
                                          style: FlutterFlowTheme.of(context)
                                              .bodySmall
                                              .copyWith(
                                                fontFamily: 'Figtree',
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Container(
                              height: 260,
                              child: MinimalistBackgroundSelector(
                                backgrounds: backgrounds,
                                selectedBackground: _selectedBackground,
                                onSelect: (path) {
                                  setState(() {
                                    _selectedBackground = path;
                                  });
                                  HapticFeedback.selectionClick();
                                },
                                primaryColor:
                                    FlutterFlowTheme.of(context).primary,
                                secondaryColor:
                                    FlutterFlowTheme.of(context).secondary,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: 500),
                            duration: Duration(milliseconds: 800),
                          ),

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

// Starfield background effect painter
class StarfieldPainter extends CustomPainter {
  final int starCount = 150;
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

// Unique hexagonal background grid with floating animation effect
class HexagonalBackgroundGrid extends StatefulWidget {
  final List<Map<String, dynamic>> backgrounds;
  final String selectedBackground;
  final Function(String) onBackgroundSelected;

  const HexagonalBackgroundGrid({
    Key? key,
    required this.backgrounds,
    required this.selectedBackground,
    required this.onBackgroundSelected,
  }) : super(key: key);

  @override
  State<HexagonalBackgroundGrid> createState() =>
      _HexagonalBackgroundGridState();
}

class _HexagonalBackgroundGridState extends State<HexagonalBackgroundGrid>
    with TickerProviderStateMixin {
  late List<AnimationController> _floatingControllers;
  late List<Animation<double>> _floatingAnimations;
  final _random = Random();

  // Animation values for each background item
  late List<double> _scales;
  late List<double> _rotations;
  late List<Offset> _offsets;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers for floating effect
    _floatingControllers = List.generate(
      widget.backgrounds.length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000 + _random.nextInt(2000)),
      ),
    );

    // Create animations with different curves for variety
    _floatingAnimations = List.generate(
      widget.backgrounds.length,
      (index) => CurvedAnimation(
        parent: _floatingControllers[index],
        curve: index % 2 == 0 ? Curves.easeInOut : Curves.easeOutQuad,
      ),
    );

    // Initialize random scales, rotations and offsets for initial positions
    _scales = List.generate(widget.backgrounds.length,
        (index) => 0.85 + _random.nextDouble() * 0.3);

    _rotations = List.generate(widget.backgrounds.length,
        (index) => (_random.nextDouble() - 0.5) * 0.2);

    _offsets = List.generate(
      widget.backgrounds.length,
      (index) => Offset(
        (_random.nextDouble() - 0.5) * 30,
        (_random.nextDouble() - 0.5) * 30,
      ),
    );

    // Start the floating animations with different delays
    for (int i = 0; i < _floatingControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _floatingControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _floatingControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate hexagon size based on the container size
    final containerWidth = MediaQuery.of(context).size.width - 80;
    final hexSize = containerWidth / 3.0;

    return Stack(
      children: [
        // Background glow effects
        Positioned.fill(
          child: CustomPaint(
            painter: GlowingBackgroundPainter(
              color: FlutterFlowTheme.of(context).primary,
            ),
          ),
        ),

        // Hexagonal grid layout with perspective effect
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(widget.backgrounds.length, (index) {
              // Calculate hexagon position in the grid
              final row = index ~/ 3;
              final col = index % 3;

              // Offset every second row for hexagonal pattern
              double xPos = col * (hexSize * 0.75);
              double yPos = row * (hexSize * 0.85);

              if (row % 2 == 1) {
                xPos += hexSize * 0.375; // Offset odd rows
              }

              // Centered adjustment
              xPos -= hexSize * 0.7;
              yPos -= hexSize * 1.5;

              final isSelected = widget.selectedBackground ==
                  widget.backgrounds[index]['path'];

              return AnimatedBuilder(
                animation: _floatingAnimations[index],
                builder: (context, child) {
                  // Create a floating/bobbing effect with animations
                  final floatValue = _floatingAnimations[index].value;

                  // Compute animated transform values
                  final scale =
                      _scales[index] + sin(floatValue * pi * 2) * 0.05;
                  final rotation =
                      _rotations[index] + sin(floatValue * pi) * 0.02;
                  final offset = Offset(
                    _offsets[index].dx + sin(floatValue * pi * 2) * 5,
                    _offsets[index].dy + cos(floatValue * pi * 2) * 5,
                  );

                  return Positioned(
                    left: xPos + offset.dx,
                    top: yPos + offset.dy,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // Add perspective
                        ..rotateZ(rotation)
                        ..scale(scale),
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () => widget.onBackgroundSelected(
                            widget.backgrounds[index]['path']),
                        child: HexagonalBackgroundTile(
                          background: widget.backgrounds[index],
                          isSelected: isSelected,
                          size: hexSize,
                          primaryColor: FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),

        // Selection hint text
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Tap a background to select',
              style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                    fontFamily: 'Figtree',
                    color: Colors.white.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ),

        // Current selection name display
        if (widget.selectedBackground.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FlutterFlowTheme.of(context).primary.withOpacity(0.6),
                    FlutterFlowTheme.of(context).secondary.withOpacity(0.6),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Selected: ${widget.backgrounds.firstWhere((bg) => bg['path'] == widget.selectedBackground, orElse: () => {
                      'name': 'None'
                    })['name']}',
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                      fontFamily: 'Figtree',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

// Hexagonal background tile widget
class HexagonalBackgroundTile extends StatefulWidget {
  final Map<String, dynamic> background;
  final bool isSelected;
  final double size;
  final Color primaryColor;

  const HexagonalBackgroundTile({
    Key? key,
    required this.background,
    required this.isSelected,
    required this.size,
    required this.primaryColor,
  }) : super(key: key);

  @override
  State<HexagonalBackgroundTile> createState() =>
      _HexagonalBackgroundTileState();
}

class _HexagonalBackgroundTileState extends State<HexagonalBackgroundTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isSelected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(HexagonalBackgroundTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = widget.isSelected ? _pulseAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: ClipPath(
            clipper: HexagonClipper(),
            child: Container(
              width: widget.size,
              height: widget.size * 1.15, // Adjust for hexagon aspect ratio
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(widget.background['path']),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Dark overlay for non-selected items
                  if (!widget.isSelected)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),

                  // Glowing border for selected item
                  if (widget.isSelected)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: HexagonBorderPainter(
                          color: widget.primaryColor,
                          strokeWidth: 3.0,
                          glowWidth: 8.0,
                        ),
                      ),
                    ),

                  // Bottom gradient for text
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: widget.size * 0.4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Background name
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Text(
                      widget.background['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: widget.isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: widget.isSelected ? 14 : 12,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Selected indicator
                  if (widget.isSelected)
                    Positioned(
                      top: 10,
                      right: widget.size / 2 - 10,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.primaryColor.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
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

// Custom clipper for hexagon shape
class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final height = size.height;
    final width = size.width;
    final heightFactor = size.height / 6;

    path.moveTo(width / 2, 0);
    path.lineTo(width, heightFactor * 1.5);
    path.lineTo(width, height - heightFactor * 1.5);
    path.lineTo(width / 2, height);
    path.lineTo(0, height - heightFactor * 1.5);
    path.lineTo(0, heightFactor * 1.5);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Custom painter for hexagon border with glow effect
class HexagonBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double glowWidth;

  HexagonBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.glowWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final height = size.height;
    final width = size.width;
    final heightFactor = size.height / 6;

    path.moveTo(width / 2, 0);
    path.lineTo(width, heightFactor * 1.5);
    path.lineTo(width, height - heightFactor * 1.5);
    path.lineTo(width / 2, height);
    path.lineTo(0, height - heightFactor * 1.5);
    path.lineTo(0, heightFactor * 1.5);
    path.close();

    // Draw glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + glowWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowWidth);

    canvas.drawPath(path, glowPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldPainter) => false;
}

// Background painter for glowing effect
class GlowingBackgroundPainter extends CustomPainter {
  final Color color;

  GlowingBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Create a radial gradient
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: [0.0, 1.0],
        radius: 0.7,
      ).createShader(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width,
          height: size.height,
        ),
      );

    // Draw radial gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldPainter) => false;
}

// Clean, minimalist background selector
class MinimalistBackgroundSelector extends StatelessWidget {
  final List<Map<String, dynamic>> backgrounds;
  final String selectedBackground;
  final Function(String) onSelect;
  final Color primaryColor;
  final Color secondaryColor;

  const MinimalistBackgroundSelector({
    Key? key,
    required this.backgrounds,
    required this.selectedBackground,
    required this.onSelect,
    required this.primaryColor,
    required this.secondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: Stack(
          children: [
            // Background preview section
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 180,
              child: BackgroundPreview(
                backgrounds: backgrounds,
                selectedBackground: selectedBackground,
              ),
            ),

            // Selection bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: backgrounds.length,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemBuilder: (context, index) {
                    final background = backgrounds[index];
                    final isSelected = selectedBackground == background['path'];

                    return GestureDetector(
                      onTap: () => onSelect(background['path']),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        width: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isSelected ? primaryColor : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              // Thumbnail image
                              Positioned.fill(
                                child: Image.asset(
                                  background['path'],
                                  fit: BoxFit.cover,
                                ),
                              ),

                              // Darkening overlay for unselected items
                              if (!isSelected)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.4),
                                  ),
                                ),

                              // Selection indicator
                              if (isSelected)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 10,
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
            ),

            // "Selected" label
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: primaryColor,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Background',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Interactive background preview with elegant transitions
class BackgroundPreview extends StatefulWidget {
  final List<Map<String, dynamic>> backgrounds;
  final String selectedBackground;

  const BackgroundPreview({
    Key? key,
    required this.backgrounds,
    required this.selectedBackground,
  }) : super(key: key);

  @override
  State<BackgroundPreview> createState() => _BackgroundPreviewState();
}

class _BackgroundPreviewState extends State<BackgroundPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late String _currentBg;
  String? _previousBg;

  @override
  void initState() {
    super.initState();
    _currentBg = widget.selectedBackground.isEmpty
        ? widget.backgrounds[0]['path']
        : widget.selectedBackground;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(BackgroundPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedBackground != oldWidget.selectedBackground) {
      setState(() {
        _previousBg = _currentBg;
        _currentBg = widget.selectedBackground;
        _controller.reset();
        _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Previous background (for smooth transition)
        if (_previousBg != null)
          Image.asset(
            _previousBg!,
            fit: BoxFit.cover,
          ),

        // Current background with fade-in animation
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            );
          },
          child: Image.asset(
            _currentBg,
            fit: BoxFit.cover,
          ),
        ),

        // Subtle gradient overlay for better visibility
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.6),
              ],
              stops: [0.7, 1.0],
            ),
          ),
        ),

        // Background name displayed in the preview
        Positioned(
          bottom: 16,
          left: 16,
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              );
            },
            child: Text(
              widget.backgrounds.firstWhere((bg) => bg['path'] == _currentBg,
                  orElse: () => widget.backgrounds[0])['name'],
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
