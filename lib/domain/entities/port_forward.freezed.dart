// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'port_forward.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PortForward {

 String get id; String get hostId; PortForwardKind get kind;/// The port that is listened on — here for local and dynamic, on the
/// server for remote.
 int get listenPort;/// Where traffic is sent. Unused for a dynamic forward, which decides per
/// connection from the SOCKS request.
 String? get destinationHost;/// The port traffic is sent to.
 int? get destinationPort;/// The address to bind. `127.0.0.1` keeps a local forward private to this
/// machine, which is the right default — binding `0.0.0.0` exposes it to
/// the whole network.
 String get bindAddress;/// What the user calls it.
 String? get label;
/// Create a copy of PortForward
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortForwardCopyWith<PortForward> get copyWith => _$PortForwardCopyWithImpl<PortForward>(this as PortForward, _$identity);

  /// Serializes this PortForward to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PortForward;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortForward&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.hostId, _this.hostId) || other.hostId == _this.hostId)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.listenPort, _this.listenPort) || other.listenPort == _this.listenPort)&&(identical(other.destinationHost, _this.destinationHost) || other.destinationHost == _this.destinationHost)&&(identical(other.destinationPort, _this.destinationPort) || other.destinationPort == _this.destinationPort)&&(identical(other.bindAddress, _this.bindAddress) || other.bindAddress == _this.bindAddress)&&(identical(other.label, _this.label) || other.label == _this.label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PortForward;
  return Object.hash(runtimeType,_this.id,_this.hostId,_this.kind,_this.listenPort,_this.destinationHost,_this.destinationPort,_this.bindAddress,_this.label);
}

