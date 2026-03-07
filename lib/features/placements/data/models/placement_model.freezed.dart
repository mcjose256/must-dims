// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'placement_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlacementModel _$PlacementModelFromJson(Map<String, dynamic> json) {
  return _PlacementModel.fromJson(json);
}

/// @nodoc
mixin _$PlacementModel {
  String get id => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  String get companyId =>
      throw _privateConstructorUsedError; // University supervisor (auto-assigned via algorithm)
  String? get universitySupervisorId =>
      throw _privateConstructorUsedError; // Company supervisor details (from acceptance letter)
  String? get companySupervisorName => throw _privateConstructorUsedError;
  String? get companySupervisorEmail => throw _privateConstructorUsedError;
  String? get companySupervisorPhone => throw _privateConstructorUsedError;
  String? get companySupervisorId =>
      throw _privateConstructorUsedError; // Acceptance letter
  String? get acceptanceLetterUrl => throw _privateConstructorUsedError;
  String? get acceptanceLetterFileName => throw _privateConstructorUsedError;
  DateTime? get letterUploadedAt =>
      throw _privateConstructorUsedError; // ── Approval (now supervisor-driven, not admin) ──────────────────────────
  PlacementStatus get status => throw _privateConstructorUsedError;

  /// Feedback left by the university supervisor on rejection.
  /// Student sees this so they know what to fix before resubmitting.
  String? get supervisorFeedback => throw _privateConstructorUsedError;
  DateTime? get supervisorApprovedAt => throw _privateConstructorUsedError;
  DateTime? get supervisorRejectedAt =>
      throw _privateConstructorUsedError; // ── Internship timeline ──────────────────────────────────────────────────
  String get academicYear => throw _privateConstructorUsedError;
  DateTime? get startDate => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  DateTime? get actualEndDate => throw _privateConstructorUsedError;
  int get totalWeeks => throw _privateConstructorUsedError;
  int get weeksCompleted => throw _privateConstructorUsedError;
  double get progressPercentage =>
      throw _privateConstructorUsedError; // ── Additional info ──────────────────────────────────────────────────────
  String? get studentNotes => throw _privateConstructorUsedError;
  String? get remarks =>
      throw _privateConstructorUsedError; // ── Timestamps ───────────────────────────────────────────────────────────
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PlacementModelCopyWith<PlacementModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlacementModelCopyWith<$Res> {
  factory $PlacementModelCopyWith(
          PlacementModel value, $Res Function(PlacementModel) then) =
      _$PlacementModelCopyWithImpl<$Res, PlacementModel>;
  @useResult
  $Res call(
      {String id,
      String studentId,
      String companyId,
      String? universitySupervisorId,
      String? companySupervisorName,
      String? companySupervisorEmail,
      String? companySupervisorPhone,
      String? companySupervisorId,
      String? acceptanceLetterUrl,
      String? acceptanceLetterFileName,
      DateTime? letterUploadedAt,
      PlacementStatus status,
      String? supervisorFeedback,
      DateTime? supervisorApprovedAt,
      DateTime? supervisorRejectedAt,
      String academicYear,
      DateTime? startDate,
      DateTime? endDate,
      DateTime? actualEndDate,
      int totalWeeks,
      int weeksCompleted,
      double progressPercentage,
      String? studentNotes,
      String? remarks,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$PlacementModelCopyWithImpl<$Res, $Val extends PlacementModel>
    implements $PlacementModelCopyWith<$Res> {
  _$PlacementModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? studentId = null,
    Object? companyId = null,
    Object? universitySupervisorId = freezed,
    Object? companySupervisorName = freezed,
    Object? companySupervisorEmail = freezed,
    Object? companySupervisorPhone = freezed,
    Object? companySupervisorId = freezed,
    Object? acceptanceLetterUrl = freezed,
    Object? acceptanceLetterFileName = freezed,
    Object? letterUploadedAt = freezed,
    Object? status = null,
    Object? supervisorFeedback = freezed,
    Object? supervisorApprovedAt = freezed,
    Object? supervisorRejectedAt = freezed,
    Object? academicYear = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? actualEndDate = freezed,
    Object? totalWeeks = null,
    Object? weeksCompleted = null,
    Object? progressPercentage = null,
    Object? studentNotes = freezed,
    Object? remarks = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      companyId: null == companyId
          ? _value.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String,
      universitySupervisorId: freezed == universitySupervisorId
          ? _value.universitySupervisorId
          : universitySupervisorId // ignore: cast_nullable_to_non_nullable
              as String?,
      companySupervisorName: freezed == companySupervisorName
          ? _value.companySupervisorName
          : companySupervisorName // ignore: cast_nullable_to_non_nullable
              as String?,
      companySupervisorEmail: freezed == companySupervisorEmail
          ? _value.companySupervisorEmail
          : companySupervisorEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      companySupervisorPhone: freezed == companySupervisorPhone
          ? _value.companySupervisorPhone
          : companySupervisorPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      companySupervisorId: freezed == companySupervisorId
          ? _value.companySupervisorId
          : companySupervisorId // ignore: cast_nullable_to_non_nullable
              as String?,
      acceptanceLetterUrl: freezed == acceptanceLetterUrl
          ? _value.acceptanceLetterUrl
          : acceptanceLetterUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      acceptanceLetterFileName: freezed == acceptanceLetterFileName
          ? _value.acceptanceLetterFileName
          : acceptanceLetterFileName // ignore: cast_nullable_to_non_nullable
              as String?,
      letterUploadedAt: freezed == letterUploadedAt
          ? _value.letterUploadedAt
          : letterUploadedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PlacementStatus,
      supervisorFeedback: freezed == supervisorFeedback
          ? _value.supervisorFeedback
          : supervisorFeedback // ignore: cast_nullable_to_non_nullable
              as String?,
      supervisorApprovedAt: freezed == supervisorApprovedAt
          ? _value.supervisorApprovedAt
          : supervisorApprovedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      supervisorRejectedAt: freezed == supervisorRejectedAt
          ? _value.supervisorRejectedAt
          : supervisorRejectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      academicYear: null == academicYear
          ? _value.academicYear
          : academicYear // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      actualEndDate: freezed == actualEndDate
          ? _value.actualEndDate
          : actualEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalWeeks: null == totalWeeks
          ? _value.totalWeeks
          : totalWeeks // ignore: cast_nullable_to_non_nullable
              as int,
      weeksCompleted: null == weeksCompleted
          ? _value.weeksCompleted
          : weeksCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      progressPercentage: null == progressPercentage
          ? _value.progressPercentage
          : progressPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      studentNotes: freezed == studentNotes
          ? _value.studentNotes
          : studentNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
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
abstract class _$$PlacementModelImplCopyWith<$Res>
    implements $PlacementModelCopyWith<$Res> {
  factory _$$PlacementModelImplCopyWith(_$PlacementModelImpl value,
          $Res Function(_$PlacementModelImpl) then) =
      __$$PlacementModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String studentId,
      String companyId,
      String? universitySupervisorId,
      String? companySupervisorName,
      String? companySupervisorEmail,
      String? companySupervisorPhone,
      String? companySupervisorId,
      String? acceptanceLetterUrl,
      String? acceptanceLetterFileName,
      DateTime? letterUploadedAt,
      PlacementStatus status,
      String? supervisorFeedback,
      DateTime? supervisorApprovedAt,
      DateTime? supervisorRejectedAt,
      String academicYear,
      DateTime? startDate,
      DateTime? endDate,
      DateTime? actualEndDate,
      int totalWeeks,
      int weeksCompleted,
      double progressPercentage,
      String? studentNotes,
      String? remarks,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$PlacementModelImplCopyWithImpl<$Res>
    extends _$PlacementModelCopyWithImpl<$Res, _$PlacementModelImpl>
    implements _$$PlacementModelImplCopyWith<$Res> {
  __$$PlacementModelImplCopyWithImpl(
      _$PlacementModelImpl _value, $Res Function(_$PlacementModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? studentId = null,
    Object? companyId = null,
    Object? universitySupervisorId = freezed,
    Object? companySupervisorName = freezed,
    Object? companySupervisorEmail = freezed,
    Object? companySupervisorPhone = freezed,
    Object? companySupervisorId = freezed,
    Object? acceptanceLetterUrl = freezed,
    Object? acceptanceLetterFileName = freezed,
    Object? letterUploadedAt = freezed,
    Object? status = null,
    Object? supervisorFeedback = freezed,
    Object? supervisorApprovedAt = freezed,
    Object? supervisorRejectedAt = freezed,
    Object? academicYear = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? actualEndDate = freezed,
    Object? totalWeeks = null,
    Object? weeksCompleted = null,
    Object? progressPercentage = null,
    Object? studentNotes = freezed,
    Object? remarks = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$PlacementModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      companyId: null == companyId
          ? _value.companyId
          : companyId // ignore: cast_nullable_to_non_nullable
              as String,
      universitySupervisorId: freezed == universitySupervisorId
          ? _value.universitySupervisorId
          : universitySupervisorId // ignore: cast_nullable_to_non_nullable
              as String?,
      companySupervisorName: freezed == companySupervisorName
          ? _value.companySupervisorName
          : companySupervisorName // ignore: cast_nullable_to_non_nullable
              as String?,
      companySupervisorEmail: freezed == companySupervisorEmail
          ? _value.companySupervisorEmail
          : companySupervisorEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      companySupervisorPhone: freezed == companySupervisorPhone
          ? _value.companySupervisorPhone
          : companySupervisorPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      companySupervisorId: freezed == companySupervisorId
          ? _value.companySupervisorId
          : companySupervisorId // ignore: cast_nullable_to_non_nullable
              as String?,
      acceptanceLetterUrl: freezed == acceptanceLetterUrl
          ? _value.acceptanceLetterUrl
          : acceptanceLetterUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      acceptanceLetterFileName: freezed == acceptanceLetterFileName
          ? _value.acceptanceLetterFileName
          : acceptanceLetterFileName // ignore: cast_nullable_to_non_nullable
              as String?,
      letterUploadedAt: freezed == letterUploadedAt
          ? _value.letterUploadedAt
          : letterUploadedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PlacementStatus,
      supervisorFeedback: freezed == supervisorFeedback
          ? _value.supervisorFeedback
          : supervisorFeedback // ignore: cast_nullable_to_non_nullable
              as String?,
      supervisorApprovedAt: freezed == supervisorApprovedAt
          ? _value.supervisorApprovedAt
          : supervisorApprovedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      supervisorRejectedAt: freezed == supervisorRejectedAt
          ? _value.supervisorRejectedAt
          : supervisorRejectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      academicYear: null == academicYear
          ? _value.academicYear
          : academicYear // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      actualEndDate: freezed == actualEndDate
          ? _value.actualEndDate
          : actualEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalWeeks: null == totalWeeks
          ? _value.totalWeeks
          : totalWeeks // ignore: cast_nullable_to_non_nullable
              as int,
      weeksCompleted: null == weeksCompleted
          ? _value.weeksCompleted
          : weeksCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      progressPercentage: null == progressPercentage
          ? _value.progressPercentage
          : progressPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      studentNotes: freezed == studentNotes
          ? _value.studentNotes
          : studentNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
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
class _$PlacementModelImpl implements _PlacementModel {
  const _$PlacementModelImpl(
      {required this.id,
      required this.studentId,
      required this.companyId,
      this.universitySupervisorId,
      this.companySupervisorName,
      this.companySupervisorEmail,
      this.companySupervisorPhone,
      this.companySupervisorId,
      this.acceptanceLetterUrl,
      this.acceptanceLetterFileName,
      this.letterUploadedAt,
      this.status = PlacementStatus.pendingSupervisorReview,
      this.supervisorFeedback,
      this.supervisorApprovedAt,
      this.supervisorRejectedAt,
      required this.academicYear,
      this.startDate,
      this.endDate,
      this.actualEndDate,
      this.totalWeeks = 12,
      this.weeksCompleted = 0,
      this.progressPercentage = 0.0,
      this.studentNotes,
      this.remarks,
      this.createdAt,
      this.updatedAt});

  factory _$PlacementModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlacementModelImplFromJson(json);

  @override
  final String id;
  @override
  final String studentId;
  @override
  final String companyId;
// University supervisor (auto-assigned via algorithm)
  @override
  final String? universitySupervisorId;
// Company supervisor details (from acceptance letter)
  @override
  final String? companySupervisorName;
  @override
  final String? companySupervisorEmail;
  @override
  final String? companySupervisorPhone;
  @override
  final String? companySupervisorId;
// Acceptance letter
  @override
  final String? acceptanceLetterUrl;
  @override
  final String? acceptanceLetterFileName;
  @override
  final DateTime? letterUploadedAt;
// ── Approval (now supervisor-driven, not admin) ──────────────────────────
  @override
  @JsonKey()
  final PlacementStatus status;

  /// Feedback left by the university supervisor on rejection.
  /// Student sees this so they know what to fix before resubmitting.
  @override
  final String? supervisorFeedback;
  @override
  final DateTime? supervisorApprovedAt;
  @override
  final DateTime? supervisorRejectedAt;
// ── Internship timeline ──────────────────────────────────────────────────
  @override
  final String academicYear;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;
  @override
  final DateTime? actualEndDate;
  @override
  @JsonKey()
  final int totalWeeks;
  @override
  @JsonKey()
  final int weeksCompleted;
  @override
  @JsonKey()
  final double progressPercentage;
// ── Additional info ──────────────────────────────────────────────────────
  @override
  final String? studentNotes;
  @override
  final String? remarks;
// ── Timestamps ───────────────────────────────────────────────────────────
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'PlacementModel(id: $id, studentId: $studentId, companyId: $companyId, universitySupervisorId: $universitySupervisorId, companySupervisorName: $companySupervisorName, companySupervisorEmail: $companySupervisorEmail, companySupervisorPhone: $companySupervisorPhone, companySupervisorId: $companySupervisorId, acceptanceLetterUrl: $acceptanceLetterUrl, acceptanceLetterFileName: $acceptanceLetterFileName, letterUploadedAt: $letterUploadedAt, status: $status, supervisorFeedback: $supervisorFeedback, supervisorApprovedAt: $supervisorApprovedAt, supervisorRejectedAt: $supervisorRejectedAt, academicYear: $academicYear, startDate: $startDate, endDate: $endDate, actualEndDate: $actualEndDate, totalWeeks: $totalWeeks, weeksCompleted: $weeksCompleted, progressPercentage: $progressPercentage, studentNotes: $studentNotes, remarks: $remarks, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlacementModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.companyId, companyId) ||
                other.companyId == companyId) &&
            (identical(other.universitySupervisorId, universitySupervisorId) ||
                other.universitySupervisorId == universitySupervisorId) &&
            (identical(other.companySupervisorName, companySupervisorName) ||
                other.companySupervisorName == companySupervisorName) &&
            (identical(other.companySupervisorEmail, companySupervisorEmail) ||
                other.companySupervisorEmail == companySupervisorEmail) &&
            (identical(other.companySupervisorPhone, companySupervisorPhone) ||
                other.companySupervisorPhone == companySupervisorPhone) &&
            (identical(other.companySupervisorId, companySupervisorId) ||
                other.companySupervisorId == companySupervisorId) &&
            (identical(other.acceptanceLetterUrl, acceptanceLetterUrl) ||
                other.acceptanceLetterUrl == acceptanceLetterUrl) &&
            (identical(
                    other.acceptanceLetterFileName, acceptanceLetterFileName) ||
                other.acceptanceLetterFileName == acceptanceLetterFileName) &&
            (identical(other.letterUploadedAt, letterUploadedAt) ||
                other.letterUploadedAt == letterUploadedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.supervisorFeedback, supervisorFeedback) ||
                other.supervisorFeedback == supervisorFeedback) &&
            (identical(other.supervisorApprovedAt, supervisorApprovedAt) ||
                other.supervisorApprovedAt == supervisorApprovedAt) &&
            (identical(other.supervisorRejectedAt, supervisorRejectedAt) ||
                other.supervisorRejectedAt == supervisorRejectedAt) &&
            (identical(other.academicYear, academicYear) ||
                other.academicYear == academicYear) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.actualEndDate, actualEndDate) ||
                other.actualEndDate == actualEndDate) &&
            (identical(other.totalWeeks, totalWeeks) ||
                other.totalWeeks == totalWeeks) &&
            (identical(other.weeksCompleted, weeksCompleted) ||
                other.weeksCompleted == weeksCompleted) &&
            (identical(other.progressPercentage, progressPercentage) ||
                other.progressPercentage == progressPercentage) &&
            (identical(other.studentNotes, studentNotes) ||
                other.studentNotes == studentNotes) &&
            (identical(other.remarks, remarks) || other.remarks == remarks) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        studentId,
        companyId,
        universitySupervisorId,
        companySupervisorName,
        companySupervisorEmail,
        companySupervisorPhone,
        companySupervisorId,
        acceptanceLetterUrl,
        acceptanceLetterFileName,
        letterUploadedAt,
        status,
        supervisorFeedback,
        supervisorApprovedAt,
        supervisorRejectedAt,
        academicYear,
        startDate,
        endDate,
        actualEndDate,
        totalWeeks,
        weeksCompleted,
        progressPercentage,
        studentNotes,
        remarks,
        createdAt,
        updatedAt
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlacementModelImplCopyWith<_$PlacementModelImpl> get copyWith =>
      __$$PlacementModelImplCopyWithImpl<_$PlacementModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlacementModelImplToJson(
      this,
    );
  }
}

abstract class _PlacementModel implements PlacementModel {
  const factory _PlacementModel(
      {required final String id,
      required final String studentId,
      required final String companyId,
      final String? universitySupervisorId,
      final String? companySupervisorName,
      final String? companySupervisorEmail,
      final String? companySupervisorPhone,
      final String? companySupervisorId,
      final String? acceptanceLetterUrl,
      final String? acceptanceLetterFileName,
      final DateTime? letterUploadedAt,
      final PlacementStatus status,
      final String? supervisorFeedback,
      final DateTime? supervisorApprovedAt,
      final DateTime? supervisorRejectedAt,
      required final String academicYear,
      final DateTime? startDate,
      final DateTime? endDate,
      final DateTime? actualEndDate,
      final int totalWeeks,
      final int weeksCompleted,
      final double progressPercentage,
      final String? studentNotes,
      final String? remarks,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$PlacementModelImpl;

  factory _PlacementModel.fromJson(Map<String, dynamic> json) =
      _$PlacementModelImpl.fromJson;

  @override
  String get id;
  @override
  String get studentId;
  @override
  String get companyId;
  @override // University supervisor (auto-assigned via algorithm)
  String? get universitySupervisorId;
  @override // Company supervisor details (from acceptance letter)
  String? get companySupervisorName;
  @override
  String? get companySupervisorEmail;
  @override
  String? get companySupervisorPhone;
  @override
  String? get companySupervisorId;
  @override // Acceptance letter
  String? get acceptanceLetterUrl;
  @override
  String? get acceptanceLetterFileName;
  @override
  DateTime? get letterUploadedAt;
  @override // ── Approval (now supervisor-driven, not admin) ──────────────────────────
  PlacementStatus get status;
  @override

  /// Feedback left by the university supervisor on rejection.
  /// Student sees this so they know what to fix before resubmitting.
  String? get supervisorFeedback;
  @override
  DateTime? get supervisorApprovedAt;
  @override
  DateTime? get supervisorRejectedAt;
  @override // ── Internship timeline ──────────────────────────────────────────────────
  String get academicYear;
  @override
  DateTime? get startDate;
  @override
  DateTime? get endDate;
  @override
  DateTime? get actualEndDate;
  @override
  int get totalWeeks;
  @override
  int get weeksCompleted;
  @override
  double get progressPercentage;
  @override // ── Additional info ──────────────────────────────────────────────────────
  String? get studentNotes;
  @override
  String? get remarks;
  @override // ── Timestamps ───────────────────────────────────────────────────────────
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$PlacementModelImplCopyWith<_$PlacementModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
