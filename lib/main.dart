import 'dart:async';
import 'dart:convert';
import 'dart:js';
// import 'dart:convert';
// import 'dart:html';

import 'package:flutter/material.dart';
// import 'package:webext/webext.dart';
import 'chrome_extension.dart' as Chrome;
import 'chrome_extension.dart' show SendMessageOptions;
import 'chrome_extension.dart' show SendMessageMessage;


Future<List<HistoryWord>> fetchHistoryWords() async {
  print('to sendMessage');

  try {
    print('hello?');
    final result = await Chrome.Extension.sendMessage("mgijmajocgfcbeboacabfgobmjgjcoja", new SendMessageMessage(getHistory: true), new SendMessageOptions(includeTlsChannelId: false));

    Map obj = jsonDecode(Chrome.stringify(result));
    var historyWords = <HistoryWord>[];
    obj.forEach((key, value) {
      var splited = key.toString().split('<');
      if (splited.length >= 3) {
        historyWords.add(HistoryWord(from: splited[0], to: splited[1], word: splited[2], definition: value));
      }
    });
    print('world!');
    return historyWords;
  } catch (err) {
    print('Caught error: $err');
    throw Exception('Failed to load history words');
  }
}

class HistoryWord {
  final String from;
  final String to;
  final String word;
  final String definition;

  HistoryWord({this.from, this.to, this.word, this.definition});

  factory HistoryWord.fromJson(Map<String, dynamic> json) {
    return HistoryWord(
      from: json['from'],
      to: json['to'],
      word: json['word'],
      definition: json['definition'],
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
          child: FutureBuilder<List<HistoryWord>>(
            future: futureWords,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data[1].word);
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
