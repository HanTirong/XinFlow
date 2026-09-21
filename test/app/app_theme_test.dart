import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xinflow/app/theme/app_theme.dart';

void main() {
  test('light theme exposes the approved semantic tokens', () {
    final theme = AppTheme.light();
    final tokens = theme.extension<AppThemeTokens>()!;

    expect(theme.scaffoldBackgroundColor, const Color(0xFFF6F8FC));
    expect(tokens.primaryCard, const Color(0xFFFFFFFF));
    expect(tokens.secondaryCard, const Color(0xFFF1F4FA));
    expect(theme.colorScheme.onSurface, const Color(0xFF1B2130));
    expect(theme.colorScheme.onSurfaceVariant, const Color(0xFF646C7A));
    expect(theme.colorScheme.primary, const Color(0xFF5874C8));
    expect(tokens.categorySurface, tokens.secondaryCard);
  });

  test('dark theme exposes the approved semantic tokens', () {
    final theme = AppTheme.dark();
    final tokens = theme.extension<AppThemeTokens>()!;

    expect(theme.scaffoldBackgroundColor, const Color(0xFF11131A));
    expect(tokens.primaryCard, const Color(0xFF1B1F29));
    expect(tokens.secondaryCard, const Color(0xFF232833));
    expect(theme.colorScheme.onSurface, const Color(0xFFF1F3F8));
    expect(theme.colorScheme.onSurfaceVariant, const Color(0xFFAEB4C2));
    expect(theme.colorScheme.primary, const Color(0xFF7F97E6));
    expect(tokens.categorySurface, tokens.secondaryCard);
  });
}
