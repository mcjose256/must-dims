import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../data/models/student_profile_model.dart';
import '../../placements/data/models/placement_model.dart';
import '../../companies/data/models/company_model.dart';
import '../../logbook/data/models/logbook_entry_model.dart';
import '../../supervisor/data/models/supervisor_profile_model.dart';
import '../data/models/internship_report_model.dart';
import '../../evaluations/data/models/evaluation_model.dart';

// ============================================================================
// STUDENT PROFILE PROVIDERS
// ============================================================================

final studentProfileProvider = StreamProvider<StudentProfileModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);

  final userId = authState.value?.uid;
  if (userId == null) return Stream.value(null);

  return firestore.collection('students').doc(userId).snapshots().map((doc) {
    if (!doc.exists || doc.data() == null) return null;
    return StudentProfileModel.fromFirestore(doc, null);
  }).handleError((e) {
    print('[StudentProfile] Error: $e');
    return null;
  });
});

final isProfileCompleteProvider = Provider<bool>((ref) {
  final profile = ref.watch(studentProfileProvider).value;
  if (profile == null) return false;

  return profile.registrationNumber.isNotEmpty &&
      profile.program.isNotEmpty &&
      profile.academicYear > 0;
});

// ============================================================================
// SUPERVISOR PROVIDER
// ============================================================================

final currentSupervisorProvider =
    StreamProvider<SupervisorProfileModel?>((ref) {
  final profile = ref.watch(studentProfileProvider).value;
  final firestore = ref.watch(firestoreProvider);

  final supervisorId = profile?.currentSupervisorId;
  if (supervisorId == null) {
    return Stream.value(null);
  }

  return firestore
      .collection('supervisorProfiles')
      .doc(supervisorId)
      .snapshots()
      .map((doc) {
    if (!doc.exists || doc.data() == null) return null;
    return SupervisorProfileModel.fromFirestore(doc, null);
  }).handleError((e) {
    print('[Supervisor] Error: $e');
    return null;
  });
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

  final companyId =
      placement?.companyId; // FIXED: Use companyId instead of companyRefPath
  if (companyId == null) return null;

  try {
    final doc =
        await firestore.collection('companies').doc(companyId).get(); // FIXED
    if (!doc.exists || doc.data() == null) return null;
    return CompanyModel.fromFirestore(doc, null);
  } catch (e) {
    print('[PlacementCompany] Error: $e');
    return null;
  }
});

// ============================================================================
// LOGBOOK PROVIDERS
// ============================================================================

final logbookEntriesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);

  final userId = authState.value?.uid;
  if (userId == null) return Stream.value([]);

  return firestore
      .collection('logbookEntries') // FIXED: Changed to logbookEntries
      .where('studentId', isEqualTo: userId) // FIXED: Use studentId
      .orderBy('weekStartDate', descending: true) // FIXED: Use weekStartDate
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) {
          try {
            final entry = LogbookEntryModel.fromFirestore(doc, null);
            return {'id': doc.id, 'entry': entry};
          } catch (e) {
            print('[LogbookProvider] Parse error on doc ${doc.id}: $e');
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }).handleError((error) => <Map<String, dynamic>>[]);
});

final pendingLogbookCountProvider = Provider<int>((ref) {
  final entries = ref.watch(logbookEntriesProvider).value ?? [];
  return entries.where((e) {
    final entry = e['entry'] as LogbookEntryModel?;
    final status = entry?.status.toLowerCase();
    return status != 'draft' &&
        status != 'rejected' &&
        entry?.isReviewedByUniversitySupervisor == false;
  }).length;
});

final approvedLogbookCountProvider = Provider<int>((ref) {
  final entries = ref.watch(logbookEntriesProvider).value ?? [];
  return entries.where((e) {
    final entry = e['entry'] as LogbookEntryModel?;
    return entry?.status.toLowerCase() == 'approved';
  }).length;
});

