import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_profile_model.freezed.dart';
part 'student_profile_model.g.dart';

@freezed
class StudentProfileModel with _$StudentProfileModel {
  const factory StudentProfileModel({
    required String uid,  // ✅ Include UID as a regular field
    required String registrationNumber,
    required String program,
    required int yearOfStudy,
    String? status,
    DateTime? createdAt,
  }) = _StudentProfileModel;

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) =>
      _$StudentProfileModelFromJson(json);
}