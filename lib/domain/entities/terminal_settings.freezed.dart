// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'terminal_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TerminalSettings {

/// The palette id, or null to follow the app theme.
 String? get paletteId; AppThemeMode get themeMode; double get fontSize; double get lineHeight; TerminalCursorShape get cursorShape; bool get cursorBlinks; BellBehaviour get bell; int get scrollbackLines;
/// Create a copy of TerminalSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TerminalSettingsCopyWith<TerminalSettings> get copyWith => _$TerminalSettingsCopyWithImpl<TerminalSettings>(this as TerminalSettings, _$identity);

  /// Serializes this TerminalSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TerminalSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TerminalSettings&&(identical(other.paletteId, _this.paletteId) || other.paletteId == _this.paletteId)&&(identical(other.themeMode, _this.themeMode) || other.themeMode == _this.themeMode)&&(identical(other.fontSize, _this.fontSize) || other.fontSize == _this.fontSize)&&(identical(other.lineHeight, _this.lineHeight) || other.lineHeight == _this.lineHeight)&&(identical(other.cursorShape, _this.cursorShape) || other.cursorShape == _this.cursorShape)&&(identical(other.cursorBlinks, _this.cursorBlinks) || other.cursorBlinks == _this.cursorBlinks)&&(identical(other.bell, _this.bell) || other.bell == _this.bell)&&(identical(other.scrollbackLines, _this.scrollbackLines) || other.scrollbackLines == _this.scrollbackLines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TerminalSettings;
  return Object.hash(runtimeType,_this.paletteId,_this.themeMode,_this.fontSize,_this.lineHeight,_this.cursorShape,_this.cursorBlinks,_this.bell,_this.scrollbackLines);
}

@override
String toString() {
  final _this = this as TerminalSettings;
  return 'TerminalSettings(paletteId: ${_this.paletteId}, themeMode: ${_this.themeMode}, fontSize: ${_this.fontSize}, lineHeight: ${_this.lineHeight}, cursorShape: ${_this.cursorShape}, cursorBlinks: ${_this.cursorBlinks}, bell: ${_this.bell}, scrollbackLines: ${_this.scrollbackLines})';
}


}

