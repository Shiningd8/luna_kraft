import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/data/dream_facts.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';

class DreamFactWidget extends StatelessWidget {
  final String fact;

  const DreamFactWidget({
    Key? key,
    required this.fact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FlutterFlowTheme.of(context).primary.withOpacity(0.3),
                  FlutterFlowTheme.of(context).secondary.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Dream Fact',
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            fontFamily: 'Figtree',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Did you know?',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Figtree',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  fact,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Figtree',
                        color: Colors.white,
                        fontSize: 14,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedDreamFactWidget extends StatefulWidget {
  const AnimatedDreamFactWidget({Key? key}) : super(key: key);

  @override
  State<AnimatedDreamFactWidget> createState() =>
      _AnimatedDreamFactWidgetState();
}

class _AnimatedDreamFactWidgetState extends State<AnimatedDreamFactWidget> {
  late String currentFact;

  @override
  void initState() {
    super.initState();
    currentFact = DreamFacts.getRandomFact();
  }

  @override
  Widget build(BuildContext context) {
    return DreamFactWidget(fact: currentFact)
        .animate()
        .fade(duration: 600.ms, curve: Curves.easeOut)
        .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }
}
