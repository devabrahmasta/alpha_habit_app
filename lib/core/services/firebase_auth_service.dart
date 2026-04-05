import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Auth service with Google Sign-In.
/// Drop-in replacement for MockAuthService.
class FirebaseAuthService {
  FirebaseAuthService._();
  static final instance = FirebaseAuthService._();

  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  /// Real-time auth state stream.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in user (null if signed out).
  User? get currentUser => _auth.currentUser;

  /// Triggers the Google Sign-In flow and returns the Firebase [User].
  Future<User> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    return result.user!;
  }

  /// Signs out of both Firebase and Google.
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
