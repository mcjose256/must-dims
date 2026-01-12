import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../auth/data/models/user_model.dart';
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

  return profile.registrationNumber.isNotEmpty &&
      profile.program.isNotEmpty &&
      profile.academicYear > 0 &&
      profile.currentLevel.isNotEmpty;
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
  if (userId == null) {
    print('[LogbookProvider] No authenticated user → returning empty list');
    return Stream.value([]);
  }

  final studentPath = 'students/$userId';
  print('[LogbookProvider] Starting query for: $studentPath');

  return firestore
      .collection('logbook_entries')
      .where('studentRefPath', isEqualTo: studentPath)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        print('[LogbookProvider] Snapshot received — ${snapshot.docs.length} entries found');
        for (final doc in snapshot.docs) {
          print('  → Doc ${doc.id} | date: ${doc['date']} | status: ${doc['status']}');
        }

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
      .handleError((error, stack) {
        print('[LogbookProvider] Stream error: $error');
        print('Stack: $stack');
        return <Map<String, dynamic>>[];
      });
});

final pendingLogbookCountProvider = Provider<int>((ref) {
  final entries = ref.watch(logbookEntriesProvider).value ?? [];
  return entries.where((e) {
    final status = (e['entry'] as LogbookEntryModel?)?.status?.toLowerCase();
    return status == 'pending';
  }).length;
});

final approvedLogbookCountProvider = Provider<int>((ref) {
  final entries = ref.watch(logbookEntriesProvider).value ?? [];
  return entries.where((e) {
    final status = (e['entry'] as LogbookEntryModel?)?.status?.toLowerCase();
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
      await _db.collection('students').doc(userId).set(
            StudentProfileModel.toFirestore(
              profile.copyWith(
                updatedAt: DateTime.now(),
                createdAt: profile.createdAt ?? DateTime.now(),
              ),
              null,
            ),
            SetOptions(merge: true),
          );
      print('[ProfileController] Profile saved/updated for $userId');
    } catch (e) {
      print('[ProfileController] Save error: $e');
      rethrow;
    }
  }

  Future<void> updateProgress(String userId, double progress) async {
    try {
      await _db.collection('students').doc(userId).update({
        'progressPercentage': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[ProfileController] Progress updated: $progress%');
    } catch (e) {
      print('[ProfileController] Progress update error: $e');
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
      await _db.collection('logbook_entries').add(
            LogbookEntryModel.toFirestore(
              entry.copyWith(status: 'pending'),
              null,
            ),
          );
      print('[LogbookController] New entry submitted');
    } catch (e) {
      print('[LogbookController] Submit error: $e');
      rethrow;
    }
  }

  Future<void> updateEntry(String entryId, LogbookEntryModel entry) async {
    try {
      if (entry.status?.toLowerCase() == 'approved') {
        throw Exception('Cannot edit approved entries');
      }
      await _db.collection('logbook_entries').doc(entryId).update(
            LogbookEntryModel.toFirestore(entry, null),
          );
      print('[LogbookController] Entry $entryId updated');
    } catch (e) {
      print('[LogbookController] Update error: $e');
      rethrow;
    }
  }

  Future<void> deleteEntry(String entryId, String? status) async {
    try {
      if (status?.toLowerCase() == 'approved') {
        throw Exception('Cannot delete approved entries');
      }
      await _db.collection('logbook_entries').doc(entryId).delete();
      print('[LogbookController] Entry $entryId deleted');
    } catch (e) {
      print('[LogbookController] Delete error: $e');
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
      print('[LogbookController] Day number error: $e');
      return 1;
    }
  }
}