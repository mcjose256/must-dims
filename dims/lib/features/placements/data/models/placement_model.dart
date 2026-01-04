// lib/features/student/data/models/placement_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'placement_model.freezed.dart';
part 'placement_model.g.dart';

enum PlacementStatus {
  pending,
  active,
  completed,
  cancelled,
  extended,
}

@freezed
class PlacementModel with _$PlacementModel {
  const factory PlacementModel({
    required String id,
    String? studentRefPath,
    String? companyRefPath,
    String? supervisorRefPath,
    
    // Company supervisor details
    String? companySupervisorName,
    String? companySupervisorEmail,
    String? companySupervisorPhone,
    
    required String academicYear,
    required DateTime startDate,
    required DateTime endDate,
    DateTime? actualEndDate,
    
    @Default(PlacementStatus.active) PlacementStatus status,
    
    String? attachmentUrl,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PlacementModel;

  factory PlacementModel.fromJson(Map<String, dynamic> json) =>
      _$PlacementModelFromJson(json);

  // Firestore converters
  static PlacementModel fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return PlacementModel.fromJson(data).copyWith(id: doc.id);
  }

  static Map<String, dynamic> toFirestore(
    PlacementModel placement,
    SetOptions? options,
  ) {
    final json = placement.toJson();
    json.remove('id'); // Don't store ID in document
    return json;
  }
}