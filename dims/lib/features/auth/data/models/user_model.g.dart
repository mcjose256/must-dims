// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      uid: json['uid'] as String,
      email: json['email'] as String,
      role: $enumDecode(_$UserRoleEnumMap, json['role']),
      displayName: json['displayName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'role': _$UserRoleEnumMap[instance.role]!,
      'displayName': instance.displayName,
      'phoneNumber': instance.phoneNumber,
      'photoUrl': instance.photoUrl,
      'isApproved': instance.isApproved,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$UserRoleEnumMap = {
  UserRole.student: 'student',
  UserRole.supervisor: 'supervisor',
  UserRole.admin: 'admin',
};
