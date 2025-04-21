import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
                  _buildSettingTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notification Preferences',
                    subtitle: 'Likes, Comments, Follows, Mentions',
                    onTap: () => _showNotificationPreferences(context),
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
                    title: 'Help & FAQ',
                    subtitle: 'Get help and answers to common questions',
                    onTap: () => _navigateToHelp(context),
                  ),
                  _buildSettingTile(
                    icon: Icons.description_outlined,
                    title: 'Terms & Privacy Policy',
                    subtitle: 'Read our terms and privacy policy',
                    onTap: () => _navigateToTerms(context),
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

  void _showNotificationPreferences(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Notification Preferences'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationToggle('Likes', 'notify_likes'),
              _buildNotificationToggle('Comments', 'notify_comments'),
              _buildNotificationToggle('Follows', 'notify_follows'),
              _buildNotificationToggle('Mentions', 'notify_mentions'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(String title, String key) {
    return FutureBuilder<bool>(
      future: Future.value(_prefs.getBool(key) ?? true),
      builder: (context, snapshot) {
        return SwitchListTile(
          title: Text(title),
          value: snapshot.data ?? true,
          onChanged: (bool newValue) async {
            await _prefs.setBool(key, newValue);
            if (mounted) {
              setState(() {});
            }
          },
        );
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
              TextFormField(
                controller: deleteController,
                onChanged: (value) {
                  setState(() {
                    isDeleteButtonEnabled = value.toLowerCase() == 'delete';
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Type "delete"',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
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
                          return;
                        }

                        // Close the initial dialog
                        navigator.pop();

                        try {
                          // Check if user is signed in with Google
                          final isGoogleUser = user.providerData
                              .any((info) => info.providerId == 'google.com');

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
                                    TextFormField(
                                      controller: passwordController,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        hintText: 'Enter your password',
                                        border: OutlineInputBorder(),
                                      ),
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

                          // Delete authentication first
                          print('Deleting authentication...');
                          await user.delete();
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report a Bug'),
        content: TextField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Describe the issue...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Implement bug report submission
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Bug report submitted successfully')),
              );
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showFeatureRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request a Feature'),
        content: TextField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Describe your feature request...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Implement feature request submission
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Feature request submitted successfully')),
              );
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _navigateToHelp(BuildContext context) {
    context.pushNamed('Help');
  }

  void _navigateToTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header with close button
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LUNAKRAFT POLICIES',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPolicySection(
                        'Privacy Policy',
                        'Last Updated: 28th March 2025',
                        [
                          _buildPolicyItem('1. Introduction', [
                            'Welcome to LunaKraft. Your privacy is important to us. This Privacy Policy explains how we collect, use, disclose, and protect your personal data when you use our social media platform (the "Service"). By using the Service, you agree to the collection and use of information in accordance with this policy.',
                          ]),
                          _buildPolicyItem('2. Information We Collect', [
                            'We may collect the following types of information:',
                            '• Personal Information: Name, email address, phone number, profile picture, and other details you provide.',
                            '• Usage Data: Information about how you use the Service, including interactions, posts, and preferences.',
                            '• Device and Technical Data: IP address, browser type, device type, operating system, and app version.',
                            '• Cookies and Tracking Technologies: We use cookies and similar technologies to enhance user experience and analyse usage patterns.',
                          ]),
                          _buildPolicyItem('3. How We Use Your Information', [
                            'We use your information for the following purposes:',
                            '• To provide, maintain, and improve the Service.',
                            '• To personalize user experience and deliver relevant content.',
                            '• To communicate with you about updates, features, and security alerts.',
                            '• To prevent fraud, enforce our Terms and Conditions, and comply with legal obligations.',
                          ]),
                          _buildPolicyItem('4. Sharing of Information', [
                            'We do not sell your personal information. However, we may share your data with:',
                            '• Service Providers: Third-party vendors who help us operate and maintain the Service.',
                            '• Legal Authorities: If required by law or to protect our rights and users\' safety.',
                            '• Other Users: Depending on your privacy settings, some of your information may be visible to other users.',
                          ]),
                          _buildPolicyItem('5. Data Security', [
                            'We take reasonable measures to protect your personal data. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.',
                          ]),
                          _buildPolicyItem('6. Your Rights and Choices', [
                            'You have the right to:',
                            '• Access, update, or delete your personal data.',
                            '• Adjust privacy settings to control data visibility.',
                            '• Opt-out of marketing communications.',
                          ]),
                          _buildPolicyItem('7. Children\'s Privacy', [
                            'The Service is not intended for individuals under the age of 13. We do not knowingly collect data from children without parental consent.',
                          ]),
                          _buildPolicyItem(
                              '8. Changes to This Privacy Policy', [
                            'We may update this Privacy Policy periodically. Any changes will be posted on this page, and continued use of the Service after updates constitutes acceptance of the revised policy.',
                          ]),
                          _buildPolicyItem('9. Contact Us', [
                            'If you have any questions about this Privacy Policy, please contact us at lunakraftco@gmail.com.',
                          ]),
                        ],
                      ),
                      Divider(height: 32),
                      _buildPolicySection(
                        'Terms of Use',
                        'Last Updated: 28th March 2025',
                        [
                          _buildPolicyItem('1. Introduction', [
                            'By accessing or using LunaKraft services, you agree to be bound by these Terms of Use. If you do not agree, you may not use the Service.',
                          ]),
                          _buildPolicyItem('2. User Responsibilities', [
                            '• You must be at least 13 years old to use LunaKraft.',
                            '• You are responsible for your account security and activity.',
                            '• You may not post unlawful, offensive, or harmful content.',
                          ]),
                          _buildPolicyItem('3. Intellectual Property', [
                            '• All content on LunaKraft belongs to us or its respective owners.',
                            '• You grant us a license to use content you upload for promotional purposes.',
                          ]),
                          _buildPolicyItem('4. Termination', [
                            'We reserve the right to suspend or terminate your account if you violate these Terms.',
                          ]),
                          _buildPolicyItem('5. Limitation of Liability', [
                            'We are not liable for damages resulting from your use of LunaKraft.',
                          ]),
                          _buildPolicyItem('6. Changes to Terms', [
                            'We may update these Terms at any time. Continued use of LunaKraft after changes means you accept them.',
                          ]),
                          _buildPolicyItem('7. Contact Us', [
                            'For questions about these Terms, contact us at lunakraftco@gmail.com.',
                          ]),
                        ],
                      ),
                      Divider(height: 32),
                      _buildPolicySection(
                        'Other Legal',
                        '',
                        [
                          Text(
                            'LunaKraft complies with applicable data protection and consumer rights laws. Users should review our Privacy Policy and Terms of Use regularly.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 32),
                      _buildPolicySection(
                        'Safety Centre',
                        '',
                        [
                          _buildPolicyItem('1. Community Guidelines', [
                            'LunaKraft is committed to a safe and inclusive environment. Users must follow our community guidelines and report harmful content.',
                          ]),
                          _buildPolicyItem('2. Reporting and Blocking', [
                            '• Users can report inappropriate behavior or content through our in-app tools.',
                            '• You may block other users to manage your interactions.',
                          ]),
                          _buildPolicyItem('3. Cybersecurity Tips', [
                            '• Do not share personal information with strangers.',
                            '• Use strong passwords and enable two-factor authentication.',
                          ]),
                          _buildPolicyItem('4. Mental Health Resources', [
                            'If you experience distress while using LunaKraft, we provide resources for mental health support.',
                          ]),
                          _buildPolicyItem('5. Contact for Safety Concerns', [
                            'For urgent safety concerns, reach out to lunakraftco@gmail.com.',
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String date, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        if (date.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
        SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildPolicyItem(String title, List<String> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8),
        ...content.map((text) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            )),
        SizedBox(height: 16),
      ],
    );
  }
}
