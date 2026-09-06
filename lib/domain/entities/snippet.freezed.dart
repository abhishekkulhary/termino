// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'snippet.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Snippet {

 String get id; String get name; String get body; DateTime get createdAt;/// When set, this snippet only appears for that host.
///
/// A command that is right on one machine is often wrong on another, and a
/// list of everything you have ever saved is not a list anyone reads.
 String? get hostId;/// Whether a newline is appended, running the command immediately.
///
/// Off by default: sending text without running it lets the user read it
/// before committing, which matters for anything destructive.
 bool get runImmediately;
/// Create a copy of Snippet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SnippetCopyWith<Snippet> get copyWith => _$SnippetCopyWithImpl<Snippet>(this as Snippet, _$identity);

  /// Serializes this Snippet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Snippet;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Snippet&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.hostId, _this.hostId) || other.hostId == _this.hostId)&&(identical(other.runImmediately, _this.runImmediately) || other.runImmediately == _this.runImmediately));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Snippet;
  return Object.hash(runtimeType,_this.id,_this.name,_this.body,_this.createdAt,_this.hostId,_this.runImmediately);
}

@override
String toString() {
  final _this = this as Snippet;
  return 'Snippet(id: ${_this.id}, name: ${_this.name}, body: ${_this.body}, createdAt: ${_this.createdAt}, hostId: ${_this.hostId}, runImmediately: ${_this.runImmediately})';
}


}

/// @nodoc
abstract mixin class $SnippetCopyWith<$Res>  {
  factory $SnippetCopyWith(Snippet value, $Res Function(Snippet) _then) = _$SnippetCopyWithImpl;
@useResult
$Res call({
 String id, String name, String body, DateTime createdAt, String? hostId, bool runImmediately
});




}
/// @nodoc
class _$SnippetCopyWithImpl<$Res>
    implements $SnippetCopyWith<$Res> {
  _$SnippetCopyWithImpl(this._self, this._then);

  final Snippet _self;
  final $Res Function(Snippet) _then;

/// Create a copy of Snippet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? body = null,Object? createdAt = null,Object? hostId = freezed,Object? runImmediately = null,}) {
  return _then(Snippet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,hostId: freezed == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String?,runImmediately: null == runImmediately ? _self.runImmediately : runImmediately // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Snippet].
extension SnippetPatterns on Snippet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Snippet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Snippet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Snippet value)  $default,){
final _that = this;
switch (_that) {
case _Snippet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Snippet value)?  $default,){
final _that = this;
switch (_that) {
case _Snippet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String body,  DateTime createdAt,  String? hostId,  bool runImmediately)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Snippet() when $default != null:
return $default(_that.id,_that.name,_that.body,_that.createdAt,_that.hostId,_that.runImmediately);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String body,  DateTime createdAt,  String? hostId,  bool runImmediately)  $default,) {final _that = this;
switch (_that) {
case _Snippet():
return $default(_that.id,_that.name,_that.body,_that.createdAt,_that.hostId,_that.runImmediately);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String body,  DateTime createdAt,  String? hostId,  bool runImmediately)?  $default,) {final _that = this;
switch (_that) {
case _Snippet() when $default != null:
return $default(_that.id,_that.name,_that.body,_that.createdAt,_that.hostId,_that.runImmediately);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Snippet extends Snippet {
  const _Snippet({required this.id, required this.name, required this.body, required this.createdAt, this.hostId, this.runImmediately = false}): super._();
  factory _Snippet.fromJson(Map<String, dynamic> json) => _$SnippetFromJson(json);

@override final  String id;
@override final  String name;
@override final  String body;
@override final  DateTime createdAt;
/// When set, this snippet only appears for that host.
///
/// A command that is right on one machine is often wrong on another, and a
/// list of everything you have ever saved is not a list anyone reads.
@override final  String? hostId;
/// Whether a newline is appended, running the command immediately.
///
/// Off by default: sending text without running it lets the user read it
/// before committing, which matters for anything destructive.
@override@JsonKey() final  bool runImmediately;

/// Create a copy of Snippet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SnippetCopyWith<_Snippet> get copyWith => __$SnippetCopyWithImpl<_Snippet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SnippetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Snippet&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.runImmediately, runImmediately) || other.runImmediately == runImmediately));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,body,createdAt,hostId,runImmediately);
}

@override
String toString() {
    return 'Snippet(id: $id, name: $name, body: $body, createdAt: $createdAt, hostId: $hostId, runImmediately: $runImmediately)';
}


}

/// @nodoc
abstract mixin class _$SnippetCopyWith<$Res> implements $SnippetCopyWith<$Res> {
  factory _$SnippetCopyWith(_Snippet value, $Res Function(_Snippet) _then) = __$SnippetCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String body, DateTime createdAt, String? hostId, bool runImmediately
});




}
/// @nodoc
class __$SnippetCopyWithImpl<$Res>
    implements _$SnippetCopyWith<$Res> {
  __$SnippetCopyWithImpl(this._self, this._then);

  final _Snippet _self;
  final $Res Function(_Snippet) _then;

/// Create a copy of Snippet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? body = null,Object? createdAt = null,Object? hostId = freezed,Object? runImmediately = null,}) {
  return _then(_Snippet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,hostId: freezed == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String?,runImmediately: null == runImmediately ? _self.runImmediately : runImmediately // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
