import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/schema/posts_record.dart';
import '/backend/schema/user_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SharePosterWidget extends StatefulWidget {
  final PostsRecord post;
  final UserRecord user;
  final GlobalKey boundaryKey;

  SharePosterWidget({
    required this.post,
    required this.user,
    Key? key,
  })  : boundaryKey = GlobalKey(debugLabel: 'poster_${post.reference.id}'),
        super(key: key);

  @override
  State<SharePosterWidget> createState() => _SharePosterWidgetState();
}

class _SharePosterWidgetState extends State<SharePosterWidget> {
  double _calculateFontSize(String text) {
    // Calculate font size based on text length
    final length = text.length;

    if (length > 1000) return 10.0;
    if (length > 700) return 11.0;
    if (length > 500) return 12.0;
    if (length > 300) return 13.0;
    if (length > 100) return 14.0;

    return 15.0;
  }

  @override
  Widget build(BuildContext context) {
    final contentFontSize = _calculateFontSize(widget.post.dream);

    return RepaintBoundary(
      key: widget.boundaryKey,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 400,
          maxHeight: 800,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Background image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildBackground(),
            ),

            // Gradient overlay for better text readability
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Content
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info at top
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        // User profile image with fallback
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 48,
                            height: 48,
                            color: FlutterFlowTheme.of(context).primary,
                            child: widget.user.photoUrl != null &&
                                    widget.user.photoUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: widget.user.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        Center(
                                      child: Text(
                                        widget.user.displayName?.isNotEmpty ==
                                                true
                                            ? widget.user.displayName![0]
                                                .toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      widget.user.displayName?.isNotEmpty ==
                                              true
                                          ? widget.user.displayName![0]
                                              .toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.user.displayName ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.user.userName?.isNotEmpty == true)
                                Text(
                                  '@${widget.user.userName}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Text(
                      widget.post.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),

                  // Dream content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        widget.post.dream,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: contentFontSize,
                          height: 1.4,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  // Brand at bottom
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/lunamoon.png',
                          width: 30,
                          height: 30,
                          color: Colors.amber[300],
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.nights_stay,
                              color: Colors.amber[300],
                              size: 24,
                            );
                          },
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'LunaKraft',
                          style: TextStyle(
                            color: Colors.amber[300],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    final bgUrl = widget.post.videoBackgroundUrl;

    // Check if the background is set and not empty
    if (bgUrl.isNotEmpty) {
      // Check if it's an asset path
      if (bgUrl.startsWith('assets/')) {
        return Opacity(
          opacity: widget.post.videoBackgroundOpacity > 0
              ? widget.post.videoBackgroundOpacity
              : 0.75,
          child: Image.asset(
            bgUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading asset image: $error');
              return _buildFallbackBackground();
            },
          ),
        );
      }

      // Check if it's a network image URL (for images, not videos)
      else if (bgUrl.contains('http') &&
          !bgUrl.contains('.mp4') &&
          !bgUrl.contains('.webm')) {
        return Opacity(
          opacity: widget.post.videoBackgroundOpacity > 0
              ? widget.post.videoBackgroundOpacity
              : 0.75,
          child: CachedNetworkImage(
            imageUrl: bgUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => _buildFallbackBackground(),
            errorWidget: (context, url, error) {
              print('Error loading network image: $error');
              return _buildFallbackBackground();
            },
          ),
        );
      }
    }

    // If the background is not valid or is empty, use the fallback
    return _buildFallbackBackground();
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF003366), // Dark blue
            Color(0xFF004080), // Medium blue
          ],
        ),
      ),
    );
  }

  Future<File?> renderToImage(BuildContext context) async {
    try {
      // Wait to ensure widget is fully laid out
      await Future.delayed(const Duration(milliseconds: 200));

      // Capture the rendered widget using a more reliable approach
      final boundary = widget.boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Failed to capture widget: Render boundary not found');
      }

      // Use a higher pixel ratio for better quality but not too high to cause memory issues
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception(
            'Failed to capture widget: Could not convert image to bytes');
      }

      // Save to file
      final tempDir = await getTemporaryDirectory();
      final file =
          File('${tempDir.path}/dream_post_${widget.post.reference.id}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file;
    } catch (e) {
      print('Error rendering poster to image: $e');
      return null;
    }
  }
}
