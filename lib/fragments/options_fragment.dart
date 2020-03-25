import 'package:flutter/material.dart';

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
  bool cbvAutoSync = true;
  bool cbvAutoAdd = true;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print('initState');

    // var a = localStorage;

  }

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: Column(
        children: [
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
        Row(children: <Widget>[
          FlatButton(onPressed: () {}, child: Text('Save')),
          FlatButton(onPressed: () {}, child: Text('Reset')),
        ],)
      ]),
    );
  }
}
