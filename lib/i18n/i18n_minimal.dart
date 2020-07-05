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
      'title_definision': "Definision"
    },
    'zh': {
      'title_app': 'Google词典扩展小工具',
      'title_word': '生词',
      'title_definision': "定义"
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