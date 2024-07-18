import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final seedColors = [
  Colors.lightGreen,
  Colors.purple,
  Colors.orange,
  Colors.blue,
  Colors.red,
  Colors.teal,
  Colors.pink,
  Colors.indigo,
  Colors.amber,
  Colors.cyan,
  Colors.deepOrange,
  Colors.deepPurple,
  Colors.green,
  Colors.lime,
  Colors.yellow,
  Colors.brown,
  Colors.grey,
  Colors.blueGrey,
];

final randomSeedColor = seedColors[Random().nextInt(seedColors.length)];

final _lightScheme = ColorScheme.fromSeed(seedColor: randomSeedColor);
final _darkScheme = ColorScheme.fromSeed(seedColor: randomSeedColor, brightness: Brightness.dark);

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
