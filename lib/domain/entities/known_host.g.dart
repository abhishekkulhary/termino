// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'known_host.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KnownHost _$KnownHostFromJson(Map<String, dynamic> json) => _KnownHost(
  host: json['host'] as String,
  port: (json['port'] as num).toInt(),
  keyType: json['keyType'] as String,
  fingerprint: json['fingerprint'] as String,
  addedAt: DateTime.parse(json['addedAt'] as String),
  source: $enumDecode(_$KnownHostSourceEnumMap, json['source']),
  publicKey: json['publicKey'] as String?,
);

Map<String, dynamic> _$KnownHostToJson(_KnownHost instance) =>
    <String, dynamic>{
      'host': instance.host,
      'port': instance.port,
      'keyType': instance.keyType,
      'fingerprint': instance.fingerprint,
      'addedAt': instance.addedAt.toIso8601String(),
      'source': _$KnownHostSourceEnumMap[instance.source]!,
      'publicKey': instance.publicKey,
    };

const _$KnownHostSourceEnumMap = {
  KnownHostSource.trustOnFirstUse: 'trustOnFirstUse',
  KnownHostSource.imported: 'imported',
};
