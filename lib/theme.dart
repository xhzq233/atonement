import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final _lightScheme = ColorScheme.fromSeed(seedColor: Colors.lightGreen);
final _darkScheme = ColorScheme.fromSeed(seedColor: Colors.lightGreen, brightness: Brightness.dark);

final lightThemeData = ThemeData(
  colorScheme: _lightScheme,
  useMaterial3: true,
  platform: TargetPlatform.iOS,
  brightness: Brightness.light,
);

final darkThemeData = ThemeData(
  colorScheme: _darkScheme,
  useMaterial3: true,
  platform: TargetPlatform.iOS,
  brightness: Brightness.dark,
  cupertinoOverrideTheme: CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: _darkScheme.primary,
    primaryContrastingColor: _darkScheme.onPrimary,
    barBackgroundColor: _darkScheme.onSecondary,
    scaffoldBackgroundColor: _darkScheme.surface,
    applyThemeToAll: true,
    textTheme: CupertinoTextThemeData(
      textStyle: const TextStyle(color: CupertinoColors.white, fontSize: 16.0),
      primaryColor: _darkScheme.primary,
    ),
  ),
);
