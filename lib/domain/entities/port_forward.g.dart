// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'port_forward.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PortForward _$PortForwardFromJson(Map<String, dynamic> json) => _PortForward(
  id: json['id'] as String,
  hostId: json['hostId'] as String,
  kind: $enumDecode(_$PortForwardKindEnumMap, json['kind']),
  listenPort: (json['listenPort'] as num).toInt(),
  destinationHost: json['destinationHost'] as String?,
  destinationPort: (json['destinationPort'] as num?)?.toInt(),
  bindAddress: json['bindAddress'] as String? ?? '127.0.0.1',
  label: json['label'] as String?,
);

Map<String, dynamic> _$PortForwardToJson(_PortForward instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hostId': instance.hostId,
      'kind': _$PortForwardKindEnumMap[instance.kind]!,
      'listenPort': instance.listenPort,
      'destinationHost': instance.destinationHost,
      'destinationPort': instance.destinationPort,
      'bindAddress': instance.bindAddress,
      'label': instance.label,
    };

const _$PortForwardKindEnumMap = {
  PortForwardKind.local: 'local',
  PortForwardKind.remote: 'remote',
  PortForwardKind.dynamic: 'dynamic',
};
