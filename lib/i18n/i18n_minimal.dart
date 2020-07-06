import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MinimalLocalizations {
  MinimalLocalizations(this.locale);

  final Locale locale;

  static MinimalLocalizations of(BuildContext context) {
    return Localizations.of<MinimalLocalizations>(context, MinimalLocalizations);
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title_app': 'Utilities for Word History of Google Dictionary Extension',
      'title_word': "Word",
      'title_definision': "Definision",
      'menu_word_history': "Word History",
      'menu_options': "Options",
      'menu_privacy': 'Privacy',
      'menu_help': 'Help'
    },
    'zh': {
      'title_app': 'Google词典扩展小工具',
      'title_word': '生词',
      'title_definision': "定义",
      'menu_word_history': "查词历史",
      'menu_options': "选项",
      'menu_privacy': '隐私',
      'menu_help': '帮助'
    },
  };

  String get appTitle {
    return _localizedValues[locale.languageCode]['title_app'];
  }

  String get wordTitle {
    return _localizedValues[locale.languageCode]['title_word'];
  }

  String get definisionTitle {
    return _localizedValues[locale.languageCode]['title_definision'];
  }

  String get wordHistoryMenu {
    return _localizedValues[locale.languageCode]['menu_word_history'];
  }

  String get optionsMenu {
    return _localizedValues[locale.languageCode]['menu_options'];
  }

  String get privacyMenu {
    return _localizedValues[locale.languageCode]['menu_privacy'];
  }

  String get helpMenu {
    return _localizedValues[locale.languageCode]['menu_help'];
  }
}

class MinimalLocalizationsDelegate extends LocalizationsDelegate<MinimalLocalizations> {
  const MinimalLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<MinimalLocalizations> load(Locale locale) {
    // Returning a SynchronousFuture here because an async "load" operation
    // isn't needed to produce an instance of DemoLocalizations.
    return SynchronousFuture<MinimalLocalizations>(MinimalLocalizations(locale));
  }

  @override
  bool shouldReload(MinimalLocalizationsDelegate old) => false;
}