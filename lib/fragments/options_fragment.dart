import 'dart:js';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../chrome_extension.dart' as Chrome;

class AppOptions {
  final bool auto_sync_on_launch;
  final bool auto_add_new_history_word;

  AppOptions({this.auto_sync_on_launch, this.auto_add_new_history_word});
}

class OptionsFragment extends StatefulWidget {
  @override
  _OptionsFragmentState createState() => _OptionsFragmentState();
}

class _OptionsFragmentState extends State<OptionsFragment> {
  bool cbvAutoSync;
  bool cbvAutoAdd;

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
    try {
      var jsObj = Chrome.mapToJSObj(map);
      print(Chrome.stringify(jsObj));
      await Chrome.Extension.storageLocalSet(jsObj);
    } catch (e) {
      print('Caught e: $e');
    }
  }

  Future<AppOptions> getAppOptions() async {
    try {
      final res = await Chrome.Extension.storageLocalGet(null);
      print(Chrome.stringify(res));
      Map map = jsonDecode(Chrome.stringify(res));

      var options = AppOptions(
          auto_add_new_history_word: map['cbvAutoAdd'],
          auto_sync_on_launch: map['cbvAutoSync']);
      return options;
    } catch (e) {
      print('Caught e: $e');
      throw Exception('load options err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: Column(children: [
        Row(
          children: [
            Text('Sync word history on launch: '),
            Checkbox(
              value: cbvAutoSync,
              onChanged: (value) {
                setState(() {
                  cbvAutoSync = value;
                });
              },
            )
          ],
        ),
        Row(children: [
          Text('Add words to review list on sync: '),
          Checkbox(
            value: cbvAutoAdd,
            onChanged: (value) {
              setState(() {
                cbvAutoAdd = value;
              });
            },
          )
        ]),
        Row(
          children: <Widget>[
            FlatButton(
                onPressed: () {
                  saveAppOptions(AppOptions(
                      auto_sync_on_launch: cbvAutoSync,
                      auto_add_new_history_word: cbvAutoAdd));
                },
                child: Text('Save')),
            FlatButton(onPressed: () {}, child: Text('Reset')),
          ],
        )
      ]),
    );
  }
}
