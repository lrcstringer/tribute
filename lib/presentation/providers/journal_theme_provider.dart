import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/journal_theme.dart';

class JournalThemeProvider extends ChangeNotifier {
  static const _prefKey = 'journal_theme_id';

  JournalTheme _theme = JournalTheme.parchment;

  JournalTheme get theme => _theme;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefKey);
    if (id == null) return;
    final saved = JournalTheme.all.where((t) => t.id == id).firstOrNull;
    if (saved != null && saved.id != _theme.id) {
      _theme = saved;
      notifyListeners();
    }
  }

  Future<void> setTheme(JournalTheme theme) async {
    if (_theme.id == theme.id) return;
    _theme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, theme.id);
  }
}
