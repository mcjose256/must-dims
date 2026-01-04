// lib/features/admin/controllers/user_approval_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/auth/controllers/auth_controller.dart';
import 'package:dims/features/auth/data/models/user_model.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

/// Stream provider that watches for pending user approvals
final pendingUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  
  return firestore
      .collection('users')
      .where('isApproved', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
    final futures = snapshot.docs.map((doc) async {
      try {
        return UserModel.fromFirestore(doc, null);
      } catch (e) {
        return null;
      }
    }).toList();
    
    final users = await Future.wait(futures);
    return users.whereType<UserModel>().toList();
  });
});

/// Controller provider for user approval operations
final userApprovalControllerProvider = Provider((ref) {
  return UserApprovalController(ref);
});

// ============================================================================
// CONTROLLER
// ============================================================================

class UserApprovalController {
  final Ref _ref;
  
  UserApprovalController(this._ref);
  
  FirebaseFirestore get _db => _ref.read(firestoreProvider);
  
  /// Approve or reject a user registration
  /// 
  /// [uid] - The user's unique ID
  /// [approve] - true to approve, false to reject
  Future<void> approveUser(String uid, bool approve) async {
    try {
      if (approve) {
        // Approve user
        await _db.collection('users').doc(uid).update({
          'isApproved': true,
          'approvedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Reject user - delete their account
        // Alternative: You can mark as rejected instead of deleting
        await _db.collection('users').doc(uid).delete();
        
        // OR keep the record but mark as rejected:
        // await _db.collection('users').doc(uid).update({
        //   'isApproved': false,
        //   'rejectedAt': FieldValue.serverTimestamp(),
        //   'status': 'rejected',
        // });
      }
    } catch (e) {
      throw Exception('Failed to ${approve ? 'approve' : 'reject'} user: $e');
    }
  }
  
  /// Bulk approve multiple users at once
  /// 
  /// [uids] - List of user IDs to approve
  Future<void> bulkApproveUsers(List<String> uids) async {
    if (uids.isEmpty) return;
    
    final batch = _db.batch();
    
    for (final uid in uids) {
      batch.update(
        _db.collection('users').doc(uid),
        {
          'isApproved': true,
          'approvedAt': FieldValue.serverTimestamp(),
        },
      );
    }
    
    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk approve users: $e');
    }
  }
  
  /// Bulk reject multiple users at once
  /// 
  /// [uids] - List of user IDs to reject
  Future<void> bulkRejectUsers(List<String> uids) async {
    if (uids.isEmpty) return;
    
    final batch = _db.batch();
    
    for (final uid in uids) {
      batch.delete(_db.collection('users').doc(uid));
    }
    
    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk reject users: $e');
    }
  }
  
  /// Get count of pending approvals
  Future<int> getPendingCount() async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('isApproved', isEqualTo: false)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get pending count: $e');
    }
  }
  
  /// Get pending users by role
  Future<List<UserModel>> getPendingUsersByRole(UserRole role) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('isApproved', isEqualTo: false)
          .where('role', isEqualTo: role.name)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) {
            try {
              return UserModel.fromFirestore(doc, null);
            } catch (e) {
              return null;
            }
          })
          .whereType<UserModel>()
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending users by role: $e');
    }
  }
}