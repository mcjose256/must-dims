// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evaluation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EvaluationModelImpl _$$EvaluationModelImplFromJson(
        Map<String, dynamic> json) =>
    _$EvaluationModelImpl(
      id: json['id'] as String?,
      studentId: json['studentId'] as String,
      supervisorId: json['supervisorId'] as String,
      performanceScore: (json['performanceScore'] as num).toDouble(),
      attendanceScore: (json['attendanceScore'] as num).toDouble(),
      communicationScore: (json['communicationScore'] as num).toDouble(),
      comments: json['comments'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$EvaluationModelImplToJson(
        _$EvaluationModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'supervisorId': instance.supervisorId,
      'performanceScore': instance.performanceScore,
      'attendanceScore': instance.attendanceScore,
      'communicationScore': instance.communicationScore,
      'comments': instance.comments,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
