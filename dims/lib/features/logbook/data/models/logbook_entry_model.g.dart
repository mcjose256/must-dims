// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logbook_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LogbookEntryModelImpl _$$LogbookEntryModelImplFromJson(
        Map<String, dynamic> json) =>
    _$LogbookEntryModelImpl(
      id: json['id'] as String?,
      studentRefPath: json['studentRefPath'] as String,
      placementRefPath: json['placementRefPath'] as String,
      date: DateTime.parse(json['date'] as String),
      dayNumber: (json['dayNumber'] as num).toInt(),
      tasksPerformed: json['tasksPerformed'] as String,
      challenges: json['challenges'] as String?,
      skillsLearned: json['skillsLearned'] as String?,
      hoursWorked: (json['hoursWorked'] as num).toDouble(),
      status: json['status'] as String? ?? 'draft',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      checkInTime: json['checkInTime'] == null
          ? null
          : DateTime.parse(json['checkInTime'] as String),
      checkOutTime: json['checkOutTime'] == null
          ? null
          : DateTime.parse(json['checkOutTime'] as String),
      photoUrl: json['photoUrl'] as String?,
      supervisorComment: json['supervisorComment'] as String?,
      approvedAt: json['approvedAt'] == null
          ? null
          : DateTime.parse(json['approvedAt'] as String),
    );

Map<String, dynamic> _$$LogbookEntryModelImplToJson(
        _$LogbookEntryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentRefPath': instance.studentRefPath,
      'placementRefPath': instance.placementRefPath,
      'date': instance.date.toIso8601String(),
      'dayNumber': instance.dayNumber,
      'tasksPerformed': instance.tasksPerformed,
      'challenges': instance.challenges,
      'skillsLearned': instance.skillsLearned,
      'hoursWorked': instance.hoursWorked,
      'status': instance.status,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'checkInTime': instance.checkInTime?.toIso8601String(),
      'checkOutTime': instance.checkOutTime?.toIso8601String(),
      'photoUrl': instance.photoUrl,
      'supervisorComment': instance.supervisorComment,
      'approvedAt': instance.approvedAt?.toIso8601String(),
    };
