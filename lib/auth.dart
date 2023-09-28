import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'home.dart';
import 'package:flutter/material.dart';

class AuthService {
  // Handle Authentication State Changes
  handleAuth() {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else {
            if (snapshot.hasData) {
              return const HomeScreen();
            } else {
              return const LoginPage();
            }
          }
        });
  }

  // Sign Out
  signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Sign In
  signIn(AuthCredential authCreds) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(authCreds);
    } catch (e) {
      print(e.toString());
    }
  }

  // Sign In with OTP
  signInWithOTP(smsCode, verId) {
    AuthCredential authCreds =
        PhoneAuthProvider.credential(verificationId: verId, smsCode: smsCode);
    signIn(authCreds);
  }

  // Verify Phone Number
  Future<void> verifyPhoneNumber({
    required BuildContext context,
    required String phoneNumber,
    required Function(AuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String, [int?]) onCodeSent,
    required Duration timeout,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      timeout: timeout,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  login() {}
}
