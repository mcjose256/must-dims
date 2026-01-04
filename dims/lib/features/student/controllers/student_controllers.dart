// lib/features/student/controllers/student_controllers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dims/features/auth/controllers/auth_controller.dart';
import 'package:dims/features/student/data/models/student_profile_model.dart';
import 'package:dims/features/placements/data/models/placement_model.dart';
import 'package:dims/features/logbook/data/models/logbook_entry_model.dart';
import 'package:dims/features/companies/data/models/company_model.dart';

// ============================================================================
// STUDENT PROFILE PROVIDERS
// ============================================================================

/// Get current student's profile
final studentProfileProvider = StreamProvider<StudentProfileModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);
  
  final userId = authState.value?.uid;
  if (userId == null) return Stream.value(null);
  
  return firestore
      .collection('students')
      .doc(userId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return StudentProfileModel.fromFirestore(doc, null);
  });
});

/// Check if profile is complete
final isProfileCompleteProvider = Provider<bool>((ref) {
  final profile = ref.watch(studentProfileProvider).value;
  if (profile == null) return false;
  
  // Profile is complete if all required fields are filled
  return profile.registrationNumber.isNotEmpty &&
         profile.program.isNotEmpty &&
         profile.academicYear > 0 &&
         profile.currentLevel.isNotEmpty;
});

// ============================================================================
// PLACEMENT PROVIDERS
// ============================================================================

/// Get current student's active placement
final currentPlacementProvider = StreamProvider<PlacementModel?>((ref) {
  final profile = ref.watch(studentProfileProvider).value;
  final firestore = ref.watch(firestoreProvider);
  
  final placementId = profile?.currentPlacementId;
  if (placementId == null) return Stream.value(null);
  
  return firestore
      .collection('placements')
      .doc(placementId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return PlacementModel.fromFirestore(doc, null);
  });
});

/// Get company details for current placement
final placementCompanyProvider = FutureProvider<CompanyModel?>((ref) async {
  final placement = ref.watch(currentPlacementProvider).value;
  final firestore = ref.watch(firestoreProvider);
  
  final companyPath = placement?.companyRefPath;
  if (companyPath == null) return null;
  
  try {
    final doc = await firestore.doc(companyPath).get();
    if (!doc.exists) return null;
    return CompanyModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null);
  } catch (e) {
    return null;
  }
});

// ============================================================================
// LOGBOOK PROVIDERS
// ============================================================================

/// Get all logbook entries for current student with document IDs
final logbookEntriesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);
  
  final userId = authState.value?.uid;
  if (userId == null) return Stream.value([]);
  
  return firestore
      .collection('logbook_entries')
      .where('studentRefPath', isEqualTo: 'students/$userId')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final entry = LogbookEntryModel.fromFirestore(doc, null);
      return {
        'id': doc.id,
        'entry': entry,
      };
    }).toList();
  });
});

/// Get pending logbook entries count
final pendingLogbookCountProvider = Provider<int>((ref) {
  final entries = ref.watch(logbookEntriesProvider).value ?? [];
  return entries.where((e) {
    final entry = e['entry'] as LogbookEntryModel;
    return entry.status?.toLowerCase() == 'pending';
  }).length;
});

/// Get approved logbook entries count
final approvedLogbookCountProvider = Provider<int>((ref) {
  final entries = ref.watch(logbookEntriesProvider).value ?? [];
  return entries.where((e) {
    final entry = e['entry'] as LogbookEntryModel;
    return entry.status?.toLowerCase() == 'approved';
  }).length;
});

// ============================================================================
// STUDENT PROFILE CONTROLLER
// ============================================================================

final studentProfileControllerProvider = Provider((ref) {
  return StudentProfileController(ref);
});

class StudentProfileController {
  final Ref _ref;
  
  StudentProfileController(this._ref);
  
  FirebaseFirestore get _db => _ref.read(firestoreProvider);
  
  /// Create or update student profile
  Future<void> saveProfile(String userId, StudentProfileModel profile) async {
    try {
      await _db
          .collection('students')
          .doc(userId)
          .set(
            StudentProfileModel.toFirestore(
              profile.copyWith(
                updatedAt: DateTime.now(),
                createdAt: profile.createdAt ?? DateTime.now(),
              ),
              null,
            ),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }
  
  /// Update progress percentage
  Future<void> updateProgress(String userId, double progress) async {
    try {
      await _db.collection('students').doc(userId).update({
        'progressPercentage': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }
}

// ============================================================================
// LOGBOOK CONTROLLER
// ============================================================================

final logbookControllerProvider = Provider((ref) {
  return LogbookController(ref);
});

class LogbookController {
  final Ref _ref;
  
  LogbookController(this._ref);
  
  FirebaseFirestore get _db => _ref.read(firestoreProvider);
  
  /// Submit a new logbook entry
  Future<void> submitEntry(LogbookEntryModel entry) async {
    try {
      await _db.collection('logbook_entries').add(
        LogbookEntryModel.toFirestore(
          entry.copyWith(status: 'pending'),
          null,
        ),
      );
    } catch (e) {
      throw Exception('Failed to submit logbook entry: $e');
    }
  }
  
  /// Update existing logbook entry (only if not approved)
  Future<void> updateEntry(String entryId, LogbookEntryModel entry) async {
    try {
      // Check if entry is approved
      if (entry.status?.toLowerCase() == 'approved') {
        throw Exception('Cannot edit approved entries');
      }
      
      await _db
          .collection('logbook_entries')
          .doc(entryId)
          .update(
            LogbookEntryModel.toFirestore(entry, null),
          );
    } catch (e) {
      throw Exception('Failed to update logbook entry: $e');
    }
  }
  
  /// Delete logbook entry (only if not approved)
  Future<void> deleteEntry(String entryId, String? status) async {
    try {
      if (status?.toLowerCase() == 'approved') {
        throw Exception('Cannot delete approved entries');
      }
      
      await _db.collection('logbook_entries').doc(entryId).delete();
    } catch (e) {
      throw Exception('Failed to delete logbook entry: $e');
    }
  }
  
  /// Get next day number for logbook
  Future<int> getNextDayNumber(String studentPath) async {
    try {
      final snapshot = await _db
          .collection('logbook_entries')
          .where('studentRefPath', isEqualTo: studentPath)
          .orderBy('dayNumber', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return 1;
      
      final lastEntry = LogbookEntryModel.fromFirestore(snapshot.docs.first, null);
      return lastEntry.dayNumber + 1;
    } catch (e) {
      return 1;
    }
  }
}