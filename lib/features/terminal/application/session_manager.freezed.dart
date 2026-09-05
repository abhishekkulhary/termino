// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_manager.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionsState {

 List<TerminalSession> get sessions; String? get activeId;/// The session shown beside the active one, when the window is split.
///
/// Null means a single pane. Only ever set on window sizes that can
/// actually show two, which the UI enforces — a split on a phone would
/// leave two terminals too narrow to use.
 String? get secondaryId;
/// Create a copy of SessionsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionsStateCopyWith<SessionsState> get copyWith => _$SessionsStateCopyWithImpl<SessionsState>(this as SessionsState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SessionsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionsState&&const DeepCollectionEquality().equals(other.sessions, _this.sessions)&&(identical(other.activeId, _this.activeId) || other.activeId == _this.activeId)&&(identical(other.secondaryId, _this.secondaryId) || other.secondaryId == _this.secondaryId));
}


@override
int get hashCode {
  final _this = this as SessionsState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.sessions),_this.activeId,_this.secondaryId);
}

@override
String toString() {
  final _this = this as SessionsState;
  return 'SessionsState(sessions: ${_this.sessions}, activeId: ${_this.activeId}, secondaryId: ${_this.secondaryId})';
}


}

/// @nodoc
abstract mixin class $SessionsStateCopyWith<$Res>  {
  factory $SessionsStateCopyWith(SessionsState value, $Res Function(SessionsState) _then) = _$SessionsStateCopyWithImpl;
@useResult
$Res call({
 List<TerminalSession> sessions, String? activeId, String? secondaryId
});




}
/// @nodoc
class _$SessionsStateCopyWithImpl<$Res>
    implements $SessionsStateCopyWith<$Res> {
  _$SessionsStateCopyWithImpl(this._self, this._then);

  final SessionsState _self;
  final $Res Function(SessionsState) _then;

/// Create a copy of SessionsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessions = null,Object? activeId = freezed,Object? secondaryId = freezed,}) {
  return _then(SessionsState(
sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as List<TerminalSession>,activeId: freezed == activeId ? _self.activeId : activeId // ignore: cast_nullable_to_non_nullable
as String?,secondaryId: freezed == secondaryId ? _self.secondaryId : secondaryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionsState].
extension SessionsStatePatterns on SessionsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionsState value)  $default,){
final _that = this;
switch (_that) {
case _SessionsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionsState value)?  $default,){
final _that = this;
switch (_that) {
case _SessionsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TerminalSession> sessions,  String? activeId,  String? secondaryId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionsState() when $default != null:
return $default(_that.sessions,_that.activeId,_that.secondaryId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TerminalSession> sessions,  String? activeId,  String? secondaryId)  $default,) {final _that = this;
switch (_that) {
case _SessionsState():
return $default(_that.sessions,_that.activeId,_that.secondaryId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TerminalSession> sessions,  String? activeId,  String? secondaryId)?  $default,) {final _that = this;
switch (_that) {
case _SessionsState() when $default != null:
return $default(_that.sessions,_that.activeId,_that.secondaryId);case _:
  return null;

}
}

}

/// @nodoc


class _SessionsState extends SessionsState {
  const _SessionsState({ List<TerminalSession> sessions = const <TerminalSession>[], this.activeId, this.secondaryId}): _sessions = sessions,super._();
  

 final  List<TerminalSession> _sessions;
@override@JsonKey() List<TerminalSession> get sessions {
  if (_sessions is EqualUnmodifiableListView) return _sessions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sessions);
}

@override final  String? activeId;
/// The session shown beside the active one, when the window is split.
///
/// Null means a single pane. Only ever set on window sizes that can
/// actually show two, which the UI enforces — a split on a phone would
/// leave two terminals too narrow to use.
@override final  String? secondaryId;

/// Create a copy of SessionsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionsStateCopyWith<_SessionsState> get copyWith => __$SessionsStateCopyWithImpl<_SessionsState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionsState&&const DeepCollectionEquality().equals(other.sessions, _sessions)&&(identical(other.activeId, activeId) || other.activeId == activeId)&&(identical(other.secondaryId, secondaryId) || other.secondaryId == secondaryId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_sessions),activeId,secondaryId);
}

@override
String toString() {
    return 'SessionsState(sessions: $sessions, activeId: $activeId, secondaryId: $secondaryId)';
}


}

/// @nodoc
abstract mixin class _$SessionsStateCopyWith<$Res> implements $SessionsStateCopyWith<$Res> {
  factory _$SessionsStateCopyWith(_SessionsState value, $Res Function(_SessionsState) _then) = __$SessionsStateCopyWithImpl;
@override @useResult
$Res call({
 List<TerminalSession> sessions, String? activeId, String? secondaryId
});




}
/// @nodoc
class __$SessionsStateCopyWithImpl<$Res>
    implements _$SessionsStateCopyWith<$Res> {
  __$SessionsStateCopyWithImpl(this._self, this._then);

  final _SessionsState _self;
  final $Res Function(_SessionsState) _then;

/// Create a copy of SessionsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessions = null,Object? activeId = freezed,Object? secondaryId = freezed,}) {
  return _then(_SessionsState(
sessions: null == sessions ? _self._sessions : sessions // ignore: cast_nullable_to_non_nullable
as List<TerminalSession>,activeId: freezed == activeId ? _self.activeId : activeId // ignore: cast_nullable_to_non_nullable
as String?,secondaryId: freezed == secondaryId ? _self.secondaryId : secondaryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
