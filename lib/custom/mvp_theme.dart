import 'package:material_ui/material_ui.dart';

abstract final class MvpTheme {
  static const bgPrimary = Color(0xFFF8FAFC);
  static const cardBg = Color(0xFFFFFFFF);
  static const cardBorder = Color(0x0D000000);
  static const borderColor = Color(0x14000000);

  static const activeColor = Color(0xFF10B981);

  static const inactiveGray = Color(0xFFD1D5DB);
  static const inactiveBadgeBg = Color(0xFFE5E7EB);

  static const dangerColor = Color(0xFFEF4444);
  static const dangerText = Color(0xFFF87171);
  static final inputBg = inactiveBadgeBg.withValues(alpha: 0.01);

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  static const toastBg = Color(0xFF1E293B);

  static const lineHeightTight = 1.0;
  static const lineHeightTitle = 1.2;
  static const lineHeightBody = 1.25;
}
