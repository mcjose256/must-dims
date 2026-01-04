// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StudentProfileModelImpl _$$StudentProfileModelImplFromJson(
        Map<String, dynamic> json) =>
    _$StudentProfileModelImpl(
      registrationNumber: json['registrationNumber'] as String,
      program: json['program'] as String,
      academicYear: (json['academicYear'] as num).toInt(),
      currentLevel: json['currentLevel'] as String,
      currentPlacementId: json['currentPlacementId'] as String?,
      currentSupervisorId: json['currentSupervisorId'] as String?,
      internshipStatus: $enumDecodeNullable(
              _$StudentInternshipStatusEnumMap, json['internshipStatus']) ??
          StudentInternshipStatus.notStarted,
      internshipStartDate: json['internshipStartDate'] == null
          ? null
          : DateTime.parse(json['internshipStartDate'] as String),
      internshipEndDate: json['internshipEndDate'] == null
          ? null
          : DateTime.parse(json['internshipEndDate'] as String),
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] as String?,
    );

Map<String, dynamic> _$$StudentProfileModelImplToJson(
        _$StudentProfileModelImpl instance) =>
    <String, dynamic>{
      'registrationNumber': instance.registrationNumber,
      'program': instance.program,
      'academicYear': instance.academicYear,
      'currentLevel': instance.currentLevel,
      'currentPlacementId': instance.currentPlacementId,
      'currentSupervisorId': instance.currentSupervisorId,
      'internshipStatus':
          _$StudentInternshipStatusEnumMap[instance.internshipStatus]!,
      'internshipStartDate': instance.internshipStartDate?.toIso8601String(),
      'internshipEndDate': instance.internshipEndDate?.toIso8601String(),
      'progressPercentage': instance.progressPercentage,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'createdBy': instance.createdBy,
    };

const _$StudentInternshipStatusEnumMap = {
  StudentInternshipStatus.notStarted: 'notStarted',
  StudentInternshipStatus.inProgress: 'inProgress',
  StudentInternshipStatus.awaitingApproval: 'awaitingApproval',
  StudentInternshipStatus.completed: 'completed',
  StudentInternshipStatus.deferred: 'deferred',
  StudentInternshipStatus.terminated: 'terminated',
};
