import 'package:flutter/material.dart';

/// Utility class for formatting tags with hashtags
class TagFormatter {
  /// Formats comma-separated tags string by adding hashtags and proper spacing
  ///
  /// Input: "tag1, tag2, tag3"
  /// Output: "#tag1 #tag2 #tag3"
  static String formatTags(String? tags) {
    if (tags == null || tags.isEmpty) {
      return '';
    }

    // Split by comma, trim each tag, and add hashtag
    final formattedTags = tags
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .map((tag) => '#$tag')
        .join(' ');

    return formattedTags;
  }

  /// Creates a styled widget for displaying tags
  ///
  /// This is useful for consistent tag styling across the app
  static Widget buildTagsWidget(BuildContext context, String? tags,
      {TextStyle? style}) {
    final formattedTags = formatTags(tags);
    if (formattedTags.isEmpty) {
      return SizedBox.shrink();
    }

    return Text(
      formattedTags,
      style: style,
    );
  }
}
