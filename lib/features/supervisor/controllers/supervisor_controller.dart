// lib/features/supervisor/controllers/supervisor_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logbook/data/models/logbook_entry_model.dart';
import '../../evaluations/data/models/evaluation_model.dart';
import '../../placements/data/models/placement_model.dart';
import '../data/models/supervisor_profile_model.dart';

final supervisorControllerProvider =
    Provider((ref) => SupervisorController());

class SupervisorController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // PLACEMENT LETTER REVIEW
  // ============================================================================

  /// Approves a student's acceptance letter.
  /// Sets internshipStatus to 'approved' — matches StudentInternshipStatus.approved
  Future<void> approvePlacement({
    required String placementId,
    required String studentId,
    required String supervisorId,
  }) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('placements').doc(placementId),
      {
        'status': PlacementStatus.approved.name,
        'supervisorFeedback': null,
        'supervisorApprovedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    // ── 'approved' now exists in StudentInternshipStatus enum ───────────
    batch.update(
      _firestore.collection('students').doc(studentId),
      {
        'internshipStatus': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  /// Rejects a student's acceptance letter with mandatory feedback.
  /// Sets internshipStatus to 'rejected' — matches StudentInternshipStatus.rejected
  Future<void> rejectPlacement({
    required String placementId,
    required String studentId,
    required String supervisorId,
    required String feedback,
  }) async {
    if (feedback.trim().isEmpty) {
      throw Exception(
          'Feedback is required when rejecting a placement letter.');
    }

    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('placements').doc(placementId),
      {
        'status': PlacementStatus.rejected.name,
        'supervisorFeedback': feedback.trim(),
        'supervisorRejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    // ── 'rejected' now exists in StudentInternshipStatus enum ───────────
    batch.update(
      _firestore.collection('students').doc(studentId),
      {
        'internshipStatus': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  // ============================================================================
  // PENDING LETTER REVIEWS STREAM
  // ============================================================================

  Stream<List<PlacementModel>> getPendingLetterReviews(String supervisorId) {
    return _firestore
        .collection('placements')
        .where('universitySupervisorId', isEqualTo: supervisorId)
        .where('status',
            isEqualTo: PlacementStatus.pendingSupervisorReview.name)
        .orderBy('letterUploadedAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PlacementModel.fromFirestore(doc, null))
            .toList());
  }

  // ============================================================================
  // LOGBOOK REVIEW
  // ============================================================================

  Future<void> approveLogbookEntry(String entryId, String comment) async {
    await _firestore.collection('logbook_entries').doc(entryId).update({
      'status': 'approved',
      'supervisorComment': comment,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectLogbookEntry(String entryId, String comment) async {
    await _firestore.collection('logbook_entries').doc(entryId).update({
      'status': 'rejected',
      'supervisorComment': comment,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================================
  // EVALUATIONS
  // ============================================================================

  Future<void> submitEvaluation(EvaluationModel eval) async {
    await _firestore.collection('evaluations').add({
      'studentId': eval.studentId,
      'placementId': eval.placementId,
      'evaluatorType': eval.evaluatorType.name,
      'evaluatorId': eval.evaluatorId,
      'evaluatorName': eval.evaluatorName,
      'finalMarks': eval.finalMarks,
      'technicalSkillsRating': eval.technicalSkillsRating,
      'workEthicRating': eval.workEthicRating,
      'communicationRating': eval.communicationRating,
      'problemSolvingRating': eval.problemSolvingRating,
      'initiativeRating': eval.initiativeRating,
      'teamworkRating': eval.teamworkRating,
      'daysPresent': eval.daysPresent,
      'daysAbsent': eval.daysAbsent,
      'totalWorkingDays': eval.totalWorkingDays,
      'overallComments': eval.overallComments,
      'strengthsHighlighted': eval.strengthsHighlighted,
      'areasForImprovement': eval.areasForImprovement,
      'recommendationsForFutureInterns': eval.recommendationsForFutureInterns,
      'wouldHireAgain': eval.wouldHireAgain,
      'hiringConditions': eval.hiringConditions,
      'createdAt': FieldValue.serverTimestamp(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================================
  // PROFILE
  // ============================================================================

  Future<void> updateProfile(SupervisorProfileModel profile) async {
    try {
      await _firestore
          .collection('supervisorProfiles')
          .doc(profile.uid)
          .update(profile.toJson());
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // ============================================================================
  // LOGBOOK STREAMS
  // ============================================================================

  Stream<List<LogbookEntryModel>> getPendingLogbooks(String supervisorId) {
    return _firestore
        .collection('logbook_entries')
        .where('supervisorId', isEqualTo: supervisorId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => LogbookEntryModel.fromFirestore(doc, null))
            .toList());
  }
}