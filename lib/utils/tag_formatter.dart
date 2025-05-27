import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '/search/explore/explore_widget.dart';

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
  
  /// Builds a row of clickable tags
  static Widget buildClickableTagsWidget(
    BuildContext context,
    List<String> tags, {
    TextStyle? style,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    double spacing = 8.0,
    double runSpacing = 8.0,
    WrapAlignment alignment = WrapAlignment.start,
    bool displayHashtag = true,
  }) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: tags.map((tag) {
        // Clean and normalize the tag (remove hashtag if present, trim spaces)
        String cleanTag = tag.trim();
        if (cleanTag.startsWith('#')) {
          cleanTag = cleanTag.substring(1).trim();
        }
        
        // Skip empty tags
        if (cleanTag.isEmpty) {
          return SizedBox.shrink();
        }
        
        return InkWell(
          onTap: () {
            print('Tag tapped: $cleanTag');
            HapticFeedback.lightImpact();
            
            // Check if we're on the DetailedpostWidget page
            final currentRoute = GoRouterState.of(context).matchedLocation;
            final isDetailedPost = currentRoute.contains('/detailedpost');
            
            print('DEBUG_TAG_SEARCH: Current route: $currentRoute, isDetailedPost: $isDetailedPost');
            
            if (isDetailedPost) {
              // For DetailedpostWidget, explicitly navigate to Explore page
              print('DEBUG_TAG_SEARCH: Navigating from detailed post page to explore with tag: $cleanTag');
              
              // First navigate to home tab
              context.go('/');
              
              // Then after a short delay, go to explore with tag parameter
              Future.delayed(Duration(milliseconds: 100), () {
                if (context.mounted) {
                  context.go('/explore?searchType=tag&searchTerm=$cleanTag');
                  print('DEBUG_TAG_SEARCH: Navigation to explore completed with tag: $cleanTag');
                }
              });
            } else {
              // For other pages, use the standard method
              print('DEBUG_TAG_SEARCH: Using standard navigation method with tag: $cleanTag');
              ExploreWidget.navigateToTagSearch(context, cleanTag);
            }
          },
          child: Text(
            displayHashtag ? '#$cleanTag' : cleanTag,
            style: style ?? const TextStyle(
              color: Color(0xFF4B39EF),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}
