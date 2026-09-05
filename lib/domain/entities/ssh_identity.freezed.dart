// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ssh_identity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SshIdentity {

 String get id; String get name; SshKeyType get keyType;/// The key that goes in `authorized_keys`. Public, so safe to store.
 String get publicKey;/// OpenSSH-style `SHA256:...` fingerprint of the public key.
 String get fingerprint; DateTime get createdAt;/// Whether the stored private key is itself passphrase-encrypted.
 bool get hasPassphrase;/// Whether using this key requires a biometric or device-credential check.
 bool get requiresBiometrics;/// Free-text comment, usually `user@host` from the original key.
 String? get comment;
/// Create a copy of SshIdentity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SshIdentityCopyWith<SshIdentity> get copyWith => _$SshIdentityCopyWithImpl<SshIdentity>(this as SshIdentity, _$identity);

  /// Serializes this SshIdentity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SshIdentity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SshIdentity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.keyType, _this.keyType) || other.keyType == _this.keyType)&&(identical(other.publicKey, _this.publicKey) || other.publicKey == _this.publicKey)&&(identical(other.fingerprint, _this.fingerprint) || other.fingerprint == _this.fingerprint)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.hasPassphrase, _this.hasPassphrase) || other.hasPassphrase == _this.hasPassphrase)&&(identical(other.requiresBiometrics, _this.requiresBiometrics) || other.requiresBiometrics == _this.requiresBiometrics)&&(identical(other.comment, _this.comment) || other.comment == _this.comment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SshIdentity;
  return Object.hash(runtimeType,_this.id,_this.name,_this.keyType,_this.publicKey,_this.fingerprint,_this.createdAt,_this.hasPassphrase,_this.requiresBiometrics,_this.comment);
}

@override
String toString() {
  final _this = this as SshIdentity;
  return 'SshIdentity(id: ${_this.id}, name: ${_this.name}, keyType: ${_this.keyType}, publicKey: ${_this.publicKey}, fingerprint: ${_this.fingerprint}, createdAt: ${_this.createdAt}, hasPassphrase: ${_this.hasPassphrase}, requiresBiometrics: ${_this.requiresBiometrics}, comment: ${_this.comment})';
}


}

