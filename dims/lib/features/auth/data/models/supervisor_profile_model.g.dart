// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supervisor_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SupervisorProfileModelImpl _$$SupervisorProfileModelImplFromJson(
        Map<String, dynamic> json) =>
    _$SupervisorProfileModelImpl(
      uid: json['uid'] as String,
      department: json['department'] as String,
      maxStudents: (json['maxStudents'] as num?)?.toInt() ?? 12,
      currentLoad: (json['currentLoad'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$SupervisorProfileModelImplToJson(
        _$SupervisorProfileModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'department': instance.department,
      'maxStudents': instance.maxStudents,
      'currentLoad': instance.currentLoad,
    };
