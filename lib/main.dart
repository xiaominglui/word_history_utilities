import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:word_history_utilities/home_page.dart';

class MinimalLocalizations {
  MinimalLocalizations(this.locale);

  final Locale locale;

  static MinimalLocalizations of(BuildContext context) {
    return Localizations.of<MinimalLocalizations>(context, MinimalLocalizations);
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Utilities for Word History of Google Dictionary Extension',
    },
    'zh': {
      'title': '哈哈',
    },
  };

  String get title {
    return _localizedValues[locale.languageCode]['title'];
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


class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) => MinimalLocalizations.of(context).title,
      localizationsDelegates: [
        const MinimalLocalizationsDelegate(),
      ],
      supportedLocales: [
        const Locale('en', ''),
        const Locale('es', ''),
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new HomePage(),
    );
  }
}

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

void main() => runApp(MyApp());