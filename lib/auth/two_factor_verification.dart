import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_theme.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_util.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_widgets.dart';
import 'package:luna_kraft/home/home_page/home_page_widget.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:luna_kraft/auth/firebase_auth/auth_util.dart';
import 'package:otp/otp.dart';
import 'package:luna_kraft/auth/auth_redirect_handler.dart';

class TwoFactorVerificationPage extends StatefulWidget {
  final String email;

  const TwoFactorVerificationPage({
    Key? key,
    required this.email,
  }) : super(key: key);

  static String routeName = 'TwoFactorVerification';
  static String routePath = '/twoFactorVerification';

  @override
  _TwoFactorVerificationPageState createState() =>
      _TwoFactorVerificationPageState();
}

class _TwoFactorVerificationPageState extends State<TwoFactorVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  bool _isVerifying = false;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _mounted = true;
  }

  @override
  void dispose() {
    _mounted = false;
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isVerifying) return;

    if (!_mounted) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      // Capture the code value before any async operations
      final code = _verificationCodeController.text.trim();
      final isValid = await AuthUtil.verifyTwoFactorCode(code);

      if (!_mounted) return;

      if (isValid) {
        // Use the redirect handler to properly navigate after successful verification
        // This will check if the user has a profile and navigate accordingly
        await AuthRedirectHandler.navigateAfterAuth(context);
      } else {
        if (!_mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid verification code. Please try again.'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    } catch (e) {
      if (!_mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while verifying the code.'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    } finally {
      if (!_mounted) return;

      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: FlutterFlowTheme.of(context).primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Two-Factor Authentication',
          style: FlutterFlowTheme.of(context).headlineSmall.override(
                fontFamily: 'Figtree',
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 64,
                  color: FlutterFlowTheme.of(context).primary,
                ),
                SizedBox(height: 24),
                Text(
                  'Verification Required',
                  style: FlutterFlowTheme.of(context).headlineMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Please enter the 6-digit code from your authenticator app to continue.',
                  style: FlutterFlowTheme.of(context).bodyLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Signed in as: ${widget.email}',
                  style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _verificationCodeController,
                    autoFocus: true,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    cursorColor: FlutterFlowTheme.of(context).primary,
                    enableActiveFill: true,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 45,
                      activeFillColor:
                          FlutterFlowTheme.of(context).primaryBackground,
                      inactiveFillColor:
                          FlutterFlowTheme.of(context).secondaryBackground,
                      selectedFillColor:
                          FlutterFlowTheme.of(context).primaryBackground,
                      activeColor: FlutterFlowTheme.of(context).primary,
                      inactiveColor: FlutterFlowTheme.of(context).alternate,
                      selectedColor: FlutterFlowTheme.of(context).primary,
                    ),
                    onCompleted: (value) {
                      if (_mounted) {
                        _verifyCode();
                      }
                    },
                    beforeTextPaste: (text) {
                      // Only allow digits
                      if (text == null) return false;
                      return text.length == 6 && int.tryParse(text) != null;
                    },
                  ),
                ),
                SizedBox(height: 32),
                FFButtonWidget(
                  onPressed: _isVerifying ? null : _verifyCode,
                  text: _isVerifying ? 'Verifying...' : 'Verify Code',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 55,
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'Figtree',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                    elevation: 3,
                    borderSide: BorderSide(
                      color: Colors.transparent,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    disabledColor: FlutterFlowTheme.of(context).alternate,
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Sign out and go back to sign in page
                    AuthUtil.signOut().then((_) {
                      context.go('/signin');
                    });
                  },
                  child: Text(
                    'Sign Out & Try Again',
                    style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                          color: FlutterFlowTheme.of(context).primary,
                        ),
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
