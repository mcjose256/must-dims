import 'package:freezed_annotation/freezed_annotation.dart';

part 'supervisor_profile_model.freezed.dart';
part 'supervisor_profile_model.g.dart';

@freezed
class SupervisorProfileModel with _$SupervisorProfileModel {
  const factory SupervisorProfileModel({
    required String uid,  // ✅ Include UID as a regular field
    required String department,
    @Default(12) int maxStudents,
    @Default(0) int currentLoad,
  }) = _SupervisorProfileModel;

  factory SupervisorProfileModel.fromJson(Map<String, dynamic> json) =>
      _$SupervisorProfileModelFromJson(json);
}