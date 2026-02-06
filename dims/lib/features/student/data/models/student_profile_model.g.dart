// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StudentProfileModelImpl _$$StudentProfileModelImplFromJson(
        Map<String, dynamic> json) =>
    _$StudentProfileModelImpl(
      uid: json['uid'] as String,
      registrationNumber: json['registrationNumber'] as String,
      program: json['program'] as String,
      academicYear: (json['academicYear'] as num?)?.toInt() ?? 1,
      currentLevel: json['currentLevel'] as String? ?? '',
      currentPlacementId: json['currentPlacementId'] as String?,
      currentSupervisorId: json['currentSupervisorId'] as String?,
      status: json['status'] as String? ?? 'active',
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      internshipStatus: $enumDecodeNullable(
              _$StudentInternshipStatusEnumMap, json['internshipStatus']) ??
          StudentInternshipStatus.notStarted,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$StudentProfileModelImplToJson(
        _$StudentProfileModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'registrationNumber': instance.registrationNumber,
      'program': instance.program,
      'academicYear': instance.academicYear,
      'currentLevel': instance.currentLevel,
      'currentPlacementId': instance.currentPlacementId,
      'currentSupervisorId': instance.currentSupervisorId,
      'status': instance.status,
      'progressPercentage': instance.progressPercentage,
      'internshipStatus':
          _$StudentInternshipStatusEnumMap[instance.internshipStatus]!,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$StudentInternshipStatusEnumMap = {
  StudentInternshipStatus.notStarted: 'notStarted',
  StudentInternshipStatus.inProgress: 'inProgress',
  StudentInternshipStatus.completed: 'completed',
  StudentInternshipStatus.awaitingApproval: 'awaitingApproval',
  StudentInternshipStatus.deferred: 'deferred',
  StudentInternshipStatus.terminated: 'terminated',
};
