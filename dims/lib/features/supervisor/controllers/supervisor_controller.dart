import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logbook/data/models/logbook_entry_model.dart';
import '../../evaluations/data/models/evaluation_model.dart';
import '../data/models/supervisor_profile_model.dart';

final supervisorControllerProvider = Provider((ref) => SupervisorController());

class SupervisorController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Approve Logbook
  Future<void> approveLogbookEntry(String entryId, String comment) async {
    await _firestore.collection('logbook_entries').doc(entryId).update({
      'status': 'approved',
      'supervisorComment': comment,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }
// Update supervisor profile
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
  // Reject Logbook
  Future<void> rejectLogbookEntry(String entryId, String comment) async {
    await _firestore.collection('logbook_entries').doc(entryId).update({
      'status': 'rejected',
      'supervisorComment': comment,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Submit Grade/Evaluation
  Future<void> submitEvaluation(EvaluationModel eval) async {
    await _firestore.collection('evaluations').add({
      'studentId': eval.studentId,
      'supervisorId': eval.supervisorId,
      'performanceScore': eval.performanceScore,
      'attendanceScore': eval.attendanceScore,
      'communicationScore': eval.communicationScore,
      'comments': eval.comments,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream for Dashboard
  Stream<List<LogbookEntryModel>> getPendingLogbooks(String supervisorId) {
    return _firestore
        .collection('logbook_entries')
        .where('supervisorId', isEqualTo: supervisorId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => LogbookEntryModel.fromFirestore(doc, null)).toList());
  }
}