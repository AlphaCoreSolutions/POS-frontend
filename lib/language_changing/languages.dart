import 'package:flutter/material.dart';

class Language {
  final String name;
  final String languageCode;
  final IconData icon;

  Language(this.name, this.languageCode, this.icon);

  static List<Language> languageList() {
    return <Language>[
      Language("English", "en", Icons.abc),
      Language("Arabic", "ar", Icons.abc),
      Language("German", "de", Icons.abc),
      Language("Spanish", "es", Icons.abc),
    ];
  }
}