@override
String toString() {
  final _this = this as PortForward;
  return 'PortForward(id: ${_this.id}, hostId: ${_this.hostId}, kind: ${_this.kind}, listenPort: ${_this.listenPort}, destinationHost: ${_this.destinationHost}, destinationPort: ${_this.destinationPort}, bindAddress: ${_this.bindAddress}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $PortForwardCopyWith<$Res>  {
  factory $PortForwardCopyWith(PortForward value, $Res Function(PortForward) _then) = _$PortForwardCopyWithImpl;
@useResult
$Res call({
 String id, String hostId, PortForwardKind kind, int listenPort, String? destinationHost, int? destinationPort, String bindAddress, String? label
});




}
/// @nodoc
class _$PortForwardCopyWithImpl<$Res>
    implements $PortForwardCopyWith<$Res> {
  _$PortForwardCopyWithImpl(this._self, this._then);

  final PortForward _self;
  final $Res Function(PortForward) _then;

/// Create a copy of PortForward
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? hostId = null,Object? kind = null,Object? listenPort = null,Object? destinationHost = freezed,Object? destinationPort = freezed,Object? bindAddress = null,Object? label = freezed,}) {
  return _then(PortForward(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PortForwardKind,listenPort: null == listenPort ? _self.listenPort : listenPort // ignore: cast_nullable_to_non_nullable
as int,destinationHost: freezed == destinationHost ? _self.destinationHost : destinationHost // ignore: cast_nullable_to_non_nullable
as String?,destinationPort: freezed == destinationPort ? _self.destinationPort : destinationPort // ignore: cast_nullable_to_non_nullable
as int?,bindAddress: null == bindAddress ? _self.bindAddress : bindAddress // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PortForward].
extension PortForwardPatterns on PortForward {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortForward value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortForward() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortForward value)  $default,){
final _that = this;
switch (_that) {
case _PortForward():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortForward value)?  $default,){
final _that = this;
switch (_that) {
case _PortForward() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String hostId,  PortForwardKind kind,  int listenPort,  String? destinationHost,  int? destinationPort,  String bindAddress,  String? label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortForward() when $default != null:
return $default(_that.id,_that.hostId,_that.kind,_that.listenPort,_that.destinationHost,_that.destinationPort,_that.bindAddress,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String hostId,  PortForwardKind kind,  int listenPort,  String? destinationHost,  int? destinationPort,  String bindAddress,  String? label)  $default,) {final _that = this;
switch (_that) {
case _PortForward():
return $default(_that.id,_that.hostId,_that.kind,_that.listenPort,_that.destinationHost,_that.destinationPort,_that.bindAddress,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String hostId,  PortForwardKind kind,  int listenPort,  String? destinationHost,  int? destinationPort,  String bindAddress,  String? label)?  $default,) {final _that = this;
switch (_that) {
case _PortForward() when $default != null:
return $default(_that.id,_that.hostId,_that.kind,_that.listenPort,_that.destinationHost,_that.destinationPort,_that.bindAddress,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PortForward extends PortForward {
  const _PortForward({required this.id, required this.hostId, required this.kind, required this.listenPort, this.destinationHost, this.destinationPort, this.bindAddress = '127.0.0.1', this.label}): super._();
  factory _PortForward.fromJson(Map<String, dynamic> json) => _$PortForwardFromJson(json);

@override final  String id;
@override final  String hostId;
@override final  PortForwardKind kind;
/// The port that is listened on — here for local and dynamic, on the
/// server for remote.
@override final  int listenPort;
/// Where traffic is sent. Unused for a dynamic forward, which decides per
/// connection from the SOCKS request.
@override final  String? destinationHost;
/// The port traffic is sent to.
@override final  int? destinationPort;
/// The address to bind. `127.0.0.1` keeps a local forward private to this
/// machine, which is the right default — binding `0.0.0.0` exposes it to
/// the whole network.
@override@JsonKey() final  String bindAddress;
/// What the user calls it.
@override final  String? label;

/// Create a copy of PortForward
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortForwardCopyWith<_PortForward> get copyWith => __$PortForwardCopyWithImpl<_PortForward>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PortForwardToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortForward&&(identical(other.id, id) || other.id == id)&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.listenPort, listenPort) || other.listenPort == listenPort)&&(identical(other.destinationHost, destinationHost) || other.destinationHost == destinationHost)&&(identical(other.destinationPort, destinationPort) || other.destinationPort == destinationPort)&&(identical(other.bindAddress, bindAddress) || other.bindAddress == bindAddress)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,hostId,kind,listenPort,destinationHost,destinationPort,bindAddress,label);
}

@override
String toString() {
    return 'PortForward(id: $id, hostId: $hostId, kind: $kind, listenPort: $listenPort, destinationHost: $destinationHost, destinationPort: $destinationPort, bindAddress: $bindAddress, label: $label)';
}


}

/// @nodoc
abstract mixin class _$PortForwardCopyWith<$Res> implements $PortForwardCopyWith<$Res> {
  factory _$PortForwardCopyWith(_PortForward value, $Res Function(_PortForward) _then) = __$PortForwardCopyWithImpl;
@override @useResult
$Res call({
 String id, String hostId, PortForwardKind kind, int listenPort, String? destinationHost, int? destinationPort, String bindAddress, String? label
});




}
/// @nodoc
class __$PortForwardCopyWithImpl<$Res>
    implements _$PortForwardCopyWith<$Res> {
  __$PortForwardCopyWithImpl(this._self, this._then);

  final _PortForward _self;
  final $Res Function(_PortForward) _then;

/// Create a copy of PortForward
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? hostId = null,Object? kind = null,Object? listenPort = null,Object? destinationHost = freezed,Object? destinationPort = freezed,Object? bindAddress = null,Object? label = freezed,}) {
  return _then(_PortForward(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PortForwardKind,listenPort: null == listenPort ? _self.listenPort : listenPort // ignore: cast_nullable_to_non_nullable
as int,destinationHost: freezed == destinationHost ? _self.destinationHost : destinationHost // ignore: cast_nullable_to_non_nullable
as String?,destinationPort: freezed == destinationPort ? _self.destinationPort : destinationPort // ignore: cast_nullable_to_non_nullable
as int?,bindAddress: null == bindAddress ? _self.bindAddress : bindAddress // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
