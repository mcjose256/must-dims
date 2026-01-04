// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allocation_rule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AllocationRuleModelImpl _$$AllocationRuleModelImplFromJson(
        Map<String, dynamic> json) =>
    _$AllocationRuleModelImpl(
      academicYear: json['academicYear'] as String,
      maxStudentsPerSupervisor:
          (json['maxStudentsPerSupervisor'] as num).toInt(),
      preferredPrograms: (json['preferredPrograms'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      enabled: json['enabled'] as bool,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AllocationRuleModelImplToJson(
        _$AllocationRuleModelImpl instance) =>
    <String, dynamic>{
      'academicYear': instance.academicYear,
      'maxStudentsPerSupervisor': instance.maxStudentsPerSupervisor,
      'preferredPrograms': instance.preferredPrograms,
      'enabled': instance.enabled,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
