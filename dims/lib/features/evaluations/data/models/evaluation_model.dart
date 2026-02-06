import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'evaluation_model.freezed.dart';
part 'evaluation_model.g.dart';

@freezed
class EvaluationModel with _$EvaluationModel {
  const factory EvaluationModel({
    String? id,
    required String studentId,
    required String supervisorId,
    required double performanceScore,
    required double attendanceScore,
    required double communicationScore,
    required String comments,
    DateTime? createdAt,
  }) = _EvaluationModel;

  factory EvaluationModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluationModelFromJson(json);
}