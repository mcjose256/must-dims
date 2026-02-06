// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supervisor_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SupervisorProfileModelImpl _$$SupervisorProfileModelImplFromJson(
        Map<String, dynamic> json) =>
    _$SupervisorProfileModelImpl(
      uid: json['uid'] as String,
      fullName: json['fullName'] as String? ?? 'Unknown Supervisor',
      email: json['email'] as String? ?? 'No email',
      department: json['department'] as String? ?? 'No department',
      programSpecialties: (json['programSpecialties'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      maxStudents: (json['maxStudents'] as num?)?.toInt() ?? 12,
      currentLoad: (json['currentLoad'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      phoneNumber: json['phoneNumber'] as String?,
      assignedStudentIds: (json['assignedStudentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SupervisorProfileModelImplToJson(
        _$SupervisorProfileModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'fullName': instance.fullName,
      'email': instance.email,
      'department': instance.department,
      'programSpecialties': instance.programSpecialties,
      'maxStudents': instance.maxStudents,
      'currentLoad': instance.currentLoad,
      'isAvailable': instance.isAvailable,
      'phoneNumber': instance.phoneNumber,
      'assignedStudentIds': instance.assignedStudentIds,
    };
