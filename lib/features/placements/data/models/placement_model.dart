import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'placement_model.freezed.dart';
part 'placement_model.g.dart';

// ============================================================================
// PLACEMENT STATUS
// Reflects the real MUST workflow:
//   Student uploads letter → University Supervisor reviews → Internship begins
// ============================================================================

enum PlacementStatus {
  pendingSupervisorReview, // Letter uploaded, awaiting university supervisor approval
  approved,                // Supervisor approved — student can begin internship
  rejected,                // Supervisor rejected — student must resubmit with fixes
  active,                  // Internship in progress
  completed,               // Successfully completed
  cancelled,               // Cancelled before completion
  terminated,              // Ended early
  extended,                // Duration extended
}

@freezed
class PlacementModel with _$PlacementModel {
  const factory PlacementModel({
    required String id,
    required String studentId,
    required String companyId,

    // University supervisor (auto-assigned via algorithm)
    String? universitySupervisorId,

    // Company supervisor details (from acceptance letter)
    String? companySupervisorName,
    String? companySupervisorEmail,
    String? companySupervisorPhone,
    String? companySupervisorId,

    // Acceptance letter
    String? acceptanceLetterUrl,
    String? acceptanceLetterFileName,
    DateTime? letterUploadedAt,

    // ── Approval (now supervisor-driven, not admin) ──────────────────────────
    @Default(PlacementStatus.pendingSupervisorReview) PlacementStatus status,

    /// Feedback left by the university supervisor on rejection.
    /// Student sees this so they know what to fix before resubmitting.
    String? supervisorFeedback,

    DateTime? supervisorApprovedAt,
    DateTime? supervisorRejectedAt,

    // ── Internship timeline ──────────────────────────────────────────────────
    required String academicYear,
    DateTime? actualStartDate,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? actualEndDate,
    @Default(12) int totalWeeks,
    @Default(0) int weeksCompleted,
    @Default(0.0) double progressPercentage,

    // ── Additional info ──────────────────────────────────────────────────────
    String? studentNotes,
    String? remarks,

    // ── Timestamps ───────────────────────────────────────────────────────────
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PlacementModel;

  factory PlacementModel.fromJson(Map<String, dynamic> json) =>
      _$PlacementModelFromJson(json);

  // ── Firestore converters ─────────────────────────────────────────────────

  static PlacementModel fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data();
    if (data == null) throw Exception('Document data is null');

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    String? normalizeOptionalText(dynamic value) {
      if (value == null) return null;
      final trimmed = value.toString().trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    // ── Legacy migration: map old 'pending' status to new name ──────────────
    final rawStatus = data['status'] as String?;
    final migratedStatus =
        rawStatus == 'pending' ? 'pendingSupervisorReview' : rawStatus;

    return PlacementModel.fromJson({
      ...data,
      'id': doc.id,
      'status': migratedStatus,
      'companySupervisorName':
          normalizeOptionalText(data['companySupervisorName']),
      'companySupervisorEmail':
          normalizeOptionalText(data['companySupervisorEmail']),
      'companySupervisorPhone':
          normalizeOptionalText(data['companySupervisorPhone']),
      'companySupervisorId':
          normalizeOptionalText(data['companySupervisorId']),
      'letterUploadedAt':
          parseDate(data['letterUploadedAt'])?.toIso8601String(),
      'supervisorApprovedAt':
          parseDate(data['supervisorApprovedAt'])?.toIso8601String(),
      'supervisorRejectedAt':
          parseDate(data['supervisorRejectedAt'])?.toIso8601String(),
      'actualStartDate': parseDate(data['actualStartDate'])?.toIso8601String(),
      'startDate': parseDate(data['startDate'])?.toIso8601String(),
      'endDate': parseDate(data['endDate'])?.toIso8601String(),
      'actualEndDate': parseDate(data['actualEndDate'])?.toIso8601String(),
      'createdAt': parseDate(data['createdAt'])?.toIso8601String(),
      'updatedAt': parseDate(data['updatedAt'])?.toIso8601String(),
    });
  }

  static Map<String, dynamic> toFirestore(
    PlacementModel placement,
    SetOptions? options,
  ) {
    final json = placement.toJson();
    json.remove('id');

    void setTimestamp(String key, DateTime? dt) {
      if (dt != null) json[key] = Timestamp.fromDate(dt);
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

    return json;
  }
}

extension PlacementTimelineX on PlacementModel {
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
