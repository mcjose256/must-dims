// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evaluation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EvaluationModelImpl _$$EvaluationModelImplFromJson(
        Map<String, dynamic> json) =>
    _$EvaluationModelImpl(
      placementRefPath: json['placementRefPath'] as String?,
      evaluatorRefPath: json['evaluatorRefPath'] as String?,
      scores: Map<String, int>.from(json['scores'] as Map),
      comments: json['comments'] as String,
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.parse(json['submittedAt'] as String),
    );

Map<String, dynamic> _$$EvaluationModelImplToJson(
        _$EvaluationModelImpl instance) =>
    <String, dynamic>{
      'placementRefPath': instance.placementRefPath,
      'evaluatorRefPath': instance.evaluatorRefPath,
      'scores': instance.scores,
      'comments': instance.comments,
      'submittedAt': instance.submittedAt?.toIso8601String(),
    };
