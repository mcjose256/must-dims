import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import Auth and Core
import '../../../auth/controllers/auth_controller.dart';
// Fix: Use ONLY this one import for the supervisor model
import '../../data/models/supervisor_profile_model.dart';
import '../../../student/data/models/student_profile_model.dart';
import '../../../logbook/data/models/logbook_entry_model.dart';
import '../../../student/data/models/internship_report_model.dart';
import '../../../placements/data/models/placement_model.dart';

// Supervisor's own profile
// Explicitly typed as <SupervisorProfileModel?>
final supervisorProfileProvider = StreamProvider<SupervisorProfileModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.watch(firestoreProvider);

  final uid = authState.value?.uid;
  if (uid == null) return Stream.value(null);

  return firestore
      .collection('supervisorProfiles')
      .doc(uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        return SupervisorProfileModel.fromFirestore(doc, null);
      });
});

// Students assigned to this supervisor
final assignedStudentsProvider = StreamProvider<List<StudentProfileModel>>((ref) {
  final profile = ref.watch(supervisorProfileProvider).value;
  final firestore = ref.watch(firestoreProvider);

  final uid = profile?.uid;
  if (uid == null) return Stream.value([]);

  return firestore
      .collection('students')
      .where('currentSupervisorId', isEqualTo: uid)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => StudentProfileModel.fromFirestore(doc, null)).toList();
      });
});

class SupervisedStudentProgress {
  final StudentProfileModel student;
  final PlacementModel? placement;

  const SupervisedStudentProgress({
    required this.student,
    required this.placement,
  });

  double get progressPercent {
    final placementProgress = placement?.progressPercentage;
    if (placementProgress != null) {
      return placementProgress <= 1 ? placementProgress * 100 : placementProgress;
    }
    return student.progressPercentage;
  }

  bool get isCompleted =>
      placement?.status == PlacementStatus.completed ||
      student.internshipStatus == StudentInternshipStatus.completed;

  bool get isInProgress =>
      placement?.status == PlacementStatus.active ||
      placement?.status == PlacementStatus.extended ||
      student.internshipStatus == StudentInternshipStatus.inProgress;

  bool get isAwaitingStart =>
      placement?.status == PlacementStatus.approved ||
      student.internshipStatus == StudentInternshipStatus.approved;
}

final supervisedStudentProgressProvider =
    StreamProvider<List<SupervisedStudentProgress>>((ref) {
  final profile = ref.watch(supervisorProfileProvider).value;
  final firestore = ref.watch(firestoreProvider);

  final uid = profile?.uid;
  if (uid == null) return Stream.value([]);

  return firestore
      .collection('students')
      .where('currentSupervisorId', isEqualTo: uid)
      .snapshots()
      .asyncMap((snapshot) async {
        final items = await Future.wait(
          snapshot.docs.map((doc) async {
            final student = StudentProfileModel.fromFirestore(doc, null);
            PlacementModel? placement;
            final placementId = student.currentPlacementId;

            if (placementId != null && placementId.trim().isNotEmpty) {
              final placementDoc = await firestore
                  .collection('placements')
                  .doc(placementId)
                  .get();
              if (placementDoc.exists && placementDoc.data() != null) {
                placement = PlacementModel.fromFirestore(placementDoc, null);
              }
            }

            return SupervisedStudentProgress(
              student: student,
              placement: placement,
            );
          }),
        );

        items.sort((a, b) {
          final aWeight = a.isInProgress
              ? 0
              : a.isAwaitingStart
                  ? 1
                  : a.isCompleted
                      ? 2
                      : 3;
          final bWeight = b.isInProgress
              ? 0
              : b.isAwaitingStart
                  ? 1
                  : b.isCompleted
                      ? 2
                      : 3;

          if (aWeight != bWeight) {
            return aWeight.compareTo(bWeight);
          }

          return a.student.fullName.toLowerCase().compareTo(
                b.student.fullName.toLowerCase(),
              );
        });

        return items;
      });
});

// Pending logbooks for the current supervisor
final pendingLogbooksProvider = StreamProvider<List<LogbookEntryModel>>((ref) {
  final profile = ref.watch(supervisorProfileProvider).value;
  final assignedStudentIds = profile?.assignedStudentIds ?? const <String>[];

  if (assignedStudentIds.isEmpty) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('logbookEntries')
      .where('isReviewedByUniversitySupervisor', isEqualTo: false)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => LogbookEntryModel.fromFirestore(doc, null))
            .where((entry) {
              final status = entry.status.toLowerCase();
              return assignedStudentIds.contains(entry.studentId) &&
                  status != 'draft' &&
                  status != 'rejected';
            })
            .toList()
          ..sort((a, b) => b.weekNumber.compareTo(a.weekNumber));
      });
});

final pendingSummaryReviewsCountProvider = Provider<int>((ref) {
  final entries = ref.watch(pendingLogbooksProvider).value ?? [];
  return entries.length;
});

final pendingFinalReportsProvider = StreamProvider<List<InternshipReportModel>>((ref) {
  final profile = ref.watch(supervisorProfileProvider).value;
  final assignedStudentIds = profile?.assignedStudentIds ?? const <String>[];

  if (assignedStudentIds.isEmpty) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('internshipReports')
      .where('status', isEqualTo: 'submitted')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => InternshipReportModel.fromFirestore(doc, null))
            .where((report) => assignedStudentIds.contains(report.studentId))
            .toList()
          ..sort((a, b) {
            final aDate = a.submittedAt ?? a.createdAt ?? DateTime(1970);
            final bDate = b.submittedAt ?? b.createdAt ?? DateTime(1970);
            return bDate.compareTo(aDate);
          });
      });
});
