import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'supervisor_profile_model.freezed.dart';
part 'supervisor_profile_model.g.dart';

@freezed
class SupervisorProfileModel with _$SupervisorProfileModel {
  const factory SupervisorProfileModel({
    required String uid,
    @Default('Unknown Supervisor') String fullName,
    @Default('No email') String email,
    @Default('No department') String department,
    @Default([]) List<String> programSpecialties,
    @Default(12) int maxStudents,
    @Default(0) int currentLoad,
    @Default(true) bool isAvailable,
    String? phoneNumber,
    @Default([]) List<String> assignedStudentIds,
  }) = _SupervisorProfileModel;

  factory SupervisorProfileModel.fromJson(Map<String, dynamic> json) =>
      _$SupervisorProfileModelFromJson(json);

  factory SupervisorProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? {};
    return SupervisorProfileModel.fromJson({
      ...data,
      'uid': snapshot.id,
      // Provide defaults if missing
      'fullName': data['FullName'] ?? data['fullName'] ?? 'Unknown Supervisor',
      'email': data['email'] ?? 'No email',
      'department': data['department'] ?? 'No department',
    });
  }
}