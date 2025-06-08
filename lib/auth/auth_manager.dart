import 'package:flutter/material.dart';

import 'base_auth_user_provider.dart';

abstract class AuthManager {
  Future<BaseAuthUser?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  );
  Future<BaseAuthUser?> signInWithGoogle(BuildContext context);
  Future<BaseAuthUser?> signInWithApple(BuildContext context);
  Future<BaseAuthUser?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  );
  Future<void> signOut();
  Future<void> deleteUser(BuildContext context);
  Future<void> resetPassword(
    BuildContext context,
    String email,
  );
  Future<void> updateEmail(
    BuildContext context,
    String email,
  );
  Future<void> updatePassword(
    BuildContext context,
    String password,
  );
  Future<void> sendEmailVerification();
  Future<void> refreshUser();
}

mixin EmailSignInManager on AuthManager {
  Future<BaseAuthUser?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  );

  Future<BaseAuthUser?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  );
}

mixin AnonymousSignInManager on AuthManager {
  Future<BaseAuthUser?> signInAnonymously(BuildContext context);
}

mixin GoogleSignInManager on AuthManager {
  Future<BaseAuthUser?> signInWithGoogle(BuildContext context);
}

mixin AppleSignInManager on AuthManager {
  Future<BaseAuthUser?> signInWithApple(BuildContext context);
}

mixin JwtSignInManager on AuthManager {
  Future<BaseAuthUser?> signInWithJwtToken(
    BuildContext context,
    String jwtToken,
  );
}

mixin PhoneSignInManager on AuthManager {
  Future beginPhoneAuth({
    required BuildContext context,
    required String phoneNumber,
    required void Function(BuildContext) onCodeSent,
  });

  Future verifySmsCode({
    required BuildContext context,
    required String smsCode,
  });
}

mixin MicrosoftSignInManager on AuthManager {
  Future<BaseAuthUser?> signInWithMicrosoft(
    BuildContext context,
    List<String> scopes,
    String tenantId,
  );
}

mixin GithubSignInManager on AuthManager {
  Future<BaseAuthUser?> signInWithGithub(BuildContext context);
}
