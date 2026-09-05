// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ssh_identity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SshIdentity _$SshIdentityFromJson(Map<String, dynamic> json) => _SshIdentity(
  id: json['id'] as String,
  name: json['name'] as String,
  keyType: $enumDecode(_$SshKeyTypeEnumMap, json['keyType']),
  publicKey: json['publicKey'] as String,
  fingerprint: json['fingerprint'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  hasPassphrase: json['hasPassphrase'] as bool? ?? false,
  requiresBiometrics: json['requiresBiometrics'] as bool? ?? false,
  comment: json['comment'] as String?,
);

Map<String, dynamic> _$SshIdentityToJson(_SshIdentity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'keyType': _$SshKeyTypeEnumMap[instance.keyType]!,
      'publicKey': instance.publicKey,
      'fingerprint': instance.fingerprint,
      'createdAt': instance.createdAt.toIso8601String(),
      'hasPassphrase': instance.hasPassphrase,
      'requiresBiometrics': instance.requiresBiometrics,
      'comment': instance.comment,
    };

const _$SshKeyTypeEnumMap = {
  SshKeyType.ed25519: 'ed25519',
  SshKeyType.rsa: 'rsa',
  SshKeyType.ecdsa: 'ecdsa',
};
