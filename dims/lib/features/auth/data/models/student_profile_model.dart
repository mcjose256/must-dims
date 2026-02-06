import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_profile_model.freezed.dart';
part 'student_profile_model.g.dart';

@freezed
class StudentProfileModel with _$StudentProfileModel {
  const factory StudentProfileModel({
    required String uid,
    required String registrationNumber,
    required String program,
    required int yearOfStudy,
    String? status,
    DateTime? createdAt,
  }) = _StudentProfileModel;

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) =>
      _$StudentProfileModelFromJson(json);

  // ── Add this Firestore factory (fixes the error) ─────────────────────────────
  factory StudentProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return StudentProfileModel.fromJson({
      ...data,
      'uid': snapshot.id,  // Use document ID as uid
    });
  }
}