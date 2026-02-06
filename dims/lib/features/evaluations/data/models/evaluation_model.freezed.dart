// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'evaluation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EvaluationModel _$EvaluationModelFromJson(Map<String, dynamic> json) {
  return _EvaluationModel.fromJson(json);
}

/// @nodoc
mixin _$EvaluationModel {
  String? get id => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  String get supervisorId => throw _privateConstructorUsedError;
  double get performanceScore => throw _privateConstructorUsedError;
  double get attendanceScore => throw _privateConstructorUsedError;
  double get communicationScore => throw _privateConstructorUsedError;
  String get comments => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $EvaluationModelCopyWith<EvaluationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EvaluationModelCopyWith<$Res> {
  factory $EvaluationModelCopyWith(
          EvaluationModel value, $Res Function(EvaluationModel) then) =
      _$EvaluationModelCopyWithImpl<$Res, EvaluationModel>;
  @useResult
  $Res call(
      {String? id,
      String studentId,
      String supervisorId,
      double performanceScore,
      double attendanceScore,
      double communicationScore,
      String comments,
      DateTime? createdAt});
}

/// @nodoc
class _$EvaluationModelCopyWithImpl<$Res, $Val extends EvaluationModel>
    implements $EvaluationModelCopyWith<$Res> {
  _$EvaluationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? studentId = null,
    Object? supervisorId = null,
    Object? performanceScore = null,
    Object? attendanceScore = null,
    Object? communicationScore = null,
    Object? comments = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      supervisorId: null == supervisorId
          ? _value.supervisorId
          : supervisorId // ignore: cast_nullable_to_non_nullable
              as String,
      performanceScore: null == performanceScore
          ? _value.performanceScore
          : performanceScore // ignore: cast_nullable_to_non_nullable
              as double,
      attendanceScore: null == attendanceScore
          ? _value.attendanceScore
          : attendanceScore // ignore: cast_nullable_to_non_nullable
              as double,
      communicationScore: null == communicationScore
          ? _value.communicationScore
          : communicationScore // ignore: cast_nullable_to_non_nullable
              as double,
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EvaluationModelImplCopyWith<$Res>
    implements $EvaluationModelCopyWith<$Res> {
  factory _$$EvaluationModelImplCopyWith(_$EvaluationModelImpl value,
          $Res Function(_$EvaluationModelImpl) then) =
      __$$EvaluationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? id,
      String studentId,
      String supervisorId,
      double performanceScore,
      double attendanceScore,
      double communicationScore,
      String comments,
      DateTime? createdAt});
}

/// @nodoc
class __$$EvaluationModelImplCopyWithImpl<$Res>
    extends _$EvaluationModelCopyWithImpl<$Res, _$EvaluationModelImpl>
    implements _$$EvaluationModelImplCopyWith<$Res> {
  __$$EvaluationModelImplCopyWithImpl(
      _$EvaluationModelImpl _value, $Res Function(_$EvaluationModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? studentId = null,
    Object? supervisorId = null,
    Object? performanceScore = null,
    Object? attendanceScore = null,
    Object? communicationScore = null,
    Object? comments = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$EvaluationModelImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      supervisorId: null == supervisorId
          ? _value.supervisorId
          : supervisorId // ignore: cast_nullable_to_non_nullable
              as String,
      performanceScore: null == performanceScore
          ? _value.performanceScore
          : performanceScore // ignore: cast_nullable_to_non_nullable
              as double,
      attendanceScore: null == attendanceScore
          ? _value.attendanceScore
          : attendanceScore // ignore: cast_nullable_to_non_nullable
              as double,
      communicationScore: null == communicationScore
          ? _value.communicationScore
          : communicationScore // ignore: cast_nullable_to_non_nullable
              as double,
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EvaluationModelImpl implements _EvaluationModel {
  const _$EvaluationModelImpl(
      {this.id,
      required this.studentId,
      required this.supervisorId,
      required this.performanceScore,
      required this.attendanceScore,
      required this.communicationScore,
      required this.comments,
      this.createdAt});

  factory _$EvaluationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$EvaluationModelImplFromJson(json);

  @override
  final String? id;
  @override
  final String studentId;
  @override
  final String supervisorId;
  @override
  final double performanceScore;
  @override
  final double attendanceScore;
  @override
  final double communicationScore;
  @override
  final String comments;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'EvaluationModel(id: $id, studentId: $studentId, supervisorId: $supervisorId, performanceScore: $performanceScore, attendanceScore: $attendanceScore, communicationScore: $communicationScore, comments: $comments, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EvaluationModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.supervisorId, supervisorId) ||
                other.supervisorId == supervisorId) &&
            (identical(other.performanceScore, performanceScore) ||
                other.performanceScore == performanceScore) &&
            (identical(other.attendanceScore, attendanceScore) ||
                other.attendanceScore == attendanceScore) &&
            (identical(other.communicationScore, communicationScore) ||
                other.communicationScore == communicationScore) &&
            (identical(other.comments, comments) ||
                other.comments == comments) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      studentId,
      supervisorId,
      performanceScore,
      attendanceScore,
      communicationScore,
      comments,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EvaluationModelImplCopyWith<_$EvaluationModelImpl> get copyWith =>
      __$$EvaluationModelImplCopyWithImpl<_$EvaluationModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EvaluationModelImplToJson(
      this,
    );
  }
}

abstract class _EvaluationModel implements EvaluationModel {
  const factory _EvaluationModel(
      {final String? id,
      required final String studentId,
      required final String supervisorId,
      required final double performanceScore,
      required final double attendanceScore,
      required final double communicationScore,
      required final String comments,
      final DateTime? createdAt}) = _$EvaluationModelImpl;

  factory _EvaluationModel.fromJson(Map<String, dynamic> json) =
      _$EvaluationModelImpl.fromJson;

  @override
  String? get id;
  @override
  String get studentId;
  @override
  String get supervisorId;
  @override
  double get performanceScore;
  @override
  double get attendanceScore;
  @override
  double get communicationScore;
  @override
  String get comments;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$EvaluationModelImplCopyWith<_$EvaluationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
