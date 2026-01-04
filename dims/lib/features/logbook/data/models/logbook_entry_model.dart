// lib/features/logbook/data/models/logbook_entry_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'logbook_entry_model.freezed.dart';
part 'logbook_entry_model.g.dart';

@freezed
class LogbookEntryModel with _$LogbookEntryModel {
  const factory LogbookEntryModel({
    String? studentRefPath,
    String? placementRefPath,
    required DateTime date,
    required int dayNumber,
    required String tasks,
    required double hoursWorked,
    double? latitude,
    double? longitude,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? photoUrl,
    String? status,
    String? supervisorComment,
    DateTime? approvedAt,
  }) = _LogbookEntryModel;

  factory LogbookEntryModel.fromJson(Map<String, dynamic> json) =>
      _$LogbookEntryModelFromJson(json);

  // Firestore converters
  static LogbookEntryModel fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    // Helper to parse DateTime from Timestamp or String
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    // Parse the date field
    final dateValue = data['date'];
    final parsedDate = parseDate(dateValue) ?? DateTime.now();

    return LogbookEntryModel(
      studentRefPath: data['studentRefPath'] as String?,
      placementRefPath: data['placementRefPath'] as String?,
      date: parsedDate,
      dayNumber: (data['dayNumber'] as num?)?.toInt() ?? 0,
      tasks: data['tasks'] as String? ?? '',
      hoursWorked: (data['hoursWorked'] as num?)?.toDouble() ?? 0.0,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      checkInTime: parseDate(data['checkInTime']),
      checkOutTime: parseDate(data['checkOutTime']),
      photoUrl: data['photoUrl'] as String?,
      status: data['status'] as String? ?? 'pending',
      supervisorComment: data['supervisorComment'] as String?,
      approvedAt: parseDate(data['approvedAt']),
    );
  }

  static Map<String, dynamic> toFirestore(
    LogbookEntryModel entry,
    SetOptions? options,
  ) {
    final json = <String, dynamic>{
      'studentRefPath': entry.studentRefPath,
      'placementRefPath': entry.placementRefPath,
      'date': Timestamp.fromDate(entry.date),
      'dayNumber': entry.dayNumber,
      'tasks': entry.tasks,
      'hoursWorked': entry.hoursWorked,
      'latitude': entry.latitude,
      'longitude': entry.longitude,
      'checkInTime': entry.checkInTime != null 
          ? Timestamp.fromDate(entry.checkInTime!) 
          : null,
      'checkOutTime': entry.checkOutTime != null 
          ? Timestamp.fromDate(entry.checkOutTime!) 
          : null,
      'photoUrl': entry.photoUrl,
      'status': entry.status ?? 'pending',
      'supervisorComment': entry.supervisorComment,
      'approvedAt': entry.approvedAt != null 
          ? Timestamp.fromDate(entry.approvedAt!) 
          : null,
    };

    // Remove null values
    json.removeWhere((key, value) => value == null);

    return json;
  }
}