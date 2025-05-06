import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
// Remove html import to prevent any issues
// import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/user_record.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:otp/otp.dart';
import 'package:base32/base32.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TwoFactorSetupPage extends StatefulWidget {
  const TwoFactorSetupPage({Key? key}) : super(key: key);

  static String routeName = 'TwoFactorSetup';
  static String routePath = '/twoFactorSetup';

  @override
  State<TwoFactorSetupPage> createState() => _TwoFactorSetupPageState();
}

class _TwoFactorSetupPageState extends State<TwoFactorSetupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _verificationCodeController =
      TextEditingController();

  bool _isLoading = false;
  bool _is2FAEnabled = false;
  bool _showVerificationCodeInput = false;
  bool _isDisposed = false;
  String _secretKey = '';
  String _userEmail = '';
  BuildContext? _savedContext;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _savedContext = context;
  }

  @override
  void initState() {
    super.initState();
    _checkCurrentState();
  }

  @override
  void dispose() {
    _verificationCodeController?.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  void _safeClearController() {
    if (_verificationCodeController != null) {
      try {
        _verificationCodeController!.clear();
      } catch (e) {
        // Ignore errors when clearing the controller
        debugPrint('Error clearing controller: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted || _isDisposed) return;
    final context = _savedContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _checkCurrentState() async {
    if (!mounted) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Get the user document from Firestore to ensure we have the correct 2FA status
    try {
      final userDoc = await UserRecord.collection.doc(currentUser.uid).get();
      final userData = UserRecord.fromSnapshot(userDoc);

      // Also get SharedPreferences for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      final secretKey = userDoc.exists && userData.hasTwoFactorSecretKey()
          ? userData.twoFactorSecretKey
          : prefs.getString('2fa_secret_key_${currentUser.uid}') ?? '';

      if (mounted) {
        setState(() {
          // Use the Firestore value as the single source of truth
          _is2FAEnabled = userDoc.exists && userData.hasIs2FAEnabled()
              ? userData.is2FAEnabled
              : false;
          _secretKey = secretKey;
          _userEmail = currentUser.email ?? '';
        });

        // Ensure SharedPreferences is in sync with Firestore
        if (userDoc.exists && userData.hasIs2FAEnabled()) {
          await prefs.setBool(
              'is_2fa_enabled_${currentUser.uid}', userData.is2FAEnabled);
          if (userData.hasTwoFactorSecretKey()) {
            await prefs.setString('2fa_secret_key_${currentUser.uid}',
                userData.twoFactorSecretKey);
          }
        }
      }
    } catch (e) {
      print('Error checking 2FA state: $e');

      // Fallback to SharedPreferences if Firestore fails
      final prefs = await SharedPreferences.getInstance();
      final isEnabled =
          prefs.getBool('is_2fa_enabled_${currentUser.uid}') ?? false;
      final secretKey =
          prefs.getString('2fa_secret_key_${currentUser.uid}') ?? '';

      if (mounted) {
        setState(() {
          _is2FAEnabled = isEnabled;
          _secretKey = secretKey;
          _userEmail = currentUser.email ?? '';
        });
      }
    }
  }

  String _generateSecretKey() {
    final random = Random.secure();
    // Generate a random 20-byte (160-bit) secret key
    final Uint8List randomBytes = Uint8List(20);
    for (int i = 0; i < 20; i++) {
      randomBytes[i] = random.nextInt(256);
    }
    // Convert to base32 for QR code
    return base32.encode(randomBytes);
  }

  void _startVerification() {
    if (!mounted || _isDisposed) return;

    // Generate a new secret key
    final secretKey = _generateSecretKey();

    _safeSetState(() {
      _secretKey = secretKey;
      _showVerificationCodeInput = true;
      _safeClearController();
    });

    _showSnackBar('Scan the QR code with Google Authenticator app');
  }

  String _getTotpCode() {
    if (_secretKey.isEmpty) return '';
    return OTP.generateTOTPCodeString(
      _secretKey,
      DateTime.now().millisecondsSinceEpoch,
      length: 6,
      interval: 30,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
  }

  Future<void> _verifyCode() async {
    if (!mounted || _isDisposed) return;

    final enteredCode = _verificationCodeController.text.trim();
    if (enteredCode.length != 6) {
      _showSnackBar('Please enter a valid 6-digit verification code');
      return;
    }

    _safeSetState(() {
      _isLoading = true;
    });

    try {
      // Get the current TOTP code
      final currentCode = _getTotpCode();

      // Check if the entered code matches the generated code
      if (enteredCode == currentCode) {
        await _save2FASettings();
        if (!mounted || _isDisposed) return;
        _showSnackBar('Two-factor authentication enabled successfully');
      } else {
        // Try with a small window to account for timing differences
        bool verified = false;

        // Try with timestamps from -30 to +30 seconds
        for (int i = -1; i <= 1; i++) {
          final timestamp =
              DateTime.now().millisecondsSinceEpoch + (i * 30 * 1000);
          final alternateCode = OTP.generateTOTPCodeString(
            _secretKey,
            timestamp,
            length: 6,
            interval: 30,
            algorithm: Algorithm.SHA1,
            isGoogle: true,
          );

          if (enteredCode == alternateCode) {
            verified = true;
            await _save2FASettings();
            if (!mounted || _isDisposed) return;
            _showSnackBar('Two-factor authentication enabled successfully');
            break;
          }
        }

        if (!verified) {
          throw Exception('Invalid verification code');
        }
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      _showSnackBar('Error verifying code: ${e.toString()}');
    } finally {
      if (mounted && !_isDisposed) {
        _safeSetState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _save2FASettings() async {
    if (!mounted || _isDisposed) return;

    try {
      // Save to Firestore using user's document
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Update Firestore first
        await UserRecord.collection.doc(currentUser.uid).update({
          'is_2fa_enabled': true,
          '2fa_secret_key': _secretKey,
        });

        // Then update SharedPreferences for local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_2fa_enabled_${currentUser.uid}', true);
        await prefs.setString('2fa_secret_key_${currentUser.uid}', _secretKey);
      }

      _safeSetState(() {
        _is2FAEnabled = true;
        _showVerificationCodeInput = false;
      });
    } catch (e) {
      print('Error saving 2FA status: $e');
      if (!mounted || _isDisposed) return;
      _showSnackBar('Error saving 2FA settings: $e');
      rethrow;
    }
  }

  Future<void> _disable2FA() async {
    if (!mounted || _isDisposed) return;

    _safeSetState(() {
      _isLoading = true;
    });

    try {
      // Remove from Firestore using user's document
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Update Firestore first
        await UserRecord.collection.doc(currentUser.uid).update({
          'is_2fa_enabled': false,
          '2fa_secret_key': '',
        });

        // Then update SharedPreferences for local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_2fa_enabled_${currentUser.uid}', false);
        await prefs.setString('2fa_secret_key_${currentUser.uid}', '');
      }

      if (!mounted || _isDisposed) return;
      _safeSetState(() {
        _is2FAEnabled = false;
        _secretKey = '';
        _isLoading = false;
      });

      _showSnackBar('Two-factor authentication disabled');
    } catch (e) {
      if (!mounted || _isDisposed) return;
      _safeSetState(() {
        _isLoading = false;
      });

      _showSnackBar('Error disabling 2FA: $e');
    }
  }

  String _getQRCodeData() {
    // Format: otpauth://totp/ISSUER:ACCOUNT?secret=SECRET&issuer=ISSUER
    final issuer = 'Luna Kraft';
    final account = _userEmail;
    final secret = _secretKey;

    return 'otpauth://totp/$issuer:$account?secret=$secret&issuer=$issuer';
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return Container(); // Return empty if disposed

    final mediaQuery = MediaQuery.of(context);
    final paddingTop = mediaQuery.padding.top;
    final paddingBottom = mediaQuery.padding.bottom;

    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
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
        actions: [
          if (_isLoading)
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: () {
                _safeSetState(() {
                  _isLoading = false;
                });
              },
            ),
        ],
      ),
      body: Material(
        color: FlutterFlowTheme.of(context).primaryBackground,
        child: SafeArea(
          minimum: EdgeInsets.only(
              left: 8.0, right: 8.0, top: 8.0, bottom: 8.0 + paddingBottom),
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing your request...'),
                      SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          _safeSetState(() {
                            _isLoading = false;
                          });
                        },
                        child: Text('Cancel'),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.security,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Enhanced Security',
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            fontFamily: 'Figtree',
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Two-factor authentication adds an extra layer of security to your account. '
                                'When enabled, you\'ll need to verify your identity using an authenticator app such as Google Authenticator in addition to your password.',
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(
                              _is2FAEnabled ? Icons.check_circle : Icons.cancel,
                              color: _is2FAEnabled
                                  ? Colors.green
                                  : FlutterFlowTheme.of(context).secondaryText,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _is2FAEnabled
                                    ? 'Two-factor authentication is enabled'
                                    : 'Two-factor authentication is not enabled',
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        if (_is2FAEnabled)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Authentication Method',
                                style: FlutterFlowTheme.of(context).titleMedium,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Google Authenticator (TOTP)',
                                style: FlutterFlowTheme.of(context).bodyLarge,
                              ),
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _disable2FA,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child:
                                      Text('Disable Two-Factor Authentication'),
                                ),
                              ),
                            ],
                          )
                        else if (_showVerificationCodeInput)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan this QR code',
                                style: FlutterFlowTheme.of(context).titleMedium,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Use Google Authenticator or any other authenticator app to scan this QR code',
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                              SizedBox(height: 24),
                              Align(
                                alignment: Alignment.center,
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: QrImageView(
                                    data: _getQRCodeData(),
                                    version: QrVersions.auto,
                                    size: 200.0,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: 24),
                              Text(
                                'Manual setup code:',
                                style: FlutterFlowTheme.of(context).labelLarge,
                              ),
                              SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate),
                                ),
                                child: SelectableText(
                                  _secretKey,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .copyWith(
                                        fontFamily: 'Courier New',
                                        letterSpacing: 1,
                                      ),
                                ),
                              ),
                              SizedBox(height: 24),
                              Text(
                                'Enter Verification Code',
                                style: FlutterFlowTheme.of(context).titleMedium,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Enter the 6-digit code from your authenticator app',
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                              SizedBox(height: 16),
                              PinCodeTextField(
                                appContext: context,
                                length: 6,
                                controller: _verificationCodeController,
                                autoFocus: true,
                                cursorColor:
                                    FlutterFlowTheme.of(context).primary,
                                keyboardType: TextInputType.number,
                                pinTheme: PinTheme(
                                  shape: PinCodeFieldShape.box,
                                  borderRadius: BorderRadius.circular(8),
                                  fieldHeight: 50,
                                  fieldWidth: 45,
                                  activeFillColor: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  inactiveFillColor:
                                      FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                  selectedFillColor:
                                      FlutterFlowTheme.of(context)
                                          .primaryBackground,
                                  activeColor:
                                      FlutterFlowTheme.of(context).primary,
                                  inactiveColor:
                                      FlutterFlowTheme.of(context).alternate,
                                  selectedColor:
                                      FlutterFlowTheme.of(context).primary,
                                ),
                                animationType: AnimationType.fade,
                                animationDuration: Duration(milliseconds: 300),
                                enableActiveFill: true,
                                onCompleted: (code) {
                                  if (mounted && !_isDisposed) {
                                    _verifyCode();
                                  }
                                },
                              ),
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _verifyCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).primary,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text('Verify Code'),
                                ),
                              ),
                              SizedBox(height: 16),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    _safeSetState(() {
                                      _showVerificationCodeInput = false;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.cancel,
                                    size: 18,
                                  ),
                                  label: Text('Cancel Setup'),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        FlutterFlowTheme.of(context)
                                            .secondaryText,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else if (!_is2FAEnabled && !_showVerificationCodeInput)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Google Authenticator',
                                style: FlutterFlowTheme.of(context).titleMedium,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Use Google Authenticator or any TOTP-compatible authenticator app to add an extra layer of security to your account.',
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .info
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context)
                                        .info
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color:
                                              FlutterFlowTheme.of(context).info,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Before You Begin',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontFamily: 'Figtree',
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .info,
                                              ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Download Google Authenticator or another authenticator app on your mobile device.',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _startVerification,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        FlutterFlowTheme.of(context).primary,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text('Setup Authenticator'),
                                ),
                              ),
                              SizedBox(height: 16),
                              Center(
                                child: Text(
                                  'You will need to scan a QR code with your authenticator app',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        fontFamily: 'Figtree',
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        fontStyle: FontStyle.italic,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
