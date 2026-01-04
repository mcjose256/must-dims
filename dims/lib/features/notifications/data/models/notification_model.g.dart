// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationModelImpl _$$NotificationModelImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationModelImpl(
      userRefPath: json['userRefPath'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$NotificationModelImplToJson(
        _$NotificationModelImpl instance) =>
    <String, dynamic>{
      'userRefPath': instance.userRefPath,
      'title': instance.title,
      'body': instance.body,
      'type': instance.type,
      'data': instance.data,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
