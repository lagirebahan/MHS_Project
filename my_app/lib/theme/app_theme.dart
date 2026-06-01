import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BgMode {dark, light, amoled}

class AppTheme extends ChangeNotifier {
  double _fontSize = 14.0;
  String _fontFamily = 'Default';
  Color _accentColor = Colors.cyanAccent;
  BgMode _bgMode = BgMode.dark;

  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  Color get accentColor => _accentColor;
  BgMode get bgMode => _bgMode;

  Color get baseBg => _bgMode == BgMode.light
    ? const Color(0xFFF0F0F5)
    : _bgMode == BgMode.amoled
      ? Colors.black
      : const Color(0xFF0D0D1A);

  Color get surfaceBg => _bgMode == BgMode.light
    ? const Color(0xFFFFFFFF)
    : _bgMode == BgMode.amoled
      ? const Color(0xFF0A0A0A)
      : const Color(0xFF1A1A2E);

  Color get borderColor => _bgMode == BgMode.light
    ? const Color(0xFFDDDDE8)
    : _bgMode == BgMode.amoled
      ? const Color(0xFF1A1A1A)
      : const Color(0xFF2A2A4A);
    
  Color get primaryTextColor =>
      _bgMode == BgMode.light ? const Color(0xFF0D0D1A) : Colors.white;

  TextStyle baseTextStyle(Color color) => TextStyle(
        fontSize: _fontSize,
        fontFamily: _fontFamily == 'Default' ? null : _fontFamily,
        color: color,
      );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('theme_fontSize') ?? 14.0;
    _fontFamily = prefs.getString('theme_fontFamily') ?? 'Default';
    _accentColor = Color(prefs.getInt('theme_accentColor') ?? Colors.cyanAccent.value);
    final modeIndex = prefs.getInt('theme_bgMode') ?? 0;
    _bgMode = BgMode.values[modeIndex];
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('theme_fontSize', _fontSize);
    await prefs.setString('theme_fontFamily', _fontFamily);
    await prefs.setInt('theme_accentColor', _accentColor.value);
    await prefs.setInt('theme_bgMode', _bgMode.index);
  }

  void setBgMode(BgMode mode) {
    _bgMode = mode;
    notifyListeners();
    _save();
  }

  void setFontSize(double v) {
    _fontSize = v;
    notifyListeners();
    _save();
  }

  void setFontFamily(String v) {
    _fontFamily = v;
    notifyListeners();
    _save();
  }

  void setAccentColor(Color v) {
    _accentColor = v;
    notifyListeners();
    _save();
  }

  Future<void> reset() async {
    _fontSize = 14.0;
    _fontFamily = 'Default';
    _accentColor = Colors.cyanAccent;
    _bgMode = BgMode.dark;
    notifyListeners();
    _save();
  }
}