final finalInternshipReportProvider =
    StreamProvider<InternshipReportModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);
  final placement = ref.watch(currentPlacementProvider).value;

  final userId = authState.value?.uid;
  final placementId = placement?.id;
  if (userId == null || placementId == null) {
    return Stream.value(null);
  }

  return firestore
      .collection('internshipReports')
      .where('studentId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
    final reports = snapshot.docs
        .map((doc) => InternshipReportModel.fromFirestore(doc, null))
        .where((report) => report.placementId == placementId)
        .toList()
      ..sort((a, b) {
        final aDate = a.submittedAt ?? a.createdAt ?? DateTime(1970);
        final bDate = b.submittedAt ?? b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

    if (reports.isEmpty) return null;
    return reports.first;
  });
});

final currentPlacementEvaluationsProvider =
    StreamProvider<List<EvaluationModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final placement = ref.watch(currentPlacementProvider).value;

  if (placement == null) {
    return Stream.value(const <EvaluationModel>[]);
  }

  return firestore
      .collection('evaluations')
      .where('placementId', isEqualTo: placement.id)
      .snapshots()
      .map((snapshot) {
    final evaluations = snapshot.docs
        .map((doc) => EvaluationModel.fromFirestore(doc, null))
        .toList()
      ..sort((a, b) {
        final aDate = a.submittedAt ?? a.createdAt ?? DateTime(1970);
        final bDate = b.submittedAt ?? b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
    return evaluations;
  });
});

final currentPlacementEvaluationsByTypeProvider =
    Provider<Map<EvaluationType, EvaluationModel>>((ref) {
  final evaluations =
      ref.watch(currentPlacementEvaluationsProvider).value ?? [];
  final byType = <EvaluationType, EvaluationModel>{};

  for (final evaluation in evaluations) {
    byType.putIfAbsent(evaluation.evaluatorType, () => evaluation);
  }

  return byType;
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
            profile
                .copyWith(
                  updatedAt: DateTime.now(),
                  createdAt: profile.createdAt ?? DateTime.now(),
                )
                .toFirestore(),
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

final supervisorVisitControllerProvider = Provider((ref) {
  return SupervisorVisitController(ref);
});

class SupervisorVisitController {
  final Ref _ref;
  SupervisorVisitController(this._ref);

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  Future<void> updateVisit({
    required PlacementModel placement,
    required int visitNumber,
    required SupervisorVisitStatus status,
    DateTime? visitDate,
    String? notes,
  }) async {
    final normalizedNotes = notes?.trim();
    final updatedVisits = placement.supervisorVisitSlots.map((visit) {
      if (visit.visitNumber != visitNumber) return visit;

      return visit.copyWith(
        status: status,
        visitDate: status == SupervisorVisitStatus.visited
            ? visitDate ?? DateTime.now()
            : null,
        notes: status == SupervisorVisitStatus.pending
            ? null
            : (normalizedNotes == null || normalizedNotes.isEmpty
                ? null
                : normalizedNotes),
        updatedAt: DateTime.now(),
      );
    }).toList(growable: false);

    await _db.collection('placements').doc(placement.id).update({
      'supervisorVisits': updatedVisits
          .map(
            (visit) => <String, dynamic>{
              'visitNumber': visit.visitNumber,
              'status': visit.status.name,
              if (visit.visitDate != null)
                'visitDate': Timestamp.fromDate(visit.visitDate!),
              if (visit.notes != null && visit.notes!.trim().isNotEmpty)
                'notes': visit.notes!.trim(),
              if (visit.updatedAt != null)
                'updatedAt': Timestamp.fromDate(visit.updatedAt!),
            },
          )
          .toList(growable: false),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
      await _db.collection('logbookEntries').add(
            entry.copyWith(status: 'submitted').toFirestore(),
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
      await _db.collection('logbookEntries').doc(entryId).update(
            entry.toFirestore(),
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
      await _db.collection('logbookEntries').doc(entryId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getNextWeekNumber(String studentId) async {
    try {
      final snapshot = await _db
          .collection('logbookEntries')
          .where('studentId', isEqualTo: studentId)
          .orderBy('weekNumber', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return 1;

      final lastEntry =
          LogbookEntryModel.fromFirestore(snapshot.docs.first, null);
      return lastEntry.weekNumber + 1;
    } catch (e) {
      return 1;
    }
  }
}
