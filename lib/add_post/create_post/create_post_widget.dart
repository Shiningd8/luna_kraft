import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide getCurrentTimestamp;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:lottie/lottie.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  bool _isLoading = false;
  String _selectedBackground = '';
  bool _isPrivate = false;

  // Upload limits
  bool _uploadsChecked = false;
  int _remainingFreeUploads = 0;
  int _lunaCoins = 0;

  // Word count tracking
  int _wordCount = 0;
  static const int _minWordCount = 25;

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
    _contentController.text = widget.generatedText;
    _checkUploadAvailability();

    // Initialize word count and listen for changes
    _updateWordCount();
    _contentController.addListener(_updateWordCount);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // Calculate word count from text content
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
      final postData = {
        'title': _titleController.text,
        'dream': _contentController.text,
        'tags': _tagsController.text,
        'date': getCurrentTimestamp,
        'post_is_edited': false,
        'poster': currentUserReference,
        'userref': currentUserReference,
        'video_background_url': _selectedBackground,
        'video_background_opacity': 0.75,
        'likes': [],
        'Post_saved_by': [],
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
        // Show error message with the new component
        DreamPostedMessage.show(
          context,
          isError: true,
          errorMessage: 'Failed to post dream',
        );
        setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
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
                                    final isSelected = _selectedBackground ==
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
                                        margin: EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? FlutterFlowTheme.of(context)
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
                            controller: _tagsController,
                            style:
                                FlutterFlowTheme.of(context).bodyLarge.override(
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
          ],
        ),
      ),
    );
  }
}
