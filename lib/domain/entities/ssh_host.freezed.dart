// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ssh_host.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SshHost {

 String get id; String get label; String get hostname; String get username; int get port;/// The identity to authenticate with, when using public key auth.
 String? get identityId;/// Which methods to offer, in order. An empty list means "try everything".
 List<SshAuthMethod> get authMethods;/// The id of another [SshHost] to tunnel through, as OpenSSH's ProxyJump.
 String? get jumpHostId;/// How often to send a keepalive. Zero disables it.
 Duration get keepAliveInterval;/// A command to run once the shell opens, e.g. `tmux attach`.
 String? get startupCommand;/// A colour for the tab and the host list, as an ARGB value.
 int? get colorValue;/// Free-text grouping, shown as a folder in the host list.
 String? get folder;/// When this host was last connected to, or null if never.
 DateTime? get lastConnectedAt;/// Whether a remembered password exists in the keystore.
 bool get hasSavedPassword;/// Whether to forward this connection's key to the remote host, so that
/// it can authenticate onward without the key ever leaving this device.
///
/// Off by default. Forwarding lets anyone with root on the remote host use
/// the key for as long as the session lasts, which is a real cost and one
/// worth opting into deliberately.
 bool get forwardAgent;
/// Create a copy of SshHost
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SshHostCopyWith<SshHost> get copyWith => _$SshHostCopyWithImpl<SshHost>(this as SshHost, _$identity);

  /// Serializes this SshHost to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SshHost;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SshHost&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.hostname, _this.hostname) || other.hostname == _this.hostname)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.port, _this.port) || other.port == _this.port)&&(identical(other.identityId, _this.identityId) || other.identityId == _this.identityId)&&const DeepCollectionEquality().equals(other.authMethods, _this.authMethods)&&(identical(other.jumpHostId, _this.jumpHostId) || other.jumpHostId == _this.jumpHostId)&&(identical(other.keepAliveInterval, _this.keepAliveInterval) || other.keepAliveInterval == _this.keepAliveInterval)&&(identical(other.startupCommand, _this.startupCommand) || other.startupCommand == _this.startupCommand)&&(identical(other.colorValue, _this.colorValue) || other.colorValue == _this.colorValue)&&(identical(other.folder, _this.folder) || other.folder == _this.folder)&&(identical(other.lastConnectedAt, _this.lastConnectedAt) || other.lastConnectedAt == _this.lastConnectedAt)&&(identical(other.hasSavedPassword, _this.hasSavedPassword) || other.hasSavedPassword == _this.hasSavedPassword)&&(identical(other.forwardAgent, _this.forwardAgent) || other.forwardAgent == _this.forwardAgent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SshHost;
  return Object.hash(runtimeType,_this.id,_this.label,_this.hostname,_this.username,_this.port,_this.identityId,const DeepCollectionEquality().hash(_this.authMethods),_this.jumpHostId,_this.keepAliveInterval,_this.startupCommand,_this.colorValue,_this.folder,_this.lastConnectedAt,_this.hasSavedPassword,_this.forwardAgent);
}

@override
String toString() {
  final _this = this as SshHost;
  return 'SshHost(id: ${_this.id}, label: ${_this.label}, hostname: ${_this.hostname}, username: ${_this.username}, port: ${_this.port}, identityId: ${_this.identityId}, authMethods: ${_this.authMethods}, jumpHostId: ${_this.jumpHostId}, keepAliveInterval: ${_this.keepAliveInterval}, startupCommand: ${_this.startupCommand}, colorValue: ${_this.colorValue}, folder: ${_this.folder}, lastConnectedAt: ${_this.lastConnectedAt}, hasSavedPassword: ${_this.hasSavedPassword}, forwardAgent: ${_this.forwardAgent})';
}


}

