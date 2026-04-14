import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/models/user_model.dart';
import '../data/company_supervisor_model.dart';

// Provider for company supervisor profile
final companySupervisorProvider = StreamProvider.family<CompanySupervisorModel?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('companySupervisors')
      .doc(uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        return CompanySupervisorModel.fromFirestore(doc, null);
      });
});

// Provider for current company supervisor's students
final companySupervisorStudentsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('placements')
      .where('companySupervisorId', isEqualTo: user.uid)
      .where('status', whereIn: ['active', 'approved', 'completed', 'extended'])
      .snapshots()
      .asyncMap((snapshot) async {
        final List<Map<String, dynamic>> students = [];
        
        for (var placementDoc in snapshot.docs) {
          final placementData = placementDoc.data();
          
          // Get student details
          final studentDoc = await FirebaseFirestore.instance
              .collection('students')
              .doc(placementData['studentId'])
              .get();
          
          if (studentDoc.exists) {
            students.add({
              'placement': placementData,
              'placementId': placementDoc.id,
              'student': studentDoc.data(),
              'studentId': studentDoc.id,
            });
          }
        }
        
        return students;
      });
});

// Provider for pending logbook reviews
final pendingLogbookReviewsProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('companySupervisors')
      .doc(user.uid)
      .snapshots()
      .asyncMap((supervisorDoc) async {
        if (!supervisorDoc.exists) return 0;
        
        final supervisorData = supervisorDoc.data();
        final assignedStudentIds = List<String>.from(supervisorData?['assignedStudentIds'] ?? []);
        
        if (assignedStudentIds.isEmpty) return 0;
        
        // Count unreviewed logbooks for assigned students
        final logbooksSnapshot = await FirebaseFirestore.instance
            .collection('logbookEntries')
            .where('studentId', whereIn: assignedStudentIds)
            .where('isReviewedByCompanySupervisor', isEqualTo: false)
            .where('status', isEqualTo: 'submitted')
            .get();
        
        return logbooksSnapshot.docs.length;
      });
});

class CompanySupervisorController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create company supervisor account from setup token
  Future<String?> setupAccount({
    required String email,
    required String password,
    required String fullName,
    required String companyId,
    required String companyName,
    String? position,
    String? phoneNumber,
  }) async {
    try {
      // 1. Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 2. Update display name
      await userCredential.user!.updateDisplayName(fullName);

      // 3. Create user document with companySupervisor role
      await _firestore.collection('users').doc(uid).set(
        UserModel(
          uid: uid,
          email: email,
          role: UserRole.companySupervisor,
          displayName: fullName,
          phoneNumber: phoneNumber,
          isApproved: true, // Auto-approved
          createdAt: DateTime.now(),
        ).toJson()
          ..['role'] = 'companySupervisor',
      );

      // 4. Create company supervisor profile
      await _firestore.collection('companySupervisors').doc(uid).set(
        CompanySupervisorModel(
          uid: uid,
          fullName: fullName,
          email: email,
          companyId: companyId,
          companyName: companyName,
          position: position,
          phoneNumber: phoneNumber,
          isActive: true,
          emailVerified: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).toJson(),
      );

      // 5. Add supervisor to company's supervisor list
      await _firestore.collection('companies').doc(companyId).update({
        'companySupervisorIds': FieldValue.arrayUnion([uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 6. Send email verification
      await userCredential.user!.sendEmailVerification();

      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'Password is too weak';
      } else if (e.code == 'email-already-in-use') {
        return 'An account already exists with this email';
      } else if (e.code == 'invalid-email') {
        return 'Invalid email address';
      }
      return e.message ?? 'Failed to create account';
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  /// Link existing placement to company supervisor after account creation
  Future<void> linkPendingPlacements(String supervisorEmail) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // Find placements with this supervisor email but no supervisor ID
      final placementsSnapshot = await _firestore
          .collection('placements')
          .where('companySupervisorEmail', isEqualTo: supervisorEmail)
          .where('companySupervisorId', isEqualTo: null)
          .get();

      // Update placements with supervisor ID
      final batch = _firestore.batch();
      final studentIds = <String>[];

      for (var doc in placementsSnapshot.docs) {
        batch.update(doc.reference, {
          'companySupervisorId': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        final data = doc.data();
        if (data['studentId'] != null) {
          studentIds.add(data['studentId']);
        }
      }

      // Update supervisor profile with assigned students
      if (studentIds.isNotEmpty) {
        batch.update(_firestore.collection('companySupervisors').doc(uid), {
          'assignedStudentIds': FieldValue.arrayUnion(studentIds),
          'currentLoad': studentIds.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error linking placements: $e');
    }
  }

  /// Update last login timestamp
  Future<void> updateLastLogin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('companySupervisors').doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update supervisor profile
  Future<String?> updateProfile({
    String? fullName,
    String? position,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'Not logged in';

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (fullName != null) updates['fullName'] = fullName;
      if (position != null) updates['position'] = position;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore.collection('companySupervisors').doc(uid).update(updates);

      // Also update display name in auth
      if (fullName != null) {
        await _auth.currentUser?.updateDisplayName(fullName);
      }

      return null; // Success
    } catch (e) {
      return 'Failed to update profile: $e';
    }
  }
}

// Provider for the controller
final companySupervisorControllerProvider = Provider((ref) {
  return CompanySupervisorController();
});
