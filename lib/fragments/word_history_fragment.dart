import 'dart:js';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
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
  bool selected = false;

  HistoryWord(
      {this.from,
      this.to,
      this.word,
      this.definition,
      this.storeTimestamp,
      this.isNew,
      this.deleted,
      this.selected = false});

  factory HistoryWord.fromJson(Map<String, dynamic> json) =>
      _$HistoryWordFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryWordToJson(this);
}

class WordHistoryFragmentState extends State<WordHistoryFragment> {
  Future<dynamic> futureWords;
  var mergeStrategy; // -1 unknown, 1 reset, 0 merge, null init

  var cachedHistoryWordsBackup = <HistoryWord>[];
  var originHistoryWordsBackup = <HistoryWord>[];

  bool sortWord = false;

  @override
  void initState() {
    super.initState();
    print('initState');
    futureWords = fetchHistoryWords();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final List<Widget> headerWidgets = <Widget>[];
    double startPadding = 24.0;

    final selectedActions = <Widget>[
      IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          // setState(() {
          //   for (var item in _items
          //       ?.where((d) => d?.selected ?? false)
          //       ?.toSet()
          //       ?.toList()) {
          //     _items.remove(item);
          //   }
          // });
        },
      ),
    ];

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
          int _selectedRowCount = snapshot.data
                  .where((element) => element.selected ?? false)
                  .toSet()
                  .toList()
                  .length ??
              0;

          if (_selectedRowCount == 0) {
            headerWidgets.add(Expanded(child: const Text('Data Management')));
            // if (header is ButtonBar) {
            //   // We adjust the padding when a button bar is present, because the
            //   // ButtonBar introduces 2 pixels of outside padding, plus 2 pixels
            //   // around each button on each side, and the button itself will have 8
            //   // pixels internally on each side, yet we want the left edge of the
            //   // inside of the button to line up with the 24.0 left inset.
            //   // Better magic. See https://github.com/flutter/flutter/issues/4460
            //   startPadding = 12.0;
            // }
          } else {
            headerWidgets.add(Expanded(
              child:
                  Text(localizations.selectedRowCountTitle(_selectedRowCount)),
            ));
          }

          if (_selectedRowCount != 0) {
            headerWidgets.addAll(selectedActions.map<Widget>((Widget action) {
              return Padding(
                // 8.0 is the default padding of an icon button
                padding:
                    const EdgeInsetsDirectional.only(start: 24.0 - 8.0 * 2.0),
                child: action,
              );
            }).toList());
          }

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
                  if (sortWord) {
                    snapshot.data.sort((a, b) => b.word.compareTo(a.word));
                  } else {
                    snapshot.data.sort((a, b) => a.word.compareTo(b.word));
                  }

                  // String formattedDate = DateFormat('yyyy-MM-dd – kk:mm')
                  //     .format(DateTime.fromMillisecondsSinceEpoch(
                  //         snapshot.data.timestamp));
                  return Scrollbar(
                    child: Column(children: [
                      Semantics(
                        container: true,
                        child: DefaultTextStyle(
                          style: _selectedRowCount > 0
                              ? themeData.textTheme.subhead
                                  .copyWith(color: themeData.accentColor)
                              : themeData.textTheme.title
                                  .copyWith(fontWeight: FontWeight.w400),
                          child: IconTheme.merge(
                              data: const IconThemeData(opacity: 0.54),
                              child: ButtonTheme.bar(
                                child: Ink(
                                  height: 64.0,
                                  color: _selectedRowCount > 0
                                      ? themeData.secondaryHeaderColor
                                      : null,
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.only(
                                        start: startPadding, end: 14.0),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: headerWidgets),
                                  ),
                                ),
                              )),
                        ),
                      ),
                      Align(
                          alignment: Alignment.topRight,
                          child: Text('number: ${snapshot.data.length}')),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            DataTable(
                                sortAscending: sortWord,
                                sortColumnIndex: 3,
                                showCheckboxColumn: true,
                                onSelectAll: (bool value) {
                                  for (var row in snapshot.data) {
                                    setState(() {
                                      row.selected = value;
                                    });
                                  }
                                },
                                columns: [
                                  DataColumn(label: Text('from')),
                                  DataColumn(label: Text('to')),
                                  DataColumn(
                                      onSort: (columnIndex, ascending) {
                                        setState(() {
                                          sortWord = !sortWord;
                                        });
                                      },
                                      numeric: false,
                                      label: Text('word')),
                                  DataColumn(label: Text('definition')),
                                ],
                                rows: _buildRows(snapshot.data?.length ?? 0,
                                    (int index) {
                                  final HistoryWord h = snapshot.data[index];
                                  return DataRow.byIndex(
                                      index: index,
                                      selected: h.selected,
                                      onSelectChanged: (bool value) {
                                        if (h.selected != value) {
                                          setState(() {
                                            h.selected = value;
                                          });
                                        }
                                      },
                                      cells: [
                                        // DataCell(FlatButton(
                                        //     onPressed: () {
                                        //       Navigator.push(context,
                                        //           MaterialPageRoute(
                                        //               builder: (_) {
                                        //         return DetailScreen();
                                        //       }));
                                        //     },
                                        //     child: Text('Button'))),
                                        DataCell(Text(h.from)),
                                        DataCell(Text(h.to)),
                                        DataCell(Text(h.word)),
                                        DataCell(Text(h.definition)),
                                      ]);
                                })),
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

  static List<DataRow> _buildRows(int count, dataRowbuilder) {
    List<DataRow> _rows = [];

    for (int i = 0; i < count; i++) {
      _rows.add(dataRowbuilder(i));
    }

    return _rows;
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
    if (cachedHistoryWords.length > 0) {
      cachedHistoryWords.forEach((hw) {
        mergedHistoryWords.add(hw);
      });
    }

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

    if (originHistoryWords.length > 0) {
      originHistoryWords.forEach((hw) {
        String k = hw.from + '<' + hw.to + '<' + hw.word;
        if (cachedMap[k] == null) {
          mergedHistoryWords.add(hw);
        }
      });
    }
    originHistoryWordsBackup.clear();
    cachedHistoryWordsBackup.clear();
  }

  Future<List<HistoryWord>> fetchHistoryWords() async {
    print('fetchHistoryWords');

    if (mergeStrategy == null) {
      try {
        final resOptions = await Chrome.Extension.storageLocalGet(null);
        print(Chrome.stringify(resOptions));
        Map map = jsonDecode(Chrome.stringify(resOptions));
        if (map['cbvAlwaysMerge'] == true) {
          mergeStrategy = 0;
        } else {
          mergeStrategy = -1;
        }
        print('mergeStrategy init: $mergeStrategy');
      } catch (e) {
        print('err on load options: $e');
      }
    }

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
