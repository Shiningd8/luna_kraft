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
    // Show directly as a dialog without using a bottom sheet
    // This way we don't have to pop anything
    ShareUtil.sharePost(context, post, user);
  }

  @override
  Widget build(BuildContext context) {
    // This widget is no longer needed, but we'll keep a minimal implementation
    // for backward compatibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ShareUtil.sharePost(context, post, user);
    });

    // Return an empty container that will be removed quickly
    return const SizedBox.shrink();
  }
}
