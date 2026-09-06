// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TerminalSettings _$TerminalSettingsFromJson(Map<String, dynamic> json) =>
    _TerminalSettings(
      paletteId: json['paletteId'] as String?,
      themeMode:
          $enumDecodeNullable(_$AppThemeModeEnumMap, json['themeMode']) ??
          AppThemeMode.system,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.2,
      cursorShape:
          $enumDecodeNullable(
            _$TerminalCursorShapeEnumMap,
            json['cursorShape'],
          ) ??
          TerminalCursorShape.block,
      cursorBlinks: json['cursorBlinks'] as bool? ?? true,
      bell:
          $enumDecodeNullable(_$BellBehaviourEnumMap, json['bell']) ??
          BellBehaviour.visual,
      scrollbackLines: (json['scrollbackLines'] as num?)?.toInt() ?? 10000,
      relayUrl: json['relayUrl'] as String?,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    );

Map<String, dynamic> _$TerminalSettingsToJson(_TerminalSettings instance) =>
    <String, dynamic>{
      'paletteId': instance.paletteId,
      'themeMode': _$AppThemeModeEnumMap[instance.themeMode]!,
      'fontSize': instance.fontSize,
      'lineHeight': instance.lineHeight,
      'cursorShape': _$TerminalCursorShapeEnumMap[instance.cursorShape]!,
      'cursorBlinks': instance.cursorBlinks,
      'bell': _$BellBehaviourEnumMap[instance.bell]!,
      'scrollbackLines': instance.scrollbackLines,
      'relayUrl': instance.relayUrl,
      'onboardingComplete': instance.onboardingComplete,
    };

const _$AppThemeModeEnumMap = {
  AppThemeMode.system: 'system',
  AppThemeMode.light: 'light',
  AppThemeMode.dark: 'dark',
};

const _$TerminalCursorShapeEnumMap = {
  TerminalCursorShape.block: 'block',
  TerminalCursorShape.bar: 'bar',
  TerminalCursorShape.underline: 'underline',
};

const _$BellBehaviourEnumMap = {
  BellBehaviour.none: 'none',
  BellBehaviour.visual: 'visual',
  BellBehaviour.haptic: 'haptic',
};
