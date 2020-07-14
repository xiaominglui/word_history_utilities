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
      'title_app': 'Google Dictionary Word History Gadget',
      'title_word': "Word",
      'title_definision': "Definision",
      'title_from': 'Source',
      'title_to': 'Target',
      'dialog_title_merge_strategy': 'Choose a merge strategy',
      'dialog_content_merge_strategy': 'Detect your Google Dictionary Extension word history reseted after last sync, Press Merge button to keep words synced before, or Reset button to keep same with Google Dictionary Extenstion.',
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
      'btn_merge': 'Merge',
      'btn_undo': 'Undo',
      'sbar_options_saved': 'Options saved',
      'tooltip_download': 'Download words selected',
      'tooltip_delete': 'Delete words selected',
      'tooltip_sync': 'Sync history words',
      'sync_status_singular': 'Number of words stored in history: %1\$; sync at: %2\$',
      'sync_status_plural': 'Number of words stored in history: %1\$; sync at: %2\$'
    },
    'zh': {
      'title_app': 'Google字典单词历史小工具',
      'title_word': '生词',
      'title_definision': '定义',
      'title_from': '源语言',
      'title_to': '目标语言',
      'dialog_title_merge_strategy': '单词合并策略',
      'dialog_content_merge_strategy': '检测到上次同步后Google字典扩展单词历史记录已重置，按“合并”按钮保留之前同步的单词，按“重置”按钮使单词历史与Google字典扩展相同。',
      'menu_word_history': "查词历史",
      'menu_options': "选项",
      'menu_privacy': '隐私',
      'menu_terms': '条款',
      'menu_policy': '政策',
      'menu_help': '帮助',
      'option_sync_on_launch': '启动时立即与Google字典扩展同步：',
      'option_add_to_review_list': '新词自动加入回顾列表：',
      'option_always_merge': '同步时自动合并：',
      'btn_save': '保存',
      'btn_reset': '重置',
      'btn_merge': '合并',
      'btn_undo': '撤销',
      'sbar_options_saved': '选项已保存',
      'tooltip_download': '下载所选单词',
      'tooltip_delete': '删除所选单词',
      'tooltip_sync': '同步查词历史',
      'sync_status_singular': '历史记录中存储的单词数: %1\$；同步于：%2\$',
      'sync_status_plural': '历史记录中存储的单词数: %1\$；同步于：%2\$'
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

  String get fromTitle {
    return _localizedValues[locale.languageCode]['title_from'];
  }

  String get toTitle {
    return _localizedValues[locale.languageCode]['title_to'];
  }

  String get mergeStrategyDialogTitle {
    return _localizedValues[locale.languageCode]['dialog_title_merge_strategy'];
  }

  String get mergeStrategyDialogContent {
    return _localizedValues[locale.languageCode]['dialog_content_merge_strategy'];
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

  String get btnMerge {
    return _localizedValues[locale.languageCode]['btn_merge'];
  }

  String get btnUndo {
    return _localizedValues[locale.languageCode]['btn_undo'];
  }

  String get sbarSaved {
    return _localizedValues[locale.languageCode]['sbar_options_saved'];
  }

  String get downloadToolTip {
    return _localizedValues[locale.languageCode]['tooltip_download'];
  }

  String get deleteToolTip {
    return _localizedValues[locale.languageCode]['tooltip_delete'];
  }

  String get syncToolTip {
    return _localizedValues[locale.languageCode]['tooltip_sync'];
  }

  String get syncStatusSingular {
    return _localizedValues[locale.languageCode]['sync_status_singular'];
  }

  String get syncStatusPlural {
    return _localizedValues[locale.languageCode]['sync_status_plural'];
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

String interpolate(String string, List<String> params) {

  String result = string;
  for (int i = 1; i < params.length + 1; i++) {
    result = result.replaceAll('%${i}\$', params[i-1]);
  }

  return result;
}

extension StringExtension on String {
    String format(List<String> params) => interpolate(this, params);
}
