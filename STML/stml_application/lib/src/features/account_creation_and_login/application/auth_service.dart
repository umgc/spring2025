import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign up with email & password
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Sign up error: ${e.message}");
      return Future.error(e.message ?? "An error occurred during sign-up.");
    }
  }

  // Log in with email & password
  Future<User?> logIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Login error: ${e.message}");
      return Future.error(e.message ?? "An error occurred during login.");
    }
  }

  // Forgot Password (send reset email)
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print("Password reset error: ${e.message}");
      return Future.error(e.message ?? "Could not send password reset email.");
    }
  }

  // Log out
  Future<void> logOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
}
