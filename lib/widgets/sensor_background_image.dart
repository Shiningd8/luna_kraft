import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// SensorBackgroundImage with gyro movement removed
class SensorBackgroundImage extends StatefulWidget {
  final String imageUrl;
  final Widget child;
  final double motionMultiplier; // kept for backward compatibility but not used

  const SensorBackgroundImage({
    Key? key,
    required this.imageUrl,
    required this.child,
    this.motionMultiplier = 40.0,
  }) : super(key: key);

  @override
  State<SensorBackgroundImage> createState() => _SensorBackgroundImageState();
}

class _SensorBackgroundImageState extends State<SensorBackgroundImage> {
  Size? _imageSize;
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Load image size for proper scaling
    _loadImage();
  }

  void _loadImage() {
    if (widget.imageUrl.startsWith('http://') ||
        widget.imageUrl.startsWith('https://')) {
      Image image = Image.network(widget.imageUrl);
      _getImageSize(image);
    } else {
      Image image = Image.asset(widget.imageUrl);
      _getImageSize(image);
    }
  }

  void _getImageSize(Image image) {
    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _imageSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
          });
        }
      }),
    );
  }

  Widget _buildBackgroundImage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use Container with BoxDecoration and DecorationImage for full coverage
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            color: Colors.black, // Fallback color while image loads
            image: DecorationImage(
              image: widget.imageUrl.startsWith('http://') ||
                      widget.imageUrl.startsWith('https://')
                  ? NetworkImage(widget.imageUrl)
                  : AssetImage(widget.imageUrl) as ImageProvider,
              fit: BoxFit.cover,
              // Increase scale slightly to ensure no white borders
              scale: 0.9,
              // Center the image
              alignment: Alignment.center,
              onError: (exception, stackTrace) {
                print('Error loading background image: $exception');
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image without parallax effect
        _buildBackgroundImage(),

        // Content
        widget.child,
      ],
    );
  }
}
