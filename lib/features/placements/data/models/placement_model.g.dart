// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'placement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlacementModelImpl _$$PlacementModelImplFromJson(Map<String, dynamic> json) =>
    _$PlacementModelImpl(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      companyId: json['companyId'] as String,
      universitySupervisorId: json['universitySupervisorId'] as String?,
      companySupervisorName: json['companySupervisorName'] as String?,
      companySupervisorEmail: json['companySupervisorEmail'] as String?,
      companySupervisorPhone: json['companySupervisorPhone'] as String?,
      companySupervisorId: json['companySupervisorId'] as String?,
      acceptanceLetterUrl: json['acceptanceLetterUrl'] as String?,
      acceptanceLetterFileName: json['acceptanceLetterFileName'] as String?,
      letterUploadedAt: json['letterUploadedAt'] == null
          ? null
          : DateTime.parse(json['letterUploadedAt'] as String),
      status: $enumDecodeNullable(_$PlacementStatusEnumMap, json['status']) ??
          PlacementStatus.pendingSupervisorReview,
      supervisorFeedback: json['supervisorFeedback'] as String?,
      supervisorApprovedAt: json['supervisorApprovedAt'] == null
          ? null
          : DateTime.parse(json['supervisorApprovedAt'] as String),
      supervisorRejectedAt: json['supervisorRejectedAt'] == null
          ? null
          : DateTime.parse(json['supervisorRejectedAt'] as String),
      academicYear: json['academicYear'] as String,
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      actualEndDate: json['actualEndDate'] == null
          ? null
          : DateTime.parse(json['actualEndDate'] as String),
      totalWeeks: (json['totalWeeks'] as num?)?.toInt() ?? 12,
      weeksCompleted: (json['weeksCompleted'] as num?)?.toInt() ?? 0,
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      studentNotes: json['studentNotes'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$PlacementModelImplToJson(
        _$PlacementModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'companyId': instance.companyId,
      'universitySupervisorId': instance.universitySupervisorId,
      'companySupervisorName': instance.companySupervisorName,
      'companySupervisorEmail': instance.companySupervisorEmail,
      'companySupervisorPhone': instance.companySupervisorPhone,
      'companySupervisorId': instance.companySupervisorId,
      'acceptanceLetterUrl': instance.acceptanceLetterUrl,
      'acceptanceLetterFileName': instance.acceptanceLetterFileName,
      'letterUploadedAt': instance.letterUploadedAt?.toIso8601String(),
      'status': _$PlacementStatusEnumMap[instance.status]!,
      'supervisorFeedback': instance.supervisorFeedback,
      'supervisorApprovedAt': instance.supervisorApprovedAt?.toIso8601String(),
      'supervisorRejectedAt': instance.supervisorRejectedAt?.toIso8601String(),
      'academicYear': instance.academicYear,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'actualEndDate': instance.actualEndDate?.toIso8601String(),
      'totalWeeks': instance.totalWeeks,
      'weeksCompleted': instance.weeksCompleted,
      'progressPercentage': instance.progressPercentage,
      'studentNotes': instance.studentNotes,
      'remarks': instance.remarks,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$PlacementStatusEnumMap = {
  PlacementStatus.pendingSupervisorReview: 'pendingSupervisorReview',
  PlacementStatus.approved: 'approved',
  PlacementStatus.rejected: 'rejected',
  PlacementStatus.active: 'active',
  PlacementStatus.completed: 'completed',
  PlacementStatus.cancelled: 'cancelled',
  PlacementStatus.terminated: 'terminated',
  PlacementStatus.extended: 'extended',
};
