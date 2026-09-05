// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shell_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShellProfile {

 String get id; String get name; String get executable; List<String> get arguments;/// Extra environment variables, merged over the inherited environment.
///
/// Note that the PTY layer always sets `TERM` and `LANG` itself, since a
/// terminal that does not announce its capabilities makes `vim` and `htop`
/// misbehave in ways that are tedious to diagnose.
 Map<String, String> get environment;/// Where the shell starts. Null means the user's home directory.
 String? get workingDirectory;
/// Create a copy of ShellProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShellProfileCopyWith<ShellProfile> get copyWith => _$ShellProfileCopyWithImpl<ShellProfile>(this as ShellProfile, _$identity);

  /// Serializes this ShellProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ShellProfile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShellProfile&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.executable, _this.executable) || other.executable == _this.executable)&&const DeepCollectionEquality().equals(other.arguments, _this.arguments)&&const DeepCollectionEquality().equals(other.environment, _this.environment)&&(identical(other.workingDirectory, _this.workingDirectory) || other.workingDirectory == _this.workingDirectory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShellProfile;
  return Object.hash(runtimeType,_this.id,_this.name,_this.executable,const DeepCollectionEquality().hash(_this.arguments),const DeepCollectionEquality().hash(_this.environment),_this.workingDirectory);
}

@override
String toString() {
  final _this = this as ShellProfile;
  return 'ShellProfile(id: ${_this.id}, name: ${_this.name}, executable: ${_this.executable}, arguments: ${_this.arguments}, environment: ${_this.environment}, workingDirectory: ${_this.workingDirectory})';
}


}

/// @nodoc
abstract mixin class $ShellProfileCopyWith<$Res>  {
  factory $ShellProfileCopyWith(ShellProfile value, $Res Function(ShellProfile) _then) = _$ShellProfileCopyWithImpl;
@useResult
$Res call({
 String id, String name, String executable, List<String> arguments, Map<String, String> environment, String? workingDirectory
});




}
/// @nodoc
class _$ShellProfileCopyWithImpl<$Res>
    implements $ShellProfileCopyWith<$Res> {
  _$ShellProfileCopyWithImpl(this._self, this._then);

  final ShellProfile _self;
  final $Res Function(ShellProfile) _then;

/// Create a copy of ShellProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? executable = null,Object? arguments = null,Object? environment = null,Object? workingDirectory = freezed,}) {
  return _then(ShellProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,executable: null == executable ? _self.executable : executable // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self.arguments : arguments // ignore: cast_nullable_to_non_nullable
as List<String>,environment: null == environment ? _self.environment : environment // ignore: cast_nullable_to_non_nullable
as Map<String, String>,workingDirectory: freezed == workingDirectory ? _self.workingDirectory : workingDirectory // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShellProfile].
extension ShellProfilePatterns on ShellProfile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShellProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShellProfile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShellProfile value)  $default,){
final _that = this;
switch (_that) {
case _ShellProfile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShellProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ShellProfile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String executable,  List<String> arguments,  Map<String, String> environment,  String? workingDirectory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShellProfile() when $default != null:
return $default(_that.id,_that.name,_that.executable,_that.arguments,_that.environment,_that.workingDirectory);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String executable,  List<String> arguments,  Map<String, String> environment,  String? workingDirectory)  $default,) {final _that = this;
switch (_that) {
case _ShellProfile():
return $default(_that.id,_that.name,_that.executable,_that.arguments,_that.environment,_that.workingDirectory);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String executable,  List<String> arguments,  Map<String, String> environment,  String? workingDirectory)?  $default,) {final _that = this;
switch (_that) {
case _ShellProfile() when $default != null:
return $default(_that.id,_that.name,_that.executable,_that.arguments,_that.environment,_that.workingDirectory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShellProfile extends ShellProfile {
  const _ShellProfile({required this.id, required this.name, required this.executable,  List<String> arguments = const <String>[],  Map<String, String> environment = const <String, String>{}, this.workingDirectory}): _arguments = arguments,_environment = environment,super._();
  factory _ShellProfile.fromJson(Map<String, dynamic> json) => _$ShellProfileFromJson(json);

@override final  String id;
@override final  String name;
@override final  String executable;
 final  List<String> _arguments;
@override@JsonKey() List<String> get arguments {
  if (_arguments is EqualUnmodifiableListView) return _arguments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_arguments);
}

/// Extra environment variables, merged over the inherited environment.
///
/// Note that the PTY layer always sets `TERM` and `LANG` itself, since a
/// terminal that does not announce its capabilities makes `vim` and `htop`
/// misbehave in ways that are tedious to diagnose.
 final  Map<String, String> _environment;
/// Extra environment variables, merged over the inherited environment.
///
/// Note that the PTY layer always sets `TERM` and `LANG` itself, since a
/// terminal that does not announce its capabilities makes `vim` and `htop`
/// misbehave in ways that are tedious to diagnose.
@override@JsonKey() Map<String, String> get environment {
  if (_environment is EqualUnmodifiableMapView) return _environment;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_environment);
}

/// Where the shell starts. Null means the user's home directory.
@override final  String? workingDirectory;

/// Create a copy of ShellProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShellProfileCopyWith<_ShellProfile> get copyWith => __$ShellProfileCopyWithImpl<_ShellProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShellProfileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShellProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.executable, executable) || other.executable == executable)&&const DeepCollectionEquality().equals(other.arguments, _arguments)&&const DeepCollectionEquality().equals(other.environment, _environment)&&(identical(other.workingDirectory, workingDirectory) || other.workingDirectory == workingDirectory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,executable,const DeepCollectionEquality().hash(_arguments),const DeepCollectionEquality().hash(_environment),workingDirectory);
}

@override
String toString() {
    return 'ShellProfile(id: $id, name: $name, executable: $executable, arguments: $arguments, environment: $environment, workingDirectory: $workingDirectory)';
}


}

/// @nodoc
abstract mixin class _$ShellProfileCopyWith<$Res> implements $ShellProfileCopyWith<$Res> {
  factory _$ShellProfileCopyWith(_ShellProfile value, $Res Function(_ShellProfile) _then) = __$ShellProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String executable, List<String> arguments, Map<String, String> environment, String? workingDirectory
});




}
/// @nodoc
class __$ShellProfileCopyWithImpl<$Res>
    implements _$ShellProfileCopyWith<$Res> {
  __$ShellProfileCopyWithImpl(this._self, this._then);

  final _ShellProfile _self;
  final $Res Function(_ShellProfile) _then;

/// Create a copy of ShellProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? executable = null,Object? arguments = null,Object? environment = null,Object? workingDirectory = freezed,}) {
  return _then(_ShellProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,executable: null == executable ? _self.executable : executable // ignore: cast_nullable_to_non_nullable
as String,arguments: null == arguments ? _self._arguments : arguments // ignore: cast_nullable_to_non_nullable
as List<String>,environment: null == environment ? _self._environment : environment // ignore: cast_nullable_to_non_nullable
as Map<String, String>,workingDirectory: freezed == workingDirectory ? _self.workingDirectory : workingDirectory // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
