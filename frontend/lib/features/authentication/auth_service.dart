import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around [FirebaseAuth]. Kept deliberately small: this
/// project's auth requirements (per Decision 2 / Document 02's `users`
/// collection) are identity + role lookup, both of which are backend
/// concerns — the Flutter client only needs to obtain a signed-in user
/// and hand its ID token to [ApiClient].
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  /// Returns the current user's Firebase ID token, or null if signed out.
  /// Passed to [ApiClient] as its [TokenProvider].
  Future<String?> getIdToken() => currentUser?.getIdToken() ?? Future.value();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithCustomToken(String token) {
    return _firebaseAuth.signInWithCustomToken(token);
  }

  Future<void> signOut() => _firebaseAuth.signOut();
}
