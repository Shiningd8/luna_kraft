import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/utils/serialization_helpers.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '/services/app_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:page_transition/page_transition.dart';
import '/flutter_flow/nav/nav.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import '/widgets/custom_text_form_field.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  static String routeName = 'Settings';
  static String routePath = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;
  late SharedPreferences _prefs;
  bool _isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    // Create staggered animations for each section
    _animations = List.generate(4, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.25,
            0.25 + index * 0.25,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _slideAnimations = List.generate(4, (index) {
      return Tween<Offset>(
        begin: Offset(0.2, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.25,
            0.25 + index * 0.25,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _fadeAnimations = List.generate(4, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.25,
            0.25 + index * 0.25,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _controller.forward();
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: FlutterFlowTheme.of(context).primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Figtree',
                color: FlutterFlowTheme.of(context).primaryText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnimatedSection(
                0,
                'General Settings',
                [
                  _buildSettingTile(
                    icon: Icons.palette_outlined,
                    title: 'Theme',
                    subtitle: 'Light, Dark, System Default',
                    onTap: () => _showThemeDialog(context),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildAnimatedSection(
                1,
                'Account & Privacy',
                [
                  _buildSettingTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: 'Change username, bio, profile picture',
                    onTap: () => _navigateToEditProfile(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.block_outlined,
                    title: 'Manage Blocked Users',
                    subtitle: 'View and manage blocked accounts',
                    onTap: () => _navigateToBlockedUsers(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.delete_forever_outlined,
                    title: 'Account Deletion',
                    subtitle: 'Permanently delete your account',
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildAnimatedSection(
                2,
                'Security & Login',
                [
                  _buildSettingTile(
                    icon: Icons.security_outlined,
                    title: 'Two-Factor Authentication',
                    subtitle: 'Add an extra layer of security',
                    onTap: () => _setupTwoFactorAuth(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.logout,
                    title: 'Logout from All Devices',
                    subtitle: 'Sign out from all connected devices',
                    onTap: () => _logoutFromAllDevices(context),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildAnimatedSection(
                3,
                'Support & Feedback',
                [
                  _buildSettingTile(
                    icon: Icons.bug_report_outlined,
                    title: 'Report a Bug',
                    subtitle: 'Help us improve by reporting issues',
                    onTap: () => _showBugReportDialog(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.lightbulb_outline,
                    title: 'Request a Feature',
                    subtitle: 'Suggest new features',
                    onTap: () => _showFeatureRequestDialog(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.help_outline,
                    title: 'Help',
                    subtitle: 'Get help with using the app',
                    onTap: () => _navigateToHelp(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.question_answer_outlined,
                    title: 'FAQ',
                    subtitle: 'Frequently Asked Questions',
                    onTap: () => _navigateToFAQ(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Use',
                    subtitle: 'Read our terms of use',
                    onTap: () => _navigateToTermsOfUse(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: () => _navigateToPrivacyPolicy(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection(int index, String title, List<Widget> children) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimations[index].value,
          child: Opacity(
            opacity: _fadeAnimations[index].value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Figtree',
                        color: FlutterFlowTheme.of(context).primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: FlutterFlowTheme.of(context).primary,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                              fontFamily: 'Figtree',
                              color: FlutterFlowTheme.of(context).primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Figtree',
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 14,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Dialog and Navigation Methods
  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('Light', Icons.light_mode, ThemeMode.light),
            _buildThemeOption('Dark', Icons.dark_mode, ThemeMode.dark),
            _buildThemeOption(
                'System Default', Icons.settings_brightness, ThemeMode.system),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String title, IconData icon, ThemeMode mode) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () async {
        FlutterFlowTheme.saveThemeMode(mode);
        setDarkModeSetting(context, mode);
        if (mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    context.pushNamed('EditProfile');
  }

  void _navigateToBlockedUsers(BuildContext context) {
    context.pushNamed(
      'blockedusers',
      queryParameters: {
        'userref': serializeParam(
          currentUserReference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final TextEditingController deleteController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    bool isDeleteButtonEnabled = false;

    // Store scaffold messenger early
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to delete your account? This action cannot be undone.',
                style: FlutterFlowTheme.of(context).bodyMedium,
              ),
              SizedBox(height: 16),
              Text(
                'Type "delete" to confirm:',
                style: FlutterFlowTheme.of(context).bodySmall,
              ),
              SizedBox(height: 8),
              CustomTextFormField(
                controller: deleteController,
                onChanged: (value) {
                  setState(() {
                    isDeleteButtonEnabled = value.toLowerCase() == 'delete';
                  });
                },
                hintText: 'Type "delete"',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Properly dispose controllers before closing dialog
                deleteController.dispose();
                passwordController.dispose();
                Navigator.pop(dialogContext);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: isDeleteButtonEnabled
                  ? () async {
                      try {
                        print('Starting account deletion process...');

                        final user = FirebaseAuth.instance.currentUser;
                        final userRef = currentUserReference;
                        final userId = user?.uid;

                        print('User Reference: $userRef');
                        print('User ID: $userId');

                        if (user == null || userRef == null || userId == null) {
                          print('Error: User not found or missing information');
                          // Dispose controllers before returning
                          deleteController.dispose();
                          passwordController.dispose();
                          return;
                        }

                        // Dispose controllers before closing the dialog
                        deleteController.dispose();
                        passwordController.dispose();

                        // Close the initial dialog
                        navigator.pop();

                        try {
                          // Check if user is signed in with Google or Apple
                          final isGoogleUser = user.providerData
                              .any((info) => info.providerId == 'google.com');
                          final isAppleUser = user.providerData
                              .any((info) => info.providerId == 'apple.com');

                          if (isGoogleUser) {
                            print('Reauthenticating Google user...');
                            final GoogleSignIn googleSignIn = GoogleSignIn();
                            final GoogleSignInAccount? googleUser =
                                await googleSignIn.signIn();
                            if (googleUser == null) {
                              throw Exception('Google Sign In failed');
                            }
                            final GoogleSignInAuthentication googleAuth =
                                await googleUser.authentication;
                            final credential = GoogleAuthProvider.credential(
                              accessToken: googleAuth.accessToken,
                              idToken: googleAuth.idToken,
                            );
                            await user.reauthenticateWithCredential(credential);
                            print('Google reauthentication successful');
                          } else if (isAppleUser) {
                            print('Handling Apple user account deletion...');
                            // Apple users cannot easily reauthenticate through the app
                            // Firebase allows recent sign-in to delete without reauthentication
                            try {
                              // Try direct deletion first, which might work for recent Apple sign-ins
                              await user.delete();
                              print('Apple user deletion successful without reauthentication');
                            } catch (authError) {
                              print('Apple user deletion requires reauthentication: $authError');
                              // Show an explanatory dialog with instructions
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) => AlertDialog(
                                  title: Text('Apple Sign-In Verification Required'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'To delete your account securely, you need to verify your identity with Apple. Please follow these steps:',
                                        style: FlutterFlowTheme.of(context).bodySmall,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        '1. Sign out from the app\n2. Sign in again with your Apple ID\n3. Then try deleting your account again',
                                        style: FlutterFlowTheme.of(context).bodyMedium,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        // Sign the user out and redirect to login
                                        await FirebaseAuth.instance.signOut();
                                        Navigator.pop(context);
                                        router.go('/');
                                      },
                                      child: Text(
                                        'Sign Out Now',
                                        style: TextStyle(color: FlutterFlowTheme.of(context).primary),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              // Don't proceed with deletion flow
                              throw Exception('Apple user reauthentication required');
                            }
                          } else {
                            // For email/password users, show password dialog
                            final password = await showDialog<String>(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) => AlertDialog(
                                title: Text('Confirm Password'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Please enter your password to confirm account deletion:',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall,
                                    ),
                                    SizedBox(height: 8),
                                    CustomTextFormField(
                                      controller: passwordController,
                                      obscureText: true,
                                      hintText: 'Enter your password',
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(
                                        context, passwordController.text),
                                    child: Text(
                                      'Confirm',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (password == null || password.isEmpty) {
                              throw Exception(
                                  'Password required to delete account');
                            }

                            print(
                                'Attempting reauthentication with password...');
                            final credential = EmailAuthProvider.credential(
                              email: user.email!,
                              password: password,
                            );
                            await user.reauthenticateWithCredential(credential);
                            print('Email/password reauthentication successful');
                          }

                          // Only proceed with deletion if we haven't thrown an exception
                          // for Apple users requiring reauthentication
                          
                          // Delete authentication first (if not Apple user that needs reauthentication)
                          if (!isAppleUser || user.metadata.lastSignInTime!.isAfter(
                              DateTime.now().subtract(Duration(minutes: 5)))) {
                            print('Deleting authentication...');
                            if (!isAppleUser) {
                              // For non-Apple users, we've already reauthenticated above
                              await user.delete();
                            }
                            // For Apple users, we already tried deletion earlier
                            print('Authentication deleted successfully');

                            // Get user's posts
                            print('Fetching user posts...');
                            final userPosts = await FirebaseFirestore.instance
                                .collection('posts')
                                .where('poster', isEqualTo: userRef)
                                .get();
                            print('Found ${userPosts.docs.length} posts');

                            // Get user document data
                            print('Fetching user document...');
                            final userDoc = await userRef.get();
                            final userData =
                                userDoc.data() as Map<String, dynamic>? ?? {};

                            final followers = List<DocumentReference>.from(
                                userData['users_following_me'] ?? []);
                            final following = List<DocumentReference>.from(
                                userData['following_users'] ?? []);

                            print('Followers: ${followers.length}');
                            print('Following: ${following.length}');

                            // Create batch
                            print('Starting batch operations...');
                            final batch = FirebaseFirestore.instance.batch();

                            // Delete posts
                            for (var post in userPosts.docs) {
                              batch.delete(post.reference);
                            }

                            // Update followers
                            for (var followerRef in followers) {
                              batch.update(followerRef, {
                                'following_users':
                                    FieldValue.arrayRemove([userRef])
                              });
                            }

                            // Update following
                            for (var followingRef in following) {
                              batch.update(followingRef, {
                                'users_following_me':
                                    FieldValue.arrayRemove([userRef])
                              });
                            }

                            // Delete user document
                            batch.delete(userRef);

                            // Commit batch
                            print('Committing batch operations...');
                            await batch.commit();
                            print('Batch operations completed successfully');

                            // Sign out
                            print('Signing out...');
                            await FirebaseAuth.instance.signOut();
                            if (isGoogleUser) {
                              await GoogleSignIn().signOut();
                            }
                            print('Signed out successfully');

                            // Clear app state
                            print('Clearing app state...');
                            await FFAppState().initializePersistedState();
                            print('App state cleared');

                            // Navigate to sign in
                            print('Attempting navigation...');
                            if (!_isDisposed) {
                              print('Widget not disposed, navigating...');
                              await Future.delayed(Duration(milliseconds: 100));
                              router.go('/');
                              print('Navigation completed');
                            }
                          }
                        } catch (e) {
                          print('Error during account deletion process: $e');
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().contains('password is invalid')
                                    ? 'Incorrect password. Please try again.'
                                    : e.toString().contains('Password required')
                                        ? 'Password is required to delete your account.'
                                        : 'Error deleting account: ${e.toString()}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          if (!_isDisposed) {
                            router.go('/');
                          }
                        }
                      } catch (e, stackTrace) {
                        print('Error during account deletion: $e');
                        print('Stack trace: $stackTrace');
                      }
                    }
                  : null,
              child: Text(
                'Delete Account',
                style: TextStyle(
                  color: isDeleteButtonEnabled ? Colors.red : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setupTwoFactorAuth(BuildContext context) {
    context.pushNamed('TwoFactorSetup');
  }

  void _logoutFromAllDevices(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout from All Devices'),
        content: Text('Are you sure you want to logout from all devices?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthUtil.safeSignOut(
                context: context,
                shouldNavigate: true,
                navigateTo: '/',
              );
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    final bugReportController = TextEditingController();
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Report a Bug'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSubmitting)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Submitting...'),
                    ],
                  ),
                ),
              CustomTextFormField(
                controller: bugReportController,
                maxLines: 5,
                hintText: 'Describe the issue...',
                enabled: !_isSubmitting,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      bugReportController.dispose();
                      Navigator.pop(dialogContext);
                    },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final bugReport = bugReportController.text.trim();
                      if (bugReport.isNotEmpty) {
                        // Show submitting state
                        setState(() => _isSubmitting = true);

                        try {
                          // Save to Firebase
                          await FirebaseFirestore.instance
                              .collection('bug_reports')
                              .add({
                            'content': bugReport,
                            'user_id': currentUserUid,
                            'user_email': currentUserEmail,
                            'timestamp': FieldValue.serverTimestamp(),
                            'status': 'new',
                          });

                          // Success - close dialog
                          bugReportController.dispose();
                          Navigator.pop(dialogContext);
                        } catch (e) {
                          print('Error submitting bug report: $e');
                          // Show error state
                          if (mounted) {
                            setState(() => _isSubmitting = false);
                          }
                        }
                      }
                    },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeatureRequestDialog(BuildContext context) {
    final featureRequestController = TextEditingController();
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Request a Feature'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSubmitting)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Submitting...'),
                    ],
                  ),
                ),
              CustomTextFormField(
                controller: featureRequestController,
                maxLines: 5,
                hintText: 'Describe your feature request...',
                enabled: !_isSubmitting,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      featureRequestController.dispose();
                      Navigator.pop(dialogContext);
                    },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final featureRequest =
                          featureRequestController.text.trim();
                      if (featureRequest.isNotEmpty) {
                        setState(() => _isSubmitting = true);
                        try {
                          await FirebaseFirestore.instance
                              .collection('bug_reports')
                              .add({
                            'content': featureRequest,
                            'user_id': currentUserUid,
                            'user_email': currentUserEmail,
                            'timestamp': FieldValue.serverTimestamp(),
                            'status': 'new',
                            'type': 'feature_request',
                          });
                          featureRequestController.dispose();
                          Navigator.pop(dialogContext);
                        } catch (e) {
                          print('Error submitting feature request: $e');
                          if (mounted) {
                            setState(() => _isSubmitting = false);
                          }
                        }
                      }
                    },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToHelp(BuildContext context) {
    _launchURL('https://lunakraft.com/Landing/Help-center.html');
  }

  void _navigateToFAQ(BuildContext context) {
    _launchURL('https://lunakraft.com/Landing/faqs.html');
  }

  void _navigateToTermsOfUse(BuildContext context) {
    _launchURL('https://lunakraft.com/Landing/terms-of-use.html');
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    _launchURL('https://lunakraft.com/Landing/privacy-policy.html');
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $urlString');
    }
  }
}
