import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide getCurrentTimestamp, dateTimeFormat;
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import '/backend/schema/usernames_record.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'profile_input_model.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:luna_kraft/onboarding/onboarding_manager.dart';
import 'package:luna_kraft/onboarding/onboarding_screen.dart';
import '/flutter_flow/nav/nav.dart';
export 'profile_input_model.dart';

class ProfileInputWidget extends StatefulWidget {
  const ProfileInputWidget({super.key});

  static String routeName = 'ProfileInput';
  static String routePath = '/profileInput';

  @override
  State<ProfileInputWidget> createState() => _ProfileInputWidgetState();
}

class _ProfileInputWidgetState extends State<ProfileInputWidget> {
  late ProfileInputModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _longLoadingTimer;
  bool _showExtendedLoadingMessage = false;

  Stream<List<UsernamesRecord>> queryUsernamesRecord({
    DocumentReference? parent,
    QueryDocumentSnapshot? startAfter,
    int? limit,
    bool singleRecord = false,
  }) {
    return FirebaseFirestore.instance.collection('usernames').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => UsernamesRecord.fromSnapshot(doc))
            .toList());
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileInputModel());

    _model.displayNameTextController ??= TextEditingController();
    _model.displayNameFocusNode ??= FocusNode();
    _model.displayNameFocusNode?.addListener(_handleFocusChange);

    _model.userIDTextController ??= TextEditingController();
    _model.userIDFocusNode ??= FocusNode();
    _model.userIDFocusNode?.addListener(_handleFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  void _handleFocusChange() {
    // If any field loses focus after being edited, show validation
    if (!_model.displayNameFocusNode!.hasFocus &&
        !_model.userIDFocusNode!.hasFocus &&
        (_model.displayNameTextController!.text.isNotEmpty ||
            _model.userIDTextController!.text.isNotEmpty)) {
      safeSetState(() {
        _model.showValidationErrors = true;
      });
    }
  }

  @override
  void dispose() {
    _model.displayNameFocusNode?.removeListener(_handleFocusChange);
    _model.userIDFocusNode?.removeListener(_handleFocusChange);
    _model.dispose();
    _longLoadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                backgroundColor: FlutterFlowTheme.of(context)
                    .primaryBackground
                    .withOpacity(0.2),
                automaticallyImplyLeading: false,
                leading: FlutterFlowIconButton(
                  borderColor: Colors.transparent,
                  borderRadius: 30.0,
                  buttonSize: 46.0,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: FlutterFlowTheme.of(context).primaryText,
                    size: 24.0,
                  ),
                  onPressed: () async {
                    context.pushNamed(SigninWidget.routeName);
                  },
                ),
                title: Text(
                  'Create Your Profile',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Outfit',
                        color: FlutterFlowTheme.of(context).primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                centerTitle: true,
                elevation: 0.0,
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          FlutterFlowTheme.of(context).primary.withOpacity(0.0),
                          FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                          FlutterFlowTheme.of(context).primary.withOpacity(0.0),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                FlutterFlowTheme.of(context).primaryBackground,
                FlutterFlowTheme.of(context)
                    .secondaryBackground
                    .withOpacity(0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Background decoration
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        FlutterFlowTheme.of(context).secondary.withOpacity(0.1),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  physics: ClampingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 10),
                        // Profile picture uploader
                        profilePictureUploader(),
                        SizedBox(height: 24),
                        // Main form in glassmorphic container
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground
                                    .withOpacity(0.7),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context)
                                      .primary
                                      .withOpacity(0.1),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText
                                        .withOpacity(0.1),
                                    blurRadius: 24,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _model.formKey,
                                autovalidateMode: _model.showValidationErrors
                                    ? AutovalidateMode.always
                                    : AutovalidateMode.disabled,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Personal Information',
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            fontFamily: 'Outfit',
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    SizedBox(height: 20),
                                    buildInputFields(),
                                    SizedBox(height: 30),
                                    buildSubmitButton(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),

              // Loading overlay
              if (_isLoading) buildLoadingOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorImageWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          color: FlutterFlowTheme.of(context).error,
          size: 24.0,
        ),
        SizedBox(height: 4),
        Text(
          'Error loading image',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Figtree',
                fontSize: 10,
                color: FlutterFlowTheme.of(context).error,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _finalizeProfile() async {
    // Set validation errors to visible regardless of validation result
    safeSetState(() {
      _model.showValidationErrors = true;
    });

    if (_model.formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _showExtendedLoadingMessage = false;
      });

      // Disable automatic auth change navigation
      AppStateNotifier.instance.updateNotifyOnAuthChange(false);

      // Start a timer to show extended message if operation takes more than 10 seconds
      _longLoadingTimer = Timer(Duration(seconds: 10), () {
        if (mounted && _isLoading) {
          setState(() {
            _showExtendedLoadingMessage = true;
          });
        }
      });

      try {
        // First check if the user is authenticated
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You need to be authenticated to create a profile. Please sign in again.',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Figtree',
                      color: Colors.white,
                    ),
              ),
              backgroundColor: FlutterFlowTheme.of(context).error,
            ),
          );
          // Navigate back to sign in page
          context.goNamed('Signin');
          return;
        }

        // Check if username is already taken with retry mechanism
        final username = _model.userIDTextController.text.toLowerCase();
        bool usernameTaken = false;
        int retryCount = 0;
        const int maxRetries = 3;

        while (retryCount < maxRetries) {
          try {
            final usernameDoc = await FirebaseFirestore.instance
                .collection('usernames')
                .doc(username)
                .get()
                .timeout(Duration(seconds: 5));

            if (usernameDoc.exists) {
              usernameTaken = true;
              break;
            }
            break; // Success, no retry needed
          } catch (e) {
            print('Error checking username (attempt ${retryCount + 1}): $e');
            retryCount++;
            if (e.toString().contains('App Check') ||
                e.toString().contains('permission-denied') ||
                e.toString().contains('network') ||
                e is TimeoutException) {
              // App Check or network error, retry after delay
              await Future.delayed(Duration(seconds: 2));
              continue;
            } else {
              // Other error, just continue with profile creation
              break;
            }
          }
        }

        if (usernameTaken) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Username is already taken. Please choose another one.',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Figtree',
                      color: Colors.white,
                    ),
              ),
              backgroundColor: FlutterFlowTheme.of(context).error,
            ),
          );
          return;
        }

        String? photoUrl;

        // Upload profile picture if one was selected
        if (_model.uploadedLocalFile1.bytes != null &&
            _model.uploadedFileUrl1 == 'local_image') {
          final userId = currentUser.uid;
          if (userId.isEmpty) {
            throw Exception('User ID is empty');
          }

          try {
            print('Starting profile picture upload...');

            // Create a timestamp for unique filename
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final fileName = '${timestamp}_${userId}_profile.jpg';

            // Create the storage reference with the user's ID
            final storageRef =
                FirebaseStorage.instance.ref().child('public').child(fileName);

            // Upload file with metadata
            final metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'userId': userId,
                'uploadedAt': DateTime.now().toIso8601String(),
                'fileName': fileName,
                'type': 'profile_image'
              },
            );

            print('Uploading file to Firebase Storage...');

            // Upload the image bytes with retry mechanism
            bool uploadSuccess = false;
            retryCount = 0;

            while (retryCount < maxRetries && !uploadSuccess) {
              try {
                final uploadTask = await storageRef
                    .putData(_model.uploadedLocalFile1.bytes!, metadata)
                    .timeout(Duration(seconds: 30));

                if (uploadTask.state == TaskState.success) {
                  // Get the download URL
                  photoUrl = await storageRef.getDownloadURL();
                  print(
                      'Successfully uploaded profile picture. URL: $photoUrl');
                  uploadSuccess = true;
                } else {
                  print('Upload task failed: ${uploadTask.state}');
                  retryCount++;
                  if (retryCount < maxRetries) {
                    await Future.delayed(Duration(seconds: 2));
                  }
                }
              } catch (e) {
                print(
                    'Error uploading profile picture (attempt ${retryCount + 1}): $e');
                retryCount++;
                if (e.toString().contains('App Check') ||
                    e.toString().contains('permission-denied') ||
                    e.toString().contains('network') ||
                    e is TimeoutException) {
                  // App Check or network error, retry after delay
                  await Future.delayed(Duration(seconds: 2));
                } else {
                  // Other error type, stop retrying
                  break;
                }
              }
            }

            if (!uploadSuccess) {
              // Failed after all retries, but continue with profile creation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Could not upload profile picture, but continuing with profile creation.'),
                  backgroundColor: FlutterFlowTheme.of(context).warning,
                ),
              );
            }
          } catch (e) {
            print('Error uploading profile picture: $e');
            // Continue with profile creation even if image upload fails
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Error uploading profile picture, but continuing with profile creation.'),
                backgroundColor: FlutterFlowTheme.of(context).warning,
              ),
            );
          }
        }

        // Update the user's profile in Firestore with retry mechanism
        bool profileUpdateSuccess = false;
        retryCount = 0;

        while (retryCount < maxRetries && !profileUpdateSuccess) {
          try {
            // First update the currentUser profile in Firebase Auth
            await currentUser.updateProfile(
              displayName: _model.displayNameTextController.text,
              photoURL: photoUrl,
            );

            // Then update the Firestore document
            if (currentUserReference != null) {
              final updateData = {
                'display_name': _model.displayNameTextController.text,
                'user_name': _model.userIDTextController.text.toLowerCase(),
                'last_updated': getCurrentTimestamp,
                'date_of_birth': _model.datePicked,
                'gender': _model.selectedGender,
              };

              // Only add photo_url if we have one
              if (photoUrl != null) {
                updateData['photo_url'] = photoUrl;
              }

              await currentUserReference!
                  .update(updateData)
                  .timeout(Duration(seconds: 10));
            } else {
              // If the currentUserReference is null, create a new document
              final userDocRef = FirebaseFirestore.instance
                  .collection('User')
                  .doc(currentUser.uid);

              final userData = {
                'display_name': _model.displayNameTextController.text,
                'user_name': _model.userIDTextController.text.toLowerCase(),
                'email': currentUser.email,
                'created_time': getCurrentTimestamp,
                'last_updated': getCurrentTimestamp,
                'date_of_birth': _model.datePicked,
                'gender': _model.selectedGender,
                'uid': currentUser.uid,
                'phone_number': currentUser.phoneNumber,
              };

              // Only add photo_url if we have one
              if (photoUrl != null) {
                userData['photo_url'] = photoUrl;
              }

              await userDocRef.set(userData).timeout(Duration(seconds: 10));
            }

            print('Successfully updated user profile with photo: $photoUrl');
            profileUpdateSuccess = true;

            // Create username record with retry mechanism
            try {
              bool usernameCreationSuccess = false;
              int usernameRetryCount = 0;

              while (
                  usernameRetryCount < maxRetries && !usernameCreationSuccess) {
                try {
                  await FirebaseFirestore.instance
                      .collection('usernames')
                      .doc(_model.userIDTextController.text.toLowerCase())
                      .set({
                    'userId': currentUserReference ??
                        FirebaseFirestore.instance
                            .collection('User')
                            .doc(currentUser.uid),
                    'username': _model.userIDTextController.text.toLowerCase(),
                    'created_time': getCurrentTimestamp,
                  }).timeout(Duration(seconds: 10));

                  usernameCreationSuccess = true;
                } catch (e) {
                  print(
                      'Error creating username record (attempt ${usernameRetryCount + 1}): $e');
                  usernameRetryCount++;
                  if (e.toString().contains('App Check') ||
                      e.toString().contains('permission-denied') ||
                      e.toString().contains('network') ||
                      e is TimeoutException) {
                    await Future.delayed(Duration(seconds: 2));
                  } else {
                    break;
                  }
                }
              }
            } catch (e) {
              print('Error creating username record: $e');
              // Continue even if username record creation fails
            }
          } catch (e) {
            print(
                'Error updating user profile (attempt ${retryCount + 1}): $e');
            retryCount++;
            if (e.toString().contains('App Check') ||
                e.toString().contains('permission-denied') ||
                e.toString().contains('network') ||
                e is TimeoutException) {
              // App Check or network error, retry after delay
              await Future.delayed(Duration(seconds: 2));
            } else {
              // Other error type, stop retrying
              throw e;
            }
          }
        }

        if (!profileUpdateSuccess) {
          throw Exception('Failed to update profile after multiple attempts');
        }

        // Only navigate if the widget is still mounted
        if (mounted) {
          // Make sure auth auto-navigation is still disabled
          AppStateNotifier.instance.updateNotifyOnAuthChange(false);

          // First check if the user is new and needs onboarding
          final isNewUser = await OnboardingManager.isNewUser();
          final hasCompletedOnboarding =
              await OnboardingManager.hasCompletedOnboarding();

          // Now mark profile setup as complete
          await OnboardingManager.markProfileSetupComplete();

          if (isNewUser && !hasCompletedOnboarding && mounted) {
            // New user should see onboarding next
            print('Profile setup complete. Redirecting to onboarding...');
            // Navigate to onboarding
            context.go('/show-onboarding');
          } else {
            // User is not new or has completed onboarding
            print(
                'Profile setup complete. User already has onboarding. Going to home...');

            // Make sure the user is marked as not new
            await OnboardingManager.markUserAsNotNew();

            // If they haven't completed onboarding, mark it as complete since they're not new
            if (!hasCompletedOnboarding) {
              await OnboardingManager.markOnboardingComplete();
              print('Skipping onboarding for returning user');
            }

            // Re-enable auth navigation
            AppStateNotifier.instance.updateNotifyOnAuthChange(true);

            // Go to home page
            if (mounted) {
              context.goNamed('HomePage');
            }
          }
        }
      } catch (e) {
        print('Error in profile creation process: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating profile: ${e.toString()}'),
              backgroundColor: FlutterFlowTheme.of(context).error,
            ),
          );
        }
      }
    }
  }

  // Profile picture uploader widget
  Widget profilePictureUploader() {
    return Column(
      children: [
        InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () async {
            try {
              final selectedMedia = await selectMediaWithSourceBottomSheet(
                context: context,
                allowPhoto: true,
                imageQuality: 85,
              );

              if (selectedMedia == null || selectedMedia.isEmpty) {
                return;
              }

              // Check for valid bytes
              if (selectedMedia.first.bytes == null ||
                  selectedMedia.first.bytes!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected image is empty or corrupted'),
                    backgroundColor: FlutterFlowTheme.of(context).error,
                  ),
                );
                return;
              }

              // Check file size (limit to 5MB)
              final fileSize = selectedMedia.first.bytes!.length;
              if (fileSize > 5 * 1024 * 1024) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Image is too large (max 5MB). Please select a smaller image.'),
                    backgroundColor: FlutterFlowTheme.of(context).error,
                  ),
                );
                return;
              }

              safeSetState(() {
                _model.isDataUploading1 = false;
                _model.uploadedLocalFile1 = FFUploadedFile(
                  name: selectedMedia.first.storagePath.split('/').last,
                  bytes: selectedMedia.first.bytes,
                );
                _model.uploadedFileUrl1 = 'local_image';
              });
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error selecting image: ${e.toString()}'),
                  backgroundColor: FlutterFlowTheme.of(context).error,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          },
          child: Container(
            width: 120.0,
            height: 120.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                  FlutterFlowTheme.of(context).secondary.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.5),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: _model.uploadedFileUrl1.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(60.0),
                    child: _model.uploadedFileUrl1 == 'local_image' &&
                            _model.uploadedLocalFile1.bytes != null
                        ? Image.memory(
                            _model.uploadedLocalFile1.bytes!,
                            width: 120.0,
                            height: 120.0,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            _model.uploadedFileUrl1,
                            width: 120.0,
                            height: 120.0,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Error loading image: $error');
                              return _buildErrorImageWidget();
                            },
                          ),
                  )
                : _model.uploadError != null
                    ? Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: FlutterFlowTheme.of(context).error,
                            size: 28.0,
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                4.0, 8.0, 4.0, 0.0),
                            child: Text(
                              'Upload Failed',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: FlutterFlowTheme.of(context).error,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 12.0, 4.0, 0.0),
                            child: InkWell(
                              onTap: () {
                                safeSetState(() {
                                  _model.uploadError = null;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context).primary,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Try Again',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        fontFamily: 'Figtree',
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            color: FlutterFlowTheme.of(context).primary,
                            size: 32.0,
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 8.0, 4.0, 0.0),
                            child: Text(
                              'Add Photo',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: FlutterFlowTheme.of(context).primary,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Profile Picture',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Figtree',
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
      ],
    );
  }

  // Form input fields
  Widget buildInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full Name field
        buildTextFormField(
          controller: _model.displayNameTextController,
          focusNode: _model.displayNameFocusNode,
          textCapitalization: TextCapitalization.words,
          labelText: 'Full Name',
          hintText: 'Enter your full name',
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        SizedBox(height: 20),

        // Username field with improved validation message
        buildTextFormField(
          controller: _model.userIDTextController,
          focusNode: _model.userIDFocusNode,
          labelText: 'Username',
          hintText: 'Create a unique username',
          prefixIcon: Icons.alternate_email,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a username';
            }
            // Validate username with a more concise error message
            if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
              return 'Use only lowercase letters, numbers, and underscores';
            }
            return null;
          },
        ),
        SizedBox(height: 20),

        // Date of Birth field
        buildDateSelector(),
        SizedBox(height: 20),

        // Gender field
        buildGenderSelector(),
      ],
    );
  }

  // Custom text form field
  Widget buildTextFormField({
    required TextEditingController? controller,
    required FocusNode? focusNode,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FlutterFlowTheme.of(context).primaryText.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: textCapitalization,
            textInputAction: TextInputAction.next,
            obscureText: false,
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
                    fontFamily: 'Figtree',
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
              hintText: hintText,
              hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
                    fontFamily: 'Figtree',
                    color: FlutterFlowTheme.of(context)
                        .secondaryText
                        .withOpacity(0.5),
                  ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color:
                      FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: FlutterFlowTheme.of(context).primary,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: FlutterFlowTheme.of(context).error,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: FlutterFlowTheme.of(context).error,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
              filled: true,
              fillColor: FlutterFlowTheme.of(context).secondaryBackground,
              contentPadding:
                  EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 24.0),
              prefixIcon: Icon(
                prefixIcon,
                color:
                    FlutterFlowTheme.of(context).primaryText.withOpacity(0.5),
                size: 22,
              ),
              // Increase error text padding for better visibility
              errorStyle: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Figtree',
                    color: FlutterFlowTheme.of(context).error,
                    fontSize: 12,
                  ),
              // Add extra padding at the bottom for error text
              errorMaxLines: 3,
            ),
            style: FlutterFlowTheme.of(context).bodyMedium,
            validator: validator,
            autovalidateMode: _model.showValidationErrors
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            onTap: () {
              // When a field is tapped, we don't immediately show validation errors
              // They will only show up if the form is submitted or the field loses focus
            },
            onChanged: (value) {
              // Clear validation state if user is typing
              if (_model.showValidationErrors) {
                _model.formKey.currentState?.validate();
              }
            },
            onFieldSubmitted: (value) {
              // Show validation when user submits a single field
              safeSetState(() {
                _model.showValidationErrors = true;
              });
              _model.formKey.currentState?.validate();
            },
          ),
          // Add additional container for alternative error display if needed
          if (labelText == 'Username' && _model.showValidationErrors)
            Builder(
              builder: (context) {
                final errorText = validator?.call(controller?.text);
                if (errorText != null && errorText.isNotEmpty) {
                  return Padding(
                    padding: EdgeInsets.only(left: 16, right: 16, top: 4),
                    child: Text(
                      errorText,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Figtree',
                            color: FlutterFlowTheme.of(context).error,
                            fontSize: 12,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

  // Date selector field
  Widget buildDateSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FlutterFlowTheme.of(context).primaryText.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            builder: (BuildContext context) => Container(
              height: MediaQuery.of(context).size.height / 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).alternate,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text(
                    'Select Date of Birth',
                    style: FlutterFlowTheme.of(context).titleMedium,
                  ),
                  Expanded(
                    child: CupertinoTheme(
                      data: CupertinoTheme.of(context).copyWith(
                        textTheme:
                            CupertinoTheme.of(context).textTheme.copyWith(
                                  dateTimePickerTextStyle:
                                      FlutterFlowTheme.of(context).titleMedium,
                                ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        minimumDate: DateTime(1920),
                        initialDateTime:
                            _model.datePicked ?? DateTime(2000, 1, 1),
                        maximumDate: DateTime.now(),
                        backgroundColor:
                            FlutterFlowTheme.of(context).secondaryBackground,
                        use24hFormat: false,
                        onDateTimeChanged: (newDateTime) => safeSetState(() {
                          _model.datePicked = newDateTime;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 22,
                ),
                SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date of Birth',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Figtree',
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                    Text(
                      _model.datePicked != null
                          ? dateTimeFormat('MMM d, y', _model.datePicked)
                          : 'Select date',
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                  ],
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Gender selector field
  Widget buildGenderSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FlutterFlowTheme.of(context).primaryText.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            builder: (context) => Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).alternate,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Select Gender',
                    style: FlutterFlowTheme.of(context).titleMedium,
                  ),
                  SizedBox(height: 24),
                  buildGenderOption('Male', Icons.male),
                  SizedBox(height: 12),
                  buildGenderOption('Female', Icons.female),
                  SizedBox(height: 12),
                  buildGenderOption('Other', Icons.person),
                  SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: FlutterFlowTheme.of(context).alternate.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 22,
                ),
                SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gender',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Figtree',
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                    Text(
                      _model.selectedGender ?? 'Select gender',
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                  ],
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Gender option item
  Widget buildGenderOption(String gender, IconData icon) {
    bool isSelected = _model.selectedGender == gender;

    return InkWell(
      onTap: () {
        safeSetState(() {
          _model.selectedGender = gender;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary.withOpacity(0.1)
              : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context).alternate,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: FlutterFlowTheme.of(context).primary,
            ),
            SizedBox(width: 16),
            Text(
              gender,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Figtree',
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
            Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: FlutterFlowTheme.of(context).primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Submit button
  Widget buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
            blurRadius: 16,
            offset: Offset(0, 8),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _finalizeProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          disabledBackgroundColor: FlutterFlowTheme.of(context).alternate,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    _showExtendedLoadingMessage
                        ? 'Still working... please wait'
                        : 'Creating profile...',
                    style: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'Outfit',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              )
            : Text(
                'Create Profile',
                style: FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
              ),
      ),
    );
  }

  // Loading overlay
  Widget buildLoadingOverlay(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.7),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 36),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: FlutterFlowTheme.of(context)
                          .primaryText
                          .withOpacity(0.1),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FlutterFlowTheme.of(context).primary,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _showExtendedLoadingMessage
                          ? 'Almost there...'
                          : 'Creating your profile',
                      style: FlutterFlowTheme.of(context).titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _showExtendedLoadingMessage
                          ? 'This is taking longer than expected, please wait'
                          : 'Please wait while we set up your account',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Figtree',
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
