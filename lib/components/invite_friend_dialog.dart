import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

import '/flutter_flow/flutter_flow_theme.dart';
import '/utils/share_util.dart';
import 'package:lottie/lottie.dart';

class InviteFriendDialog extends StatelessWidget {
  final String? userName;

  const InviteFriendDialog({
    Key? key,
    this.userName,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {String? userName}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return InviteFriendDialog(userName: userName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                  FlutterFlowTheme.of(context).secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with animation
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          child: Lottie.asset(
                            'assets/lottie/invitation.json',
                            fit: BoxFit.contain,
                            animate: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Invite Your Friends!',
                          style: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 300.ms).slideY(
                              begin: 0.2,
                              end: 0,
                              curve: Curves.easeOutBack,
                              duration: 500.ms,
                            ),

                        SizedBox(height: 16),

                        Text(
                          'Share the dream journey with your friends and family. Invite them to join LunaKraft and explore their dream world together!',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(
                              delay: 200.ms,
                              duration: 500.ms,
                            ),

                        SizedBox(height: 32),

                        // Benefits
                        ..._buildBenefitItems(context)
                            .animate(
                              interval: 100.ms,
                            )
                            .fadeIn(
                              duration: 400.ms,
                            )
                            .slideX(
                              begin: -0.2,
                              end: 0,
                              curve: Curves.easeOut,
                              duration: 500.ms,
                            ),

                        SizedBox(height: 32),

                        // Share button
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await ShareUtil.shareAppInvitation(
                              context,
                              userName: userName,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FlutterFlowTheme.of(context)
                                .primary
                                .withOpacity(0.8),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.share),
                              SizedBox(width: 12),
                              Text(
                                'Invite Now',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(
                              delay: 500.ms,
                              duration: 400.ms,
                            )
                            .scale(
                              delay: 500.ms,
                              duration: 400.ms,
                              curve: Curves.elasticOut,
                            ),

                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
          begin: Offset(0.9, 0.9),
          end: Offset(1.0, 1.0),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }

  List<Widget> _buildBenefitItems(BuildContext context) {
    final benefits = [
      {
        'icon': Icons.cloud_outlined,
        'title': 'Dream sharing',
        'description': 'Share dreams with friends',
      },
      {
        'icon': Icons.insights_outlined,
        'title': 'Dream analysis',
        'description': 'Analyze dream patterns together',
      },
      {
        'icon': Icons.people_outline,
        'title': 'Social features',
        'description': 'Like and comment on dreams',
      },
    ];

    return benefits.map((benefit) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                benefit['icon'] as IconData,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    benefit['title'] as String,
                    style: FlutterFlowTheme.of(context).titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    benefit['description'] as String,
                    style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
