import 'dart:js';

import 'package:flutter/material.dart';
import 'package:word_history_utilities/i18n/i18n_minimal.dart';
import 'dart:async';
import 'dart:convert';
import '../chrome_extension.dart' as Chrome;

class AppOptions {
  final bool auto_sync_on_launch;
  final bool auto_add_new_history_word;
  final bool always_merge;

  AppOptions(
      {this.auto_sync_on_launch,
      this.auto_add_new_history_word,
      this.always_merge});
}

class OptionsFragment extends StatefulWidget {
  @override
  _OptionsFragmentState createState() => _OptionsFragmentState();
}

class _OptionsFragmentState extends State<OptionsFragment> {
  bool cbvAutoSyncBakup;
  bool cbvAutoAddBakup;
  bool cbvAlwaysMergeBakup;
  bool cbvAutoSync;
  bool cbvAutoAdd;
  bool cbvAlwaysMerge;
  bool hasChanged = false;

  @override
  void initState() {
    print('initState');
    super.initState();
    getAppOptions()
        .then((value) => updateUI(value))
        .catchError((e) => handleError(e));
  }

  updateUI(AppOptions options) {
    setState(() {
      cbvAutoSync = options.auto_sync_on_launch;
      cbvAutoAdd = options.auto_add_new_history_word;
      cbvAlwaysMerge = options.always_merge;
      cbvAutoSyncBakup = cbvAutoSync;
      cbvAutoAddBakup = cbvAutoAdd;
      cbvAlwaysMergeBakup = cbvAlwaysMergeBakup;
    });
  }

  handleError(dynamic e) {
    print(e);
  }

  Future saveAppOptions(AppOptions o) async {
    print('saveAppOptions');
    var map = {};
    map['cbvAutoSync'] = o.auto_sync_on_launch;
    map['cbvAutoAdd'] = o.auto_add_new_history_word;
    map['cbvAlwaysMerge'] = o.always_merge;
    try {
      var jsObj = Chrome.mapToJSObj(map);
      await Chrome.Extension.storageSyncSet(jsObj);
    } catch (e) {
      print('Caught e: $e');
    }
  }

  Future<AppOptions> getAppOptions() async {
    try {
      final res = await Chrome.Extension.storageSyncGet(null);
      // print(Chrome.stringify(res));
      Map map = jsonDecode(Chrome.stringify(res));

      var options = AppOptions(
          auto_add_new_history_word: map['cbvAutoAdd'] ?? true,
          auto_sync_on_launch: map['cbvAutoSync'] ?? true,
          always_merge: map['cbvAlwaysMerge'] ?? false);
      return options;
    } catch (e) {
      print('Caught e: $e');
      throw Exception('load options err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(
          children: [
            Text(MinimalLocalizations.of(context).syncOnLaunch),
            Checkbox(
              value: cbvAutoSync,
              onChanged: (value) {
                setState(() {
                  hasChanged = true;
                  cbvAutoSync = value;
                });
              },
            )
          ],
        ),
        Row(children: [
          Text(MinimalLocalizations.of(context).addToReviewList),
          Checkbox(
            value: cbvAutoAdd,
            onChanged: (value) {
              setState(() {
                hasChanged = true;
                cbvAutoAdd = value;
              });
            },
          )
        ]),
        Row(children: [
          Text(MinimalLocalizations.of(context).alwaysMerge),
          Checkbox(
            value: cbvAlwaysMerge,
            onChanged: (value) {
              setState(() {
                hasChanged = true;
                cbvAlwaysMerge = value;
              });
            },
          )
        ]),
        Row(
          children: <Widget>[
            FlatButton(
                onPressed: hasChanged
                    ? () {
                        saveAppOptions(AppOptions(
                            auto_sync_on_launch: cbvAutoSync,
                            auto_add_new_history_word: cbvAutoAdd,
                            always_merge: cbvAlwaysMerge));
                        cbvAutoSyncBakup = cbvAutoSync;
                        cbvAutoAddBakup = cbvAutoAdd;
                        setState(() {
                          hasChanged = false;
                        });
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text(MinimalLocalizations.of(context).sbarSaved),
                          duration: const Duration(seconds: 3),
                        ));
                      }
                    : null,
                child: Text(MinimalLocalizations.of(context).btnSave)),
            FlatButton(
                onPressed: hasChanged
                    ? () {
                        setState(() {
                          cbvAutoAdd = cbvAutoAddBakup;
                          cbvAutoSync = cbvAutoSyncBakup;
                          cbvAlwaysMerge = cbvAlwaysMergeBakup;
                          hasChanged = false;
                        });
                      }
                    : null,
                child: Text(MinimalLocalizations.of(context).btnReset)),
          ],
        )
      ]),
    );
  }
}
