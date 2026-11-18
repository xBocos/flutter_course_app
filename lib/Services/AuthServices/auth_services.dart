import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:page_transition/page_transition.dart';

import '../Home Screen/home_show_poll_screen.dart';

class AuthServices {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static Future<String> SignUpwithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return 'Sign-Up successful!';
    } catch (e) {
      return 'Error during sign-up : ${e.toString()}';
    }
  }

  static handleSignUp(
    String email,
    String password,
    BuildContext context,
  ) async {
    String message = await SignUpwithEmail(email, password);
    showSnackBar(message, context);
  }

  static Future<String> SignInwithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return 'Sign-In successful!';
    } catch (e) {
      return 'Error during sign-In : ${e.toString()}';
    }
  }

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      log(userCredential.toString());
      return null;
    } catch (e) {
      log('Google Sign-In Error: $e');
      return null;
    }
  }

  static handleSignIn(
    String email,
    String password,
    BuildContext context,
  ) async {
    String message = await SignInwithEmail(email, password);
    if (message == "Sign-In successful!") {
      Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          child: HomeShowPollScreen(),
        ),
      );
    }
    showSnackBar(message, context);
  }

  static void showSnackBar(String message, BuildContext context) {
    final snackBar = SnackBar(
      content: Text(message, style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.orange,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static Future<void> resetForgetPassword(
      String email, BuildContext context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showSnackBar("Reset Password email send successfully", context);
    } catch (e) {
      showSnackBar("Error in Reset Password ${e.toString()}", context);
    }
  }
}
