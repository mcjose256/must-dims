// lib/features/logbook/data/models/logbook_entry_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'logbook_entry_model.freezed.dart';
part 'logbook_entry_model.g.dart';

@freezed
class LogbookEntryModel with _$LogbookEntryModel {
  const factory LogbookEntryModel({
    String? id, // document ID - useful when editing
    required String studentRefPath,
    required String placementRefPath,
    required DateTime date,
    required int dayNumber,
    required String tasksPerformed, // renamed for better readability
    String? challenges,
    String? skillsLearned,
    required double hoursWorked,

    @Default('draft') String status, // draft → submitted → pending → approved/rejected
    DateTime? createdAt,
    DateTime? updatedAt,

    // GPS / check-in/out fields (for phase 2)
    double? latitude,
    double? longitude,
    DateTime? checkInTime,
    DateTime? checkOutTime,

    // Supervisor feedback fields
    String? photoUrl, // optional proof photo
    String? supervisorComment,
    DateTime? approvedAt,
  }) = _LogbookEntryModel;

  factory LogbookEntryModel.fromJson(Map<String, dynamic> json) =>
      _$LogbookEntryModelFromJson(json);

  // ── Firestore converters ────────────────────────────────────────────────────
  factory LogbookEntryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data() ?? {};

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return LogbookEntryModel(
      id: doc.id,
      studentRefPath: data['studentRefPath'] as String? ?? '',
      placementRefPath: data['placementRefPath'] as String? ?? '',
      date: parseDate(data['date']) ?? DateTime.now(),
      dayNumber: (data['dayNumber'] as num?)?.toInt() ?? 0,
      tasksPerformed: data['tasksPerformed'] as String? ?? '',
      challenges: data['challenges'] as String?,
      skillsLearned: data['skillsLearned'] as String?,
      hoursWorked: (data['hoursWorked'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'draft',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      checkInTime: parseDate(data['checkInTime']),
      checkOutTime: parseDate(data['checkOutTime']),
      photoUrl: data['photoUrl'] as String?,
      supervisorComment: data['supervisorComment'] as String?,
      approvedAt: parseDate(data['approvedAt']),
    );
  }

  static Map<String, dynamic> toFirestore(
    LogbookEntryModel entry, [
    SetOptions? options,
  ]) {
    final json = {
      'studentRefPath': entry.studentRefPath,
      'placementRefPath': entry.placementRefPath,
      'date': Timestamp.fromDate(entry.date),
      'dayNumber': entry.dayNumber,
      'tasksPerformed': entry.tasksPerformed,
      'challenges': entry.challenges,
      'skillsLearned': entry.skillsLearned,
      'hoursWorked': entry.hoursWorked,
      'status': entry.status,
      'createdAt': entry.createdAt != null
          ? Timestamp.fromDate(entry.createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (entry.latitude != null) 'latitude': entry.latitude,
      if (entry.longitude != null) 'longitude': entry.longitude,
      if (entry.checkInTime != null)
        'checkInTime': Timestamp.fromDate(entry.checkInTime!),
      if (entry.checkOutTime != null)
        'checkOutTime': Timestamp.fromDate(entry.checkOutTime!),
      'photoUrl': entry.photoUrl,
      'supervisorComment': entry.supervisorComment,
      if (entry.approvedAt != null)
        'approvedAt': Timestamp.fromDate(entry.approvedAt!),
    }..removeWhere((key, value) => value == null);

    return json;
  }
}