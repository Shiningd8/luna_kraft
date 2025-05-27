import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '/backend/schema/posts_record.dart';
import '/backend/schema/user_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/utils/share_util.dart';

class ShareOptionsDialog extends StatelessWidget {
  final PostsRecord post;
  final UserRecord user;

  const ShareOptionsDialog({
    Key? key,
    required this.post,
    required this.user,
  }) : super(key: key);

  static void show(BuildContext context, PostsRecord post, UserRecord user) {
    // Call directly to ShareUtil with proper error handling
    try {
      ShareUtil.sharePost(context, post, user);
    } catch (e) {
      print('Error showing share dialog: $e');
      // If context is still valid, show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to show share dialog: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This widget is no longer needed, but we'll keep a minimal implementation
    // for backward compatibility. We don't want to automatically pop or trigger share here.
    return const SizedBox.shrink();
  }
}
