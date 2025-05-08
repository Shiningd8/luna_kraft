import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_button_tabbar.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/utils/serialization_helpers.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'signin_model.dart';
import 'dart:async';
import 'package:luna_kraft/backend/schema/util/record_data.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '/debug_login_helper.dart';
import '/flutter_flow/nav/nav.dart';
import '/auth/auth_redirect_handler.dart';
import '/onboarding/onboarding_manager.dart';
import '/signreg/forgot_password/forgot_password_widget.dart';
export 'signin_model.dart';

class SigninWidget extends StatefulWidget {
  const SigninWidget({super.key});

  static String routeName = 'Signin';
  static String routePath = '/signin';

  @override
  State<SigninWidget> createState() => _SigninWidgetState();
}

class _SigninWidgetState extends State<SigninWidget>
    with TickerProviderStateMixin {
  late SigninModel _model;
  bool _isLoading = false;
  String? _errorMessage;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SigninModel());

    _model.tabBarController = TabController(
      vsync: this,
      length: 2,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));
    _model.emailAddressCreateTextController ??= TextEditingController();
    _model.emailAddressCreateFocusNode ??= FocusNode();

    _model.passwordCreateTextController ??= TextEditingController();
    _model.passwordCreateFocusNode ??= FocusNode();

    _model.passwordCreateConfirmTextController ??= TextEditingController();
    _model.passwordCreateConfirmFocusNode ??= FocusNode();

    _model.emailAddressTextController ??= TextEditingController();
    _model.emailAddressFocusNode ??= FocusNode();

    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeIn,
            delay: 0.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 400.0.ms,
            begin: Offset(0.0, 80.0),
            end: Offset(0.0, 0.0),
          ),
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 150.0.ms,
            duration: 400.0.ms,
            begin: Offset(0.8, 0.8),
            end: Offset(1.0, 1.0),
          ),
        ],
      ),
      'columnOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 300.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 300.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 300.0.ms,
            duration: 400.0.ms,
            begin: Offset(0.0, 20.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'columnOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 300.ms),
          FadeEffect(
            curve: Curves.linear,
            delay: 300.0.ms,
            duration: 400.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 300.0.ms,
            duration: 400.0.ms,
            begin: Offset(0.0, 20.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _signIn() async {
    int attemptCount = 0;
    const maxAttempts = 2;
    bool appCheckBypassEnabled = false; // Start with normal App Check

    // Helper function for the actual sign-in attempt
    Future<BaseAuthUser?> attemptSignIn({bool bypassAppCheck = false}) async {
      try {
        if (bypassAppCheck) {
          print('Attempting sign-in with App Check bypass');
          // First try to refresh the token
          try {
            await FirebaseAppCheck.instance.getToken(true);
            await Future.delayed(Duration(milliseconds: 500));
          } catch (e) {
            print('Token refresh failed (continuing anyway): $e');
          }
        }

        // Standard sign-in logic
        final router = GoRouter.of(context);
        router.prepareAuthEvent();

        return await authManager
            .signInWithEmail(
          context,
          _model.emailAddressTextController.text,
          _model.passwordTextController.text,
        )
            .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception(
              'Sign-in is taking longer than expected. Please check your internet connection and try again.',
            );
          },
        );
      } catch (e) {
        print('Sign in error in attempt $attemptCount: $e');
        if (isAppCheckError(e.toString())) {
          throw Exception('App Check error: ${e.toString()}');
        }
        throw e;
      }
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check network connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Show network error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.signal_wifi_off, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Network connection issue detected. Please check your internet connection and try again.',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Figtree',
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _signIn(); // Retry login
              },
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Validate credentials before attempting sign in
      if (_model.emailAddressTextController.text.isEmpty ||
          _model.passwordTextController.text.isEmpty) {
        throw Exception('Please enter both email and password.');
      }

      // Try normal sign-in first
      BaseAuthUser? user;
      while (user == null && attemptCount < maxAttempts) {
        try {
          attemptCount++;
          // Try the sign-in with current App Check setting
          user = await attemptSignIn(bypassAppCheck: appCheckBypassEnabled);
        } catch (e) {
          final errorMsg = e.toString();
          print('Sign in attempt $attemptCount failed: $errorMsg');

          if (attemptCount < maxAttempts && isAppCheckError(errorMsg)) {
            // If it's an App Check error and we haven't tried bypassing yet
            appCheckBypassEnabled = true;
            print('Enabling App Check bypass for next attempt');
            continue;
          }

          // If we've exhausted attempts or it's not an App Check error, rethrow
          if (attemptCount >= maxAttempts || !isAppCheckError(errorMsg)) {
            throw e;
          }
        }
      }

      // Handle null user case - this means authentication failed
      if (user == null) {
        throw Exception('Failed to sign in. Please check your credentials.');
      }

      // Check if 2FA is enabled for this user
      final is2FAEnabled = await AuthUtil.isTwoFactorEnabled();
      if (is2FAEnabled) {
        if (mounted) {
          context.pushNamed(
            'TwoFactorVerification',
            extra: <String, dynamic>{
              'email': user.email,
              kTransitionInfoKey: TransitionInfo(
                hasTransition: true,
                transitionType: PageTransitionType.fade,
                duration: Duration(milliseconds: 250),
              ),
            },
          );
        }
      } else {
        // If no 2FA, handle redirection to ensure onboarding is completed
        if (mounted) {
          await AuthRedirectHandler.navigateAfterAuth(context);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        print('Final sign in error: $errorMsg');

        // Provide more specific error message for "Too many attempts"
        if (errorMsg.contains('too many attempts') ||
            errorMsg.contains('Too many attempts')) {
          errorMsg =
              'Too many login attempts detected. Please wait a moment and try again later.';
        }
        // For App Check errors, provide more detailed explanation and solutions
        else if (errorMsg.contains('App attestation failed') ||
            errorMsg.contains('App Check') ||
            errorMsg.contains('403') ||
            errorMsg.contains('AppCheckProvider') ||
            errorMsg.contains('token') ||
            errorMsg.contains('verification failed')) {
          // Try to automatically retry once with relaxed App Check
          try {
            print('Attempting authentication retry with relaxed App Check...');
            setState(() {
              _errorMessage = 'Retrying authentication...';
            });

            final user = await retryAuthWithRelaxedAppCheck(
              context: context,
              email: _model.emailAddressTextController.text,
              password: _model.passwordTextController.text,
            );

            if (user != null) {
              print('Retry authentication succeeded!');

              // Check if 2FA is enabled for this user
              final is2FAEnabled = await AuthUtil.isTwoFactorEnabled();
              if (is2FAEnabled) {
                if (mounted) {
                  context.pushNamed(
                    'TwoFactorVerification',
                    extra: <String, dynamic>{
                      'email': user.email,
                      kTransitionInfoKey: TransitionInfo(
                        hasTransition: true,
                        transitionType: PageTransitionType.fade,
                        duration: Duration(milliseconds: 250),
                      ),
                    },
                  );
                }
              } else {
                // If no 2FA, directly go to home page
                if (mounted) {
                  context.pushNamedAuth(
                    HomePageWidget.routeName,
                    context.mounted,
                    extra: <String, dynamic>{
                      kTransitionInfoKey: TransitionInfo(
                        hasTransition: true,
                        transitionType: PageTransitionType.fade,
                        duration: Duration(milliseconds: 1000),
                      ),
                    },
                  );
                }
              }
              return;
            } else {
              print('Retry authentication failed, showing error dialog');
            }
          } catch (retryErr) {
            print('Error during authentication retry: $retryErr');
          }

          // Show an alert dialog with more detailed instructions
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Authentication Error'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('There was an error verifying your app:'),
                      SizedBox(height: 10),
                      Text('• Please check your internet connection'),
                      Text('• Make sure you have the latest app version'),
                      Text('• Your device time might be incorrect'),
                      Text('• Try restarting the app'),
                      SizedBox(height: 10),
                      Text(
                        'Technical details: $errorMsg',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Try Again'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _signIn(); // Retry login
                    },
                  ),
                ],
              );
            },
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        // For network errors, suggest checking connection with a retry button
        else if (errorMsg.contains('network') ||
            errorMsg.contains('connection')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.signal_wifi_off, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Network connection issue detected. Please check your internet connection and try again.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 10),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  _signIn(); // Retry login
                },
              ),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        // For timeout errors, suggest trying again
        else if (errorMsg.contains('timed out') ||
            errorMsg.contains('timeout')) {
          errorMsg = 'Login request timed out. Please try again.';
        }
        // For invalid credentials
        else if (errorMsg.contains('password') ||
            errorMsg.contains('user-not-found') ||
            errorMsg.contains('invalid-credential') ||
            errorMsg.contains('INVALID_LOGIN_CREDENTIALS')) {
          errorMsg =
              'Invalid email or password. Please check your credentials and try again.';
        }

        setState(() {
          _errorMessage = errorMsg;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createAccount() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Disable automatic auth change navigation BEFORE creating account
      // This prevents auto-navigation to home page when auth state changes
      AppStateNotifier.instance.updateNotifyOnAuthChange(false);

      // Check network connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Show persistent error banner with retry option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.signal_wifi_off, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Network connection issue detected. Please check your internet connection and try again.',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontFamily: 'Figtree',
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _createAccount(); // Retry account creation
              },
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Pre-validate form fields
      if (_model.emailAddressCreateTextController.text.isEmpty ||
          _model.passwordCreateTextController.text.isEmpty) {
        throw Exception('Please enter both email and password.');
      }

      if (_model.passwordCreateTextController.text !=
          _model.passwordCreateConfirmTextController.text) {
        throw Exception('Passwords do not match.');
      }

      // Increase timeout to 30 seconds for account creation
      final BaseAuthUser? user = await authManager
          .createAccountWithEmail(
        context,
        _model.emailAddressCreateTextController.text,
        _model.passwordCreateTextController.text,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'Account creation is taking longer than expected. Please check your internet connection and try again.',
          );
        },
      );

      if (user == null) {
        throw Exception('Failed to create account.');
      }

      // Reset any onboarding or profile setup flags
      await OnboardingManager.resetOnboardingStatus();

      // Check and ensure this user is truly logged in before redirecting
      if (loggedIn && currentUser != null) {
        // Use direct navigation to the profile input page to avoid any redirection issues
        if (mounted) {
          print('Account created successfully - navigating to profile input');

          // Force the navigation to the profile input page
          context.goNamed(
            ProfileInputWidget.routeName,
            extra: <String, dynamic>{
              kTransitionInfoKey: TransitionInfo(
                hasTransition: true,
                transitionType: PageTransitionType.fade,
                duration: Duration(milliseconds: 500),
              ),
            },
          );
        }
      } else {
        throw Exception(
            'Account was created but user is not logged in. Please try signing in manually.');
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();

        // Provide more specific error message for "Too many attempts"
        if (errorMsg.contains('too many attempts') ||
            errorMsg.contains('Too many attempts')) {
          errorMsg =
              'Too many account creation attempts detected. Please wait a moment and try again later.';
        }
        // For App Check errors, provide a more helpful message
        else if (errorMsg.contains('App attestation failed') ||
            errorMsg.contains('App Check') ||
            errorMsg.contains('403') ||
            errorMsg.contains('AppCheckProvider')) {
          errorMsg =
              'Authentication error. Please try again or restart the app.';
        }
        // For network errors, suggest checking connection with a retry button
        else if (errorMsg.contains('network') ||
            errorMsg.contains('connection')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.signal_wifi_off, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Network connection issue detected. Please check your internet connection and try again.',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Figtree',
                            color: Colors.white,
                          ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 10),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  _createAccount(); // Retry account creation
                },
              ),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        // For timeout errors, suggest trying again
        else if (errorMsg.contains('timed out') ||
            errorMsg.contains('timeout')) {
          errorMsg = 'Account creation request timed out. Please try again.';
        }
        // For email already in use errors
        else if (errorMsg.contains('email-already-in-use') ||
            errorMsg.contains('already in use')) {
          errorMsg =
              'This email is already registered. Please use a different email or try signing in.';
        }

        setState(() {
          _errorMessage = errorMsg;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: SafeArea(
          top: true,
          child: Align(
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Stack(
              children: [
                Lottie.asset(
                  'assets/jsons/Animation_-_1739171323302.json',
                  width: 500.0,
                  height: 1000.0,
                  fit: BoxFit.none,
                  animate: true,
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        0.0,
                        32.0,
                        0.0,
                        16.0,
                      ),
                      child: Text(
                        'LunaKraft.',
                        style: FlutterFlowTheme.of(
                          context,
                        ).displaySmall.override(
                              fontFamily: 'Mukta',
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                            0.0,
                            12.0,
                            0.0,
                            12.0,
                          ),
                          child: Container(
                            width: double.infinity,
                            height: MediaQuery.sizeOf(context).height * 0.8,
                            constraints: BoxConstraints(maxWidth: 530.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                0.0,
                                16.0,
                                0.0,
                                0.0,
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: TabBarView(
                                      controller: _model.tabBarController,
                                      children: [
                                        Align(
                                          alignment: AlignmentDirectional(
                                            0.0,
                                            -1.0,
                                          ),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                              24.0,
                                              16.0,
                                              24.0,
                                              0.0,
                                            ),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (responsiveVisibility(
                                                    context: context,
                                                    phone: false,
                                                    tablet: false,
                                                  ))
                                                    Container(
                                                      width: 230.0,
                                                      height: 16.0,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                          context,
                                                        ).secondaryBackground,
                                                      ),
                                                    ),
                                                  Text(
                                                    'Create Account',
                                                    textAlign: TextAlign.start,
                                                    style: FlutterFlowTheme.of(
                                                      context,
                                                    ).headlineMedium.override(
                                                          fontFamily: 'Outfit',
                                                          letterSpacing: 0.0,
                                                        ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                      0.0,
                                                      4.0,
                                                      0.0,
                                                      24.0,
                                                    ),
                                                    child: Text(
                                                      'Let\'s get started by filling out the form below.',
                                                      textAlign:
                                                          TextAlign.start,
                                                      style:
                                                          FlutterFlowTheme.of(
                                                        context,
                                                      ).labelMedium.override(
                                                                fontFamily:
                                                                    'Figtree',
                                                                letterSpacing:
                                                                    0.0,
                                                              ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                      0.0,
                                                      0.0,
                                                      0.0,
                                                      16.0,
                                                    ),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: TextFormField(
                                                        controller: _model
                                                            .emailAddressCreateTextController,
                                                        focusNode: _model
                                                            .emailAddressCreateFocusNode,
                                                        autofocus: true,
                                                        autofillHints: [
                                                          AutofillHints.email,
                                                        ],
                                                        obscureText: false,
                                                        decoration:
                                                            InputDecoration(
                                                          labelText: 'Email',
                                                          labelStyle:
                                                              FlutterFlowTheme
                                                                      .of(
                                                            context,
                                                          ).labelLarge.override(
                                                                    fontFamily:
                                                                        'Figtree',
                                                                    letterSpacing:
                                                                        0.0,
                                                                  ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).alternate,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).primary,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          errorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).error,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          focusedErrorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).error,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          filled: true,
                                                          fillColor:
                                                              FlutterFlowTheme
                                                                  .of(
                                                            context,
                                                          ).secondaryBackground,
                                                          contentPadding:
                                                              EdgeInsets.all(
                                                            24.0,
                                                          ),
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                          context,
                                                        ).bodyLarge.override(
                                                                  fontFamily:
                                                                      'Figtree',
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                        keyboardType:
                                                            TextInputType
                                                                .emailAddress,
                                                        cursorColor:
                                                            FlutterFlowTheme.of(
                                                          context,
                                                        ).primary,
                                                        validator: _model
                                                            .emailAddressCreateTextControllerValidator
                                                            .asValidator(
                                                          context,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                      0.0,
                                                      0.0,
                                                      0.0,
                                                      16.0,
                                                    ),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: TextFormField(
                                                        controller: _model
                                                            .passwordCreateTextController,
                                                        focusNode: _model
                                                            .passwordCreateFocusNode,
                                                        autofocus: true,
                                                        autofillHints: [
                                                          AutofillHints
                                                              .password,
                                                        ],
                                                        obscureText: !_model
                                                            .passwordCreateVisibility,
                                                        decoration:
                                                            InputDecoration(
                                                          labelText: 'Password',
                                                          labelStyle:
                                                              FlutterFlowTheme
                                                                      .of(
                                                            context,
                                                          ).labelLarge.override(
                                                                    fontFamily:
                                                                        'Figtree',
                                                                    letterSpacing:
                                                                        0.0,
                                                                  ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).alternate,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).primary,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          errorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).error,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          focusedErrorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).error,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          filled: true,
                                                          fillColor:
                                                              FlutterFlowTheme
                                                                  .of(
                                                            context,
                                                          ).secondaryBackground,
                                                          contentPadding:
                                                              EdgeInsets.all(
                                                            24.0,
                                                          ),
                                                          suffixIcon: InkWell(
                                                            onTap: () =>
                                                                safeSetState(
                                                              () => _model
                                                                      .passwordCreateVisibility =
                                                                  !_model
                                                                      .passwordCreateVisibility,
                                                            ),
                                                            focusNode:
                                                                FocusNode(
                                                              skipTraversal:
                                                                  true,
                                                            ),
                                                            child: Icon(
                                                              _model.passwordCreateVisibility
                                                                  ? Icons
                                                                      .visibility_outlined
                                                                  : Icons
                                                                      .visibility_off_outlined,
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).secondaryText,
                                                              size: 24.0,
                                                            ),
                                                          ),
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                          context,
                                                        ).bodyLarge.override(
                                                                  fontFamily:
                                                                      'Figtree',
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                        cursorColor:
                                                            FlutterFlowTheme.of(
                                                          context,
                                                        ).primary,
                                                        validator: _model
                                                            .passwordCreateTextControllerValidator
                                                            .asValidator(
                                                          context,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                      0.0,
                                                      0.0,
                                                      0.0,
                                                      16.0,
                                                    ),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: TextFormField(
                                                        controller: _model
                                                            .passwordCreateConfirmTextController,
                                                        focusNode: _model
                                                            .passwordCreateConfirmFocusNode,
                                                        autofocus: true,
                                                        autofillHints: [
                                                          AutofillHints
                                                              .password,
                                                        ],
                                                        obscureText: !_model
                                                            .passwordCreateConfirmVisibility,
                                                        decoration:
                                                            InputDecoration(
                                                          labelText: 'Password',
                                                          labelStyle:
                                                              FlutterFlowTheme
                                                                      .of(
                                                            context,
                                                          ).labelLarge.override(
                                                                    fontFamily:
                                                                        'Figtree',
                                                                    letterSpacing:
                                                                        0.0,
                                                                  ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).alternate,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).primary,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          errorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).error,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          focusedErrorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).error,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          filled: true,
                                                          fillColor:
                                                              FlutterFlowTheme
                                                                  .of(
                                                            context,
                                                          ).secondaryBackground,
                                                          contentPadding:
                                                              EdgeInsets.all(
                                                            24.0,
                                                          ),
                                                          suffixIcon: InkWell(
                                                            onTap: () =>
                                                                safeSetState(
                                                              () => _model
                                                                      .passwordCreateConfirmVisibility =
                                                                  !_model
                                                                      .passwordCreateConfirmVisibility,
                                                            ),
                                                            focusNode:
                                                                FocusNode(
                                                              skipTraversal:
                                                                  true,
                                                            ),
                                                            child: Icon(
                                                              _model.passwordCreateConfirmVisibility
                                                                  ? Icons
                                                                      .visibility_outlined
                                                                  : Icons
                                                                      .visibility_off_outlined,
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).secondaryText,
                                                              size: 24.0,
                                                            ),
                                                          ),
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                          context,
                                                        ).bodyLarge.override(
                                                                  fontFamily:
                                                                      'Figtree',
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                        cursorColor:
                                                            FlutterFlowTheme.of(
                                                          context,
                                                        ).primary,
                                                        validator: _model
                                                            .passwordCreateConfirmTextControllerValidator
                                                            .asValidator(
                                                          context,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                      0.0,
                                                      0.0,
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                        0.0,
                                                        0.0,
                                                        0.0,
                                                        16.0,
                                                      ),
                                                      child: FFButtonWidget(
                                                        onPressed: _isLoading
                                                            ? null
                                                            : _createAccount,
                                                        text: _isLoading
                                                            ? 'Creating account...'
                                                            : 'Get Started',
                                                        options:
                                                            FFButtonOptions(
                                                          width: 230.0,
                                                          height: 52.0,
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                            0.0,
                                                            0.0,
                                                            0.0,
                                                            0.0,
                                                          ),
                                                          iconPadding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                            0.0,
                                                            0.0,
                                                            0.0,
                                                            0.0,
                                                          ),
                                                          color:
                                                              FlutterFlowTheme
                                                                  .of(
                                                            context,
                                                          ).primary,
                                                          textStyle:
                                                              FlutterFlowTheme
                                                                      .of(
                                                            context,
                                                          ).titleSmall.override(
                                                                    fontFamily:
                                                                        'Figtree',
                                                                    color: Colors
                                                                        .white,
                                                                    letterSpacing:
                                                                        0.0,
                                                                  ),
                                                          elevation: 3.0,
                                                          borderSide:
                                                              BorderSide(
                                                            color: Colors
                                                                .transparent,
                                                            width: 1.0,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            12.0,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Align(
                                                        alignment:
                                                            AlignmentDirectional(
                                                          0.0,
                                                          0.0,
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                            16.0,
                                                            0.0,
                                                            16.0,
                                                            24.0,
                                                          ),
                                                          child: Text(
                                                            'Or sign up with',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style:
                                                                FlutterFlowTheme
                                                                        .of(
                                                              context,
                                                            )
                                                                    .labelMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'Figtree',
                                                                      color:
                                                                          Color(
                                                                        0xFFFFFEFE,
                                                                      ),
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                          ),
                                                        ),
                                                      ),
                                                      Align(
                                                        alignment:
                                                            AlignmentDirectional(
                                                          0.0,
                                                          0.0,
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                            0.0,
                                                            0.0,
                                                            0.0,
                                                            16.0,
                                                          ),
                                                          child: Wrap(
                                                            spacing: 16.0,
                                                            runSpacing: 0.0,
                                                            alignment:
                                                                WrapAlignment
                                                                    .center,
                                                            crossAxisAlignment:
                                                                WrapCrossAlignment
                                                                    .center,
                                                            direction:
                                                                Axis.horizontal,
                                                            runAlignment:
                                                                WrapAlignment
                                                                    .center,
                                                            verticalDirection:
                                                                VerticalDirection
                                                                    .down,
                                                            clipBehavior:
                                                                Clip.none,
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  16.0,
                                                                ),
                                                                child:
                                                                    FFButtonWidget(
                                                                  onPressed:
                                                                      () async {
                                                                    // Disable automatic auth change navigation to prevent interruption
                                                                    AppStateNotifier
                                                                        .instance
                                                                        .updateNotifyOnAuthChange(
                                                                      false,
                                                                    );

                                                                    GoRouter.of(
                                                                      context,
                                                                    ).prepareAuthEvent();
                                                                    final user =
                                                                        await authManager
                                                                            .signInWithGoogle(
                                                                      context,
                                                                    );
                                                                    if (user ==
                                                                        null) {
                                                                      return;
                                                                    }

                                                                    // Check if 2FA is enabled for this user
                                                                    final is2FAEnabled =
                                                                        await AuthUtil
                                                                            .isTwoFactorEnabled();

                                                                    if (mounted) {
                                                                      if (is2FAEnabled) {
                                                                        // If 2FA is enabled, redirect to the verification page
                                                                        context
                                                                            .pushNamed(
                                                                          'TwoFactorVerification',
                                                                          extra: <String,
                                                                              dynamic>{
                                                                            'email':
                                                                                user.email,
                                                                            kTransitionInfoKey:
                                                                                TransitionInfo(
                                                                              hasTransition: true,
                                                                              transitionType: PageTransitionType.fade,
                                                                              duration: Duration(
                                                                                milliseconds: 250,
                                                                              ),
                                                                            ),
                                                                          },
                                                                        );
                                                                      } else {
                                                                        // Handle proper navigation flow through profile/onboarding if needed
                                                                        await AuthRedirectHandler
                                                                            .navigateAfterAuth(
                                                                          context,
                                                                        );
                                                                      }
                                                                    }
                                                                  },
                                                                  text:
                                                                      'Continue with Google',
                                                                  icon: FaIcon(
                                                                    FontAwesomeIcons
                                                                        .google,
                                                                    size: 20.0,
                                                                  ),
                                                                  options:
                                                                      FFButtonOptions(
                                                                    width:
                                                                        230.0,
                                                                    height:
                                                                        44.0,
                                                                    padding:
                                                                        EdgeInsetsDirectional
                                                                            .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                    ),
                                                                    iconPadding:
                                                                        EdgeInsetsDirectional
                                                                            .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                    ),
                                                                    color:
                                                                        FlutterFlowTheme
                                                                            .of(
                                                                      context,
                                                                    ).secondaryBackground,
                                                                    textStyle: FlutterFlowTheme
                                                                            .of(
                                                                      context,
                                                                    )
                                                                        .bodyMedium
                                                                        .override(
                                                                          fontFamily:
                                                                              'Figtree',
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                    elevation:
                                                                        0.0,
                                                                    borderSide:
                                                                        BorderSide(
                                                                      color:
                                                                          FlutterFlowTheme
                                                                              .of(
                                                                        context,
                                                                      ).alternate,
                                                                      width:
                                                                          2.0,
                                                                    ),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(
                                                                      12.0,
                                                                    ),
                                                                    hoverColor:
                                                                        FlutterFlowTheme
                                                                            .of(
                                                                      context,
                                                                    ).primaryBackground,
                                                                  ),
                                                                ),
                                                              ),
                                                              isAndroid
                                                                  ? Container()
                                                                  : Padding(
                                                                      padding:
                                                                          EdgeInsetsDirectional
                                                                              .fromSTEB(
                                                                        0.0,
                                                                        0.0,
                                                                        0.0,
                                                                        16.0,
                                                                      ),
                                                                      child:
                                                                          FFButtonWidget(
                                                                        onPressed:
                                                                            () async {
                                                                          // Disable automatic auth change navigation
                                                                          AppStateNotifier
                                                                              .instance
                                                                              .updateNotifyOnAuthChange(
                                                                            false,
                                                                          );

                                                                          GoRouter
                                                                              .of(
                                                                            context,
                                                                          ).prepareAuthEvent();
                                                                          final user =
                                                                              await authManager.signInWithApple(
                                                                            context,
                                                                          );
                                                                          if (user ==
                                                                              null) {
                                                                            return;
                                                                          }

                                                                          // Check if 2FA is enabled
                                                                          final is2FAEnabled =
                                                                              await AuthUtil.isTwoFactorEnabled();

                                                                          if (mounted) {
                                                                            if (is2FAEnabled) {
                                                                              // If 2FA is enabled, redirect to verification
                                                                              context.pushNamed(
                                                                                'TwoFactorVerification',
                                                                                extra: <String, dynamic>{
                                                                                  'email': user.email,
                                                                                  kTransitionInfoKey: TransitionInfo(
                                                                                    hasTransition: true,
                                                                                    transitionType: PageTransitionType.fade,
                                                                                    duration: Duration(
                                                                                      milliseconds: 250,
                                                                                    ),
                                                                                  ),
                                                                                },
                                                                              );
                                                                            } else {
                                                                              // Handle proper navigation flow
                                                                              await AuthRedirectHandler.navigateAfterAuth(
                                                                                context,
                                                                              );
                                                                            }
                                                                          }
                                                                        },
                                                                        text:
                                                                            'Continue with Apple',
                                                                        icon:
                                                                            FaIcon(
                                                                          FontAwesomeIcons
                                                                              .apple,
                                                                          size:
                                                                              20.0,
                                                                        ),
                                                                        options:
                                                                            FFButtonOptions(
                                                                          width:
                                                                              230.0,
                                                                          height:
                                                                              44.0,
                                                                          padding:
                                                                              EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                          ),
                                                                          iconPadding:
                                                                              EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                          ),
                                                                          color:
                                                                              FlutterFlowTheme.of(
                                                                            context,
                                                                          ).secondaryBackground,
                                                                          textStyle: FlutterFlowTheme.of(
                                                                            context,
                                                                          ).bodyMedium.override(
                                                                                fontFamily: 'Figtree',
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                          elevation:
                                                                              0.0,
                                                                          borderSide:
                                                                              BorderSide(
                                                                            color:
                                                                                FlutterFlowTheme.of(
                                                                              context,
                                                                            ).alternate,
                                                                            width:
                                                                                2.0,
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                            12.0,
                                                                          ),
                                                                          hoverColor:
                                                                              FlutterFlowTheme.of(
                                                                            context,
                                                                          ).primaryBackground,
                                                                        ),
                                                                      ),
                                                                    ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ).animateOnPageLoad(
                                              animationsMap[
                                                  'columnOnPageLoadAnimation1']!,
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: AlignmentDirectional(
                                            0.0,
                                            -1.0,
                                          ),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                              24.0,
                                              16.0,
                                              24.0,
                                              0.0,
                                            ),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (responsiveVisibility(
                                                    context: context,
                                                    phone: false,
                                                    tablet: false,
                                                  ))
                                                    Container(
                                                      width: 230.0,
                                                      height: 16.0,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                          context,
                                                        ).secondaryBackground,
                                                      ),
                                                    ),
                                                  Text(
                                                    'Welcome Back',
                                                    textAlign: TextAlign.start,
                                                    style: FlutterFlowTheme.of(
                                                      context,
                                                    ).headlineMedium.override(
                                                          fontFamily: 'Outfit',
                                                          letterSpacing: 0.0,
                                                        ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                      0.0,
                                                      4.0,
                                                      0.0,
                                                      24.0,
                                                    ),
                                                    child: Text(
                                                      'Fill out the information below in order to access your account.',
                                                      textAlign:
                                                          TextAlign.start,
                                                      style:
                                                          FlutterFlowTheme.of(
                                                        context,
                                                      ).labelMedium.override(
                                                                fontFamily:
                                                                    'Figtree',
                                                                letterSpacing:
                                                                    0.0,
                                                              ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                      0.0,
                                                      0.0,
                                                      0.0,
                                                      16.0,
                                                    ),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: TextFormField(
                                                        controller: _model
                                                            .emailAddressTextController,
                                                        focusNode: _model
                                                            .emailAddressFocusNode,
                                                        autofocus: true,
                                                        autofillHints: [
                                                          AutofillHints.email,
                                                        ],
                                                        obscureText: false,
                                                        decoration:
                                                            InputDecoration(
                                                          labelText: 'Email',
                                                          labelStyle:
                                                              FlutterFlowTheme
                                                                      .of(
                                                            context,
                                                          ).labelLarge.override(
                                                                    fontFamily:
                                                                        'Figtree',
                                                                    letterSpacing:
                                                                        0.0,
                                                                  ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).alternate,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).primary,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          errorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).alternate,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          focusedErrorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).alternate,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          filled: true,
                                                          fillColor:
                                                              FlutterFlowTheme
                                                                  .of(
                                                            context,
                                                          ).secondaryBackground,
                                                          contentPadding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                            24.0,
                                                            24.0,
                                                            0.0,
                                                            24.0,
                                                          ),
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                          context,
                                                        ).bodyLarge.override(
                                                                  fontFamily:
                                                                      'Figtree',
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                        keyboardType:
                                                            TextInputType
                                                                .emailAddress,
                                                        cursorColor:
                                                            FlutterFlowTheme.of(
                                                          context,
                                                        ).primary,
                                                        validator: _model
                                                            .emailAddressTextControllerValidator
                                                            .asValidator(
                                                          context,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                      0.0,
                                                      0.0,
                                                      0.0,
                                                      16.0,
                                                    ),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: TextFormField(
                                                        controller: _model
                                                            .passwordTextController,
                                                        focusNode: _model
                                                            .passwordFocusNode,
                                                        autofocus: true,
                                                        autofillHints: [
                                                          AutofillHints
                                                              .password,
                                                        ],
                                                        obscureText: !_model
                                                            .passwordVisibility,
                                                        decoration:
                                                            InputDecoration(
                                                          labelText: 'Password',
                                                          labelStyle:
                                                              FlutterFlowTheme
                                                                      .of(
                                                            context,
                                                          ).labelLarge.override(
                                                                    fontFamily:
                                                                        'Figtree',
                                                                    letterSpacing:
                                                                        0.0,
                                                                  ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).alternate,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).primary,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          errorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).error,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          focusedErrorBorder:
                                                              OutlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).error,
                                                              width: 2.0,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              12.0,
                                                            ),
                                                          ),
                                                          filled: true,
                                                          fillColor:
                                                              FlutterFlowTheme
                                                                  .of(
                                                            context,
                                                          ).secondaryBackground,
                                                          contentPadding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                            24.0,
                                                            24.0,
                                                            0.0,
                                                            24.0,
                                                          ),
                                                          suffixIcon: InkWell(
                                                            onTap: () =>
                                                                safeSetState(
                                                              () => _model
                                                                      .passwordVisibility =
                                                                  !_model
                                                                      .passwordVisibility,
                                                            ),
                                                            focusNode:
                                                                FocusNode(
                                                              skipTraversal:
                                                                  true,
                                                            ),
                                                            child: Icon(
                                                              _model.passwordVisibility
                                                                  ? Icons
                                                                      .visibility_outlined
                                                                  : Icons
                                                                      .visibility_off_outlined,
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).secondaryText,
                                                              size: 24.0,
                                                            ),
                                                          ),
                                                        ),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                          context,
                                                        ).bodyLarge.override(
                                                                  fontFamily:
                                                                      'Figtree',
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                        cursorColor:
                                                            FlutterFlowTheme.of(
                                                          context,
                                                        ).primary,
                                                        validator: _model
                                                            .passwordTextControllerValidator
                                                            .asValidator(
                                                          context,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            1.0, 0.0),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  16.0),
                                                      child: InkWell(
                                                        onTap: () async {
                                                          context.pushNamed(
                                                            ForgotPasswordWidget
                                                                .routeName,
                                                            extra: <String,
                                                                dynamic>{
                                                              kTransitionInfoKey:
                                                                  TransitionInfo(
                                                                hasTransition:
                                                                    true,
                                                                transitionType:
                                                                    PageTransitionType
                                                                        .fade,
                                                                duration: Duration(
                                                                    milliseconds:
                                                                        250),
                                                              ),
                                                            },
                                                          );
                                                        },
                                                        child: Text(
                                                          'Forgot Password?',
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .labelMedium
                                                              .override(
                                                                fontFamily:
                                                                    'Figtree',
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                      0.0,
                                                      0.0,
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                        0.0,
                                                        0.0,
                                                        0.0,
                                                        16.0,
                                                      ),
                                                      child: FFButtonWidget(
                                                        onPressed: _isLoading
                                                            ? null
                                                            : _signIn,
                                                        text: _isLoading
                                                            ? 'Signing in...'
                                                            : 'Sign In',
                                                        options:
                                                            FFButtonOptions(
                                                          width: 230.0,
                                                          height: 52.0,
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                            0.0,
                                                            0.0,
                                                            0.0,
                                                            0.0,
                                                          ),
                                                          iconPadding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                            0.0,
                                                            0.0,
                                                            0.0,
                                                            0.0,
                                                          ),
                                                          color:
                                                              FlutterFlowTheme
                                                                  .of(
                                                            context,
                                                          ).primary,
                                                          textStyle:
                                                              FlutterFlowTheme
                                                                      .of(
                                                            context,
                                                          ).titleSmall.override(
                                                                    fontFamily:
                                                                        'Figtree',
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        16.0,
                                                                    letterSpacing:
                                                                        0.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                          elevation: 0.0,
                                                          borderSide:
                                                              BorderSide(
                                                            color: Colors
                                                                .transparent,
                                                            width: 1.0,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            50.0,
                                                          ),
                                                          disabledColor:
                                                              FlutterFlowTheme
                                                                      .of(
                                                            context,
                                                          )
                                                                  .secondaryText
                                                                  .withOpacity(
                                                                    0.5,
                                                                  ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                      0.0,
                                                      0.0,
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                        16.0,
                                                        0.0,
                                                        16.0,
                                                        24.0,
                                                      ),
                                                      child: Text(
                                                        'Or sign in with',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            FlutterFlowTheme.of(
                                                          context,
                                                        ).labelMedium.override(
                                                                  fontFamily:
                                                                      'Figtree',
                                                                  color: Colors
                                                                      .white,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                      0.0,
                                                      0.0,
                                                    ),
                                                    child: Wrap(
                                                      spacing: 16.0,
                                                      runSpacing: 0.0,
                                                      alignment:
                                                          WrapAlignment.center,
                                                      crossAxisAlignment:
                                                          WrapCrossAlignment
                                                              .center,
                                                      direction:
                                                          Axis.horizontal,
                                                      runAlignment:
                                                          WrapAlignment.center,
                                                      verticalDirection:
                                                          VerticalDirection
                                                              .down,
                                                      clipBehavior: Clip.none,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                            0.0,
                                                            0.0,
                                                            0.0,
                                                            16.0,
                                                          ),
                                                          child: FFButtonWidget(
                                                            onPressed:
                                                                () async {
                                                              GoRouter.of(
                                                                context,
                                                              ).prepareAuthEvent();
                                                              final user =
                                                                  await authManager
                                                                      .signInWithGoogle(
                                                                context,
                                                              );
                                                              if (user ==
                                                                  null) {
                                                                return;
                                                              }

                                                              // Check if 2FA is enabled for this user
                                                              final is2FAEnabled =
                                                                  await AuthUtil
                                                                      .isTwoFactorEnabled();

                                                              if (mounted) {
                                                                if (is2FAEnabled) {
                                                                  // If 2FA is enabled, redirect to the verification page
                                                                  context
                                                                      .pushNamed(
                                                                    'TwoFactorVerification',
                                                                    extra: <String,
                                                                        dynamic>{
                                                                      'email': user
                                                                          .email,
                                                                      kTransitionInfoKey:
                                                                          TransitionInfo(
                                                                        hasTransition:
                                                                            true,
                                                                        transitionType:
                                                                            PageTransitionType.fade,
                                                                        duration:
                                                                            Duration(
                                                                          milliseconds:
                                                                              250,
                                                                        ),
                                                                      ),
                                                                    },
                                                                  );
                                                                } else {
                                                                  // Handle proper navigation flow through profile/onboarding if needed
                                                                  await AuthRedirectHandler
                                                                      .navigateAfterAuth(
                                                                    context,
                                                                  );
                                                                }
                                                              }
                                                            },
                                                            text:
                                                                'Continue with Google',
                                                            icon: FaIcon(
                                                              FontAwesomeIcons
                                                                  .google,
                                                              size: 20.0,
                                                            ),
                                                            options:
                                                                FFButtonOptions(
                                                              width: 230.0,
                                                              height: 44.0,
                                                              padding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                0.0,
                                                                0.0,
                                                                0.0,
                                                                0.0,
                                                              ),
                                                              iconPadding:
                                                                  EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                0.0,
                                                                0.0,
                                                                0.0,
                                                                0.0,
                                                              ),
                                                              color:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).secondaryBackground,
                                                              textStyle:
                                                                  FlutterFlowTheme
                                                                          .of(
                                                                context,
                                                              )
                                                                      .bodyMedium
                                                                      .override(
                                                                        fontFamily:
                                                                            'Figtree',
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                              elevation: 0.0,
                                                              borderSide:
                                                                  BorderSide(
                                                                color:
                                                                    FlutterFlowTheme
                                                                        .of(
                                                                  context,
                                                                ).alternate,
                                                                width: 2.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                12.0,
                                                              ),
                                                              hoverColor:
                                                                  FlutterFlowTheme
                                                                      .of(
                                                                context,
                                                              ).primaryBackground,
                                                            ),
                                                          ),
                                                        ),
                                                        isAndroid
                                                            ? Container()
                                                            : Padding(
                                                                padding:
                                                                    EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  16.0,
                                                                ),
                                                                child:
                                                                    FFButtonWidget(
                                                                  onPressed:
                                                                      () async {
                                                                    // Disable automatic auth change navigation
                                                                    AppStateNotifier
                                                                        .instance
                                                                        .updateNotifyOnAuthChange(
                                                                      false,
                                                                    );

                                                                    GoRouter.of(
                                                                      context,
                                                                    ).prepareAuthEvent();
                                                                    final user =
                                                                        await authManager
                                                                            .signInWithApple(
                                                                      context,
                                                                    );
                                                                    if (user ==
                                                                        null) {
                                                                      return;
                                                                    }

                                                                    // Check if 2FA is enabled
                                                                    final is2FAEnabled =
                                                                        await AuthUtil
                                                                            .isTwoFactorEnabled();

                                                                    if (mounted) {
                                                                      if (is2FAEnabled) {
                                                                        // If 2FA is enabled, redirect to verification
                                                                        context
                                                                            .pushNamed(
                                                                          'TwoFactorVerification',
                                                                          extra: <String,
                                                                              dynamic>{
                                                                            'email':
                                                                                user.email,
                                                                            kTransitionInfoKey:
                                                                                TransitionInfo(
                                                                              hasTransition: true,
                                                                              transitionType: PageTransitionType.fade,
                                                                              duration: Duration(
                                                                                milliseconds: 250,
                                                                              ),
                                                                            ),
                                                                          },
                                                                        );
                                                                      } else {
                                                                        // Handle proper navigation flow
                                                                        await AuthRedirectHandler
                                                                            .navigateAfterAuth(
                                                                          context,
                                                                        );
                                                                      }
                                                                    }
                                                                  },
                                                                  text:
                                                                      'Continue with Apple',
                                                                  icon: FaIcon(
                                                                    FontAwesomeIcons
                                                                        .apple,
                                                                    size: 20.0,
                                                                  ),
                                                                  options:
                                                                      FFButtonOptions(
                                                                    width:
                                                                        230.0,
                                                                    height:
                                                                        44.0,
                                                                    padding:
                                                                        EdgeInsetsDirectional
                                                                            .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                    ),
                                                                    iconPadding:
                                                                        EdgeInsetsDirectional
                                                                            .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                      0.0,
                                                                    ),
                                                                    color:
                                                                        FlutterFlowTheme
                                                                            .of(
                                                                      context,
                                                                    ).secondaryBackground,
                                                                    textStyle: FlutterFlowTheme
                                                                            .of(
                                                                      context,
                                                                    )
                                                                        .bodyMedium
                                                                        .override(
                                                                          fontFamily:
                                                                              'Figtree',
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                    elevation:
                                                                        0.0,
                                                                    borderSide:
                                                                        BorderSide(
                                                                      color:
                                                                          FlutterFlowTheme
                                                                              .of(
                                                                        context,
                                                                      ).alternate,
                                                                      width:
                                                                          2.0,
                                                                    ),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(
                                                                      12.0,
                                                                    ),
                                                                    hoverColor:
                                                                        FlutterFlowTheme
                                                                            .of(
                                                                      context,
                                                                    ).primaryBackground,
                                                                  ),
                                                                ),
                                                              ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ).animateOnPageLoad(
                                              animationsMap[
                                                  'columnOnPageLoadAnimation2']!,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment(0.0, 0),
                                    child: FlutterFlowButtonTabBar(
                                      useToggleButtonStyle: true,
                                      labelStyle: FlutterFlowTheme.of(
                                        context,
                                      ).bodyLarge.override(
                                            fontFamily: 'Figtree',
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      unselectedLabelStyle: FlutterFlowTheme.of(
                                        context,
                                      ).bodyLarge.override(
                                            fontFamily: 'Figtree',
                                            letterSpacing: 0.0,
                                          ),
                                      labelColor: FlutterFlowTheme.of(
                                        context,
                                      ).primaryText,
                                      unselectedLabelColor: FlutterFlowTheme.of(
                                        context,
                                      ).secondaryText,
                                      backgroundColor: FlutterFlowTheme.of(
                                        context,
                                      ).secondaryBackground,
                                      unselectedBackgroundColor:
                                          FlutterFlowTheme.of(
                                        context,
                                      ).primaryBackground,
                                      borderColor: FlutterFlowTheme.of(
                                        context,
                                      ).alternate,
                                      unselectedBorderColor:
                                          FlutterFlowTheme.of(
                                        context,
                                      ).alternate,
                                      borderWidth: 2.0,
                                      borderRadius: 12.0,
                                      elevation: 0.0,
                                      labelPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                        16.0,
                                        0.0,
                                        16.0,
                                        0.0,
                                      ),
                                      buttonMargin:
                                          EdgeInsetsDirectional.fromSTEB(
                                        12.0,
                                        0.0,
                                        12.0,
                                        0.0,
                                      ),
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0,
                                        0.0,
                                        16.0,
                                        0.0,
                                      ),
                                      tabs: [
                                        Tab(text: 'Create Account'),
                                        Tab(text: 'Log In'),
                                      ],
                                      controller: _model.tabBarController,
                                      onTap: (i) async {
                                        [() async {}, () async {}][i]();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animateOnPageLoad(
                            animationsMap['containerOnPageLoadAnimation']!,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
