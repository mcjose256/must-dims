// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'placement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlacementModelImpl _$$PlacementModelImplFromJson(Map<String, dynamic> json) =>
    _$PlacementModelImpl(
      id: json['id'] as String,
      studentRefPath: json['studentRefPath'] as String?,
      companyRefPath: json['companyRefPath'] as String?,
      supervisorRefPath: json['supervisorRefPath'] as String?,
      companySupervisorName: json['companySupervisorName'] as String?,
      companySupervisorEmail: json['companySupervisorEmail'] as String?,
      companySupervisorPhone: json['companySupervisorPhone'] as String?,
      academicYear: json['academicYear'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      actualEndDate: json['actualEndDate'] == null
          ? null
          : DateTime.parse(json['actualEndDate'] as String),
      status: $enumDecodeNullable(_$PlacementStatusEnumMap, json['status']) ??
          PlacementStatus.active,
      attachmentUrl: json['attachmentUrl'] as String?,
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
      'studentRefPath': instance.studentRefPath,
      'companyRefPath': instance.companyRefPath,
      'supervisorRefPath': instance.supervisorRefPath,
      'companySupervisorName': instance.companySupervisorName,
      'companySupervisorEmail': instance.companySupervisorEmail,
      'companySupervisorPhone': instance.companySupervisorPhone,
      'academicYear': instance.academicYear,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'actualEndDate': instance.actualEndDate?.toIso8601String(),
      'status': _$PlacementStatusEnumMap[instance.status]!,
      'attachmentUrl': instance.attachmentUrl,
      'remarks': instance.remarks,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$PlacementStatusEnumMap = {
  PlacementStatus.pending: 'pending',
  PlacementStatus.active: 'active',
  PlacementStatus.completed: 'completed',
  PlacementStatus.cancelled: 'cancelled',
  PlacementStatus.extended: 'extended',
};
