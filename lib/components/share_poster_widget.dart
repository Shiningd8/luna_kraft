import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
    // Dynamic font size calculation based on text length
    final length = text.length;

    // More gradual size reduction for longer texts
    if (length > 1500) return 10.0;
    if (length > 1200) return 11.0;
    if (length > 900) return 12.0;
    if (length > 700) return 13.0;
    if (length > 500) return 14.0;
    if (length > 300) return 15.0;
    if (length > 150) return 16.0;

    // Default size for short texts
    return 17.0;
  }

  @override
  Widget build(BuildContext context) {
    final contentFontSize = _calculateFontSize(widget.post.dream);

    // Calculate title font size based on length
    final titleLength = widget.post.title.length;
    final double titleFontSize =
        titleLength > 30 ? 28.0 : (titleLength > 20 ? 30.0 : 32.0);

    // Calculate username font size based on length
    final usernameLength = (widget.user.displayName ?? '').length;
    final double usernameFontSize = usernameLength > 15 ? 18.0 : 20.0;

    return RepaintBoundary(
      key: widget.boundaryKey,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 400,
          maxHeight: 800,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Background image - keeping this intact as requested
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildBackground(),
            ),

            // Gradient overlay for better text readability - enhanced for better contrast
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.75),
                  ],
                  stops: const [0.1, 0.5, 0.9],
                ),
              ),
            ),

            // Content
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info at top with improved styling
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Row(
                      children: [
                        // User profile image with enhanced styling
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
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
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.user.displayName ?? 'User',
                                style: GoogleFonts.figtree(
                                  color: Colors.white,
                                  fontSize: usernameFontSize,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.user.userName?.isNotEmpty == true)
                                Text(
                                  '@${widget.user.userName}',
                                  style: GoogleFonts.figtree(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Title with enhanced typography and sizing
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Text(
                      widget.post.title,
                      style: GoogleFonts.figtree(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Dream content with improved readability and scaling
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      // Use shrinkWrap ListView to ensure all content is visible
                      child: ListView(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          Text(
                            widget.post.dream,
                            style: GoogleFonts.figtree(
                              color: Colors.white,
                              fontSize: contentFontSize,
                              height: 1.5,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w400,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Brand at bottom with enhanced styling
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo with glow effect
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/lunamoon.png',
                            width: 28,
                            height: 28,
                            color: Colors.amber[300],
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.nights_stay,
                                color: Colors.amber[300],
                                size: 24,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LunaKraft',
                          style: GoogleFonts.figtree(
                            color: Colors.amber[300],
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
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

            // Optional: subtle vignette effect for more depth
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
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
