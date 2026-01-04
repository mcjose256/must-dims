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
  String? get studentRefPath => throw _privateConstructorUsedError;
  String? get companyRefPath => throw _privateConstructorUsedError;
  String? get supervisorRefPath =>
      throw _privateConstructorUsedError; // Company supervisor details
  String? get companySupervisorName => throw _privateConstructorUsedError;
  String? get companySupervisorEmail => throw _privateConstructorUsedError;
  String? get companySupervisorPhone => throw _privateConstructorUsedError;
  String get academicYear => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  DateTime? get actualEndDate => throw _privateConstructorUsedError;
  PlacementStatus get status => throw _privateConstructorUsedError;
  String? get attachmentUrl => throw _privateConstructorUsedError;
  String? get remarks => throw _privateConstructorUsedError;
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
      String? studentRefPath,
      String? companyRefPath,
      String? supervisorRefPath,
      String? companySupervisorName,
      String? companySupervisorEmail,
      String? companySupervisorPhone,
      String academicYear,
      DateTime startDate,
      DateTime endDate,
      DateTime? actualEndDate,
      PlacementStatus status,
      String? attachmentUrl,
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
    Object? studentRefPath = freezed,
    Object? companyRefPath = freezed,
    Object? supervisorRefPath = freezed,
    Object? companySupervisorName = freezed,
    Object? companySupervisorEmail = freezed,
    Object? companySupervisorPhone = freezed,
    Object? academicYear = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? actualEndDate = freezed,
    Object? status = null,
    Object? attachmentUrl = freezed,
    Object? remarks = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      studentRefPath: freezed == studentRefPath
          ? _value.studentRefPath
          : studentRefPath // ignore: cast_nullable_to_non_nullable
              as String?,
      companyRefPath: freezed == companyRefPath
          ? _value.companyRefPath
          : companyRefPath // ignore: cast_nullable_to_non_nullable
              as String?,
      supervisorRefPath: freezed == supervisorRefPath
          ? _value.supervisorRefPath
          : supervisorRefPath // ignore: cast_nullable_to_non_nullable
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
      academicYear: null == academicYear
          ? _value.academicYear
          : academicYear // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      actualEndDate: freezed == actualEndDate
          ? _value.actualEndDate
          : actualEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PlacementStatus,
      attachmentUrl: freezed == attachmentUrl
          ? _value.attachmentUrl
          : attachmentUrl // ignore: cast_nullable_to_non_nullable
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
      String? studentRefPath,
      String? companyRefPath,
      String? supervisorRefPath,
      String? companySupervisorName,
      String? companySupervisorEmail,
      String? companySupervisorPhone,
      String academicYear,
      DateTime startDate,
      DateTime endDate,
      DateTime? actualEndDate,
      PlacementStatus status,
      String? attachmentUrl,
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
    Object? studentRefPath = freezed,
    Object? companyRefPath = freezed,
    Object? supervisorRefPath = freezed,
    Object? companySupervisorName = freezed,
    Object? companySupervisorEmail = freezed,
    Object? companySupervisorPhone = freezed,
    Object? academicYear = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? actualEndDate = freezed,
    Object? status = null,
    Object? attachmentUrl = freezed,
    Object? remarks = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$PlacementModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      studentRefPath: freezed == studentRefPath
          ? _value.studentRefPath
          : studentRefPath // ignore: cast_nullable_to_non_nullable
              as String?,
      companyRefPath: freezed == companyRefPath
          ? _value.companyRefPath
          : companyRefPath // ignore: cast_nullable_to_non_nullable
              as String?,
      supervisorRefPath: freezed == supervisorRefPath
          ? _value.supervisorRefPath
          : supervisorRefPath // ignore: cast_nullable_to_non_nullable
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
      academicYear: null == academicYear
          ? _value.academicYear
          : academicYear // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      actualEndDate: freezed == actualEndDate
          ? _value.actualEndDate
          : actualEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as PlacementStatus,
      attachmentUrl: freezed == attachmentUrl
          ? _value.attachmentUrl
          : attachmentUrl // ignore: cast_nullable_to_non_nullable
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
      this.studentRefPath,
      this.companyRefPath,
      this.supervisorRefPath,
      this.companySupervisorName,
      this.companySupervisorEmail,
      this.companySupervisorPhone,
      required this.academicYear,
      required this.startDate,
      required this.endDate,
      this.actualEndDate,
      this.status = PlacementStatus.active,
      this.attachmentUrl,
      this.remarks,
      this.createdAt,
      this.updatedAt});

  factory _$PlacementModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlacementModelImplFromJson(json);

  @override
  final String id;
  @override
  final String? studentRefPath;
  @override
  final String? companyRefPath;
  @override
  final String? supervisorRefPath;
