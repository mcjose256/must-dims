import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_profile_model.freezed.dart';
part 'student_profile_model.g.dart';

// 1. ADD THIS ENUM (Fixes "Undefined class StudentInternshipStatus")
enum StudentInternshipStatus {
  notStarted,
  inProgress,
  completed,
  awaitingApproval,
  deferred,
  terminated
}

@freezed
class StudentProfileModel with _$StudentProfileModel {
  const factory StudentProfileModel({
    required String uid, // This must be required
    required String registrationNumber,
    required String program,
    @Default(1) int academicYear,
    @Default('') String currentLevel,
    String? currentPlacementId,
    String? currentSupervisorId,
    @Default('active') String status,
    @Default(0.0) double progressPercentage,
    // 2. ADD THIS FIELD (Fixes "internshipStatus isn't defined")
    @Default(StudentInternshipStatus.notStarted) StudentInternshipStatus internshipStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _StudentProfileModel;

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) =>
      _$StudentProfileModelFromJson(json);

  factory StudentProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return StudentProfileModel.fromJson({
      ...data,
      'uid': snapshot.id,
      // Handle the enum conversion from string if stored in Firestore
      'internshipStatus': data['internshipStatus'] ?? 'notStarted',
    });
  }

  static Map<String, dynamic> toFirestore(StudentProfileModel profile) {
    final json = profile.toJson();
    json.remove('uid'); // UID is the document ID
    // Ensure enum is saved as string
    json['internshipStatus'] = profile.internshipStatus.name;
    return json;
  }
}