import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  static const _sessionKey = 'ee.session.user';
  /// Bump when Terms / Privacy change so the welcome tick is required again.
  static const agreementKey = 'ee.legal.bundle.v2';
  static const _legacyAgreementKey = 'ee.agreement.accepted';
  static const skippedKey = 'ee.legal.skipped';

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  static Future<bool> readAgreementAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(agreementKey) ?? false;
  }

  Future<void> persistAgreementAccepted(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(agreementKey, accepted);
    if (accepted) {
      await prefs.setBool(skippedKey, false);
    }
  }

  Future<AppUser> enterSkippedGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(skippedKey, true);
    await prefs.setBool(agreementKey, false);
    await _persist(AppUser.guest);
    return AppUser.guest;
  }

  static Future<void> ensureFirebase() async {
    if (kIsWeb) return;
    if (Firebase.apps.isNotEmpty) return;
    try {
      await Firebase.initializeApp();
    } catch (error) {
      debugPrint('Firebase init skipped: $error');
    }
  }

  static Future<AppUser?> readSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist(AppUser? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
    }
  }

  static const debugSha1 =
      '57:0C:80:58:9D:2E:A8:6D:0E:1B:20:2A:5A:3F:6F:38:47:D0:95:33';

  static bool _isDeveloperError(Object error) {
    final text = error.toString();
    return text.contains('ApiException: 10') ||
        text.contains('ApiException:10') ||
        (error is PlatformException &&
            (error.code == 'sign_in_failed' &&
                (error.message?.contains('10') ?? false)));
  }

  static AuthException _developerError() {
    return AuthException(
      'Google ApiException 10: Firebase still has no Android OAuth client '
      'for package com.eniwhere.energy. Add SHA-1 $debugSha1, enable '
      'Authentication → Google, then replace android/app/google-services.json '
      'with the newly downloaded file.',
    );
  }

  Future<AppUser> signInWithGoogle() async {
    try {
      final started = DateTime.now();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        final elapsedMs = DateTime.now().difference(started).inMilliseconds;
        if (elapsedMs < 4000) {
          throw _developerError();
        }
        throw AuthException('Sign-in cancelled');
      }

      if (!kIsWeb && Firebase.apps.isNotEmpty) {
        try {
          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
        } catch (error) {
          debugPrint('Firebase credential exchange skipped: $error');
        }
      }

      final user = AppUser(
        id: googleUser.id,
        email: googleUser.email,
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
      );
      await _persist(user);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(skippedKey, false);
      return user;
    } on AuthException {
      rethrow;
    } catch (error) {
      if (_isDeveloperError(error)) {
        throw _developerError();
      }
      throw AuthException('Google Sign-In failed: $error');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    if (!kIsWeb && Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    await _persist(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(skippedKey, false);
  }

  /// Wipe EE keys on this device (session, legal tick, vehicle, owner PIN).
  Future<void> clearAllLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(agreementKey);
    await prefs.remove(_legacyAgreementKey);
    await prefs.remove('ee.vehicle.profile');
    await prefs.remove('ee.owner.pin');
    await prefs.remove(skippedKey);
  }
}
