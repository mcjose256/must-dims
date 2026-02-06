// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'student_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StudentProfileModel _$StudentProfileModelFromJson(Map<String, dynamic> json) {
  return _StudentProfileModel.fromJson(json);
}

/// @nodoc
mixin _$StudentProfileModel {
  String get uid => throw _privateConstructorUsedError;
  String get registrationNumber => throw _privateConstructorUsedError;
  String get program => throw _privateConstructorUsedError;
  int get yearOfStudy => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StudentProfileModelCopyWith<StudentProfileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudentProfileModelCopyWith<$Res> {
  factory $StudentProfileModelCopyWith(
          StudentProfileModel value, $Res Function(StudentProfileModel) then) =
      _$StudentProfileModelCopyWithImpl<$Res, StudentProfileModel>;
  @useResult
  $Res call(
      {String uid,
      String registrationNumber,
      String program,
      int yearOfStudy,
      String? status,
      DateTime? createdAt});
}

/// @nodoc
class _$StudentProfileModelCopyWithImpl<$Res, $Val extends StudentProfileModel>
    implements $StudentProfileModelCopyWith<$Res> {
  _$StudentProfileModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? registrationNumber = null,
    Object? program = null,
    Object? yearOfStudy = null,
    Object? status = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      registrationNumber: null == registrationNumber
          ? _value.registrationNumber
          : registrationNumber // ignore: cast_nullable_to_non_nullable
              as String,
      program: null == program
          ? _value.program
          : program // ignore: cast_nullable_to_non_nullable
              as String,
      yearOfStudy: null == yearOfStudy
          ? _value.yearOfStudy
          : yearOfStudy // ignore: cast_nullable_to_non_nullable
              as int,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StudentProfileModelImplCopyWith<$Res>
    implements $StudentProfileModelCopyWith<$Res> {
  factory _$$StudentProfileModelImplCopyWith(_$StudentProfileModelImpl value,
          $Res Function(_$StudentProfileModelImpl) then) =
      __$$StudentProfileModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uid,
      String registrationNumber,
      String program,
      int yearOfStudy,
      String? status,
      DateTime? createdAt});
}

/// @nodoc
class __$$StudentProfileModelImplCopyWithImpl<$Res>
    extends _$StudentProfileModelCopyWithImpl<$Res, _$StudentProfileModelImpl>
    implements _$$StudentProfileModelImplCopyWith<$Res> {
  __$$StudentProfileModelImplCopyWithImpl(_$StudentProfileModelImpl _value,
      $Res Function(_$StudentProfileModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? registrationNumber = null,
    Object? program = null,
    Object? yearOfStudy = null,
    Object? status = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$StudentProfileModelImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      registrationNumber: null == registrationNumber
          ? _value.registrationNumber
          : registrationNumber // ignore: cast_nullable_to_non_nullable
              as String,
      program: null == program
          ? _value.program
          : program // ignore: cast_nullable_to_non_nullable
              as String,
      yearOfStudy: null == yearOfStudy
          ? _value.yearOfStudy
          : yearOfStudy // ignore: cast_nullable_to_non_nullable
              as int,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentProfileModelImpl implements _StudentProfileModel {
  const _$StudentProfileModelImpl(
      {required this.uid,
      required this.registrationNumber,
      required this.program,
      required this.yearOfStudy,
      this.status,
      this.createdAt});

  factory _$StudentProfileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentProfileModelImplFromJson(json);

  @override
  final String uid;
  @override
  final String registrationNumber;
  @override
  final String program;
  @override
  final int yearOfStudy;
  @override
  final String? status;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'StudentProfileModel(uid: $uid, registrationNumber: $registrationNumber, program: $program, yearOfStudy: $yearOfStudy, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentProfileModelImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.registrationNumber, registrationNumber) ||
                other.registrationNumber == registrationNumber) &&
            (identical(other.program, program) || other.program == program) &&
            (identical(other.yearOfStudy, yearOfStudy) ||
                other.yearOfStudy == yearOfStudy) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, uid, registrationNumber, program,
      yearOfStudy, status, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StudentProfileModelImplCopyWith<_$StudentProfileModelImpl> get copyWith =>
      __$$StudentProfileModelImplCopyWithImpl<_$StudentProfileModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudentProfileModelImplToJson(
      this,
    );
  }
}

abstract class _StudentProfileModel implements StudentProfileModel {
  const factory _StudentProfileModel(
      {required final String uid,
      required final String registrationNumber,
      required final String program,
      required final int yearOfStudy,
      final String? status,
      final DateTime? createdAt}) = _$StudentProfileModelImpl;

  factory _StudentProfileModel.fromJson(Map<String, dynamic> json) =
      _$StudentProfileModelImpl.fromJson;

  @override
  String get uid;
  @override
  String get registrationNumber;
  @override
  String get program;
  @override
  int get yearOfStudy;
  @override
  String? get status;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$StudentProfileModelImplCopyWith<_$StudentProfileModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
