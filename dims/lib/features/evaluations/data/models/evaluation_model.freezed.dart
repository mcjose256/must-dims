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
  String? get placementRefPath => throw _privateConstructorUsedError;
  String? get evaluatorRefPath => throw _privateConstructorUsedError;
  Map<String, int> get scores => throw _privateConstructorUsedError;
  String get comments => throw _privateConstructorUsedError;
  DateTime? get submittedAt => throw _privateConstructorUsedError;

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
      {String? placementRefPath,
      String? evaluatorRefPath,
      Map<String, int> scores,
      String comments,
      DateTime? submittedAt});
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
    Object? placementRefPath = freezed,
    Object? evaluatorRefPath = freezed,
    Object? scores = null,
    Object? comments = null,
    Object? submittedAt = freezed,
  }) {
    return _then(_value.copyWith(
      placementRefPath: freezed == placementRefPath
          ? _value.placementRefPath
          : placementRefPath // ignore: cast_nullable_to_non_nullable
              as String?,
      evaluatorRefPath: freezed == evaluatorRefPath
          ? _value.evaluatorRefPath
          : evaluatorRefPath // ignore: cast_nullable_to_non_nullable
              as String?,
      scores: null == scores
          ? _value.scores
          : scores // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as String,
      submittedAt: freezed == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
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
      {String? placementRefPath,
      String? evaluatorRefPath,
      Map<String, int> scores,
      String comments,
      DateTime? submittedAt});
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
    Object? placementRefPath = freezed,
    Object? evaluatorRefPath = freezed,
    Object? scores = null,
    Object? comments = null,
    Object? submittedAt = freezed,
  }) {
    return _then(_$EvaluationModelImpl(
      placementRefPath: freezed == placementRefPath
          ? _value.placementRefPath
          : placementRefPath // ignore: cast_nullable_to_non_nullable
              as String?,
      evaluatorRefPath: freezed == evaluatorRefPath
          ? _value.evaluatorRefPath
          : evaluatorRefPath // ignore: cast_nullable_to_non_nullable
              as String?,
      scores: null == scores
          ? _value._scores
          : scores // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as String,
      submittedAt: freezed == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EvaluationModelImpl implements _EvaluationModel {
  const _$EvaluationModelImpl(
      {this.placementRefPath,
      this.evaluatorRefPath,
      required final Map<String, int> scores,
      required this.comments,
      this.submittedAt})
      : _scores = scores;

  factory _$EvaluationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$EvaluationModelImplFromJson(json);

  @override
  final String? placementRefPath;
  @override
  final String? evaluatorRefPath;
  final Map<String, int> _scores;
  @override
  Map<String, int> get scores {
    if (_scores is EqualUnmodifiableMapView) return _scores;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_scores);
  }

  @override
  final String comments;
  @override
  final DateTime? submittedAt;

  @override
  String toString() {
    return 'EvaluationModel(placementRefPath: $placementRefPath, evaluatorRefPath: $evaluatorRefPath, scores: $scores, comments: $comments, submittedAt: $submittedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EvaluationModelImpl &&
            (identical(other.placementRefPath, placementRefPath) ||
                other.placementRefPath == placementRefPath) &&
            (identical(other.evaluatorRefPath, evaluatorRefPath) ||
                other.evaluatorRefPath == evaluatorRefPath) &&
            const DeepCollectionEquality().equals(other._scores, _scores) &&
            (identical(other.comments, comments) ||
                other.comments == comments) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      placementRefPath,
      evaluatorRefPath,
      const DeepCollectionEquality().hash(_scores),
      comments,
      submittedAt);

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
      {final String? placementRefPath,
      final String? evaluatorRefPath,
      required final Map<String, int> scores,
      required final String comments,
      final DateTime? submittedAt}) = _$EvaluationModelImpl;

  factory _EvaluationModel.fromJson(Map<String, dynamic> json) =
      _$EvaluationModelImpl.fromJson;

  @override
  String? get placementRefPath;
  @override
  String? get evaluatorRefPath;
  @override
  Map<String, int> get scores;
  @override
  String get comments;
  @override
  DateTime? get submittedAt;
  @override
  @JsonKey(ignore: true)
  _$$EvaluationModelImplCopyWith<_$EvaluationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
