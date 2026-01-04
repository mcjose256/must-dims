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
      yearOfStudy: (json['yearOfStudy'] as num).toInt(),
      status: json['status'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$StudentProfileModelImplToJson(
        _$StudentProfileModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'registrationNumber': instance.registrationNumber,
      'program': instance.program,
      'yearOfStudy': instance.yearOfStudy,
      'status': instance.status,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
