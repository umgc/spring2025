import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  Color _primaryColor = Colors.deepPurple;

  Color get primaryColor => _primaryColor;

  void updateTheme(Color color) {
    _primaryColor = color;
    print('Theme updated to: $color');
    notifyListeners();  // Notify listeners (like the whole app) to rebuild
  }
}

