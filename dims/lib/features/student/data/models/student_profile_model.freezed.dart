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
  String get uid => throw _privateConstructorUsedError; // This must be required
  String get registrationNumber => throw _privateConstructorUsedError;
  String get program => throw _privateConstructorUsedError;
  int get academicYear => throw _privateConstructorUsedError;
  String get currentLevel => throw _privateConstructorUsedError;
  String? get currentPlacementId => throw _privateConstructorUsedError;
  String? get currentSupervisorId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  double get progressPercentage =>
      throw _privateConstructorUsedError; // 2. ADD THIS FIELD (Fixes "internshipStatus isn't defined")
  StudentInternshipStatus get internshipStatus =>
      throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

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
      int academicYear,
      String currentLevel,
      String? currentPlacementId,
      String? currentSupervisorId,
      String status,
      double progressPercentage,
      StudentInternshipStatus internshipStatus,
      DateTime? createdAt,
      DateTime? updatedAt});
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
    Object? academicYear = null,
    Object? currentLevel = null,
    Object? currentPlacementId = freezed,
    Object? currentSupervisorId = freezed,
    Object? status = null,
    Object? progressPercentage = null,
    Object? internshipStatus = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
      academicYear: null == academicYear
          ? _value.academicYear
          : academicYear // ignore: cast_nullable_to_non_nullable
              as int,
      currentLevel: null == currentLevel
          ? _value.currentLevel
          : currentLevel // ignore: cast_nullable_to_non_nullable
              as String,
      currentPlacementId: freezed == currentPlacementId
          ? _value.currentPlacementId
          : currentPlacementId // ignore: cast_nullable_to_non_nullable
              as String?,
      currentSupervisorId: freezed == currentSupervisorId
          ? _value.currentSupervisorId
          : currentSupervisorId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      progressPercentage: null == progressPercentage
          ? _value.progressPercentage
          : progressPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      internshipStatus: null == internshipStatus
          ? _value.internshipStatus
          : internshipStatus // ignore: cast_nullable_to_non_nullable
              as StudentInternshipStatus,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
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
      int academicYear,
      String currentLevel,
      String? currentPlacementId,
      String? currentSupervisorId,
      String status,
      double progressPercentage,
      StudentInternshipStatus internshipStatus,
      DateTime? createdAt,
      DateTime? updatedAt});
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
    Object? academicYear = null,
    Object? currentLevel = null,
    Object? currentPlacementId = freezed,
    Object? currentSupervisorId = freezed,
    Object? status = null,
    Object? progressPercentage = null,
    Object? internshipStatus = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
      academicYear: null == academicYear
          ? _value.academicYear
          : academicYear // ignore: cast_nullable_to_non_nullable
              as int,
      currentLevel: null == currentLevel
          ? _value.currentLevel
          : currentLevel // ignore: cast_nullable_to_non_nullable
              as String,
      currentPlacementId: freezed == currentPlacementId
          ? _value.currentPlacementId
          : currentPlacementId // ignore: cast_nullable_to_non_nullable
              as String?,
      currentSupervisorId: freezed == currentSupervisorId
          ? _value.currentSupervisorId
          : currentSupervisorId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      progressPercentage: null == progressPercentage
          ? _value.progressPercentage
          : progressPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      internshipStatus: null == internshipStatus
          ? _value.internshipStatus
          : internshipStatus // ignore: cast_nullable_to_non_nullable
              as StudentInternshipStatus,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
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
      this.academicYear = 1,
      this.currentLevel = '',
      this.currentPlacementId,
      this.currentSupervisorId,
      this.status = 'active',
      this.progressPercentage = 0.0,
      this.internshipStatus = StudentInternshipStatus.notStarted,
      this.createdAt,
      this.updatedAt});

  factory _$StudentProfileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentProfileModelImplFromJson(json);

  @override
  final String uid;
// This must be required
  @override
  final String registrationNumber;
  @override
  final String program;
  @override
  @JsonKey()
  final int academicYear;
  @override
  @JsonKey()
  final String currentLevel;
  @override
  final String? currentPlacementId;
  @override
  final String? currentSupervisorId;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final double progressPercentage;
// 2. ADD THIS FIELD (Fixes "internshipStatus isn't defined")
  @override
  @JsonKey()
  final StudentInternshipStatus internshipStatus;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'StudentProfileModel(uid: $uid, registrationNumber: $registrationNumber, program: $program, academicYear: $academicYear, currentLevel: $currentLevel, currentPlacementId: $currentPlacementId, currentSupervisorId: $currentSupervisorId, status: $status, progressPercentage: $progressPercentage, internshipStatus: $internshipStatus, createdAt: $createdAt, updatedAt: $updatedAt)';
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
            (identical(other.academicYear, academicYear) ||
                other.academicYear == academicYear) &&
            (identical(other.currentLevel, currentLevel) ||
                other.currentLevel == currentLevel) &&
            (identical(other.currentPlacementId, currentPlacementId) ||
                other.currentPlacementId == currentPlacementId) &&
            (identical(other.currentSupervisorId, currentSupervisorId) ||
                other.currentSupervisorId == currentSupervisorId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progressPercentage, progressPercentage) ||
                other.progressPercentage == progressPercentage) &&
            (identical(other.internshipStatus, internshipStatus) ||
                other.internshipStatus == internshipStatus) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      uid,
      registrationNumber,
      program,
      academicYear,
      currentLevel,
      currentPlacementId,
      currentSupervisorId,
      status,
      progressPercentage,
      internshipStatus,
      createdAt,
      updatedAt);

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
      final int academicYear,
      final String currentLevel,
      final String? currentPlacementId,
      final String? currentSupervisorId,
      final String status,
      final double progressPercentage,
      final StudentInternshipStatus internshipStatus,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$StudentProfileModelImpl;

  factory _StudentProfileModel.fromJson(Map<String, dynamic> json) =
      _$StudentProfileModelImpl.fromJson;

  @override
  String get uid;
  @override // This must be required
  String get registrationNumber;
  @override
  String get program;
  @override
  int get academicYear;
  @override
  String get currentLevel;
  @override
  String? get currentPlacementId;
  @override
  String? get currentSupervisorId;
  @override
  String get status;
  @override
  double get progressPercentage;
  @override // 2. ADD THIS FIELD (Fixes "internshipStatus isn't defined")
  StudentInternshipStatus get internshipStatus;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$StudentProfileModelImplCopyWith<_$StudentProfileModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
