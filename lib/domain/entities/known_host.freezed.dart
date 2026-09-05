// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'known_host.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KnownHost {

 String get host; int get port; String get keyType;/// OpenSSH-style fingerprint, e.g. `SHA256:SoUNE+BPf...`.
 String get fingerprint; DateTime get addedAt; KnownHostSource get source;/// The base64 key blob, when known. Present for imported entries only.
 String? get publicKey;
/// Create a copy of KnownHost
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KnownHostCopyWith<KnownHost> get copyWith => _$KnownHostCopyWithImpl<KnownHost>(this as KnownHost, _$identity);

  /// Serializes this KnownHost to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as KnownHost;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KnownHost&&(identical(other.host, _this.host) || other.host == _this.host)&&(identical(other.port, _this.port) || other.port == _this.port)&&(identical(other.keyType, _this.keyType) || other.keyType == _this.keyType)&&(identical(other.fingerprint, _this.fingerprint) || other.fingerprint == _this.fingerprint)&&(identical(other.addedAt, _this.addedAt) || other.addedAt == _this.addedAt)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.publicKey, _this.publicKey) || other.publicKey == _this.publicKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as KnownHost;
  return Object.hash(runtimeType,_this.host,_this.port,_this.keyType,_this.fingerprint,_this.addedAt,_this.source,_this.publicKey);
}

@override
String toString() {
  final _this = this as KnownHost;
  return 'KnownHost(host: ${_this.host}, port: ${_this.port}, keyType: ${_this.keyType}, fingerprint: ${_this.fingerprint}, addedAt: ${_this.addedAt}, source: ${_this.source}, publicKey: ${_this.publicKey})';
}


}

/// @nodoc
abstract mixin class $KnownHostCopyWith<$Res>  {
  factory $KnownHostCopyWith(KnownHost value, $Res Function(KnownHost) _then) = _$KnownHostCopyWithImpl;
@useResult
$Res call({
 String host, int port, String keyType, String fingerprint, DateTime addedAt, KnownHostSource source, String? publicKey
});




}
/// @nodoc
class _$KnownHostCopyWithImpl<$Res>
    implements $KnownHostCopyWith<$Res> {
  _$KnownHostCopyWithImpl(this._self, this._then);

  final KnownHost _self;
  final $Res Function(KnownHost) _then;

/// Create a copy of KnownHost
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? host = null,Object? port = null,Object? keyType = null,Object? fingerprint = null,Object? addedAt = null,Object? source = null,Object? publicKey = freezed,}) {
  return _then(KnownHost(
host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,keyType: null == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as String,fingerprint: null == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as KnownHostSource,publicKey: freezed == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [KnownHost].
extension KnownHostPatterns on KnownHost {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KnownHost value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KnownHost() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KnownHost value)  $default,){
final _that = this;
switch (_that) {
case _KnownHost():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KnownHost value)?  $default,){
final _that = this;
switch (_that) {
case _KnownHost() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String host,  int port,  String keyType,  String fingerprint,  DateTime addedAt,  KnownHostSource source,  String? publicKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KnownHost() when $default != null:
return $default(_that.host,_that.port,_that.keyType,_that.fingerprint,_that.addedAt,_that.source,_that.publicKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String host,  int port,  String keyType,  String fingerprint,  DateTime addedAt,  KnownHostSource source,  String? publicKey)  $default,) {final _that = this;
switch (_that) {
case _KnownHost():
return $default(_that.host,_that.port,_that.keyType,_that.fingerprint,_that.addedAt,_that.source,_that.publicKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String host,  int port,  String keyType,  String fingerprint,  DateTime addedAt,  KnownHostSource source,  String? publicKey)?  $default,) {final _that = this;
switch (_that) {
case _KnownHost() when $default != null:
return $default(_that.host,_that.port,_that.keyType,_that.fingerprint,_that.addedAt,_that.source,_that.publicKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KnownHost extends KnownHost {
  const _KnownHost({required this.host, required this.port, required this.keyType, required this.fingerprint, required this.addedAt, required this.source, this.publicKey}): super._();
  factory _KnownHost.fromJson(Map<String, dynamic> json) => _$KnownHostFromJson(json);

@override final  String host;
@override final  int port;
@override final  String keyType;
/// OpenSSH-style fingerprint, e.g. `SHA256:SoUNE+BPf...`.
@override final  String fingerprint;
@override final  DateTime addedAt;
@override final  KnownHostSource source;
/// The base64 key blob, when known. Present for imported entries only.
@override final  String? publicKey;

/// Create a copy of KnownHost
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KnownHostCopyWith<_KnownHost> get copyWith => __$KnownHostCopyWithImpl<_KnownHost>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KnownHostToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _KnownHost&&(identical(other.host, host) || other.host == host)&&(identical(other.port, port) || other.port == port)&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.source, source) || other.source == source)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,host,port,keyType,fingerprint,addedAt,source,publicKey);
}

@override
String toString() {
    return 'KnownHost(host: $host, port: $port, keyType: $keyType, fingerprint: $fingerprint, addedAt: $addedAt, source: $source, publicKey: $publicKey)';
}


}

/// @nodoc
abstract mixin class _$KnownHostCopyWith<$Res> implements $KnownHostCopyWith<$Res> {
  factory _$KnownHostCopyWith(_KnownHost value, $Res Function(_KnownHost) _then) = __$KnownHostCopyWithImpl;
@override @useResult
$Res call({
 String host, int port, String keyType, String fingerprint, DateTime addedAt, KnownHostSource source, String? publicKey
});




}
/// @nodoc
class __$KnownHostCopyWithImpl<$Res>
    implements _$KnownHostCopyWith<$Res> {
  __$KnownHostCopyWithImpl(this._self, this._then);

  final _KnownHost _self;
  final $Res Function(_KnownHost) _then;

/// Create a copy of KnownHost
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? host = null,Object? port = null,Object? keyType = null,Object? fingerprint = null,Object? addedAt = null,Object? source = null,Object? publicKey = freezed,}) {
  return _then(_KnownHost(
host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,keyType: null == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as String,fingerprint: null == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as KnownHostSource,publicKey: freezed == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
