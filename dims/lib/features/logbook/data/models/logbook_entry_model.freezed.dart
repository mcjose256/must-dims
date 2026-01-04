// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'logbook_entry_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LogbookEntryModel _$LogbookEntryModelFromJson(Map<String, dynamic> json) {
  return _LogbookEntryModel.fromJson(json);
}

/// @nodoc
mixin _$LogbookEntryModel {
  String? get studentRefPath => throw _privateConstructorUsedError;
  String? get placementRefPath => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  int get dayNumber => throw _privateConstructorUsedError;
  String get tasks => throw _privateConstructorUsedError;
  double get hoursWorked => throw _privateConstructorUsedError;
  double? get latitude =>
      throw _privateConstructorUsedError; // Store GeoPoint as separate coordinates
  double? get longitude => throw _privateConstructorUsedError;
  DateTime? get checkInTime => throw _privateConstructorUsedError;
  DateTime? get checkOutTime => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;
  String? get supervisorComment => throw _privateConstructorUsedError;
  DateTime? get approvedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LogbookEntryModelCopyWith<LogbookEntryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LogbookEntryModelCopyWith<$Res> {
  factory $LogbookEntryModelCopyWith(
          LogbookEntryModel value, $Res Function(LogbookEntryModel) then) =
      _$LogbookEntryModelCopyWithImpl<$Res, LogbookEntryModel>;
  @useResult
  $Res call(
      {String? studentRefPath,
      String? placementRefPath,
      DateTime date,
      int dayNumber,
      String tasks,
      double hoursWorked,
      double? latitude,
      double? longitude,
      DateTime? checkInTime,
      DateTime? checkOutTime,
      String? photoUrl,
      String? status,
      String? supervisorComment,
      DateTime? approvedAt});
}

/// @nodoc
class _$LogbookEntryModelCopyWithImpl<$Res, $Val extends LogbookEntryModel>
    implements $LogbookEntryModelCopyWith<$Res> {
  _$LogbookEntryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentRefPath = freezed,
    Object? placementRefPath = freezed,
    Object? date = null,
    Object? dayNumber = null,
    Object? tasks = null,
    Object? hoursWorked = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? checkInTime = freezed,
    Object? checkOutTime = freezed,
    Object? photoUrl = freezed,
    Object? status = freezed,
    Object? supervisorComment = freezed,
    Object? approvedAt = freezed,
  }) {
    return _then(_value.copyWith(
      studentRefPath: freezed == studentRefPath
          ? _value.studentRefPath
          : studentRefPath // ignore: cast_nullable_to_non_nullable
              as String?,
      placementRefPath: freezed == placementRefPath
          ? _value.placementRefPath
          : placementRefPath // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      tasks: null == tasks
          ? _value.tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as String,
      hoursWorked: null == hoursWorked
          ? _value.hoursWorked
          : hoursWorked // ignore: cast_nullable_to_non_nullable
              as double,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      checkInTime: freezed == checkInTime
          ? _value.checkInTime
          : checkInTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      checkOutTime: freezed == checkOutTime
          ? _value.checkOutTime
          : checkOutTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      supervisorComment: freezed == supervisorComment
          ? _value.supervisorComment
          : supervisorComment // ignore: cast_nullable_to_non_nullable
              as String?,
      approvedAt: freezed == approvedAt
          ? _value.approvedAt
          : approvedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LogbookEntryModelImplCopyWith<$Res>
    implements $LogbookEntryModelCopyWith<$Res> {
  factory _$$LogbookEntryModelImplCopyWith(_$LogbookEntryModelImpl value,
          $Res Function(_$LogbookEntryModelImpl) then) =
      __$$LogbookEntryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? studentRefPath,
      String? placementRefPath,
      DateTime date,
      int dayNumber,
      String tasks,
      double hoursWorked,
      double? latitude,
      double? longitude,
      DateTime? checkInTime,
      DateTime? checkOutTime,
      String? photoUrl,
      String? status,
      String? supervisorComment,
      DateTime? approvedAt});
}

/// @nodoc
class __$$LogbookEntryModelImplCopyWithImpl<$Res>
    extends _$LogbookEntryModelCopyWithImpl<$Res, _$LogbookEntryModelImpl>
    implements _$$LogbookEntryModelImplCopyWith<$Res> {
  __$$LogbookEntryModelImplCopyWithImpl(_$LogbookEntryModelImpl _value,
      $Res Function(_$LogbookEntryModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? studentRefPath = freezed,
    Object? placementRefPath = freezed,
    Object? date = null,
    Object? dayNumber = null,
    Object? tasks = null,
    Object? hoursWorked = null,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? checkInTime = freezed,
    Object? checkOutTime = freezed,
    Object? photoUrl = freezed,
    Object? status = freezed,
    Object? supervisorComment = freezed,
    Object? approvedAt = freezed,
  }) {
    return _then(_$LogbookEntryModelImpl(
      studentRefPath: freezed == studentRefPath
          ? _value.studentRefPath
          : studentRefPath // ignore: cast_nullable_to_non_nullable
              as String?,
      placementRefPath: freezed == placementRefPath
          ? _value.placementRefPath
          : placementRefPath // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      tasks: null == tasks
          ? _value.tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as String,
      hoursWorked: null == hoursWorked
          ? _value.hoursWorked
          : hoursWorked // ignore: cast_nullable_to_non_nullable
              as double,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      checkInTime: freezed == checkInTime
          ? _value.checkInTime
          : checkInTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      checkOutTime: freezed == checkOutTime
          ? _value.checkOutTime
          : checkOutTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      supervisorComment: freezed == supervisorComment
          ? _value.supervisorComment
          : supervisorComment // ignore: cast_nullable_to_non_nullable
              as String?,
      approvedAt: freezed == approvedAt
          ? _value.approvedAt
          : approvedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LogbookEntryModelImpl implements _LogbookEntryModel {
  const _$LogbookEntryModelImpl(
      {this.studentRefPath,
      this.placementRefPath,
      required this.date,
      required this.dayNumber,
      required this.tasks,
      required this.hoursWorked,
      this.latitude,
      this.longitude,
      this.checkInTime,
      this.checkOutTime,
      this.photoUrl,
      this.status,
      this.supervisorComment,
      this.approvedAt});

  factory _$LogbookEntryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LogbookEntryModelImplFromJson(json);

  @override
  final String? studentRefPath;
  @override
  final String? placementRefPath;
  @override
  final DateTime date;
  @override
  final int dayNumber;
  @override
  final String tasks;
  @override
  final double hoursWorked;
  @override
  final double? latitude;
// Store GeoPoint as separate coordinates
  @override
  final double? longitude;
  @override
  final DateTime? checkInTime;
  @override
  final DateTime? checkOutTime;
  @override
  final String? photoUrl;
  @override
  final String? status;
  @override
  final String? supervisorComment;
  @override
  final DateTime? approvedAt;

  @override
  String toString() {
    return 'LogbookEntryModel(studentRefPath: $studentRefPath, placementRefPath: $placementRefPath, date: $date, dayNumber: $dayNumber, tasks: $tasks, hoursWorked: $hoursWorked, latitude: $latitude, longitude: $longitude, checkInTime: $checkInTime, checkOutTime: $checkOutTime, photoUrl: $photoUrl, status: $status, supervisorComment: $supervisorComment, approvedAt: $approvedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LogbookEntryModelImpl &&
            (identical(other.studentRefPath, studentRefPath) ||
                other.studentRefPath == studentRefPath) &&
            (identical(other.placementRefPath, placementRefPath) ||
                other.placementRefPath == placementRefPath) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.dayNumber, dayNumber) ||
                other.dayNumber == dayNumber) &&
            (identical(other.tasks, tasks) || other.tasks == tasks) &&
            (identical(other.hoursWorked, hoursWorked) ||
                other.hoursWorked == hoursWorked) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.checkInTime, checkInTime) ||
                other.checkInTime == checkInTime) &&
            (identical(other.checkOutTime, checkOutTime) ||
                other.checkOutTime == checkOutTime) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.supervisorComment, supervisorComment) ||
                other.supervisorComment == supervisorComment) &&
            (identical(other.approvedAt, approvedAt) ||
                other.approvedAt == approvedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      studentRefPath,
      placementRefPath,
      date,
      dayNumber,
      tasks,
      hoursWorked,
      latitude,
      longitude,
      checkInTime,
      checkOutTime,
      photoUrl,
      status,
      supervisorComment,
      approvedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LogbookEntryModelImplCopyWith<_$LogbookEntryModelImpl> get copyWith =>
      __$$LogbookEntryModelImplCopyWithImpl<_$LogbookEntryModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LogbookEntryModelImplToJson(
      this,
    );
  }
}

