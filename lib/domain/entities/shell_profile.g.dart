// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shell_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShellProfile _$ShellProfileFromJson(Map<String, dynamic> json) =>
    _ShellProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      executable: json['executable'] as String,
      arguments:
          (json['arguments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      environment:
          (json['environment'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      workingDirectory: json['workingDirectory'] as String?,
    );

Map<String, dynamic> _$ShellProfileToJson(_ShellProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'executable': instance.executable,
      'arguments': instance.arguments,
      'environment': instance.environment,
      'workingDirectory': instance.workingDirectory,
    };
