import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/base_layout.dart';

export '/auth/firebase_auth/auth_util.dart';
// Export pages
export '/signreg/signin/signin_widget.dart' show SigninWidget;
export '/signreg/forgot_password/forgot_password_widget.dart'
    show ForgotPasswordWidget;
export '/signreg/profile_input/profile_input_widget.dart'
    show ProfileInputWidget;
export '/home/home_page/home_page_widget.dart' show HomePageWidget;
export '/add_post/dream_entry_selection/dream_entry_selection_widget.dart'
    show DreamEntrySelectionWidget;
export '/add_post/add_post1/add_post1_widget.dart' show AddPost1Widget;
export '/add_post/add_post2/add_post2_widget.dart' show AddPost2Widget;
export '/add_post4/add_post4_widget.dart' show AddPost4Widget;
export '/profile/prof1/prof1_widget.dart' show Prof1Widget;
export '/home/detailedpost/detailedpost_widget.dart' show DetailedpostWidget;
export '/search/explore/explore_widget.dart' show ExploreWidget;
export '/search/userpage/userpage_widget.dart' show UserpageWidget;
export '/add_post/edit_page/edit_page_widget.dart' show EditPageWidget;
export '/profile/blockedusers/blockedusers_widget.dart' show BlockedusersWidget;
export '/profile/saved_posts/saved_posts_widget.dart' show SavedPostsWidget;
export '/notificationpage/notificationpage_widget.dart'
    show NotificationpageWidget;
export '/membership_page/membership_page_widget.dart' show MembershipPageWidget;
export '/dream_analysis/analysis/analysis_widget.dart' show AnalysisWidget;
export '/pendingfollows/pendingfollows_widget.dart' show PendingfollowsWidget;
export '/settings/settings_page.dart' show SettingsPage;
export '/settings/two_factor_setup.dart' show TwoFactorSetupPage;
export '/zen_mode/zen_mode_page.dart' show ZenModePage;

class AppInitializer extends StatefulWidget {
  // State fields for stateful widgets in this page.

  final Future<bool> Function() onInit;
  final Widget? child;

  const AppInitializer({
    super.key,
    required this.onInit,
    this.child,
  });

  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<bool> _isInitialized;

  @override
  void initState() {
    super.initState();
    _isInitialized = widget.onInit();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luna Kraft',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.figtreeTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: FutureBuilder<bool>(
        future: _isInitialized,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return BaseLayout();
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      routes: {
        // ... existing routes ...
      },
    );
  }
}
