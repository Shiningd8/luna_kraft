import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class NativeAdPost extends StatefulWidget {
  final String adUnitId;
  final int animationIndex;
  final bool animateEntry;

  const NativeAdPost({
    Key? key,
    required this.adUnitId,
    this.animationIndex = 0,
    this.animateEntry = false,
  }) : super(key: key);

  @override
  State<NativeAdPost> createState() => _NativeAdPostState();
}

class _NativeAdPostState extends State<NativeAdPost> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isAdError = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadNativeAd();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: widget.adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (_) {
          print('Native ad loaded');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _isAdError = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('Native ad failed to load: ${error.message}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _isAdError = true;
            });
          }
        },
        onAdClicked: (_) {
          print('Native ad clicked');
        },
        onAdImpression: (_) {
          print('Native ad impression recorded');
        },
        onAdClosed: (_) {
          print('Native ad closed');
        },
        onAdOpened: (_) {
          print('Native ad opened');
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: const Color(0x00000000), // Completely transparent
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: FlutterFlowTheme.of(context).primary,
          style: NativeTemplateFontStyle.monospace,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 15.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white.withOpacity(0.9),
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 13.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white.withOpacity(0.7),
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.italic,
          size: 12.0,
        ),
      ),
    );

    _nativeAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    Widget adWidget = Container(
      height: 130, // Increased from 120 to 130 to accommodate content
      margin: EdgeInsets.symmetric(horizontal: 0),
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          if (_isAdLoaded && _nativeAd != null)
            // Display the ad
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 12, top: 4, bottom: 2),
                    child: Text(
                      'Sponsored',
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            fontFamily: 'Figtree',
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.6),
                          ),
                    ),
                  ),
                  Expanded(
                    child: AdWidget(ad: _nativeAd!),
                  ),
                ],
              ),
            )
          else if (_isAdError)
            // Show error message (styled like posts)
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Added to prevent overflow
                children: [
                  Text(
                    'Sponsored Content',
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                          fontFamily: 'Figtree',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ad content currently unavailable.',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Figtree',
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                  ),
                ],
              ),
            )
          else
            // Show loading placeholder (styled like posts)
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Added to prevent overflow
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.3),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize:
                              MainAxisSize.min, // Added to prevent overflow
                          children: [
                            Container(
                              height: 12,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              height: 8,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircularProgressIndicator(
                        color: FlutterFlowTheme.of(context).primary,
                        strokeWidth: 2,
                      ),
                    ],
                  ),
                  SizedBox(height: 10), // Reduced from 12 to 10
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 4), // Reduced from 6 to 4
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    // Apply animation if needed
    if (widget.animateEntry) {
      return adWidget
          .animate()
          .fade(
            duration: 250.ms,
            curve: Curves.easeOutQuart,
          )
          .scale(
            begin: const Offset(0.98, 0.98),
            end: const Offset(1.0, 1.0),
            duration: 250.ms,
            curve: Curves.easeOutQuart,
          );
    }

    return adWidget;
  }
}
