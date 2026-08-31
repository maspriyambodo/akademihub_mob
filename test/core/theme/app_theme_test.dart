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
    expect(light.navigationBarTheme.height, 76);
    expect(light.colorScheme.primary, const Color(0xFF087F8C));
    expect(light.colorScheme.secondary, const Color(0xFFFFC857));
    expect(light.scaffoldBackgroundColor, const Color(0xFFF4F7FA));
  });
}
