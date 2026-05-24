import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? name,
    String? photoUrl,
  }) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (name != null || photoUrl != null) {
      await userCredential.user?.updateProfile(
        displayName: name?.trim(),
        photoURL: photoUrl,
      );
    }
    return userCredential;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
