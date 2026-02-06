import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'logbook_entry_model.freezed.dart';
part 'logbook_entry_model.g.dart';

@freezed
class LogbookEntryModel with _$LogbookEntryModel {
  const factory LogbookEntryModel({
    String? id, 
    required String studentRefPath,
    required String placementRefPath,
    required String supervisorId, 
    required DateTime date,
    required int dayNumber,
    required String tasksPerformed,
    String? challenges,
    String? skillsLearned,
    required double hoursWorked,
    @Default('pending') String status, 
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    String? photoUrl, // Ensure this is exactly as written here
    String? supervisorComment,
    DateTime? approvedAt,
  }) = _LogbookEntryModel;

  factory LogbookEntryModel.fromJson(Map<String, dynamic> json) =>
      _$LogbookEntryModelFromJson(json);

  factory LogbookEntryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data() ?? {};

    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return LogbookEntryModel.fromJson({
      ...data,
      'id': doc.id,
      'date': parseDate(data['date'])?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'createdAt': parseDate(data['createdAt'])?.toIso8601String(),
      'updatedAt': parseDate(data['updatedAt'])?.toIso8601String(),
      'approvedAt': parseDate(data['approvedAt'])?.toIso8601String(),
    });
  }

  static Map<String, dynamic> toFirestore(LogbookEntryModel entry) {
    return {
      'studentRefPath': entry.studentRefPath,
      'placementRefPath': entry.placementRefPath,
      'supervisorId': entry.supervisorId,
      'date': Timestamp.fromDate(entry.date),
      'dayNumber': entry.dayNumber,
      'tasksPerformed': entry.tasksPerformed,
      'challenges': entry.challenges,
      'skillsLearned': entry.skillsLearned,
      'hoursWorked': entry.hoursWorked,
      'status': entry.status,
      'latitude': entry.latitude,
      'longitude': entry.longitude,
      'photoUrl': entry.photoUrl, // This will now be recognized
      'supervisorComment': entry.supervisorComment,
      // FIXED: changed server_timestamp to serverTimestamp
      'createdAt': entry.createdAt != null ? Timestamp.fromDate(entry.createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (entry.approvedAt != null) 'approvedAt': Timestamp.fromDate(entry.approvedAt!),
    };
  }
}