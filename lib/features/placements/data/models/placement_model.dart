import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'placement_model.freezed.dart';
part 'placement_model.g.dart';

enum PlacementStatus {
  pendingSupervisorReview,
  approved,
  rejected,
  active,
  completed,
  cancelled,
  terminated,
  extended,
}

enum SupervisorVisitStatus {
  pending,
  visited,
  notVisited,
}

DateTime? _parsePlacementDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String? _normalizePlacementText(dynamic value) {
  if (value == null) return null;
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<SupervisorVisitRecord> _parseSupervisorVisits(dynamic value) {
  if (value is! Iterable) {
    return const <SupervisorVisitRecord>[];
  }

  final visits = <SupervisorVisitRecord>[];
  var fallbackVisitNumber = 1;

  for (final rawVisit in value) {
    if (rawVisit is! Map) continue;

    final visitMap = Map<String, dynamic>.from(rawVisit);
    final visitNumber =
        (visitMap['visitNumber'] as num?)?.toInt() ?? fallbackVisitNumber;

    visits.add(
      SupervisorVisitRecord.fromJson({
        'visitNumber': visitNumber,
        'status': visitMap['status'] ?? SupervisorVisitStatus.pending.name,
        'visitDate':
            _parsePlacementDate(visitMap['visitDate'])?.toIso8601String(),
        'notes': _normalizePlacementText(visitMap['notes']),
        'updatedAt':
            _parsePlacementDate(visitMap['updatedAt'])?.toIso8601String(),
      }),
    );

    fallbackVisitNumber++;
  }

  visits.sort((a, b) => a.visitNumber.compareTo(b.visitNumber));
  return visits;
}

List<Map<String, dynamic>> _supervisorVisitsToFirestore(
  List<SupervisorVisitRecord> visits,
) {
  return visits.map((visit) {
    final json = visit.toJson();
    json['status'] = visit.status.name;

    if (visit.visitDate != null) {
      json['visitDate'] = Timestamp.fromDate(visit.visitDate!);
    } else {
      json.remove('visitDate');
    }

    if (visit.updatedAt != null) {
      json['updatedAt'] = Timestamp.fromDate(visit.updatedAt!);
    } else {
      json.remove('updatedAt');
    }

    final notes = visit.notes?.trim();
    if (notes == null || notes.isEmpty) {
      json.remove('notes');
    } else {
      json['notes'] = notes;
    }

    return json;
  }).toList(growable: false);
}

@freezed
class SupervisorVisitRecord with _$SupervisorVisitRecord {
  const factory SupervisorVisitRecord({
    required int visitNumber,
    @Default(SupervisorVisitStatus.pending) SupervisorVisitStatus status,
    DateTime? visitDate,
    String? notes,
    DateTime? updatedAt,
  }) = _SupervisorVisitRecord;

  factory SupervisorVisitRecord.fromJson(Map<String, dynamic> json) =>
      _$SupervisorVisitRecordFromJson(json);
}

@freezed
class PlacementModel with _$PlacementModel {
  const factory PlacementModel({
    required String id,
    required String studentId,
    required String companyId,
    String? universitySupervisorId,
    String? companySupervisorName,
    String? companySupervisorEmail,
    String? companySupervisorPhone,
    String? companySupervisorId,
    String? acceptanceLetterUrl,
    String? acceptanceLetterFileName,
    DateTime? letterUploadedAt,
    @Default(PlacementStatus.pendingSupervisorReview) PlacementStatus status,
    String? supervisorFeedback,
    DateTime? supervisorApprovedAt,
    DateTime? supervisorRejectedAt,
    required String academicYear,
    DateTime? actualStartDate,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? actualEndDate,
    @Default(12) int totalWeeks,
    @Default(0) int weeksCompleted,
    @Default(0.0) double progressPercentage,
    @Default(<SupervisorVisitRecord>[])
    List<SupervisorVisitRecord> supervisorVisits,
    String? studentNotes,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PlacementModel;

  factory PlacementModel.fromJson(Map<String, dynamic> json) =>
      _$PlacementModelFromJson(json);

  static PlacementModel fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data();
    if (data == null) throw Exception('Document data is null');

    final rawStatus = data['status'] as String?;
    final migratedStatus =
        rawStatus == 'pending' ? 'pendingSupervisorReview' : rawStatus;
    final supervisorVisits = _parseSupervisorVisits(data['supervisorVisits']);

    return PlacementModel.fromJson({
      ...data,
      'id': doc.id,
      'status': migratedStatus,
      'companySupervisorName':
          _normalizePlacementText(data['companySupervisorName']),
      'companySupervisorEmail':
          _normalizePlacementText(data['companySupervisorEmail']),
      'companySupervisorPhone':
          _normalizePlacementText(data['companySupervisorPhone']),
      'companySupervisorId':
          _normalizePlacementText(data['companySupervisorId']),
      'letterUploadedAt':
          _parsePlacementDate(data['letterUploadedAt'])?.toIso8601String(),
      'supervisorApprovedAt':
          _parsePlacementDate(data['supervisorApprovedAt'])?.toIso8601String(),
      'supervisorRejectedAt':
          _parsePlacementDate(data['supervisorRejectedAt'])?.toIso8601String(),
      'actualStartDate':
          _parsePlacementDate(data['actualStartDate'])?.toIso8601String(),
      'startDate': _parsePlacementDate(data['startDate'])?.toIso8601String(),
      'endDate': _parsePlacementDate(data['endDate'])?.toIso8601String(),
      'actualEndDate':
          _parsePlacementDate(data['actualEndDate'])?.toIso8601String(),
      'supervisorVisits': supervisorVisits
          .map((visit) => visit.toJson())
          .toList(growable: false),
      'createdAt': _parsePlacementDate(data['createdAt'])?.toIso8601String(),
      'updatedAt': _parsePlacementDate(data['updatedAt'])?.toIso8601String(),
    });
  }

  static Map<String, dynamic> toFirestore(
    PlacementModel placement,
    SetOptions? options,
  ) {
    final json = placement.toJson();
    json.remove('id');

    void setTimestamp(String key, DateTime? value) {
      if (value != null) {
        json[key] = Timestamp.fromDate(value);
      }
    }

    setTimestamp('letterUploadedAt', placement.letterUploadedAt);
    setTimestamp('supervisorApprovedAt', placement.supervisorApprovedAt);
    setTimestamp('supervisorRejectedAt', placement.supervisorRejectedAt);
    setTimestamp('actualStartDate', placement.actualStartDate);
    setTimestamp('startDate', placement.startDate);
    setTimestamp('endDate', placement.endDate);
    setTimestamp('actualEndDate', placement.actualEndDate);
    setTimestamp('createdAt', placement.createdAt);
    setTimestamp('updatedAt', placement.updatedAt);

    json['status'] = placement.status.name;
    json['supervisorVisits'] =
        _supervisorVisitsToFirestore(placement.supervisorVisitSlots);

    return json;
  }
}

extension PlacementTimelineX on PlacementModel {
  List<SupervisorVisitRecord> get supervisorVisitSlots {
    final visitsByNumber = {
      for (final visit in supervisorVisits) visit.visitNumber: visit,
    };

    return List<SupervisorVisitRecord>.generate(
      2,
      (index) =>
          visitsByNumber[index + 1] ??
          SupervisorVisitRecord(visitNumber: index + 1),
      growable: false,
    );
  }

  int get completedSupervisorVisitCount => supervisorVisitSlots
      .where((visit) => visit.status == SupervisorVisitStatus.visited)
      .length;

  bool get hasActiveCountdownReminder =>
      status == PlacementStatus.active || status == PlacementStatus.extended;

  bool get isFinalAssessmentUnlocked {
    if (status == PlacementStatus.completed) {
      return true;
    }

    if (weeksCompleted >= totalWeeks && totalWeeks > 0) {
      return true;
    }

    final end = effectiveReminderEndDate;
    if (end == null) {
      return false;
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final endDateOnly = DateTime(end.year, end.month, end.day);
    return !todayDate.isBefore(endDateOnly);
  }

  DateTime? get effectiveReminderStartDate => actualStartDate ?? startDate;

  DateTime? get effectiveReminderEndDate {
    if (actualEndDate != null) {
      return actualEndDate;
    }
    if (endDate != null) {
      return endDate;
    }

    final start = effectiveReminderStartDate;
    if (start == null) {
      return null;
    }

    return start.add(Duration(days: totalWeeks * 7));
  }

  int? get internshipDaysLeft {
    final end = effectiveReminderEndDate;
    if (end == null) {
      return null;
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final endDateOnly = DateTime(end.year, end.month, end.day);
    return endDateOnly.difference(todayDate).inDays;
  }

  int? get internshipDaysElapsed {
    final start = effectiveReminderStartDate;
    if (start == null) {
      return null;
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final startDateOnly = DateTime(start.year, start.month, start.day);
    return todayDate.difference(startDateOnly).inDays;
  }
}
