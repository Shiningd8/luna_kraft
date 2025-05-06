import '';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/add_post/create_post/create_post_widget.dart';
import '/widgets/lottie_background.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'add_post1_model.dart';
export 'add_post1_model.dart';

class AddPost1Widget extends StatefulWidget {
  const AddPost1Widget({super.key});

  static String routeName = 'AddPost1';
  static String routePath = '/addPost1';

  @override
  State<AddPost1Widget> createState() => _AddPost1WidgetState();
}

class _AddPost1WidgetState extends State<AddPost1Widget>
    with TickerProviderStateMixin {
  late AddPost1Model _model;
  bool _isLoading = false;
  bool _isGenerating = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddPost1Model());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    // Add listener to text controller
    _model.textController?.addListener(() {
      setState(() {}); // Trigger rebuild when text changes
    });

    // Initialize glow animation controller
    _glowController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    );

    // Create color animation with pulsing effect
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation
    _glowController.repeat();

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.ms,
            duration: 600.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    _glowController.stop();
    _glowController.dispose();
    super.dispose();
  }

  Color _getGlowColor() {
    final value = _glowAnimation.value;
    if (value < 0.25) {
      return Color.lerp(Color(0xFF6448FE), Color(0xFF9747FF), value * 4)!;
    } else if (value < 0.5) {
      return Color.lerp(
          Color(0xFF9747FF), Color(0xFF20B6EB), (value - 0.25) * 4)!;
    } else if (value < 0.75) {
      return Color.lerp(
          Color(0xFF20B6EB), Color(0xFF036257), (value - 0.5) * 4)!;
    } else {
      return Color.lerp(
          Color(0xFF036257), Color(0xFF6448FE), (value - 0.75) * 4)!;
    }
  }

  double _getGlowOpacity() {
    return 0.4 + (0.3 * (1 - (_glowAnimation.value - 0.5).abs() * 2));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        drawer: Drawer(
          elevation: 16.0,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 1.0, 0.0),
            child: Container(
              width: 270.0,
              height: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 300.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFE5E7EB),
                    offset: Offset(
                      1.0,
                      0.0,
                    ),
                  )
                ],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(0.0),
                  bottomRight: Radius.circular(20.0),
                  topLeft: Radius.circular(0.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 20.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(
                            Icons.mode_night_sharp,
                            color: Color(0xFF6F61EF),
                            size: 32.0,
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                12.0, 0.0, 0.0, 0.0),
                            child: Text(
                              'Hello!',
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    fontFamily: 'Outfit',
                                    color: Color(0xFF15161E),
                                    fontSize: 24.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                140.0, 0.0, 0.0, 0.0),
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                if (scaffoldKey.currentState!.isDrawerOpen ||
                                    scaffoldKey.currentState!.isEndDrawerOpen) {
                                  Navigator.pop(context);
                                }
                              },
                              child: Icon(
                                Icons.close_outlined,
                                color: Color(0xFF553AD5),
                                size: 35.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFFF1F4F8),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).info,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.dashboard_rounded,
                                color: Color(0xFF6F61EF),
                                size: 28.0,
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    12.0, 0.0, 0.0, 0.0),
                                child: Text(
                                  'My account',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .override(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF15161E),
                                        fontSize: 16.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business_rounded,
                                color: Color(0xFF606A85),
                                size: 28.0,
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    12.0, 0.0, 0.0, 0.0),
                                child: Text(
                                  'Settings',
                                  style: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .override(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF606A85),
                                        fontSize: 16.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.document_scanner_rounded,
                                color: Color(0xFF606A85),
                                size: 28.0,
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    12.0, 0.0, 0.0, 0.0),
                                child: Text(
                                  'Invite a Friend',
                                  style: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .override(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF606A85),
                                        fontSize: 16.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.groups,
                                color: Color(0xFF606A85),
                                size: 28.0,
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    12.0, 0.0, 0.0, 0.0),
                                child: Text(
                                  'Feedback',
                                  style: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .override(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF606A85),
                                        fontSize: 16.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              context.pushNamed(
                                SigninWidget.routeName,
                                extra: <String, dynamic>{
                                  kTransitionInfoKey: TransitionInfo(
                                    hasTransition: true,
                                    transitionType: PageTransitionType.fade,
                                    duration: Duration(milliseconds: 1000),
                                  ),
                                },
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_circle_rounded,
                                  color: Color(0xFF606A85),
                                  size: 28.0,
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      12.0, 0.0, 0.0, 0.0),
                                  child: Text(
                                    'Sign out',
                                    style: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .override(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: Color(0xFF606A85),
                                          fontSize: 16.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Divider(
                              height: 12.0,
                              thickness: 2.0,
                              color: Color(0xFFE5E7EB),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 12.0, 0.0, 0.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Container(
                                    width: 50.0,
                                    height: 50.0,
                                    decoration: BoxDecoration(
                                      color: Color(0x4D9489F5),
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(
                                        color: Color(0xFF6F61EF),
                                        width: 2.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(2.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        child: CachedNetworkImage(
                                          fadeInDuration:
                                              Duration(milliseconds: 500),
                                          fadeOutDuration:
                                              Duration(milliseconds: 500),
                                          imageUrl:
                                              'https://images.unsplash.com/photo-1624561172888-ac93c696e10c?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8NjJ8fHVzZXJzfGVufDB8fDB8fA%3D%3D&auto=format&fit=crop&w=900&q=60',
                                          width: 44.0,
                                          height: 44.0,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 0.0, 0.0, 0.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AuthUserStreamWidget(
                                            builder: (context) => GradientText(
                                              currentUserDisplayName,
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyLarge
                                                  .override(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    color: Color(0xFF15161E),
                                                    fontSize: 16.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              colors: [
                                                FlutterFlowTheme.of(context)
                                                    .primary,
                                                FlutterFlowTheme.of(context)
                                                    .secondary
                                              ],
                                              gradientDirection:
                                                  GradientDirection.ltr,
                                              gradientType: GradientType.linear,
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 4.0, 0.0, 0.0),
                                            child: Text(
                                              currentUserEmail,
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .labelMedium
                                                  .override(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    color: Color(0xFF606A85),
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 4.0, 0.0, 0.0),
                                            child: Text(
                                              'View Profile',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodySmall
                                                  .override(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    color: Color(0xFF6F61EF),
                                                    fontSize: 12.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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
          ),
        ),
        body: LottieBackground(
          child: SafeArea(
            top: true,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Header section
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => context.safePop(),
                                child: Icon(
                                  Icons.arrow_back_ios_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            'AI Dream Assistant',
                            style: FlutterFlowTheme.of(context)
                                .titleMedium
                                .override(
                                  fontFamily: 'Figtree',
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(width: 48),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),

                    // Dream input section
                    if (GeminiAPICall.aiGeneratedText(
                                (_model.apiResultssd?.jsonBody ?? '')) ==
                            null ||
                        GeminiAPICall.aiGeneratedText(
                                (_model.apiResultssd?.jsonBody ?? '')) ==
                            '')
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share Your Dream Fragment',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tell us what you remember, and we\'ll help complete your dream story',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 16,
                                  ),
                            ),
                            SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isGenerating
                                      ? Colors.transparent
                                      : Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                                boxShadow: _isGenerating
                                    ? [
                                        BoxShadow(
                                          color: _getGlowColor()
                                              .withOpacity(_getGlowOpacity()),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                        BoxShadow(
                                          color: _getGlowColor().withOpacity(
                                              _getGlowOpacity() * 0.7),
                                          blurRadius: 30,
                                          spreadRadius: 4,
                                        ),
                                        BoxShadow(
                                          color: _getGlowColor().withOpacity(
                                              _getGlowOpacity() * 0.5),
                                          blurRadius: 40,
                                          spreadRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: TextFormField(
                                controller: _model.textController,
                                focusNode: _model.textFieldFocusNode,
                                maxLines: 6,
                                minLines: 2,
                                maxLength: 250,
                                enabled: !_isGenerating,
                                style: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .override(
                                      fontFamily: 'Figtree',
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                decoration: InputDecoration(
                                  hintText: 'Start dreaming here...',
                                  hintStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Figtree',
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 16,
                                      ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.all(20),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.tips_and_updates,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      'Include colors, feelings, and specific events to help AI better understand your dream',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Figtree',
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 14,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                          delay: 200.ms,
                          duration: 600.ms,
                          curve: Curves.easeOut),

                    // Next button
                    if (GeminiAPICall.aiGeneratedText(
                                (_model.apiResultssd?.jsonBody ?? '')) ==
                            null ||
                        GeminiAPICall.aiGeneratedText(
                                (_model.apiResultssd?.jsonBody ?? '')) ==
                            '')
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: Column(
                          children: [
                            // Word count indicator
                            if (!_isGenerating)
                              Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${_model.textController.text.split(' ').where((word) => word.isNotEmpty).length}/10 words minimum',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            fontFamily: 'Figtree',
                                            color: _model.textController.text
                                                        .split(' ')
                                                        .where((word) =>
                                                            word.isNotEmpty)
                                                        .length >=
                                                    10
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.white.withOpacity(0.5),
                                            fontSize: 12,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _model.textController.text
                                                .split(' ')
                                                .where(
                                                    (word) => word.isNotEmpty)
                                                .length >=
                                            10
                                        ? Color(0xFF6448FE)
                                        : Color(0xFF6448FE).withOpacity(0.5),
                                    _model.textController.text
                                                .split(' ')
                                                .where(
                                                    (word) => word.isNotEmpty)
                                                .length >=
                                            10
                                        ? Color(0xFF9747FF)
                                        : Color(0xFF9747FF).withOpacity(0.5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF9747FF).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _model.textController.text
                                                  .split(' ')
                                                  .where(
                                                      (word) => word.isNotEmpty)
                                                  .length >=
                                              10 &&
                                          !_isGenerating
                                      ? () async {
                                          setState(() {
                                            _isLoading = true;
                                            _isGenerating = true;
                                          });

                                          _model.apiResultssd =
                                              await GeminiAPICall.call(
                                            userInputText:
                                                _model.textController.text,
                                          );

                                          // Add delay to show loading animation
                                          await Future.delayed(
                                              Duration(seconds: 5));

                                          if ((_model.apiResultssd?.succeeded ??
                                              true)) {
                                            _model.apiResponse =
                                                valueOrDefault<String>(
                                              GeminiAPICall.aiGeneratedText(
                                                (_model.apiResultssd
                                                        ?.jsonBody ??
                                                    ''),
                                              ),
                                              'unset',
                                            );
                                            safeSetState(() {});
                                          }

                                          setState(() {
                                            _isLoading = false;
                                            _isGenerating = false;
                                          });
                                          safeSetState(() {});
                                        }
                                      : null,
                                  child: Container(
                                    width: double.infinity,
                                    height: 60,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 24),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _isGenerating
                                              ? 'Generating...'
                                              : 'Generate Dream',
                                          style: FlutterFlowTheme.of(context)
                                              .titleSmall
                                              .override(
                                                fontFamily: 'Figtree',
                                                color: _model.textController
                                                                .text
                                                                .split(' ')
                                                                .where((word) =>
                                                                    word
                                                                        .isNotEmpty)
                                                                .length >=
                                                            10 &&
                                                        !_isGenerating
                                                    ? Colors.white
                                                    : Colors.white
                                                        .withOpacity(0.7),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        SizedBox(width: 12),
                                        if (!_isGenerating)
                                          Icon(
                                            Icons.auto_awesome,
                                            color: _model.textController.text
                                                        .split(' ')
                                                        .where((word) =>
                                                            word.isNotEmpty)
                                                        .length >=
                                                    10
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.7),
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                          delay: 400.ms,
                          duration: 600.ms,
                          curve: Curves.easeOut),

                    // Loading Animation
                    if (_isGenerating)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              child: Lottie.asset(
                                'assets/jsons/loading.json',
                                fit: BoxFit.contain,
                                animate: true,
                                frameRate: FrameRate(60),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Hang on...',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    fontFamily: 'Figtree',
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut),

                    // AI Generated Content
                    if (GeminiAPICall.aiGeneratedText(
                                (_model.apiResultssd?.jsonBody ?? '')) !=
                            null &&
                        GeminiAPICall.aiGeneratedText(
                                (_model.apiResultssd?.jsonBody ?? '')) !=
                            '')
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.auto_awesome,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Text(
                                        'AI Generated Dream',
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              fontFamily: 'Figtree',
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 24),
                                  Text(
                                    _model.apiResponse,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Figtree',
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          setState(() {
                                            _isGenerating = false;
                                            _model.apiResponse = '';
                                            _model.apiResultssd = null;
                                          });
                                          safeSetState(() {});
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.refresh,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Try Again',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Figtree',
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF6448FE),
                                          Color(0xFF9747FF),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF9747FF)
                                              .withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          context.pushNamed(
                                            CreatePostWidget.routeName,
                                            queryParameters: {
                                              'generatedText': serializeParam(
                                                _model.apiResponse,
                                                ParamType.String,
                                              ),
                                            }.withoutNulls,
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Use This',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Figtree',
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                        ),
                                              ),
                                            ],
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
                      ).animate().fadeIn(
                          delay: 600.ms,
                          duration: 800.ms,
                          curve: Curves.easeOut),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
