import 'package:akademihub_mob/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tema aplikasi konsisten untuk mode terang dan gelap', () {
    final light = AppTheme.lightTheme;
    final dark = AppTheme.darkTheme;

    expect(light.useMaterial3, isTrue);
    expect(dark.useMaterial3, isTrue);
    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);
    expect(light.cardTheme.elevation, 0);
    expect(light.navigationBarTheme.height, 72);
    expect(light.colorScheme.primary, const Color(0xFF086F68));
    expect(light.colorScheme.secondary, const Color(0xFFF2A93B));
    expect(light.scaffoldBackgroundColor, const Color(0xFFF6F7F3));
  });
}
