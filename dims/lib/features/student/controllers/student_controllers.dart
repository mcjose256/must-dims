import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../data/models/student_profile_model.dart';
import '../../placements/data/models/placement_model.dart';
import '../../companies/data/models/company_model.dart';
import '../../logbook/data/models/logbook_entry_model.dart';

// ============================================================================
// STUDENT PROFILE PROVIDERS
// ============================================================================

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
        if (!doc.exists || doc.data() == null) return null;
        return StudentProfileModel.fromFirestore(doc, null);
      })
      .handleError((e) {
        print('[StudentProfile] Error: $e');
        return null;
      });
});

final isProfileCompleteProvider = Provider<bool>((ref) {
  final profile = ref.watch(studentProfileProvider).value;
  if (profile == null) return false;

  // Matching fields against StudentProfileModel
  return profile.registrationNumber.isNotEmpty &&
      profile.program.isNotEmpty &&
      profile.academicYear > 0;
});

// ============================================================================
// PLACEMENT PROVIDERS
// ============================================================================

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
        if (!doc.exists || doc.data() == null) return null;
        return PlacementModel.fromFirestore(doc, null);
      });
});

final placementCompanyProvider = FutureProvider<CompanyModel?>((ref) async {
  final placement = ref.watch(currentPlacementProvider).value;
  final firestore = ref.watch(firestoreProvider);

  final companyPath = placement?.companyRefPath;
  if (companyPath == null) return null;

  try {
    final doc = await firestore.doc(companyPath).get();
    if (!doc.exists || doc.data() == null) return null;
    return CompanyModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>, null);
  } catch (e) {
    print('[PlacementCompany] Error: $e');
    return null;
  }
});

// ============================================================================
// LOGBOOK PROVIDERS — Debug-friendly & robust
// ============================================================================

final logbookEntriesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);

  final userId = authState.value?.uid;
  if (userId == null) return Stream.value([]);

  final studentPath = 'students/$userId';

  return firestore
      .collection('logbook_entries')
      .where('studentRefPath', isEqualTo: studentPath)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            final entry = LogbookEntryModel.fromFirestore(doc, null);
            return {'id': doc.id, 'entry': entry};
          } catch (e) {
            print('[LogbookProvider] Parse error on doc ${doc.id}: $e');
            return null;
          }
        }).whereType<Map<String, dynamic>>().toList();
      })
      .handleError((error) => <Map<String, dynamic>>[]);
});

final pendingLogbookCountProvider = Provider<int>((ref) {
  final entries = ref.watch(logbookEntriesProvider).value ?? [];
  return entries.where((e) {
    final status = (e['entry'] as LogbookEntryModel?)?.status.toLowerCase();
    return status == 'pending';
  }).length;
});

final approvedLogbookCountProvider = Provider<int>((ref) {
  final entries = ref.watch(logbookEntriesProvider).value ?? [];
  return entries.where((e) {
    final status = (e['entry'] as LogbookEntryModel?)?.status.toLowerCase();
    return status == 'approved';
  }).length;
});

// ============================================================================
// CONTROLLERS
// ============================================================================

final studentProfileControllerProvider = Provider((ref) {
  return StudentProfileController(ref);
});

class StudentProfileController {
  final Ref _ref;
  StudentProfileController(this._ref);

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  Future<void> saveProfile(String userId, StudentProfileModel profile) async {
    try {
      // FIXED: Removed extra null argument
      await _db.collection('students').doc(userId).set(
            StudentProfileModel.toFirestore(
              profile.copyWith(
                updatedAt: DateTime.now(),
                createdAt: profile.createdAt ?? DateTime.now(),
              ),
            ),
            SetOptions(merge: true),
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProgress(String userId, double progress) async {
    try {
      await _db.collection('students').doc(userId).update({
        'progressPercentage': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}

final logbookControllerProvider = Provider((ref) {
  return LogbookController(ref);
});

class LogbookController {
  final Ref _ref;
  LogbookController(this._ref);

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  Future<void> submitEntry(LogbookEntryModel entry) async {
    try {
      // FIXED: Removed extra null argument
      await _db.collection('logbook_entries').add(
            LogbookEntryModel.toFirestore(
              entry.copyWith(status: 'pending'),
            ),
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEntry(String entryId, LogbookEntryModel entry) async {
    try {
      if (entry.status.toLowerCase() == 'approved') {
        throw Exception('Cannot edit approved entries');
      }
      // FIXED: Removed extra null argument
      await _db.collection('logbook_entries').doc(entryId).update(
            LogbookEntryModel.toFirestore(entry),
          );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEntry(String entryId, String? status) async {
    try {
      if (status?.toLowerCase() == 'approved') {
        throw Exception('Cannot delete approved entries');
      }
      await _db.collection('logbook_entries').doc(entryId).delete();
    } catch (e) {
      rethrow;
    }
  }

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