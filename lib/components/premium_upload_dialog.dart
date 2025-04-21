import 'package:flutter/material.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import 'package:lottie/lottie.dart';
import '../services/dream_upload_service.dart';
import 'dart:io';
import 'dart:math';

class PremiumUploadDialog extends StatelessWidget {
  final int lunaCoins;
  final VoidCallback onCancel;
  final Function(bool success) onPurchase;

  const PremiumUploadDialog({
    Key? key,
    required this.lunaCoins,
    required this.onCancel,
    required this.onPurchase,
  }) : super(key: key);

  static Future<bool?> show(
    BuildContext context, {
    required int lunaCoins,
    required Function(bool success) onPurchase,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PremiumUploadDialog(
        lunaCoins: lunaCoins,
        onCancel: () => Navigator.of(context).pop(false),
        onPurchase: (success) {
          Navigator.of(context).pop(success);
          onPurchase(success);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasEnoughCoins = lunaCoins >= DreamUploadService.LUNA_COINS_COST;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation or Icon
            Container(
              height: 120,
              child: _buildAnimation(context),
            ),
            SizedBox(height: 16),

            // Title
            Text(
              'Premium Dream Upload',
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                    fontFamily: 'Figtree',
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12),

            // Description
            Text(
              'You\'ve used all your free uploads for today. Unlock more dreams with Luna Coins!',
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Figtree',
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
            ),
            SizedBox(height: 24),

            // Cost display
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipOval(
                    child: Container(
                      width: 28,
                      height: 28,
                      color: Color(0xFFFFD700),
                      child: Center(
                        child: Image.asset(
                          'assets/images/lunacoin.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '${DreamUploadService.LUNA_COINS_COST} Luna Coins',
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                          fontFamily: 'Figtree',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),

            // Current balance
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your balance: ',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Figtree',
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                ),
                Text(
                  lunaCoins > 0 ? '$lunaCoins Luna Coins' : '0',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Figtree',
                        color: lunaCoins > 0
                            ? Color(0xFF4CAF50)
                            : Color(0xFFE57373),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (lunaCoins == 0)
                  Text(
                    ' Luna Coins',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Figtree',
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                  ),
              ],
            ),
            SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: onCancel,
                        child: Center(
                          child: Text(
                            'Cancel',
                            style:
                                FlutterFlowTheme.of(context).bodyLarge.override(
                                      fontFamily: 'Figtree',
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Purchase button
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: hasEnoughCoins
                          ? Colors.transparent
                          : Colors.grey.shade700,
                      gradient: hasEnoughCoins
                          ? LinearGradient(
                              colors: [Color(0xFF6448FE), Color(0xFF9747FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: hasEnoughCoins
                          ? [
                              BoxShadow(
                                color: Color(0xFF9747FF).withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: hasEnoughCoins
                            ? () async {
                                final success = await DreamUploadService
                                    .chargeLunaCoinsForUpload();
                                onPurchase(success);
                              }
                            : null,
                        child: Center(
                          child: Text(
                            'Purchase',
                            style:
                                FlutterFlowTheme.of(context).bodyLarge.override(
                                      fontFamily: 'Figtree',
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build animation or fallback icon
  Widget _buildAnimation(BuildContext context) {
    try {
      // Using try-catch with Lottie.asset is more platform-agnostic
      // than checking for file existence with dart:io
      return Lottie.asset(
        'assets/jsons/premium_animation.json',
        fit: BoxFit.contain,
        animate: true,
        repeat: true,
        errorBuilder: (context, error, stackTrace) {
          // If loading fails, show a custom coin animation
          return CoinAnimation();
        },
      );
    } catch (e) {
      // If there's an error, show a custom coin animation
      return CoinAnimation();
    }
  }
}

// Separate StatefulWidget for the coin animation
class CoinAnimation extends StatefulWidget {
  const CoinAnimation({Key? key}) : super(key: key);

  @override
  State<CoinAnimation> createState() => _CoinAnimationState();
}

class _CoinAnimationState extends State<CoinAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Transform.scale(
          scale: 0.8 + 0.2 * sin(value * 3.14 * 2), // Pulsing effect
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 20 * value,
                  spreadRadius: 5 * value,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotating glow
                Transform.rotate(
                  angle: value * 3.14 * 2,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xFFFFD700).withOpacity(0.5),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Coin image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/lunacoin.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