/// @nodoc
abstract mixin class $SshHostCopyWith<$Res>  {
  factory $SshHostCopyWith(SshHost value, $Res Function(SshHost) _then) = _$SshHostCopyWithImpl;
@useResult
$Res call({
 String id, String label, String hostname, String username, int port, String? identityId, List<SshAuthMethod> authMethods, String? jumpHostId, Duration keepAliveInterval, String? startupCommand, int? colorValue, String? folder, DateTime? lastConnectedAt, bool hasSavedPassword, bool forwardAgent
});




}
/// @nodoc
class _$SshHostCopyWithImpl<$Res>
    implements $SshHostCopyWith<$Res> {
  _$SshHostCopyWithImpl(this._self, this._then);

  final SshHost _self;
  final $Res Function(SshHost) _then;

/// Create a copy of SshHost
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? hostname = null,Object? username = null,Object? port = null,Object? identityId = freezed,Object? authMethods = null,Object? jumpHostId = freezed,Object? keepAliveInterval = null,Object? startupCommand = freezed,Object? colorValue = freezed,Object? folder = freezed,Object? lastConnectedAt = freezed,Object? hasSavedPassword = null,Object? forwardAgent = null,}) {
  return _then(SshHost(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,hostname: null == hostname ? _self.hostname : hostname // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,identityId: freezed == identityId ? _self.identityId : identityId // ignore: cast_nullable_to_non_nullable
as String?,authMethods: null == authMethods ? _self.authMethods : authMethods // ignore: cast_nullable_to_non_nullable
as List<SshAuthMethod>,jumpHostId: freezed == jumpHostId ? _self.jumpHostId : jumpHostId // ignore: cast_nullable_to_non_nullable
as String?,keepAliveInterval: null == keepAliveInterval ? _self.keepAliveInterval : keepAliveInterval // ignore: cast_nullable_to_non_nullable
as Duration,startupCommand: freezed == startupCommand ? _self.startupCommand : startupCommand // ignore: cast_nullable_to_non_nullable
as String?,colorValue: freezed == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int?,folder: freezed == folder ? _self.folder : folder // ignore: cast_nullable_to_non_nullable
as String?,lastConnectedAt: freezed == lastConnectedAt ? _self.lastConnectedAt : lastConnectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,hasSavedPassword: null == hasSavedPassword ? _self.hasSavedPassword : hasSavedPassword // ignore: cast_nullable_to_non_nullable
as bool,forwardAgent: null == forwardAgent ? _self.forwardAgent : forwardAgent // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SshHost].
extension SshHostPatterns on SshHost {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SshHost value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SshHost() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SshHost value)  $default,){
final _that = this;
switch (_that) {
case _SshHost():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SshHost value)?  $default,){
final _that = this;
switch (_that) {
case _SshHost() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String hostname,  String username,  int port,  String? identityId,  List<SshAuthMethod> authMethods,  String? jumpHostId,  Duration keepAliveInterval,  String? startupCommand,  int? colorValue,  String? folder,  DateTime? lastConnectedAt,  bool hasSavedPassword,  bool forwardAgent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SshHost() when $default != null:
return $default(_that.id,_that.label,_that.hostname,_that.username,_that.port,_that.identityId,_that.authMethods,_that.jumpHostId,_that.keepAliveInterval,_that.startupCommand,_that.colorValue,_that.folder,_that.lastConnectedAt,_that.hasSavedPassword,_that.forwardAgent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String hostname,  String username,  int port,  String? identityId,  List<SshAuthMethod> authMethods,  String? jumpHostId,  Duration keepAliveInterval,  String? startupCommand,  int? colorValue,  String? folder,  DateTime? lastConnectedAt,  bool hasSavedPassword,  bool forwardAgent)  $default,) {final _that = this;
switch (_that) {
case _SshHost():
return $default(_that.id,_that.label,_that.hostname,_that.username,_that.port,_that.identityId,_that.authMethods,_that.jumpHostId,_that.keepAliveInterval,_that.startupCommand,_that.colorValue,_that.folder,_that.lastConnectedAt,_that.hasSavedPassword,_that.forwardAgent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String hostname,  String username,  int port,  String? identityId,  List<SshAuthMethod> authMethods,  String? jumpHostId,  Duration keepAliveInterval,  String? startupCommand,  int? colorValue,  String? folder,  DateTime? lastConnectedAt,  bool hasSavedPassword,  bool forwardAgent)?  $default,) {final _that = this;
switch (_that) {
case _SshHost() when $default != null:
return $default(_that.id,_that.label,_that.hostname,_that.username,_that.port,_that.identityId,_that.authMethods,_that.jumpHostId,_that.keepAliveInterval,_that.startupCommand,_that.colorValue,_that.folder,_that.lastConnectedAt,_that.hasSavedPassword,_that.forwardAgent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SshHost extends SshHost {
  const _SshHost({required this.id, required this.label, required this.hostname, required this.username, this.port = 22, this.identityId,  List<SshAuthMethod> authMethods = const <SshAuthMethod>[], this.jumpHostId, this.keepAliveInterval = const Duration(seconds: 30), this.startupCommand, this.colorValue, this.folder, this.lastConnectedAt, this.hasSavedPassword = false, this.forwardAgent = false}): _authMethods = authMethods,super._();
  factory _SshHost.fromJson(Map<String, dynamic> json) => _$SshHostFromJson(json);

@override final  String id;
@override final  String label;
@override final  String hostname;
@override final  String username;
@override@JsonKey() final  int port;
/// The identity to authenticate with, when using public key auth.
@override final  String? identityId;
/// Which methods to offer, in order. An empty list means "try everything".
 final  List<SshAuthMethod> _authMethods;
/// Which methods to offer, in order. An empty list means "try everything".
@override@JsonKey() List<SshAuthMethod> get authMethods {
  if (_authMethods is EqualUnmodifiableListView) return _authMethods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_authMethods);
}

/// The id of another [SshHost] to tunnel through, as OpenSSH's ProxyJump.
@override final  String? jumpHostId;
/// How often to send a keepalive. Zero disables it.
@override@JsonKey() final  Duration keepAliveInterval;
/// A command to run once the shell opens, e.g. `tmux attach`.
@override final  String? startupCommand;
/// A colour for the tab and the host list, as an ARGB value.
@override final  int? colorValue;
/// Free-text grouping, shown as a folder in the host list.
@override final  String? folder;
/// When this host was last connected to, or null if never.
@override final  DateTime? lastConnectedAt;
/// Whether a remembered password exists in the keystore.
@override@JsonKey() final  bool hasSavedPassword;
/// Whether to forward this connection's key to the remote host, so that
/// it can authenticate onward without the key ever leaving this device.
///
/// Off by default. Forwarding lets anyone with root on the remote host use
/// the key for as long as the session lasts, which is a real cost and one
/// worth opting into deliberately.
@override@JsonKey() final  bool forwardAgent;

/// Create a copy of SshHost
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SshHostCopyWith<_SshHost> get copyWith => __$SshHostCopyWithImpl<_SshHost>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SshHostToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SshHost&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.hostname, hostname) || other.hostname == hostname)&&(identical(other.username, username) || other.username == username)&&(identical(other.port, port) || other.port == port)&&(identical(other.identityId, identityId) || other.identityId == identityId)&&const DeepCollectionEquality().equals(other.authMethods, _authMethods)&&(identical(other.jumpHostId, jumpHostId) || other.jumpHostId == jumpHostId)&&(identical(other.keepAliveInterval, keepAliveInterval) || other.keepAliveInterval == keepAliveInterval)&&(identical(other.startupCommand, startupCommand) || other.startupCommand == startupCommand)&&(identical(other.colorValue, colorValue) || other.colorValue == colorValue)&&(identical(other.folder, folder) || other.folder == folder)&&(identical(other.lastConnectedAt, lastConnectedAt) || other.lastConnectedAt == lastConnectedAt)&&(identical(other.hasSavedPassword, hasSavedPassword) || other.hasSavedPassword == hasSavedPassword)&&(identical(other.forwardAgent, forwardAgent) || other.forwardAgent == forwardAgent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,label,hostname,username,port,identityId,const DeepCollectionEquality().hash(_authMethods),jumpHostId,keepAliveInterval,startupCommand,colorValue,folder,lastConnectedAt,hasSavedPassword,forwardAgent);
}

@override
String toString() {
    return 'SshHost(id: $id, label: $label, hostname: $hostname, username: $username, port: $port, identityId: $identityId, authMethods: $authMethods, jumpHostId: $jumpHostId, keepAliveInterval: $keepAliveInterval, startupCommand: $startupCommand, colorValue: $colorValue, folder: $folder, lastConnectedAt: $lastConnectedAt, hasSavedPassword: $hasSavedPassword, forwardAgent: $forwardAgent)';
}


}

/// @nodoc
abstract mixin class _$SshHostCopyWith<$Res> implements $SshHostCopyWith<$Res> {
  factory _$SshHostCopyWith(_SshHost value, $Res Function(_SshHost) _then) = __$SshHostCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String hostname, String username, int port, String? identityId, List<SshAuthMethod> authMethods, String? jumpHostId, Duration keepAliveInterval, String? startupCommand, int? colorValue, String? folder, DateTime? lastConnectedAt, bool hasSavedPassword, bool forwardAgent
});




}
/// @nodoc
class __$SshHostCopyWithImpl<$Res>
    implements _$SshHostCopyWith<$Res> {
  __$SshHostCopyWithImpl(this._self, this._then);

  final _SshHost _self;
  final $Res Function(_SshHost) _then;

/// Create a copy of SshHost
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? hostname = null,Object? username = null,Object? port = null,Object? identityId = freezed,Object? authMethods = null,Object? jumpHostId = freezed,Object? keepAliveInterval = null,Object? startupCommand = freezed,Object? colorValue = freezed,Object? folder = freezed,Object? lastConnectedAt = freezed,Object? hasSavedPassword = null,Object? forwardAgent = null,}) {
  return _then(_SshHost(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,hostname: null == hostname ? _self.hostname : hostname // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,identityId: freezed == identityId ? _self.identityId : identityId // ignore: cast_nullable_to_non_nullable
as String?,authMethods: null == authMethods ? _self._authMethods : authMethods // ignore: cast_nullable_to_non_nullable
as List<SshAuthMethod>,jumpHostId: freezed == jumpHostId ? _self.jumpHostId : jumpHostId // ignore: cast_nullable_to_non_nullable
as String?,keepAliveInterval: null == keepAliveInterval ? _self.keepAliveInterval : keepAliveInterval // ignore: cast_nullable_to_non_nullable
as Duration,startupCommand: freezed == startupCommand ? _self.startupCommand : startupCommand // ignore: cast_nullable_to_non_nullable
as String?,colorValue: freezed == colorValue ? _self.colorValue : colorValue // ignore: cast_nullable_to_non_nullable
as int?,folder: freezed == folder ? _self.folder : folder // ignore: cast_nullable_to_non_nullable
as String?,lastConnectedAt: freezed == lastConnectedAt ? _self.lastConnectedAt : lastConnectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,hasSavedPassword: null == hasSavedPassword ? _self.hasSavedPassword : hasSavedPassword // ignore: cast_nullable_to_non_nullable
as bool,forwardAgent: null == forwardAgent ? _self.forwardAgent : forwardAgent // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
