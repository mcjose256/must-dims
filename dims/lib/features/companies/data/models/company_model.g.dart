// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompanyModelImpl _$$CompanyModelImplFromJson(Map<String, dynamic> json) =>
    _$CompanyModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      contactPerson: json['contactPerson'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      industry: json['industry'] as String?,
      description: json['description'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      createdByPath: json['createdByPath'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$CompanyModelImplToJson(_$CompanyModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'location': instance.location,
      'contactPerson': instance.contactPerson,
      'email': instance.email,
      'phone': instance.phone,
      'website': instance.website,
      'industry': instance.industry,
      'description': instance.description,
      'isApproved': instance.isApproved,
      'createdByPath': instance.createdByPath,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
