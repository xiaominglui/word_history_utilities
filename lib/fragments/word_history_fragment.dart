import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import '../chrome_extension.dart' as Chrome;
import '../chrome_extension.dart' show SendMessageOptions;
import '../chrome_extension.dart' show SendMessageMessage;
part 'word_history_fragment.g.dart';

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

@JsonSerializable()
class HistoryWord {
  final String from;
  final String to;
  final String word;
  final String definition;
  final int storeTimestamp;
  bool isNew = true;
  bool deleted = false;

  HistoryWord(
      {this.from,
      this.to,
      this.word,
      this.definition,
      this.storeTimestamp,
      this.isNew,
      this.deleted});

  factory HistoryWord.fromJson(Map<String, dynamic> json) =>
      _$HistoryWordFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryWordToJson(this);
}

class WordHistoryFragmentState extends State<WordHistoryFragment> {
  Future<dynamic> futureWords;

  @override
  void initState() {
    super.initState();
    print('initState');
    futureWords = fetchHistoryWords();
  }

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: FutureBuilder<List<HistoryWord>>(
        future: futureWords,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return CircularProgressIndicator();
            default:
              if (snapshot.hasError) {
                return Text("${snapshot.error}");
              } else {
                if (snapshot.hasData) {
                  var dr = snapshot.data
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
                  // String formattedDate = DateFormat('yyyy-MM-dd – kk:mm')
                  //     .format(DateTime.fromMillisecondsSinceEpoch(
                  //         snapshot.data.timestamp));
                  return Scrollbar(
                    child: Column(children: [
                      Align(
                          alignment: Alignment.topRight,
                          child: Text('number: ${snapshot.data.length}')),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            DataTable(columns: [
                              DataColumn(label: Text('from')),
                              DataColumn(label: Text('to')),
                              DataColumn(label: Text('word')),
                              DataColumn(label: Text('definition')),
                              DataColumn(label: Text('remark')),
                            ], rows: dr),
                          ],
                        ),
                      )
                    ]),
                  );
                } else {
                  return Text('No Data');
                }
              }
          }
        },
      ),
    );
  }

  void refresh() {
    setState(() {
      futureWords = fetchHistoryWords();
    });
  }

  Future<void> _storeCache(List<HistoryWord> historyWords) async {
    print('storeCache');

    var map = {};
    var list = {};

    historyWords.forEach((hw) {
      String k = hw.from + '<' + hw.to + '<' + hw.word;
      String v = hw.definition +
          '<' +
          hw.storeTimestamp.toString() +
          '<' +
          (hw.deleted ? 'true' : 'false') +
          '<' +
          (hw.isNew ? 'true' : 'false');
      list[k] = v;
    });

    map['word-history-snapshot'] = Chrome.mapToJSObj(list);

    try {
      await Chrome.Extension.storageSyncSet(Chrome.mapToJSObj(map))
          .then((value) => print('storage sync set'));
    } catch (e) {
      print('storeCache Caught e: $e');
    }
  }

  Future<List<HistoryWord>> _loadCache() async {
    print('loadCache');
    try {
      final result =
          await Chrome.Extension.storageSyncGet('word-history-snapshot');
      Map resultMap = Chrome.mapify(result);
      Map list = resultMap['word-history-snapshot'];
      var hw = <HistoryWord>[];
      list.forEach((key, value) {
        var splitedKey = key.toString().split('<');
        var splitedValue = value.toString().split('<');
        hw.add(HistoryWord(
            from: splitedKey[0],
            to: splitedKey[1],
            word: splitedKey[2],
            definition: splitedValue[0],
            storeTimestamp: int.parse(splitedValue[1]),
            isNew: splitedValue[3].toLowerCase() == 'true',
            deleted: splitedValue[2].toLowerCase() == 'true'));
      });

      if (hw.length > 0) {
        return hw;
      } else {
        throw Exception('your word history is empty');
      }
    } catch (e) {
      print('loadCache Caught e: $e');
      throw Exception('load error');
    }
  }

  Future<List<HistoryWord>> fetchHistoryWords() async {
    print('fetchHistoryWords');
    var cachedHistoryWords = <HistoryWord>[];
    var originHistoryWords = <HistoryWord>[];
    var mergedHistoryWords = <HistoryWord>[];
    try {
      cachedHistoryWords = await _loadCache();
    } catch (e) {
      print('err: $e');
      cachedHistoryWords = null;
    }

    try {
      print('hello?');

      final r = await Chrome.Extension.sendMessage2(
              "mgijmajocgfcbeboacabfgobmjgjcoja",
              new SendMessageMessage(getHistory: true),
              new SendMessageOptions(includeTlsChannelId: false))
          .timeout(const Duration(seconds: 5));

      Map obj = Chrome.mapify(r);
      var ts = new DateTime.now().millisecondsSinceEpoch;

      obj.forEach((key, value) {
        var splited = key.toString().split('<');
        if (splited.length >= 3) {
          originHistoryWords.add(HistoryWord(
              from: splited[0],
              to: splited[1],
              word: splited[2],
              definition: value,
              storeTimestamp: ts));
        }
      });

      bool irr = isOriginReset(cachedHistoryWords, originHistoryWords);
      print('origin reset? $irr');
      if (cachedHistoryWords.length > originHistoryWords.length) {
        print('origin become less');
        // dialog user for choosing merge or reset
      } else if (cachedHistoryWords.length < originHistoryWords.length) {
        print('origin become more');
        if(irr) {
          // dialog user for choosing merge or reset
        } else {
          // merge directly
        }
      } else {
        print('origin equal cached');
        if(irr) {
          // dialog user for choosing merge or reset
        } else {
          // pass, cached words is the latest version
          print('cached is the latest version');
          mergedHistoryWords = cachedHistoryWords;
        }
      }

      if (mergedHistoryWords.length > 0) {
        print('world! ${originHistoryWords.length} @ $ts');
        await _storeCache(originHistoryWords);
        return originHistoryWords;
      } else {
        throw Exception('your word history is empty');
      }
    } on Error catch (e) {
      print('Caught error: $e');
      throw Exception('Failed to load history words');
    } on TimeoutException catch (e) {
      print('Timeout: $e');
      throw Exception('load history words timeout');
    }
  }

  bool isOriginReset(List<HistoryWord> cachedHistoryWords,
      List<HistoryWord> originHistoryWords) {
    var originMap = {};
    originHistoryWords.forEach((hw) {
      String k = hw.from + '<' + hw.to + '<' + hw.word;
      String v = hw.definition +
          '<' +
          hw.storeTimestamp.toString() +
          '<' +
          (hw.deleted ? 'true' : 'false') +
          '<' +
          (hw.isNew ? 'true' : 'false');
      originMap[k] = v;
    });

    // return cachedHistoryWords
    //     .any((hw) => originMap[hw.from + '< ' + hw.to + '<' + hw.word] == null);

    bool result = false;

    for (var i = 0; i < cachedHistoryWords.length; i++) {
      var hw = cachedHistoryWords[i];
      String k = hw.from + '<' + hw.to + '<' + hw.word;
      print("hasn't value: ${originMap[k] == null}");
      if(originMap[k] == null) {
        result = true;
        break;
      } else {
        continue;
      }
    }
    return result;
  }
}

class WordHistoryFragment extends StatefulWidget {
  WordHistoryFragment({Key key}) : super(key: key);

  @override
  WordHistoryFragmentState createState() => WordHistoryFragmentState();
}
