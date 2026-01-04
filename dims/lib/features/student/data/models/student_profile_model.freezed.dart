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
// Core identification
  String get registrationNumber => throw _privateConstructorUsedError;
  String get program => throw _privateConstructorUsedError;
  int get academicYear => throw _privateConstructorUsedError;
  String get currentLevel =>
      throw _privateConstructorUsedError; // Internship related
  String? get currentPlacementId => throw _privateConstructorUsedError;
  String? get currentSupervisorId =>
      throw _privateConstructorUsedError; // Status & progress
  StudentInternshipStatus get internshipStatus =>
      throw _privateConstructorUsedError;
  DateTime? get internshipStartDate => throw _privateConstructorUsedError;
  DateTime? get internshipEndDate => throw _privateConstructorUsedError;
  double get progressPercentage =>
      throw _privateConstructorUsedError; // Metadata
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;

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
      {String registrationNumber,
      String program,
      int academicYear,
      String currentLevel,
      String? currentPlacementId,
      String? currentSupervisorId,
      StudentInternshipStatus internshipStatus,
      DateTime? internshipStartDate,
      DateTime? internshipEndDate,
      double progressPercentage,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? createdBy});
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
    Object? registrationNumber = null,
    Object? program = null,
    Object? academicYear = null,
    Object? currentLevel = null,
    Object? currentPlacementId = freezed,
    Object? currentSupervisorId = freezed,
    Object? internshipStatus = null,
    Object? internshipStartDate = freezed,
    Object? internshipEndDate = freezed,
    Object? progressPercentage = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(_value.copyWith(
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
      internshipStatus: null == internshipStatus
          ? _value.internshipStatus
          : internshipStatus // ignore: cast_nullable_to_non_nullable
              as StudentInternshipStatus,
      internshipStartDate: freezed == internshipStartDate
          ? _value.internshipStartDate
          : internshipStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      internshipEndDate: freezed == internshipEndDate
          ? _value.internshipEndDate
          : internshipEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      progressPercentage: null == progressPercentage
          ? _value.progressPercentage
          : progressPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
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
      {String registrationNumber,
      String program,
      int academicYear,
      String currentLevel,
      String? currentPlacementId,
      String? currentSupervisorId,
      StudentInternshipStatus internshipStatus,
      DateTime? internshipStartDate,
      DateTime? internshipEndDate,
      double progressPercentage,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? createdBy});
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
    Object? registrationNumber = null,
    Object? program = null,
    Object? academicYear = null,
    Object? currentLevel = null,
    Object? currentPlacementId = freezed,
    Object? currentSupervisorId = freezed,
    Object? internshipStatus = null,
    Object? internshipStartDate = freezed,
    Object? internshipEndDate = freezed,
    Object? progressPercentage = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(_$StudentProfileModelImpl(
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
      internshipStatus: null == internshipStatus
          ? _value.internshipStatus
          : internshipStatus // ignore: cast_nullable_to_non_nullable
              as StudentInternshipStatus,
      internshipStartDate: freezed == internshipStartDate
          ? _value.internshipStartDate
          : internshipStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      internshipEndDate: freezed == internshipEndDate
          ? _value.internshipEndDate
          : internshipEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      progressPercentage: null == progressPercentage
          ? _value.progressPercentage
          : progressPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StudentProfileModelImpl implements _StudentProfileModel {
  const _$StudentProfileModelImpl(
      {required this.registrationNumber,
      required this.program,
      required this.academicYear,
      required this.currentLevel,
      this.currentPlacementId,
      this.currentSupervisorId,
      this.internshipStatus = StudentInternshipStatus.notStarted,
      this.internshipStartDate,
      this.internshipEndDate,
      this.progressPercentage = 0.0,
      this.createdAt,
      this.updatedAt,
      this.createdBy});

  factory _$StudentProfileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudentProfileModelImplFromJson(json);

// Core identification
  @override
  final String registrationNumber;
  @override
  final String program;
  @override
  final int academicYear;
  @override
  final String currentLevel;
// Internship related
  @override
  final String? currentPlacementId;
  @override
  final String? currentSupervisorId;
// Status & progress
  @override
  @JsonKey()
  final StudentInternshipStatus internshipStatus;
  @override
  final DateTime? internshipStartDate;
  @override
  final DateTime? internshipEndDate;
  @override
  @JsonKey()
  final double progressPercentage;
// Metadata
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final String? createdBy;

  @override
  String toString() {
    return 'StudentProfileModel(registrationNumber: $registrationNumber, program: $program, academicYear: $academicYear, currentLevel: $currentLevel, currentPlacementId: $currentPlacementId, currentSupervisorId: $currentSupervisorId, internshipStatus: $internshipStatus, internshipStartDate: $internshipStartDate, internshipEndDate: $internshipEndDate, progressPercentage: $progressPercentage, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudentProfileModelImpl &&
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
            (identical(other.internshipStatus, internshipStatus) ||
                other.internshipStatus == internshipStatus) &&
            (identical(other.internshipStartDate, internshipStartDate) ||
                other.internshipStartDate == internshipStartDate) &&
            (identical(other.internshipEndDate, internshipEndDate) ||
                other.internshipEndDate == internshipEndDate) &&
            (identical(other.progressPercentage, progressPercentage) ||
                other.progressPercentage == progressPercentage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      registrationNumber,
      program,
      academicYear,
      currentLevel,
      currentPlacementId,
      currentSupervisorId,
      internshipStatus,
      internshipStartDate,
      internshipEndDate,
      progressPercentage,
      createdAt,
      updatedAt,
      createdBy);

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
      {required final String registrationNumber,
      required final String program,
      required final int academicYear,
      required final String currentLevel,
      final String? currentPlacementId,
      final String? currentSupervisorId,
      final StudentInternshipStatus internshipStatus,
      final DateTime? internshipStartDate,
      final DateTime? internshipEndDate,
      final double progressPercentage,
      final DateTime? createdAt,
      final DateTime? updatedAt,
      final String? createdBy}) = _$StudentProfileModelImpl;

  factory _StudentProfileModel.fromJson(Map<String, dynamic> json) =
      _$StudentProfileModelImpl.fromJson;

  @override // Core identification
  String get registrationNumber;
  @override
  String get program;
  @override
  int get academicYear;
  @override
  String get currentLevel;
  @override // Internship related
  String? get currentPlacementId;
  @override
  String? get currentSupervisorId;
  @override // Status & progress
  StudentInternshipStatus get internshipStatus;
  @override
  DateTime? get internshipStartDate;
  @override
  DateTime? get internshipEndDate;
  @override
  double get progressPercentage;
  @override // Metadata
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  String? get createdBy;
  @override
  @JsonKey(ignore: true)
  _$$StudentProfileModelImplCopyWith<_$StudentProfileModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
