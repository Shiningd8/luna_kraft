import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/add_post/create_post/create_post_widget.dart';
import '/add_post/add_post1/add_post1_widget.dart';
import 'dream_entry_selection_model.dart';
export 'dream_entry_selection_model.dart';

class DreamEntrySelectionWidget extends StatefulWidget {
  const DreamEntrySelectionWidget({Key? key}) : super(key: key);

  static String routeName = 'DreamEntrySelection';
  static String routePath = '/dreamEntrySelection';

  @override
  _DreamEntrySelectionWidgetState createState() =>
      _DreamEntrySelectionWidgetState();
}

class _DreamEntrySelectionWidgetState extends State<DreamEntrySelectionWidget>
    with TickerProviderStateMixin {
  late DreamEntrySelectionModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DreamEntrySelectionModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F0E20),
              Color(0xFF25224A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Animated Background
            Positioned.fill(
              child: Lottie.asset(
                'assets/jsons/Animation_-_1739171323302.json',
                fit: BoxFit.cover,
                animate: true,
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header
                      Text(
                        'Post Your Dream',
                        style: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .override(
                              fontFamily: 'Figtree',
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, curve: Curves.easeOut),

                      SizedBox(height: 12),

                      Text(
                        'Choose how you want to share your dream',
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              fontFamily: 'Figtree',
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                      ).animate().fadeIn(
                          delay: 200.ms,
                          duration: 600.ms,
                          curve: Curves.easeOut),

                      SizedBox(height: 30),

                      // Write Your Own Dream Option
                      _buildOptionCard(
                        context: context,
                        icon: Icons.edit_note_rounded,
                        title: 'Write Your Own Dream',
                        description:
                            'Write and share your dream experience in your own words',
                        gradient: [Color(0xFF7B61FF), Color(0xFF5B41FF)],
                        glowColor: Color(0xFF7B61FF).withOpacity(0.3),
                        onTap: () {
                          context.pushNamed(
                            CreatePostWidget.routeName,
                            extra: <String, dynamic>{
                              kTransitionInfoKey: TransitionInfo(
                                hasTransition: true,
                                transitionType: PageTransitionType.fade,
                                duration: Duration(milliseconds: 350),
                              ),
                            },
                          );
                        },
                      ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                      SizedBox(height: 14),

                      // Text divider
                      Row(
                        children: [
                          Expanded(
                              child:
                                  Divider(color: Colors.white24, thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
                          ),
                          Expanded(
                              child:
                                  Divider(color: Colors.white24, thickness: 1)),
                        ],
                      ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                      SizedBox(height: 14),

                      // Complete with AI Option
                      _buildOptionCard(
                        context: context,
                        icon: Icons.auto_awesome,
                        title: 'Complete with AI',
                        description:
                            'Start with a fragment and let AI help complete your dream',
                        gradient: [Color(0xFF6448FE), Color(0xFF9747FF)],
                        glowColor: Color(0xFF9747FF).withOpacity(0.3),
                        onTap: () {
                          context.pushNamed(
                            AddPost1Widget.routeName,
                            extra: <String, dynamic>{
                              kTransitionInfoKey: TransitionInfo(
                                hasTransition: true,
                                transitionType: PageTransitionType.fade,
                                duration: Duration(milliseconds: 350),
                              ),
                            },
                          );
                        },
                      ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradient,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: 15,
              spreadRadius: 0,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(height: 14),
            Text(
              title,
              style: FlutterFlowTheme.of(context).titleMedium.override(
                    fontFamily: 'Figtree',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Figtree',
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
            ),
            SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
