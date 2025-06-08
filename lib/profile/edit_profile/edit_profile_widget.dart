import 'package:flutter/material.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart' hide getCurrentTimestamp;
import '/backend/firebase_storage/storage.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/widgets/custom_text_form_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileWidget extends StatefulWidget {
  const EditProfileWidget({super.key});

  static String routeName = 'EditProfile';
  static String routePath = '/edit-profile';

  @override
  State<EditProfileWidget> createState() => _EditProfileWidgetState();
}

class _EditProfileWidgetState extends State<EditProfileWidget> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  bool _isImagePickerActive = false;
  bool _canChangeUsername = true;
  String? _originalUsername;
  DateTime? _lastUsernameChangeDate;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (currentUserReference == null) return;

    final userDoc = await UserRecord.getDocumentOnce(currentUserReference!);
    if (userDoc != null) {
      setState(() {
        _displayNameController.text = userDoc.displayName ?? '';
        _usernameController.text = userDoc.userName ?? '';
        _originalUsername = userDoc.userName;
        _lastUsernameChangeDate = userDoc.lastUsernameChangeDate;

        // Check if user can change username (once per 30 days)
        if (_lastUsernameChangeDate != null) {
          final daysSinceLastChange =
              DateTime.now().difference(_lastUsernameChangeDate!).inDays;
          _canChangeUsername = daysSinceLastChange >= 30;
          print(
              'Last username change: $_lastUsernameChangeDate, Days since: $daysSinceLastChange, Can change: $_canChangeUsername');
        } else {
          _canChangeUsername = true;
          print('No previous username change found. User can change username.');
        }
      });
    }
  }

  Future<void> _pickImage() async {
    if (_isImagePickerActive) return;

    setState(() => _isImagePickerActive = true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    } finally {
      if (mounted) {
        setState(() => _isImagePickerActive = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if username is being changed and if the user can change it
    final trimmedOriginalUsername = _originalUsername?.trim() ?? '';
    final trimmedNewUsername = _usernameController.text.trim();
    bool usernameChanged = trimmedOriginalUsername != trimmedNewUsername;

    if (usernameChanged && !_canChangeUsername) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Username can only be changed once every 30 days.'),
          backgroundColor: FlutterFlowTheme.of(context).error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? photoUrl;
      if (_imageFile != null) {
        try {
          // Check authentication status
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            throw Exception('User is not authenticated');
          }

          final userId = currentUser.uid;
          print('Current user ID: $userId');
          print('Current user email: ${currentUser.email}');
          print('Current user is email verified: ${currentUser.emailVerified}');

          // Verify Firebase Storage instance
          final storage = FirebaseStorage.instance;
          print(
              'Firebase Storage bucket: ${storage.app.options.storageBucket}');

          print('Starting profile picture upload for user: $userId');
          print('Image file path: ${_imageFile!.path}');
          print('Image file size: ${_imageFile!.lengthSync()} bytes');

          // Create a timestamp for the filename
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = '${timestamp}_${timestamp - 5}_profile.jpg';

          // Create the storage reference with the user's ID and timestamp
          final storageRef = storage.ref().child('public').child(fileName);

          print('Storage reference path: ${storageRef.fullPath}');

          // Upload the file with metadata
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

          // Upload file with metadata
          final uploadTask = storageRef.putFile(_imageFile!, metadata);

          // Monitor upload progress
          uploadTask.snapshotEvents.listen(
            (TaskSnapshot snapshot) {
              final progress =
                  (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
              print('Upload progress: $progress%');
            },
            onError: (error) {
              print('Error during upload: $error');
              print('Error code: ${error.code}');
              print('Error message: ${error.message}');
              throw error;
            },
          );

          // Wait for upload to complete
          final uploadSnapshot = await uploadTask;
          print('File uploaded successfully');
          print('Upload snapshot: ${uploadSnapshot.toString()}');

          // Get the download URL
          photoUrl = await storageRef.getDownloadURL();
          print('Got download URL: $photoUrl');

          // Delete old profile picture if it exists
          try {
            final oldPhotoUrl = currentUserDocument?.photoUrl;
            if (oldPhotoUrl != null && oldPhotoUrl.isNotEmpty) {
              final oldRef = storage.refFromURL(oldPhotoUrl);
              await oldRef.delete();
              print('Deleted old profile picture');
            }
          } catch (e) {
            print('Error deleting old profile picture: $e');
            // Continue even if deletion fails
          }
        } catch (e, stackTrace) {
          print('Error during image upload: $e');
          print('Stack trace: $stackTrace');
          if (e is FirebaseException) {
            print('Firebase error code: ${e.code}');
            print('Firebase error message: ${e.message}');
          }
          throw Exception('Failed to upload profile picture: ${e.toString()}');
        }
      }

      // Update user profile
      print('Updating user profile in Firestore...');
      try {
        // Prepare update data
        Map<String, dynamic> updateData = {
          'display_name': _displayNameController.text,
          'user_name': _usernameController.text,
          if (photoUrl != null) 'photo_url': photoUrl,
          'last_updated': getCurrentTimestamp,
        };

        // If username changed, update the last_username_change_date
        if (usernameChanged) {
          updateData['last_username_change_date'] = getCurrentTimestamp;

          // Update username record in usernames collection
          try {
            // If there's an old username, delete it
            if (_originalUsername != null && _originalUsername!.isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection('usernames')
                  .doc(_originalUsername!.toLowerCase())
                  .delete();
            }

            // Create new username record
            await FirebaseFirestore.instance
                .collection('usernames')
                .doc(_usernameController.text.toLowerCase())
                .set({
              'userId': currentUserReference,
              'username': _usernameController.text.toLowerCase(),
              'created_time': getCurrentTimestamp,
            });
          } catch (e) {
            print('Error updating username record: $e');
            // Continue even if username record update fails
          }
        }

        await currentUserReference!.update(updateData);
        print('Profile updated successfully');
      } catch (e) {
        print('Error updating Firestore document: $e');
        throw Exception('Failed to update profile: ${e.toString()}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: FlutterFlowTheme.of(context).primary,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Profile updated successfully',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Figtree',
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );

        // Pop back after successful update
        context.pop();
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context)
                      .secondaryBackground
                      .withOpacity(0.7),
                  border: Border(
                    bottom: BorderSide(
                      color:
                          FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            'Edit Profile',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Outfit',
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: FlutterFlowTheme.of(context).primaryText,
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
          ),
          child: Stack(
            children: [
              // Lottie Animation Background
              Positioned.fill(
                child: Lottie.asset(
                  'assets/jsons/Animation_-_1739171323302.json',
                  fit: BoxFit.cover,
                  animate: true,
                ),
              ),
              // Content
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 20),
                        // Profile Picture Section
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).primary,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _imageFile != null
                                    ? Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                      )
                                    : currentUserDocument?.photoUrl != null
                                        ? Image.network(
                                            currentUserDocument!.photoUrl!,
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                child: Center(
                                                  child: Text(
                                                    currentUserDisplayName
                                                            .isNotEmpty
                                                        ? currentUserDisplayName[
                                                                0]
                                                            .toUpperCase()
                                                        : '?',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 40,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 60,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                          ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 5,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),
                        // Display Name Field
                        CustomTextFormField(
                          controller: _displayNameController,
                          hintText: 'Enter your display name',
                          decoration: InputDecoration(
                            labelText: 'Display Name',
                            labelStyle: FlutterFlowTheme.of(context).labelMedium,
                            hintStyle: FlutterFlowTheme.of(context).labelMedium,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                            contentPadding: EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your display name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        // Username Field
                        CustomTextFormField(
                          controller: _usernameController,
                          hintText: 'Enter your username',
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: FlutterFlowTheme.of(context).labelMedium,
                            hintStyle: FlutterFlowTheme.of(context).labelMedium,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                            contentPadding: EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                          enabled: _canChangeUsername ||
                              (_originalUsername?.trim() ?? '') ==
                                  _usernameController.text.trim(),
                        ),
                        SizedBox(height: 8),
                        // Username change info box
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _canChangeUsername
                                ? FlutterFlowTheme.of(context)
                                    .info
                                    .withOpacity(0.1)
                                : FlutterFlowTheme.of(context)
                                    .error
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _canChangeUsername
                                  ? FlutterFlowTheme.of(context)
                                      .info
                                      .withOpacity(0.3)
                                  : FlutterFlowTheme.of(context)
                                      .error
                                      .withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _canChangeUsername
                                    ? Icons.info_outline
                                    : Icons.warning_amber_rounded,
                                color: _canChangeUsername
                                    ? FlutterFlowTheme.of(context).info
                                    : FlutterFlowTheme.of(context).error,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _canChangeUsername
                                      ? 'Username can be changed only once in 30 days. Editing this field will count as your change for the next 30 days.'
                                      : 'You can change your username again in ${_lastUsernameChangeDate != null ? (30 - DateTime.now().difference(_lastUsernameChangeDate!).inDays) : 30} days. You can still update your display name and profile photo.',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        fontFamily: 'Figtree',
                                        color: _canChangeUsername
                                            ? FlutterFlowTheme.of(context).info
                                            : FlutterFlowTheme.of(context)
                                                .error,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        // Save Button
                        FFButtonWidget(
                          onPressed: _isLoading ? null : _saveChanges,
                          text: _isLoading ? 'Saving...' : 'Save Changes',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 50,
                            padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                            iconPadding:
                                EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  fontFamily: 'Figtree',
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                            elevation: 3,
                            borderSide: BorderSide(
                              color: Colors.transparent,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            disabledColor: FlutterFlowTheme.of(context)
                                .primary
                                .withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
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
