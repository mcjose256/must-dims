// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'supervisor_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SupervisorProfileModel _$SupervisorProfileModelFromJson(
    Map<String, dynamic> json) {
  return _SupervisorProfileModel.fromJson(json);
}

/// @nodoc
mixin _$SupervisorProfileModel {
  String get uid =>
      throw _privateConstructorUsedError; // ✅ Include UID as a regular field
  String get department => throw _privateConstructorUsedError;
  int get maxStudents => throw _privateConstructorUsedError;
  int get currentLoad => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SupervisorProfileModelCopyWith<SupervisorProfileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SupervisorProfileModelCopyWith<$Res> {
  factory $SupervisorProfileModelCopyWith(SupervisorProfileModel value,
          $Res Function(SupervisorProfileModel) then) =
      _$SupervisorProfileModelCopyWithImpl<$Res, SupervisorProfileModel>;
  @useResult
  $Res call({String uid, String department, int maxStudents, int currentLoad});
}

/// @nodoc
class _$SupervisorProfileModelCopyWithImpl<$Res,
        $Val extends SupervisorProfileModel>
    implements $SupervisorProfileModelCopyWith<$Res> {
  _$SupervisorProfileModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? department = null,
    Object? maxStudents = null,
    Object? currentLoad = null,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      department: null == department
          ? _value.department
          : department // ignore: cast_nullable_to_non_nullable
              as String,
      maxStudents: null == maxStudents
          ? _value.maxStudents
          : maxStudents // ignore: cast_nullable_to_non_nullable
              as int,
      currentLoad: null == currentLoad
          ? _value.currentLoad
          : currentLoad // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SupervisorProfileModelImplCopyWith<$Res>
    implements $SupervisorProfileModelCopyWith<$Res> {
  factory _$$SupervisorProfileModelImplCopyWith(
          _$SupervisorProfileModelImpl value,
          $Res Function(_$SupervisorProfileModelImpl) then) =
      __$$SupervisorProfileModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String uid, String department, int maxStudents, int currentLoad});
}

/// @nodoc
class __$$SupervisorProfileModelImplCopyWithImpl<$Res>
    extends _$SupervisorProfileModelCopyWithImpl<$Res,
        _$SupervisorProfileModelImpl>
    implements _$$SupervisorProfileModelImplCopyWith<$Res> {
  __$$SupervisorProfileModelImplCopyWithImpl(
      _$SupervisorProfileModelImpl _value,
      $Res Function(_$SupervisorProfileModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? department = null,
    Object? maxStudents = null,
    Object? currentLoad = null,
  }) {
    return _then(_$SupervisorProfileModelImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      department: null == department
          ? _value.department
          : department // ignore: cast_nullable_to_non_nullable
              as String,
      maxStudents: null == maxStudents
          ? _value.maxStudents
          : maxStudents // ignore: cast_nullable_to_non_nullable
              as int,
      currentLoad: null == currentLoad
          ? _value.currentLoad
          : currentLoad // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SupervisorProfileModelImpl implements _SupervisorProfileModel {
  const _$SupervisorProfileModelImpl(
      {required this.uid,
      required this.department,
      this.maxStudents = 12,
      this.currentLoad = 0});

  factory _$SupervisorProfileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SupervisorProfileModelImplFromJson(json);

  @override
  final String uid;
// ✅ Include UID as a regular field
  @override
  final String department;
  @override
  @JsonKey()
  final int maxStudents;
  @override
  @JsonKey()
  final int currentLoad;

  @override
  String toString() {
    return 'SupervisorProfileModel(uid: $uid, department: $department, maxStudents: $maxStudents, currentLoad: $currentLoad)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SupervisorProfileModelImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.department, department) ||
                other.department == department) &&
            (identical(other.maxStudents, maxStudents) ||
                other.maxStudents == maxStudents) &&
            (identical(other.currentLoad, currentLoad) ||
                other.currentLoad == currentLoad));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, uid, department, maxStudents, currentLoad);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SupervisorProfileModelImplCopyWith<_$SupervisorProfileModelImpl>
      get copyWith => __$$SupervisorProfileModelImplCopyWithImpl<
          _$SupervisorProfileModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SupervisorProfileModelImplToJson(
      this,
    );
  }
}

abstract class _SupervisorProfileModel implements SupervisorProfileModel {
  const factory _SupervisorProfileModel(
      {required final String uid,
      required final String department,
      final int maxStudents,
      final int currentLoad}) = _$SupervisorProfileModelImpl;

  factory _SupervisorProfileModel.fromJson(Map<String, dynamic> json) =
      _$SupervisorProfileModelImpl.fromJson;

  @override
  String get uid;
  @override // ✅ Include UID as a regular field
  String get department;
  @override
  int get maxStudents;
  @override
  int get currentLoad;
  @override
  @JsonKey(ignore: true)
  _$$SupervisorProfileModelImplCopyWith<_$SupervisorProfileModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
