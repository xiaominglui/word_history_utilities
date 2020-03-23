import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../chrome_extension.dart' as Chrome;
import '../chrome_extension.dart' show SendMessageOptions;
import '../chrome_extension.dart' show SendMessageMessage;

class DetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: Image.network(
            'https://picsum.photos/250?image=9',
          ),
        ),
      ),
    );
  }
}

Future<WordHistorySnapshot> fetchHistoryWords() async {
  print('to sendMessage');

  try {
    print('hello?');
    final result = await Chrome.Extension.sendMessage(
            "mgijmajocgfcbeboacabfgobmjgjcoja",
            new SendMessageMessage(getHistory: true),
            new SendMessageOptions(includeTlsChannelId: false))
        .timeout(const Duration(seconds: 5));

    Map obj = jsonDecode(Chrome.stringify(result));
    var ts = new DateTime.now().millisecondsSinceEpoch;

    var hw = <HistoryWord>[];
    obj.forEach((key, value) {
      var splited = key.toString().split('<');
      if (splited.length >= 3) {
        hw.add(HistoryWord(
            from: splited[0],
            to: splited[1],
            word: splited[2],
            definition: value));
      }
    });

    if (hw.length > 0) {
      var snapshot = WordHistorySnapshot(timestamp: ts, historyWords: hw);
      print('world! ${hw.length} @ $ts');
      return snapshot;
    } else {
      throw Exception('your word history is empty');
    }
  } on Error catch (e) {
    print('Caught error: $e');
    var le = Chrome.Extension.lastError();
    if (le != null) {
      throw Exception('err: ${le.toString()}');
    } else {
      throw Exception('Failed to load history words');
    }
  } on TimeoutException catch (e) {
    print('Timeout: $e');
    throw Exception('load history words timeout');
  }
}

class VocabularySnapshot {
  final int timestamp;
  final List<ChallengingWord> challengingWords;

  VocabularySnapshot({this.timestamp, this.challengingWords});
}

class WordHistorySnapshot {
  final int timestamp;
  final List<HistoryWord> historyWords;

  WordHistorySnapshot({this.timestamp, this.historyWords});
}

class ChallengingWord {
  final String from;
  final String to;
  final String word;

  final bool isNew = true;
  final bool deleted = false;

  ChallengingWord({this.from, this.to, this.word});
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

class _MyAppState extends State<WordHistoryFragment> {
  Future<dynamic> futureWords;

  @override
  void initState() {
    super.initState();
    print('initState');
    futureWords = fetchHistoryWords();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new Scaffold(
        appBar: AppBar(
          title: Text('A AppBar Title'),
        ),
        body: Center(
          child: FutureBuilder<WordHistorySnapshot>(
            future: futureWords,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var dr = snapshot.data.historyWords
                    .map((val) => DataRow(cells: [
                          DataCell(Text(val.from)),
                          DataCell(Text(val.to)),
                          DataCell(Text(val.word)),
                          DataCell(Text(val.definition)),
                          DataCell(FlatButton(
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (_) {
                                  return DetailScreen();
                                }));
                              },
                              child: Text('Button'))),
                        ]))
                    .toList();
                return Scrollbar(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      DataTable(columns: [
                        DataColumn(label: Text('from')),
                        DataColumn(label: Text('to')),
                        DataColumn(label: Text('word')),
                        DataColumn(label: Text('def')),
                        DataColumn(label: Text('remark')),
                      ], rows: dr),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }

              // By default, show a loading spinner.
              return CircularProgressIndicator();
            },
          ),
        ),
      );
  }
}

class WordHistoryFragment extends StatefulWidget {

  WordHistoryFragment({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}