// Company supervisor details
  @override
  final String? companySupervisorName;
  @override
  final String? companySupervisorEmail;
  @override
  final String? companySupervisorPhone;
  @override
  final String academicYear;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  final DateTime? actualEndDate;
  @override
  @JsonKey()
  final PlacementStatus status;
  @override
  final String? attachmentUrl;
  @override
  final String? remarks;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'PlacementModel(id: $id, studentRefPath: $studentRefPath, companyRefPath: $companyRefPath, supervisorRefPath: $supervisorRefPath, companySupervisorName: $companySupervisorName, companySupervisorEmail: $companySupervisorEmail, companySupervisorPhone: $companySupervisorPhone, academicYear: $academicYear, startDate: $startDate, endDate: $endDate, actualEndDate: $actualEndDate, status: $status, attachmentUrl: $attachmentUrl, remarks: $remarks, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlacementModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.studentRefPath, studentRefPath) ||
                other.studentRefPath == studentRefPath) &&
            (identical(other.companyRefPath, companyRefPath) ||
                other.companyRefPath == companyRefPath) &&
            (identical(other.supervisorRefPath, supervisorRefPath) ||
                other.supervisorRefPath == supervisorRefPath) &&
            (identical(other.companySupervisorName, companySupervisorName) ||
                other.companySupervisorName == companySupervisorName) &&
            (identical(other.companySupervisorEmail, companySupervisorEmail) ||
                other.companySupervisorEmail == companySupervisorEmail) &&
            (identical(other.companySupervisorPhone, companySupervisorPhone) ||
                other.companySupervisorPhone == companySupervisorPhone) &&
            (identical(other.academicYear, academicYear) ||
                other.academicYear == academicYear) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.actualEndDate, actualEndDate) ||
                other.actualEndDate == actualEndDate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.attachmentUrl, attachmentUrl) ||
                other.attachmentUrl == attachmentUrl) &&
            (identical(other.remarks, remarks) || other.remarks == remarks) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      studentRefPath,
      companyRefPath,
      supervisorRefPath,
      companySupervisorName,
      companySupervisorEmail,
      companySupervisorPhone,
      academicYear,
      startDate,
      endDate,
      actualEndDate,
      status,
      attachmentUrl,
      remarks,
      createdAt,
      updatedAt);

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
      final String? studentRefPath,
      final String? companyRefPath,
      final String? supervisorRefPath,
      final String? companySupervisorName,
      final String? companySupervisorEmail,
      final String? companySupervisorPhone,
      required final String academicYear,
      required final DateTime startDate,
      required final DateTime endDate,
      final DateTime? actualEndDate,
      final PlacementStatus status,
      final String? attachmentUrl,
      final String? remarks,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$PlacementModelImpl;

  factory _PlacementModel.fromJson(Map<String, dynamic> json) =
      _$PlacementModelImpl.fromJson;

  @override
  String get id;
  @override
  String? get studentRefPath;
  @override
  String? get companyRefPath;
  @override
  String? get supervisorRefPath;
  @override // Company supervisor details
  String? get companySupervisorName;
  @override
  String? get companySupervisorEmail;
  @override
  String? get companySupervisorPhone;
  @override
  String get academicYear;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  DateTime? get actualEndDate;
  @override
  PlacementStatus get status;
  @override
  String? get attachmentUrl;
  @override
  String? get remarks;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$PlacementModelImplCopyWith<_$PlacementModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
