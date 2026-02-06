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
  String? get id => throw _privateConstructorUsedError;
  String get studentRefPath => throw _privateConstructorUsedError;
  String get placementRefPath => throw _privateConstructorUsedError;
  String get supervisorId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  int get dayNumber => throw _privateConstructorUsedError;
  String get tasksPerformed => throw _privateConstructorUsedError;
  String? get challenges => throw _privateConstructorUsedError;
  String? get skillsLearned => throw _privateConstructorUsedError;
  double get hoursWorked => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  String? get photoUrl =>
      throw _privateConstructorUsedError; // Ensure this is exactly as written here
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
      {String? id,
      String studentRefPath,
      String placementRefPath,
      String supervisorId,
      DateTime date,
      int dayNumber,
      String tasksPerformed,
      String? challenges,
      String? skillsLearned,
      double hoursWorked,
      String status,
      DateTime? createdAt,
      DateTime? updatedAt,
      double? latitude,
      double? longitude,
      String? photoUrl,
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
    Object? id = freezed,
    Object? studentRefPath = null,
    Object? placementRefPath = null,
    Object? supervisorId = null,
    Object? date = null,
    Object? dayNumber = null,
    Object? tasksPerformed = null,
    Object? challenges = freezed,
    Object? skillsLearned = freezed,
    Object? hoursWorked = null,
    Object? status = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? photoUrl = freezed,
    Object? supervisorComment = freezed,
    Object? approvedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      studentRefPath: null == studentRefPath
          ? _value.studentRefPath
          : studentRefPath // ignore: cast_nullable_to_non_nullable
              as String,
      placementRefPath: null == placementRefPath
          ? _value.placementRefPath
          : placementRefPath // ignore: cast_nullable_to_non_nullable
              as String,
      supervisorId: null == supervisorId
          ? _value.supervisorId
          : supervisorId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      tasksPerformed: null == tasksPerformed
          ? _value.tasksPerformed
          : tasksPerformed // ignore: cast_nullable_to_non_nullable
              as String,
      challenges: freezed == challenges
          ? _value.challenges
          : challenges // ignore: cast_nullable_to_non_nullable
              as String?,
      skillsLearned: freezed == skillsLearned
          ? _value.skillsLearned
          : skillsLearned // ignore: cast_nullable_to_non_nullable
              as String?,
      hoursWorked: null == hoursWorked
          ? _value.hoursWorked
          : hoursWorked // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
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
      {String? id,
      String studentRefPath,
      String placementRefPath,
      String supervisorId,
      DateTime date,
      int dayNumber,
      String tasksPerformed,
      String? challenges,
      String? skillsLearned,
      double hoursWorked,
      String status,
      DateTime? createdAt,
      DateTime? updatedAt,
      double? latitude,
      double? longitude,
      String? photoUrl,
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
    Object? id = freezed,
    Object? studentRefPath = null,
    Object? placementRefPath = null,
    Object? supervisorId = null,
    Object? date = null,
    Object? dayNumber = null,
    Object? tasksPerformed = null,
    Object? challenges = freezed,
    Object? skillsLearned = freezed,
    Object? hoursWorked = null,
    Object? status = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? photoUrl = freezed,
    Object? supervisorComment = freezed,
    Object? approvedAt = freezed,
  }) {
    return _then(_$LogbookEntryModelImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      studentRefPath: null == studentRefPath
          ? _value.studentRefPath
          : studentRefPath // ignore: cast_nullable_to_non_nullable
              as String,
      placementRefPath: null == placementRefPath
          ? _value.placementRefPath
          : placementRefPath // ignore: cast_nullable_to_non_nullable
              as String,
      supervisorId: null == supervisorId
          ? _value.supervisorId
          : supervisorId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      tasksPerformed: null == tasksPerformed
          ? _value.tasksPerformed
          : tasksPerformed // ignore: cast_nullable_to_non_nullable
              as String,
      challenges: freezed == challenges
          ? _value.challenges
          : challenges // ignore: cast_nullable_to_non_nullable
              as String?,
      skillsLearned: freezed == skillsLearned
          ? _value.skillsLearned
          : skillsLearned // ignore: cast_nullable_to_non_nullable
              as String?,
      hoursWorked: null == hoursWorked
          ? _value.hoursWorked
          : hoursWorked // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
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
      {this.id,
      required this.studentRefPath,
      required this.placementRefPath,
      required this.supervisorId,
      required this.date,
      required this.dayNumber,
      required this.tasksPerformed,
      this.challenges,
      this.skillsLearned,
      required this.hoursWorked,
      this.status = 'pending',
      this.createdAt,
      this.updatedAt,
      this.latitude,
      this.longitude,
      this.photoUrl,
      this.supervisorComment,
      this.approvedAt});

  factory _$LogbookEntryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LogbookEntryModelImplFromJson(json);

  @override
  final String? id;
  @override
  final String studentRefPath;
  @override
  final String placementRefPath;
  @override
  final String supervisorId;
  @override
  final DateTime date;
  @override
  final int dayNumber;
  @override
  final String tasksPerformed;
  @override
  final String? challenges;
  @override
  final String? skillsLearned;
  @override
  final double hoursWorked;
  @override
  @JsonKey()
  final String status;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  final String? photoUrl;
// Ensure this is exactly as written here
  @override
  final String? supervisorComment;
  @override
  final DateTime? approvedAt;

  @override
  String toString() {
    return 'LogbookEntryModel(id: $id, studentRefPath: $studentRefPath, placementRefPath: $placementRefPath, supervisorId: $supervisorId, date: $date, dayNumber: $dayNumber, tasksPerformed: $tasksPerformed, challenges: $challenges, skillsLearned: $skillsLearned, hoursWorked: $hoursWorked, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, latitude: $latitude, longitude: $longitude, photoUrl: $photoUrl, supervisorComment: $supervisorComment, approvedAt: $approvedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LogbookEntryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.studentRefPath, studentRefPath) ||
                other.studentRefPath == studentRefPath) &&
            (identical(other.placementRefPath, placementRefPath) ||
                other.placementRefPath == placementRefPath) &&
            (identical(other.supervisorId, supervisorId) ||
                other.supervisorId == supervisorId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.dayNumber, dayNumber) ||
                other.dayNumber == dayNumber) &&
            (identical(other.tasksPerformed, tasksPerformed) ||
                other.tasksPerformed == tasksPerformed) &&
            (identical(other.challenges, challenges) ||
                other.challenges == challenges) &&
            (identical(other.skillsLearned, skillsLearned) ||
                other.skillsLearned == skillsLearned) &&
            (identical(other.hoursWorked, hoursWorked) ||
                other.hoursWorked == hoursWorked) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.supervisorComment, supervisorComment) ||
                other.supervisorComment == supervisorComment) &&
            (identical(other.approvedAt, approvedAt) ||
                other.approvedAt == approvedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      studentRefPath,
      placementRefPath,
      supervisorId,
      date,
      dayNumber,
      tasksPerformed,
      challenges,
      skillsLearned,
      hoursWorked,
      status,
      createdAt,
      updatedAt,
      latitude,
      longitude,
      photoUrl,
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
      {final String? id,
      required final String studentRefPath,
      required final String placementRefPath,
      required final String supervisorId,
      required final DateTime date,
      required final int dayNumber,
      required final String tasksPerformed,
      final String? challenges,
      final String? skillsLearned,
      required final double hoursWorked,
      final String status,
      final DateTime? createdAt,
      final DateTime? updatedAt,
      final double? latitude,
      final double? longitude,
      final String? photoUrl,
      final String? supervisorComment,
      final DateTime? approvedAt}) = _$LogbookEntryModelImpl;

  factory _LogbookEntryModel.fromJson(Map<String, dynamic> json) =
      _$LogbookEntryModelImpl.fromJson;

  @override
  String? get id;
  @override
  String get studentRefPath;
  @override
  String get placementRefPath;
  @override
  String get supervisorId;
  @override
  DateTime get date;
  @override
  int get dayNumber;
  @override
  String get tasksPerformed;
  @override
  String? get challenges;
  @override
  String? get skillsLearned;
  @override
  double get hoursWorked;
  @override
  String get status;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  String? get photoUrl;
  @override // Ensure this is exactly as written here
  String? get supervisorComment;
  @override
  DateTime? get approvedAt;
  @override
  @JsonKey(ignore: true)
  _$$LogbookEntryModelImplCopyWith<_$LogbookEntryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
