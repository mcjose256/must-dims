// lib/features/auth/controllers/auth_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/auth/data/models/user_model.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

// Stream provider that listens to auth state changes
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  
  return auth.authStateChanges().asyncMap((firebaseUser) async {
    if (firebaseUser == null) return null;
    
    try {
      final doc = await firestore.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) return null;
      
      return UserModel.fromFirestore(doc, null);
    } catch (e) {
      return null;
    }
  });
});

// Main auth controller provider
final authControllerProvider = Provider((ref) => AuthController(ref));

// ============================================================================
// AUTH CONTROLLER
// ============================================================================

class AuthController {
  final Ref _ref;
  
  AuthController(this._ref);
  
  FirebaseAuth get _auth => _ref.read(firebaseAuthProvider);
  FirebaseFirestore get _db => _ref.read(firestoreProvider);
  
  // --------------------------------------------------------------------------
  // EMAIL/PASSWORD SIGN IN
  // --------------------------------------------------------------------------
  
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    }
  }
  
  // --------------------------------------------------------------------------
  // EMAIL/PASSWORD SIGN UP
  // --------------------------------------------------------------------------
  
  Future<void> signUp({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        final newUser = UserModel(
          uid: credential.user!.uid,
          email: email,
          role: role,
          isApproved: false,
          createdAt: DateTime.now(),
        );
        
        await _db
            .collection('users')
            .doc(credential.user!.uid)
            .set(UserModel.toFirestore(newUser, null));
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    }
  }
  
  // --------------------------------------------------------------------------
  // GOOGLE SIGN IN (Platform-aware: Web uses popup, Mobile uses redirect)
  // --------------------------------------------------------------------------
  
  Future<void> signInWithGoogle() async {
    try {
      // Create a GoogleAuthProvider instance and add scopes
      final googleProvider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      
      if (kIsWeb) {
        // WEB: Use popup
        final userCredential = await _auth.signInWithPopup(googleProvider);
        final firebaseUser = userCredential.user;
        
        if (firebaseUser != null) {
          await _createUserIfNotExists(firebaseUser);
        }
      } else {
        // MOBILE: Use redirect (works on iOS and Android)
        // This initiates the redirect - the user will be signed in when they return
        // The actual sign-in is handled by handleGoogleSignInRedirect() in main.dart
        await _auth.signInWithRedirect(googleProvider);
        // Note: This function returns void. The sign-in completes after redirect.
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user') {
        throw Exception('Sign-in cancelled');
      }
      throw Exception('Google Sign-In failed: ${e.message}');
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }
  
  // --------------------------------------------------------------------------
  // Handle redirect result (call this in app initialization for mobile)
  // --------------------------------------------------------------------------
  
  Future<void> handleGoogleSignInRedirect() async {
    if (kIsWeb) return; // Only needed for mobile
    
    try {
      final userCredential = await _auth.getRedirectResult();
      final firebaseUser = userCredential.user;
      
      if (firebaseUser != null) {
        await _createUserIfNotExists(firebaseUser);
      }
    } catch (e) {
      // Handle error silently or log it
    }
  }
  
  // --------------------------------------------------------------------------
  // Helper: Create user document if it doesn't exist
  // --------------------------------------------------------------------------
  
  Future<void> _createUserIfNotExists(User firebaseUser) async {
    final doc = await _db.collection('users').doc(firebaseUser.uid).get();
    
    if (!doc.exists) {
      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        role: UserRole.student,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        isApproved: false,
        createdAt: DateTime.now(),
      );
      
      await _db
          .collection('users')
          .doc(firebaseUser.uid)
          .set(UserModel.toFirestore(newUser, null));
    }
  }
  
  // --------------------------------------------------------------------------
  // SIGN OUT
  // --------------------------------------------------------------------------
  
  Future<void> signOut() async {
    await _auth.signOut();
  }
}