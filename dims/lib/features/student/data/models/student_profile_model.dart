// lib/features/student/data/models/student_profile_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_profile_model.freezed.dart';
part 'student_profile_model.g.dart';

enum StudentInternshipStatus {
  notStarted,
  inProgress,
  awaitingApproval,
  completed,
  deferred,
  terminated,
}

@freezed
class StudentProfileModel with _$StudentProfileModel {
  const factory StudentProfileModel({
    // Core identification
    required String registrationNumber,
    required String program,
    required int academicYear,
    required String currentLevel,
    
    // Internship related
    String? currentPlacementId,
    String? currentSupervisorId,
    
    // Status & progress
    @Default(StudentInternshipStatus.notStarted) 
    StudentInternshipStatus internshipStatus,
    DateTime? internshipStartDate,
    DateTime? internshipEndDate,
    @Default(0.0) double progressPercentage,
    
    // Metadata
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) = _StudentProfileModel;

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) =>
      _$StudentProfileModelFromJson(json);

  // Firestore converters
  static StudentProfileModel fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }
    return StudentProfileModel.fromJson(data);
  }

  static Map<String, dynamic> toFirestore(
    StudentProfileModel profile,
    SetOptions? options,
  ) {
    return profile.toJson();
  }
}