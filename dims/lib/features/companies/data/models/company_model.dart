// lib/features/student/data/models/company_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'company_model.freezed.dart';
part 'company_model.g.dart';

@freezed
class CompanyModel with _$CompanyModel {
  const factory CompanyModel({
    required String id,
    required String name,
    required String location,
    required String contactPerson,
    required String email,
    String? phone,
    String? website,
    String? industry,
    String? description,
    
    @Default(false) bool isApproved,
    String? createdByPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CompanyModel;

  factory CompanyModel.fromJson(Map<String, dynamic> json) =>
      _$CompanyModelFromJson(json);

  // Firestore converters
  static CompanyModel fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return CompanyModel.fromJson(data).copyWith(id: doc.id);
  }

  static Map<String, dynamic> toFirestore(
    CompanyModel company,
    SetOptions? options,
  ) {
    final json = company.toJson();
    json.remove('id');
    return json;
  }
}