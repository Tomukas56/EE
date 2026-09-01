import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final sessionProvider = StateNotifierProvider<SessionNotifier, AppUser?>((ref) {
  throw StateError('sessionProvider must be overridden in main()');
});

class SessionNotifier extends StateNotifier<AppUser?> {
  SessionNotifier(this._auth, AppUser? initial) : super(initial);

  final AuthService _auth;

  bool get isLoggedIn => state != null;

  Future<AppUser> enterSkippedGuest() async {
    final user = await _auth.enterSkippedGuest();
    state = user;
    return user;
  }

  Future<AppUser> signInWithGoogle() async {
    final user = await _auth.signInWithGoogle();
    state = user;
    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = null;
  }

  Future<void> afterRemoteErase() async {
    await _auth.clearAllLocalData();
    await signOut();
  }
}