/// @nodoc
abstract mixin class $SshIdentityCopyWith<$Res>  {
  factory $SshIdentityCopyWith(SshIdentity value, $Res Function(SshIdentity) _then) = _$SshIdentityCopyWithImpl;
@useResult
$Res call({
 String id, String name, SshKeyType keyType, String publicKey, String fingerprint, DateTime createdAt, bool hasPassphrase, bool requiresBiometrics, String? comment
});




}
/// @nodoc
class _$SshIdentityCopyWithImpl<$Res>
    implements $SshIdentityCopyWith<$Res> {
  _$SshIdentityCopyWithImpl(this._self, this._then);

  final SshIdentity _self;
  final $Res Function(SshIdentity) _then;

/// Create a copy of SshIdentity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? keyType = null,Object? publicKey = null,Object? fingerprint = null,Object? createdAt = null,Object? hasPassphrase = null,Object? requiresBiometrics = null,Object? comment = freezed,}) {
  return _then(SshIdentity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,keyType: null == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as SshKeyType,publicKey: null == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String,fingerprint: null == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,hasPassphrase: null == hasPassphrase ? _self.hasPassphrase : hasPassphrase // ignore: cast_nullable_to_non_nullable
as bool,requiresBiometrics: null == requiresBiometrics ? _self.requiresBiometrics : requiresBiometrics // ignore: cast_nullable_to_non_nullable
as bool,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SshIdentity].
extension SshIdentityPatterns on SshIdentity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SshIdentity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SshIdentity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SshIdentity value)  $default,){
final _that = this;
switch (_that) {
case _SshIdentity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SshIdentity value)?  $default,){
final _that = this;
switch (_that) {
case _SshIdentity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  SshKeyType keyType,  String publicKey,  String fingerprint,  DateTime createdAt,  bool hasPassphrase,  bool requiresBiometrics,  String? comment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SshIdentity() when $default != null:
return $default(_that.id,_that.name,_that.keyType,_that.publicKey,_that.fingerprint,_that.createdAt,_that.hasPassphrase,_that.requiresBiometrics,_that.comment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  SshKeyType keyType,  String publicKey,  String fingerprint,  DateTime createdAt,  bool hasPassphrase,  bool requiresBiometrics,  String? comment)  $default,) {final _that = this;
switch (_that) {
case _SshIdentity():
return $default(_that.id,_that.name,_that.keyType,_that.publicKey,_that.fingerprint,_that.createdAt,_that.hasPassphrase,_that.requiresBiometrics,_that.comment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  SshKeyType keyType,  String publicKey,  String fingerprint,  DateTime createdAt,  bool hasPassphrase,  bool requiresBiometrics,  String? comment)?  $default,) {final _that = this;
switch (_that) {
case _SshIdentity() when $default != null:
return $default(_that.id,_that.name,_that.keyType,_that.publicKey,_that.fingerprint,_that.createdAt,_that.hasPassphrase,_that.requiresBiometrics,_that.comment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SshIdentity extends SshIdentity {
  const _SshIdentity({required this.id, required this.name, required this.keyType, required this.publicKey, required this.fingerprint, required this.createdAt, this.hasPassphrase = false, this.requiresBiometrics = false, this.comment}): super._();
  factory _SshIdentity.fromJson(Map<String, dynamic> json) => _$SshIdentityFromJson(json);

@override final  String id;
@override final  String name;
@override final  SshKeyType keyType;
/// The key that goes in `authorized_keys`. Public, so safe to store.
@override final  String publicKey;
/// OpenSSH-style `SHA256:...` fingerprint of the public key.
@override final  String fingerprint;
@override final  DateTime createdAt;
/// Whether the stored private key is itself passphrase-encrypted.
@override@JsonKey() final  bool hasPassphrase;
/// Whether using this key requires a biometric or device-credential check.
@override@JsonKey() final  bool requiresBiometrics;
/// Free-text comment, usually `user@host` from the original key.
@override final  String? comment;

/// Create a copy of SshIdentity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SshIdentityCopyWith<_SshIdentity> get copyWith => __$SshIdentityCopyWithImpl<_SshIdentity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SshIdentityToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SshIdentity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.keyType, keyType) || other.keyType == keyType)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.hasPassphrase, hasPassphrase) || other.hasPassphrase == hasPassphrase)&&(identical(other.requiresBiometrics, requiresBiometrics) || other.requiresBiometrics == requiresBiometrics)&&(identical(other.comment, comment) || other.comment == comment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,keyType,publicKey,fingerprint,createdAt,hasPassphrase,requiresBiometrics,comment);
}

@override
String toString() {
    return 'SshIdentity(id: $id, name: $name, keyType: $keyType, publicKey: $publicKey, fingerprint: $fingerprint, createdAt: $createdAt, hasPassphrase: $hasPassphrase, requiresBiometrics: $requiresBiometrics, comment: $comment)';
}


}

/// @nodoc
abstract mixin class _$SshIdentityCopyWith<$Res> implements $SshIdentityCopyWith<$Res> {
  factory _$SshIdentityCopyWith(_SshIdentity value, $Res Function(_SshIdentity) _then) = __$SshIdentityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, SshKeyType keyType, String publicKey, String fingerprint, DateTime createdAt, bool hasPassphrase, bool requiresBiometrics, String? comment
});




}
/// @nodoc
class __$SshIdentityCopyWithImpl<$Res>
    implements _$SshIdentityCopyWith<$Res> {
  __$SshIdentityCopyWithImpl(this._self, this._then);

  final _SshIdentity _self;
  final $Res Function(_SshIdentity) _then;

/// Create a copy of SshIdentity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? keyType = null,Object? publicKey = null,Object? fingerprint = null,Object? createdAt = null,Object? hasPassphrase = null,Object? requiresBiometrics = null,Object? comment = freezed,}) {
  return _then(_SshIdentity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,keyType: null == keyType ? _self.keyType : keyType // ignore: cast_nullable_to_non_nullable
as SshKeyType,publicKey: null == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String,fingerprint: null == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,hasPassphrase: null == hasPassphrase ? _self.hasPassphrase : hasPassphrase // ignore: cast_nullable_to_non_nullable
as bool,requiresBiometrics: null == requiresBiometrics ? _self.requiresBiometrics : requiresBiometrics // ignore: cast_nullable_to_non_nullable
as bool,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
