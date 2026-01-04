import 'package:freezed_annotation/freezed_annotation.dart';

part 'allocation_rule_model.freezed.dart';
part 'allocation_rule_model.g.dart';

@freezed
class AllocationRuleModel with _$AllocationRuleModel {
  const factory AllocationRuleModel({
    required String academicYear,
    required int maxStudentsPerSupervisor,
    required List<String> preferredPrograms,
    required bool enabled,
    DateTime? updatedAt,
  }) = _AllocationRuleModel;

  factory AllocationRuleModel.fromJson(Map<String, dynamic> json) =>
      _$AllocationRuleModelFromJson(json);
}