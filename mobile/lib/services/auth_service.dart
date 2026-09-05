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
    final current = prefs.getBool(agreementKey);
    if (current == true) return true;
    final legacy = prefs.getBool(_legacyAgreementKey) ?? false;
    if (legacy) {
      await prefs.setBool(agreementKey, true);
      return true;
    }
    return false;
  }

  Future<void> persistAgreementAccepted(bool accepted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(agreementKey, accepted);
      if (accepted) {
        await prefs.setBool(skippedKey, false);
      }
    } catch (error) {
      debugPrint('Could not persist agreement tick: $error');
    }
  }

  Future<AppUser> enterLabDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(skippedKey, false);
    await prefs.setBool(agreementKey, true);
    await _persist(AppUser.labDevice);
    return AppUser.labDevice;
  }

  Future<AppUser> enterSkippedGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(skippedKey, true);
    // Skip is a preview; it does not revoke a prior Terms tick.
    await prefs.remove(_sessionKey);
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
      final user = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (user.limitedAccess) {
        await prefs.remove(_sessionKey);
        return null;
      }
      return user;
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

  Future<AppUser> signInWithGoogle() async {
    try {
      final started = DateTime.now();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        final elapsedMs = DateTime.now().difference(started).inMilliseconds;
        if (elapsedMs < 4000) {
          debugPrint(
            'Google Sign-In returned null in ${elapsedMs}ms (likely ApiException 10). '
            'Lab session. Add Android SHA-1 $debugSha1 in Firebase when going to store.',
          );
          return enterLabDevice();
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
      await prefs.setBool(agreementKey, true);
      return user;
    } on AuthException {
      rethrow;
    } catch (error) {
      if (_isDeveloperError(error)) {
        debugPrint('Google Play OAuth not configured: $error');
        return enterLabDevice();
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
    // Keep agreementKey so README is not shown again after Sign out.
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
