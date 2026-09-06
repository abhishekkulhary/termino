// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snippet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Snippet _$SnippetFromJson(Map<String, dynamic> json) => _Snippet(
  id: json['id'] as String,
  name: json['name'] as String,
  body: json['body'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  hostId: json['hostId'] as String?,
  runImmediately: json['runImmediately'] as bool? ?? false,
);

Map<String, dynamic> _$SnippetToJson(_Snippet instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'body': instance.body,
  'createdAt': instance.createdAt.toIso8601String(),
  'hostId': instance.hostId,
  'runImmediately': instance.runImmediately,
};
