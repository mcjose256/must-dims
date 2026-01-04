// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'allocation_rule_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AllocationRuleModel _$AllocationRuleModelFromJson(Map<String, dynamic> json) {
  return _AllocationRuleModel.fromJson(json);
}

/// @nodoc
mixin _$AllocationRuleModel {
  String get academicYear => throw _privateConstructorUsedError;
  int get maxStudentsPerSupervisor => throw _privateConstructorUsedError;
  List<String> get preferredPrograms => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AllocationRuleModelCopyWith<AllocationRuleModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AllocationRuleModelCopyWith<$Res> {
  factory $AllocationRuleModelCopyWith(
          AllocationRuleModel value, $Res Function(AllocationRuleModel) then) =
      _$AllocationRuleModelCopyWithImpl<$Res, AllocationRuleModel>;
  @useResult
  $Res call(
      {String academicYear,
      int maxStudentsPerSupervisor,
      List<String> preferredPrograms,
      bool enabled,
      DateTime? updatedAt});
}

/// @nodoc
class _$AllocationRuleModelCopyWithImpl<$Res, $Val extends AllocationRuleModel>
    implements $AllocationRuleModelCopyWith<$Res> {
  _$AllocationRuleModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? academicYear = null,
    Object? maxStudentsPerSupervisor = null,
    Object? preferredPrograms = null,
    Object? enabled = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      academicYear: null == academicYear
          ? _value.academicYear
          : academicYear // ignore: cast_nullable_to_non_nullable
              as String,
      maxStudentsPerSupervisor: null == maxStudentsPerSupervisor
          ? _value.maxStudentsPerSupervisor
          : maxStudentsPerSupervisor // ignore: cast_nullable_to_non_nullable
              as int,
      preferredPrograms: null == preferredPrograms
          ? _value.preferredPrograms
          : preferredPrograms // ignore: cast_nullable_to_non_nullable
              as List<String>,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AllocationRuleModelImplCopyWith<$Res>
    implements $AllocationRuleModelCopyWith<$Res> {
  factory _$$AllocationRuleModelImplCopyWith(_$AllocationRuleModelImpl value,
          $Res Function(_$AllocationRuleModelImpl) then) =
      __$$AllocationRuleModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String academicYear,
      int maxStudentsPerSupervisor,
      List<String> preferredPrograms,
      bool enabled,
      DateTime? updatedAt});
}

/// @nodoc
class __$$AllocationRuleModelImplCopyWithImpl<$Res>
    extends _$AllocationRuleModelCopyWithImpl<$Res, _$AllocationRuleModelImpl>
    implements _$$AllocationRuleModelImplCopyWith<$Res> {
  __$$AllocationRuleModelImplCopyWithImpl(_$AllocationRuleModelImpl _value,
      $Res Function(_$AllocationRuleModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? academicYear = null,
    Object? maxStudentsPerSupervisor = null,
    Object? preferredPrograms = null,
    Object? enabled = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$AllocationRuleModelImpl(
      academicYear: null == academicYear
          ? _value.academicYear
          : academicYear // ignore: cast_nullable_to_non_nullable
              as String,
      maxStudentsPerSupervisor: null == maxStudentsPerSupervisor
          ? _value.maxStudentsPerSupervisor
          : maxStudentsPerSupervisor // ignore: cast_nullable_to_non_nullable
              as int,
      preferredPrograms: null == preferredPrograms
          ? _value._preferredPrograms
          : preferredPrograms // ignore: cast_nullable_to_non_nullable
              as List<String>,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AllocationRuleModelImpl implements _AllocationRuleModel {
  const _$AllocationRuleModelImpl(
      {required this.academicYear,
      required this.maxStudentsPerSupervisor,
      required final List<String> preferredPrograms,
      required this.enabled,
      this.updatedAt})
      : _preferredPrograms = preferredPrograms;

  factory _$AllocationRuleModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AllocationRuleModelImplFromJson(json);

  @override
  final String academicYear;
  @override
  final int maxStudentsPerSupervisor;
  final List<String> _preferredPrograms;
  @override
  List<String> get preferredPrograms {
    if (_preferredPrograms is EqualUnmodifiableListView)
      return _preferredPrograms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_preferredPrograms);
  }

  @override
  final bool enabled;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'AllocationRuleModel(academicYear: $academicYear, maxStudentsPerSupervisor: $maxStudentsPerSupervisor, preferredPrograms: $preferredPrograms, enabled: $enabled, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AllocationRuleModelImpl &&
            (identical(other.academicYear, academicYear) ||
                other.academicYear == academicYear) &&
            (identical(
                    other.maxStudentsPerSupervisor, maxStudentsPerSupervisor) ||
                other.maxStudentsPerSupervisor == maxStudentsPerSupervisor) &&
            const DeepCollectionEquality()
                .equals(other._preferredPrograms, _preferredPrograms) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      academicYear,
      maxStudentsPerSupervisor,
      const DeepCollectionEquality().hash(_preferredPrograms),
      enabled,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AllocationRuleModelImplCopyWith<_$AllocationRuleModelImpl> get copyWith =>
      __$$AllocationRuleModelImplCopyWithImpl<_$AllocationRuleModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AllocationRuleModelImplToJson(
      this,
    );
  }
}

abstract class _AllocationRuleModel implements AllocationRuleModel {
  const factory _AllocationRuleModel(
      {required final String academicYear,
      required final int maxStudentsPerSupervisor,
      required final List<String> preferredPrograms,
      required final bool enabled,
      final DateTime? updatedAt}) = _$AllocationRuleModelImpl;

  factory _AllocationRuleModel.fromJson(Map<String, dynamic> json) =
      _$AllocationRuleModelImpl.fromJson;

  @override
  String get academicYear;
  @override
  int get maxStudentsPerSupervisor;
  @override
  List<String> get preferredPrograms;
  @override
  bool get enabled;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$AllocationRuleModelImplCopyWith<_$AllocationRuleModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
