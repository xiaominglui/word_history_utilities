import 'dart:async';
// import 'dart:convert';
// import 'dart:html';

import 'package:flutter/material.dart';
// import 'package:webext/webext.dart';
import 'chromeext.dart' as Chrome;
import 'chromeext.dart' show SendMessageOptions;
import 'chromeext.dart' show SendMessageMessage;


Future fetchHistoryWords() async {
  print('to sendMessage');

  try {
    print('hello');
    // response = await Runtime.runtime.sendMessage(
    //                 "mgijmajocgfcbeboacabfgobmjgjcoja", {}, null);

    // return Album.fromJson(json.decode(response));

    final res = await Chrome.ChromeExt.sendMessage("mgijmajocgfcbeboacabfgobmjgjcoja", new SendMessageMessage(getHistory: true), new SendMessageOptions(includeTlsChannelId: false));
    print('world');
    print(res);

    // https://github.com/dart-lang/sdk/issues/33134

    // Error handling response: NoSuchMethodError: method not found: 'call' Receiver: Closure 'minified:Lv' Arguments: []
    return res;
  } catch (err) {
    print('Caught error: $err');
    throw Exception('Failed to load history words');
  }
}

class Album {
  final int userId;
  final int id;
  final String title;

  Album({this.userId, this.id, this.title});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      userId: json['userId'],
      id: json['id'],
      title: json['title'],
    );
  }
}

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();

}

class _MyAppState extends State<MyApp> {
Future<dynamic> futureWords;

  @override
  void initState() {
    super.initState();
    print('initState');
    futureWords = fetchHistoryWords();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fetch Data Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Fetch Data Example'),
        ),
        body: Center(
          child: FutureBuilder<dynamic>(
            future: futureWords,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data);
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }

              // By default, show a loading spinner.
              return CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}
