import 'package:freezed_annotation/freezed_annotation.dart';

part 'evaluation_model.freezed.dart';
part 'evaluation_model.g.dart';

@freezed
class EvaluationModel with _$EvaluationModel {
  const factory EvaluationModel({
    String? placementRefPath,
    String? evaluatorRefPath,
    required Map<String, int> scores,
    required String comments,
    DateTime? submittedAt,
  }) = _EvaluationModel;

  factory EvaluationModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluationModelFromJson(json);
}