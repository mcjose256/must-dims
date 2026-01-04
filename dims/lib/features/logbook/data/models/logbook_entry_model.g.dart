// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logbook_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LogbookEntryModelImpl _$$LogbookEntryModelImplFromJson(
        Map<String, dynamic> json) =>
    _$LogbookEntryModelImpl(
      studentRefPath: json['studentRefPath'] as String?,
      placementRefPath: json['placementRefPath'] as String?,
      date: DateTime.parse(json['date'] as String),
      dayNumber: (json['dayNumber'] as num).toInt(),
      tasks: json['tasks'] as String,
      hoursWorked: (json['hoursWorked'] as num).toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      checkInTime: json['checkInTime'] == null
          ? null
          : DateTime.parse(json['checkInTime'] as String),
      checkOutTime: json['checkOutTime'] == null
          ? null
          : DateTime.parse(json['checkOutTime'] as String),
      photoUrl: json['photoUrl'] as String?,
      status: json['status'] as String?,
      supervisorComment: json['supervisorComment'] as String?,
      approvedAt: json['approvedAt'] == null
          ? null
          : DateTime.parse(json['approvedAt'] as String),
    );

Map<String, dynamic> _$$LogbookEntryModelImplToJson(
        _$LogbookEntryModelImpl instance) =>
    <String, dynamic>{
      'studentRefPath': instance.studentRefPath,
      'placementRefPath': instance.placementRefPath,
      'date': instance.date.toIso8601String(),
      'dayNumber': instance.dayNumber,
      'tasks': instance.tasks,
      'hoursWorked': instance.hoursWorked,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'checkInTime': instance.checkInTime?.toIso8601String(),
      'checkOutTime': instance.checkOutTime?.toIso8601String(),
      'photoUrl': instance.photoUrl,
      'status': instance.status,
      'supervisorComment': instance.supervisorComment,
      'approvedAt': instance.approvedAt?.toIso8601String(),
    };
