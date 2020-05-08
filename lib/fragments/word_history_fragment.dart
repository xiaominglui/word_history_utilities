import 'dart:js';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:json_annotation/json_annotation.dart';
import 'package:word_history_utilities/exceptions/UnknownMergeStrategyException.dart';
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
  var mergeStrategy = -1; // -1 unknown, 1 reset, 0 merge

  var cachedHistoryWordsBackup = <HistoryWord>[];
  var originHistoryWordsBackup = <HistoryWord>[];

  @override
  void initState() {
    super.initState();
    print('initState');
    futureWords = fetchHistoryWords();
  }

  @override
  Widget build(BuildContext context) {
    void _showMergeStrategryChooserDialog() {
      // flutter defined function
      showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: new Text("Choose a merge strategy"),
            content: new Text(
                "Detect your Google Dictionary Extension word history reseted after last sync, Press Merge button to keep words synced before, or Reset button to keep same with Google Dictionary Extenstion."),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              new FlatButton(
                child: new Text("Merge"),
                onPressed: () {
                  mergeStrategy = 0;
                  refresh();
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text("Reset"),
                onPressed: () {
                  mergeStrategy = 1;
                  refresh();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

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
                if (snapshot.error is UnknownMergeStrategyException) {
                  _showMergeStrategryChooserDialog();
                } else {
                  return Text("${snapshot.error}");
                }
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
      throw Exception('load cache error');
    }
  }

  void mergeHistoryWords(
      List<HistoryWord> cachedHistoryWords,
      List<HistoryWord> originHistoryWords,
      List<HistoryWord> mergedHistoryWords) {
    print(
        'mergeHistoryWords, cached ${cachedHistoryWords.length}; origin ${originHistoryWords.length}');
    // word only in origin or only in cached directly add into merged;
    // word both in cached and origin directly add into merged;

    if (originHistoryWords.length > 0) {
      if (cachedHistoryWords.length > originHistoryWords.length) {
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

        cachedHistoryWords.forEach((hw) {
          String k = hw.from + '<' + hw.to + '<' + hw.word;
          if (originMap[k] == null) {
            // word only in cache
            mergedHistoryWords.add(hw);
          } else {
            // word both in origin and cached
            mergedHistoryWords.add(hw);
          }
          // word only in origin be pass TODO
        });

      } else {
        var cachedMap = {};
        cachedHistoryWords.forEach((hw) {
          String k = hw.from + '<' + hw.to + '<' + hw.word;
          String v = hw.definition +
              '<' +
              hw.storeTimestamp.toString() +
              '<' +
              (hw.deleted ? 'true' : 'false') +
              '<' +
              (hw.isNew ? 'true' : 'false');
          cachedMap[k] = v;
        });
        originHistoryWords.forEach((hw) {
          String k = hw.from + '<' + hw.to + '<' + hw.word;
          if (cachedMap[k] == null) {
            // word only in orgin
            hw.isNew = true;
            hw.deleted = false;
            mergedHistoryWords.add(hw);
          } else {
            // word both in origin and cached
            mergedHistoryWords.add(hw);
          }
        });
      }
    } else {
      mergedHistoryWords.addAll(cachedHistoryWords);
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

      print('objMap: ${obj.length}');

      obj.forEach((key, value) {
        print('handle each');
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

      print('I am here');
      bool irr = isOriginReset(cachedHistoryWords, originHistoryWords);
      print('I am here again');
      print('origin reset? $irr; merge strategy is $mergeStrategy');
      if (mergeStrategy == -1) {
        if (cachedHistoryWords.length > originHistoryWords.length) {
          print('origin become less');
          // dialog user for choosing merge or reset
          cachedHistoryWordsBackup.addAll(cachedHistoryWords);
          originHistoryWordsBackup.addAll(originHistoryWords);
          throw UnknownMergeStrategyException();
        } else if (cachedHistoryWords.length < originHistoryWords.length) {
          print('origin become more');
          if (irr) {
            // dialog user for choosing merge or reset
            cachedHistoryWordsBackup.addAll(cachedHistoryWords);
            originHistoryWordsBackup.addAll(originHistoryWords);
            throw UnknownMergeStrategyException();
          } else {
            // merge directly
            mergeHistoryWords(
                cachedHistoryWords, originHistoryWords, mergedHistoryWords);
          }
        } else {
          print('origin equal cached');
          if (irr) {
            // dialog user for choosing merge or reset
            cachedHistoryWordsBackup.addAll(cachedHistoryWords);
            originHistoryWordsBackup.addAll(originHistoryWords);
            throw UnknownMergeStrategyException();
          } else {
            // pass, cached words is the latest version
            print('cached is the latest version');
            mergedHistoryWords = cachedHistoryWords;
          }
        }
      } else {
        if (mergeStrategy == 0) {
          mergeStrategy = -1;
          // merge
          if (originHistoryWordsBackup.length > 0 &&
              cachedHistoryWordsBackup.length > 0) {
            print(
                'cb: ${cachedHistoryWordsBackup.length}; ob: ${originHistoryWordsBackup.length}');
            mergeHistoryWords(cachedHistoryWordsBackup,
                originHistoryWordsBackup, mergedHistoryWords);
            originHistoryWordsBackup.clear();
            cachedHistoryWordsBackup.clear();
          } else {
            mergeHistoryWords(
                cachedHistoryWords, originHistoryWords, mergedHistoryWords);
          }
        } else if (mergeStrategy == 1) {
          // reset
          mergeStrategy = -1;
          cachedHistoryWordsBackup.clear();
          cachedHistoryWords.clear();
          mergeHistoryWords(
              cachedHistoryWords, originHistoryWords, mergedHistoryWords);
        }
      }

      await _storeCache(mergedHistoryWords);

      if (mergedHistoryWords.length > 0) {
        print('world! ${originHistoryWords.length} @ $ts');
        return mergedHistoryWords;
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
    print('isOriginReset');
    print(
        'isOriginReset, cached ${cachedHistoryWords.length}; origin ${originHistoryWords.length}');
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

    bool result = false;

    for (var i = 0; i < cachedHistoryWords.length; i++) {
      var hw = cachedHistoryWords[i];
      String k = hw.from + '<' + hw.to + '<' + hw.word;
      print("origin hasn't value in cached: ${originMap[k] == null}");
      if (originMap[k] == null) {
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
