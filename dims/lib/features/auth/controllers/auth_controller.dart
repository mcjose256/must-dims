import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/auth/data/models/user_model.dart';

final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

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

final authControllerProvider = Provider((ref) => AuthController(ref));

class AuthController {
  final Ref _ref;
  AuthController(this._ref);
  
  FirebaseAuth get _auth => _ref.read(firebaseAuthProvider);
  FirebaseFirestore get _db => _ref.read(firestoreProvider);
  
  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }
  
  /// Sign up new user with role-specific profiles
  Future<void> signUp({
    required String email,
    required String password,
    required UserRole role,
    required String fullName,
    required String department,
  }) async {
    UserCredential? credential;
    
    try {
      // 1. Create Auth User
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = credential.user!.uid;
      
      // Update display name
      await credential.user!.updateDisplayName(fullName);
      
      // 2. Create the BASE User document (for login & role system)
      final newUser = UserModel(
        uid: uid,
        email: email,
        role: role,
        displayName: fullName,
        isApproved: false, // Wait for admin
        createdAt: DateTime.now(),
      );
      
      await _db.collection('users').doc(uid).set(
        UserModel.toFirestore(newUser, null),
      );
      
      // 3. Create the ROLE-SPECIFIC document (for the Dashboard)
      await _createRoleSpecificProfile(
        uid: uid,
        role: role,
        fullName: fullName,
        email: email,
        department: department,
      );
      
    } on FirebaseAuthException catch (e) {
      // If user creation failed, clean up any partial data
      if (credential?.user != null) {
        await _cleanupFailedRegistration(credential!.user!.uid);
      }
      throw _handleAuthException(e);
    } catch (e) {
      // Clean up on any other error
      if (credential?.user != null) {
        await _cleanupFailedRegistration(credential!.user!.uid);
      }
      throw Exception('Registration failed: ${e.toString()}');
    }
  }
  
  /// Create role-specific profile in Firestore
  Future<void> _createRoleSpecificProfile({
    required String uid,
    required UserRole role,
    required String fullName,
    required String email,
    required String department,
  }) async {
    if (role == UserRole.supervisor) {
      await _db.collection('supervisorProfiles').doc(uid).set({
        'uid': uid,
        'fullName': fullName,
        'email': email,
        'department': department,
        'maxStudents': 12,
        'currentLoad': 0,
        'isAvailable': true,
        'assignedStudentIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _db.collection('students').doc(uid).set({
        'uid': uid,
        'registrationNumber': 'PENDING',
        'program': department,
        'fullName': fullName,
        'status': 'active',
        'internshipStatus': 'notStarted',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
  
  /// Clean up partial data if registration fails
  Future<void> _cleanupFailedRegistration(String uid) async {
    try {
      // Delete Firestore documents
      await Future.wait([
        _db.collection('users').doc(uid).delete(),
        _db.collection('supervisorProfiles').doc(uid).delete(),
        _db.collection('students').doc(uid).delete(),
      ]);
      
      // Try to delete the auth user
      final currentUser = _auth.currentUser;
      if (currentUser?.uid == uid) {
        await currentUser?.delete();
      }
    } catch (e) {
      // Silently fail cleanup - not critical
      print('Cleanup failed: $e');
    }
  }
  
  /// Create user profile directly (for bypass scenarios)
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required UserRole role,
    required String fullName,
    required String department,
  }) async {
    try {
      // Create base user document
      final newUser = UserModel(
        uid: uid,
        email: email,
        role: role,
        displayName: fullName,
        isApproved: false,
        createdAt: DateTime.now(),
      );
      
      await _db.collection('users').doc(uid).set(
        UserModel.toFirestore(newUser, null),
      );
      
      // Create role-specific profile
      await _createRoleSpecificProfile(
        uid: uid,
        role: role,
        fullName: fullName,
        email: email,
        department: department,
      );
    } catch (e) {
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }
  
  /// Handle Firebase Auth exceptions with user-friendly messages
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;
    
    switch (e.code) {
      case 'email-already-in-use':
        message = 'This email is already registered. Try logging in instead.';
        break;
      case 'invalid-email':
        message = 'Invalid email address format.';
        break;
      case 'operation-not-allowed':
        message = 'Email/password accounts are not enabled. Contact administrator.';
        break;
      case 'weak-password':
        message = 'Password is too weak. Use at least 6 characters.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled. Contact administrator.';
        break;
      case 'user-not-found':
        message = 'No account found with this email.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'network-request-failed':
        message = 'Network error. Check your internet connection.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      case 'invalid-credential':
        message = 'Invalid credentials. Please check your email and password.';
        break;
      default:
        // Handle 403/permission errors
        if (e.message?.contains('403') ?? false) {
          message = 'Authentication service is temporarily unavailable. Please contact administrator.';
        } else if (e.message?.contains('PERMISSION_DENIED') ?? false) {
          message = 'Permission denied. Please contact administrator.';
        } else {
          message = e.message ?? 'Authentication failed. Please try again.';
        }
    }
    
    return Exception(message);
  }
  
  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }
  
  /// Get current user
  User? get currentUser => _auth.currentUser;
  
  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;
}