abstract class _LogbookEntryModel implements LogbookEntryModel {
  const factory _LogbookEntryModel(
      {final String? studentRefPath,
      final String? placementRefPath,
      required final DateTime date,
      required final int dayNumber,
      required final String tasks,
      required final double hoursWorked,
      final double? latitude,
      final double? longitude,
      final DateTime? checkInTime,
      final DateTime? checkOutTime,
      final String? photoUrl,
      final String? status,
      final String? supervisorComment,
      final DateTime? approvedAt}) = _$LogbookEntryModelImpl;

  factory _LogbookEntryModel.fromJson(Map<String, dynamic> json) =
      _$LogbookEntryModelImpl.fromJson;

  @override
  String? get studentRefPath;
  @override
  String? get placementRefPath;
  @override
  DateTime get date;
  @override
  int get dayNumber;
  @override
  String get tasks;
  @override
  double get hoursWorked;
  @override
  double? get latitude;
  @override // Store GeoPoint as separate coordinates
  double? get longitude;
  @override
  DateTime? get checkInTime;
  @override
  DateTime? get checkOutTime;
  @override
  String? get photoUrl;
  @override
  String? get status;
  @override
  String? get supervisorComment;
  @override
  DateTime? get approvedAt;
  @override
  @JsonKey(ignore: true)
  _$$LogbookEntryModelImplCopyWith<_$LogbookEntryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
