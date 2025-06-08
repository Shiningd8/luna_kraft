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
    // More aggressive font size calculation for better content fitting
    final length = text.length;

    if (length > 2000) return 12.0;
    if (length > 1500) return 13.0;
    if (length > 1200) return 14.0;
    if (length > 900) return 15.0;
    if (length > 700) return 16.0;
    if (length > 500) return 17.0;
    if (length > 300) return 18.0;
    if (length > 150) return 19.0;

    return 20.0;
  }

  @override
  Widget build(BuildContext context) {
    final contentFontSize = _calculateFontSize(widget.post.dream);

    // Calculate title font size based on length
    final titleLength = widget.post.title.length;
    final double titleFontSize =
        titleLength > 50 ? 24.0 : (titleLength > 30 ? 28.0 : 32.0);

    // Calculate username font size
    final usernameLength = (widget.user.displayName ?? '').length;
    final double usernameFontSize = usernameLength > 15 ? 18.0 : 20.0;

    return RepaintBoundary(
      key: widget.boundaryKey,
      child: Container(
        // Instagram Story dimensions (9:16 aspect ratio)
        width: 1080,
        height: 1920,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: _buildBackground(),
              ),

              // Gradient overlay for better text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Content with Instagram story safe area margins
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 120, // Safe area for Instagram story top
                    bottom: 200, // Safe area for Instagram story bottom
                    left: 24,
                    right: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User info at top - more compact
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            // User profile image - smaller
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 36, // Further reduced
                                  height: 36,
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
                                                fontSize: 16,
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
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
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
                                    style: GoogleFonts.figtree(
                                      color: Colors.white,
                                      fontSize: usernameFontSize,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.5),
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
                                        fontSize: 12,
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

                      // Title - more compact
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: AutoSizeText(
                          widget.post.title,
                          style: GoogleFonts.figtree(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 2, // Reduced to save space
                          minFontSize: 20,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Dream content - use remaining available space
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: AutoSizeText(
                            widget.post.dream,
                            style: GoogleFonts.figtree(
                              color: Colors.white,
                              fontSize: contentFontSize,
                              height: 1.3, // Slightly tighter
                              letterSpacing: 0.2,
                              fontWeight: FontWeight.w400,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.left,
                            minFontSize: 10,
                            maxLines: null,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),

                      // Brand at bottom - using combined logo and text image
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 16),
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/lunalogotext.png',
                          height: 36, // Same height as the previous icon
                          fit: BoxFit.contain,
                          color: Colors.amber[300],
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to the original design if image fails to load
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.nights_stay,
                                  color: Colors.amber[300],
                                  size: 36,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'LunaKraft',
                                  style: GoogleFonts.figtree(
                                    color: Colors.amber[300],
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.6),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
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

      // Use a higher pixel ratio for better quality and proper font rendering
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
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
