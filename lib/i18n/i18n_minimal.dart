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
      'menu_terms': 'Terms',
      'menu_policy': 'Policy',
      'menu_help': 'Help',
      'option_sync_on_launch': 'Sync word history on launch:',
      'option_add_to_review_list': 'Add words to review list on sync:',
      'option_always_merge': 'Always merge on sync:',
      'btn_save': 'Save',
      'btn_reset': 'Reset',
      'sbar_options_saved': 'Options saved'
    },
    'zh': {
      'title_app': 'Google词典扩展小工具',
      'title_word': '生词',
      'title_definision': "定义",
      'menu_word_history': "查词历史",
      'menu_options': "选项",
      'menu_privacy': '隐私',
      'menu_terms': '条款',
      'menu_policy': '政策',
      'menu_help': '帮助',
      'option_sync_on_launch': '启动时立即与Google词典扩展同步：',
      'option_add_to_review_list': '新词自动加入回顾列表：',
      'option_always_merge': '同步时自动合并：',
      'btn_save': '保存',
      'btn_reset': '重置',
      'sbar_options_saved': '选项已保存'
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

  String get termsMenu {
    return _localizedValues[locale.languageCode]['menu_terms'];
  }

  String get policyMenu {
    return _localizedValues[locale.languageCode]['menu_policy'];
  }

  String get helpMenu {
    return _localizedValues[locale.languageCode]['menu_help'];
  }

  String get syncOnLaunch {
    return _localizedValues[locale.languageCode]['option_sync_on_launch'];
  }

  String get addToReviewList {
    return _localizedValues[locale.languageCode]['option_add_to_review_list'];
  }

  String get alwaysMerge {
    return _localizedValues[locale.languageCode]['option_always_merge'];
  }

  String get btnSave {
    return _localizedValues[locale.languageCode]['btn_save'];
  }

  String get btnReset {
    return _localizedValues[locale.languageCode]['btn_reset'];
  }

  String get sbarSaved {
    return _localizedValues[locale.languageCode]['sbar_options_saved'];
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