/// @nodoc
abstract mixin class $TerminalSettingsCopyWith<$Res>  {
  factory $TerminalSettingsCopyWith(TerminalSettings value, $Res Function(TerminalSettings) _then) = _$TerminalSettingsCopyWithImpl;
@useResult
$Res call({
 String? paletteId, AppThemeMode themeMode, double fontSize, double lineHeight, TerminalCursorShape cursorShape, bool cursorBlinks, BellBehaviour bell, int scrollbackLines
});




}
/// @nodoc
class _$TerminalSettingsCopyWithImpl<$Res>
    implements $TerminalSettingsCopyWith<$Res> {
  _$TerminalSettingsCopyWithImpl(this._self, this._then);

  final TerminalSettings _self;
  final $Res Function(TerminalSettings) _then;

/// Create a copy of TerminalSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? paletteId = freezed,Object? themeMode = null,Object? fontSize = null,Object? lineHeight = null,Object? cursorShape = null,Object? cursorBlinks = null,Object? bell = null,Object? scrollbackLines = null,}) {
  return _then(TerminalSettings(
paletteId: freezed == paletteId ? _self.paletteId : paletteId // ignore: cast_nullable_to_non_nullable
as String?,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,lineHeight: null == lineHeight ? _self.lineHeight : lineHeight // ignore: cast_nullable_to_non_nullable
as double,cursorShape: null == cursorShape ? _self.cursorShape : cursorShape // ignore: cast_nullable_to_non_nullable
as TerminalCursorShape,cursorBlinks: null == cursorBlinks ? _self.cursorBlinks : cursorBlinks // ignore: cast_nullable_to_non_nullable
as bool,bell: null == bell ? _self.bell : bell // ignore: cast_nullable_to_non_nullable
as BellBehaviour,scrollbackLines: null == scrollbackLines ? _self.scrollbackLines : scrollbackLines // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TerminalSettings].
extension TerminalSettingsPatterns on TerminalSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TerminalSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TerminalSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TerminalSettings value)  $default,){
final _that = this;
switch (_that) {
case _TerminalSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TerminalSettings value)?  $default,){
final _that = this;
switch (_that) {
case _TerminalSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? paletteId,  AppThemeMode themeMode,  double fontSize,  double lineHeight,  TerminalCursorShape cursorShape,  bool cursorBlinks,  BellBehaviour bell,  int scrollbackLines)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TerminalSettings() when $default != null:
return $default(_that.paletteId,_that.themeMode,_that.fontSize,_that.lineHeight,_that.cursorShape,_that.cursorBlinks,_that.bell,_that.scrollbackLines);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? paletteId,  AppThemeMode themeMode,  double fontSize,  double lineHeight,  TerminalCursorShape cursorShape,  bool cursorBlinks,  BellBehaviour bell,  int scrollbackLines)  $default,) {final _that = this;
switch (_that) {
case _TerminalSettings():
return $default(_that.paletteId,_that.themeMode,_that.fontSize,_that.lineHeight,_that.cursorShape,_that.cursorBlinks,_that.bell,_that.scrollbackLines);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? paletteId,  AppThemeMode themeMode,  double fontSize,  double lineHeight,  TerminalCursorShape cursorShape,  bool cursorBlinks,  BellBehaviour bell,  int scrollbackLines)?  $default,) {final _that = this;
switch (_that) {
case _TerminalSettings() when $default != null:
return $default(_that.paletteId,_that.themeMode,_that.fontSize,_that.lineHeight,_that.cursorShape,_that.cursorBlinks,_that.bell,_that.scrollbackLines);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TerminalSettings extends TerminalSettings {
  const _TerminalSettings({this.paletteId, this.themeMode = AppThemeMode.system, this.fontSize = 14, this.lineHeight = 1.2, this.cursorShape = TerminalCursorShape.block, this.cursorBlinks = true, this.bell = BellBehaviour.visual, this.scrollbackLines = 10000}): super._();
  factory _TerminalSettings.fromJson(Map<String, dynamic> json) => _$TerminalSettingsFromJson(json);

/// The palette id, or null to follow the app theme.
@override final  String? paletteId;
@override@JsonKey() final  AppThemeMode themeMode;
@override@JsonKey() final  double fontSize;
@override@JsonKey() final  double lineHeight;
@override@JsonKey() final  TerminalCursorShape cursorShape;
@override@JsonKey() final  bool cursorBlinks;
@override@JsonKey() final  BellBehaviour bell;
@override@JsonKey() final  int scrollbackLines;

/// Create a copy of TerminalSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TerminalSettingsCopyWith<_TerminalSettings> get copyWith => __$TerminalSettingsCopyWithImpl<_TerminalSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TerminalSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TerminalSettings&&(identical(other.paletteId, paletteId) || other.paletteId == paletteId)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.fontSize, fontSize) || other.fontSize == fontSize)&&(identical(other.lineHeight, lineHeight) || other.lineHeight == lineHeight)&&(identical(other.cursorShape, cursorShape) || other.cursorShape == cursorShape)&&(identical(other.cursorBlinks, cursorBlinks) || other.cursorBlinks == cursorBlinks)&&(identical(other.bell, bell) || other.bell == bell)&&(identical(other.scrollbackLines, scrollbackLines) || other.scrollbackLines == scrollbackLines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,paletteId,themeMode,fontSize,lineHeight,cursorShape,cursorBlinks,bell,scrollbackLines);
}

@override
String toString() {
    return 'TerminalSettings(paletteId: $paletteId, themeMode: $themeMode, fontSize: $fontSize, lineHeight: $lineHeight, cursorShape: $cursorShape, cursorBlinks: $cursorBlinks, bell: $bell, scrollbackLines: $scrollbackLines)';
}


}

/// @nodoc
abstract mixin class _$TerminalSettingsCopyWith<$Res> implements $TerminalSettingsCopyWith<$Res> {
  factory _$TerminalSettingsCopyWith(_TerminalSettings value, $Res Function(_TerminalSettings) _then) = __$TerminalSettingsCopyWithImpl;
@override @useResult
$Res call({
 String? paletteId, AppThemeMode themeMode, double fontSize, double lineHeight, TerminalCursorShape cursorShape, bool cursorBlinks, BellBehaviour bell, int scrollbackLines
});




}
/// @nodoc
class __$TerminalSettingsCopyWithImpl<$Res>
    implements _$TerminalSettingsCopyWith<$Res> {
  __$TerminalSettingsCopyWithImpl(this._self, this._then);

  final _TerminalSettings _self;
  final $Res Function(_TerminalSettings) _then;

/// Create a copy of TerminalSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? paletteId = freezed,Object? themeMode = null,Object? fontSize = null,Object? lineHeight = null,Object? cursorShape = null,Object? cursorBlinks = null,Object? bell = null,Object? scrollbackLines = null,}) {
  return _then(_TerminalSettings(
paletteId: freezed == paletteId ? _self.paletteId : paletteId // ignore: cast_nullable_to_non_nullable
as String?,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,fontSize: null == fontSize ? _self.fontSize : fontSize // ignore: cast_nullable_to_non_nullable
as double,lineHeight: null == lineHeight ? _self.lineHeight : lineHeight // ignore: cast_nullable_to_non_nullable
as double,cursorShape: null == cursorShape ? _self.cursorShape : cursorShape // ignore: cast_nullable_to_non_nullable
as TerminalCursorShape,cursorBlinks: null == cursorBlinks ? _self.cursorBlinks : cursorBlinks // ignore: cast_nullable_to_non_nullable
as bool,bell: null == bell ? _self.bell : bell // ignore: cast_nullable_to_non_nullable
as BellBehaviour,scrollbackLines: null == scrollbackLines ? _self.scrollbackLines : scrollbackLines // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
