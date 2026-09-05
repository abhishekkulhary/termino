// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ssh_host.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SshHost _$SshHostFromJson(Map<String, dynamic> json) => _SshHost(
  id: json['id'] as String,
  label: json['label'] as String,
  hostname: json['hostname'] as String,
  username: json['username'] as String,
  port: (json['port'] as num?)?.toInt() ?? 22,
  identityId: json['identityId'] as String?,
  authMethods:
      (json['authMethods'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$SshAuthMethodEnumMap, e))
          .toList() ??
      const <SshAuthMethod>[],
  jumpHostId: json['jumpHostId'] as String?,
  keepAliveInterval: json['keepAliveInterval'] == null
      ? const Duration(seconds: 30)
      : Duration(microseconds: (json['keepAliveInterval'] as num).toInt()),
  startupCommand: json['startupCommand'] as String?,
  colorValue: (json['colorValue'] as num?)?.toInt(),
  folder: json['folder'] as String?,
  hasSavedPassword: json['hasSavedPassword'] as bool? ?? false,
  forwardAgent: json['forwardAgent'] as bool? ?? false,
);

Map<String, dynamic> _$SshHostToJson(_SshHost instance) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'hostname': instance.hostname,
  'username': instance.username,
  'port': instance.port,
  'identityId': instance.identityId,
  'authMethods': instance.authMethods
      .map((e) => _$SshAuthMethodEnumMap[e]!)
      .toList(),
  'jumpHostId': instance.jumpHostId,
  'keepAliveInterval': instance.keepAliveInterval.inMicroseconds,
  'startupCommand': instance.startupCommand,
  'colorValue': instance.colorValue,
  'folder': instance.folder,
  'hasSavedPassword': instance.hasSavedPassword,
  'forwardAgent': instance.forwardAgent,
};

const _$SshAuthMethodEnumMap = {
  SshAuthMethod.publicKey: 'publicKey',
  SshAuthMethod.password: 'password',
  SshAuthMethod.keyboardInteractive: 'keyboardInteractive',
};
