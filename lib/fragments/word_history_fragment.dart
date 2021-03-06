import 'dart:js';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'package:word_history_utilities/exceptions/UnknownMergeStrategyException.dart';
import 'package:word_history_utilities/i18n/i18n_minimal.dart';
import '../chrome_extension.dart' as Chrome;
import '../chrome_extension.dart' show SendMessageOptions;
import '../chrome_extension.dart' show SendMessageMessage;
import 'package:timeago/timeago.dart' as timeago;
import 'dart:html' as html;
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
  var autoSync;

  var cachedHistoryWordsBackup = <HistoryWord>[];
  var originHistoryWordsBackup = <HistoryWord>[];

  bool sortWord = false;
  bool deleting = false;

  int syncTimestramp;

  @override
  void initState() {
    super.initState();
    print('initState');
    futureWords = fetchHistoryWords(false);
  }

  @override
  Widget build(BuildContext context) {
    print('WordHistoryFragmentState build');
    final ThemeData themeData = Theme.of(context);
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final List<Widget> headerWidgets = <Widget>[];
    double startPadding = 24.0;

    void _showMergeStrategryChooserDialog() {
      // flutter defined function
      showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: new Text(
                MinimalLocalizations.of(context).mergeStrategyDialogTitle),
            content: new Text(
                MinimalLocalizations.of(context).mergeStrategyDialogContent),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              new FlatButton(
                child: new Text(MinimalLocalizations.of(context).btnMerge),
                onPressed: () {
                  mergeStrategy = 0;
                  refresh(true);
                  Navigator.of(context).pop();
                },
              ),
              new FlatButton(
                child: new Text(MinimalLocalizations.of(context).btnReset),
                onPressed: () {
                  mergeStrategy = 1;
                  refresh(true);
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
          print('FutureBuilder build');
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return CircularProgressIndicator();
            default:
              if (snapshot.hasError) {
                if (snapshot.error is UnknownMergeStrategyException) {
                  _showMergeStrategryChooserDialog();
                } else if (snapshot.error is TimeoutException) {
                  return Text(MinimalLocalizations.of(context).retrieveTimeout);
                } else {
                  return Text("${snapshot.error}");
                }
              } else {
                if (snapshot.hasData) {
                  int _selectedRowCount = snapshot.data
                          .where((element) => element.selected ?? false)
                          .toSet()
                          .toList()
                          .length ??
                      0;

                  final selectedActions = <Widget>[
                    IconButton(
                      icon: Icon(Icons.delete),
                      tooltip: MinimalLocalizations.of(context).deleteToolTip,
                      onPressed: () {
                        setState(() {
                          deleting = true;
                        });

                        var selected = snapshot.data
                            ?.where((d) => d?.selected ?? false)
                            ?.toSet()
                            ?.toList();
                        final snackBar = SnackBar(
                            content: Text(selected.length > 1
                                ? 'Remove ${selected.length} words'
                                : 'Remove ${selected.length} word'),
                            action: SnackBarAction(
                                label: MinimalLocalizations.of(context).btnUndo,
                                onPressed: () {
                                  setState(() {
                                    for (var item in selected) {
                                      item.deleted = false;
                                    }
                                  });
                                }));
                        Scaffold.of(context)
                            .showSnackBar(snackBar)
                            .closed
                            .then((reason) {
                          print('snackbar dismiss: $reason');
                          _storeCache(snapshot.data);
                          setState(() {
                            deleting = false;
                          });
                        });
                        setState(() {
                          for (var item in selected) {
                            item.deleted = true;
                            item.selected = false;
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.file_download),
                      tooltip: MinimalLocalizations.of(context).downloadToolTip,
                      onPressed: () {
                        // https://stackoverflow.com/questions/59663377/how-to-save-and-download-text-file-in-flutter-web-application
                        var selected = snapshot.data
                            ?.where((d) => d?.selected ?? false)
                            ?.toSet()
                            ?.toList();
                        var b = '';
                        for (var item in selected) {
                          b = b + item.from;
                          b = b + "\t";
                          b = b + item.to;
                          b = b + "\t";
                          b = b + item.word;
                          b = b + "\t";
                          b = b + item.definition;
                          b = b + "\n";
                        }
                        final bytes = utf8.encode(b);
                        final blob = html.Blob([bytes]);
                        final url = html.Url.createObjectUrlFromBlob(blob);
                        final anchor = html.document.createElement('a')
                            as html.AnchorElement
                          ..href = url
                          ..style.display = 'none'
                          ..download = 'GoogleDictionaryHistory.csv';
                        html.document.body.children.add(anchor);
                        // download
                        anchor.click();
                        // cleanup
                        html.document.body.children.remove(anchor);
                        html.Url.revokeObjectUrl(url);
                      },
                    ),
                  ];

                  if (_selectedRowCount == 0) {
                    // headerWidgets.add(Expanded(child: const Text('Data Management')));
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
                      child: Text(localizations
                          .selectedRowCountTitle(_selectedRowCount)),
                    ));
                  }

                  if (_selectedRowCount != 0) {
                    headerWidgets
                        .addAll(selectedActions.map<Widget>((Widget action) {
                      return Padding(
                        // 8.0 is the default padding of an icon button
                        padding: const EdgeInsetsDirectional.only(
                            start: 24.0 - 8.0 * 2.0),
                        child: action,
                      );
                    }).toList());
                  }

                  if (sortWord) {
                    snapshot.data.sort((a, b) => b.word.compareTo(a.word));
                  } else {
                    snapshot.data.sort((a, b) => a.word.compareTo(b.word));
                  }

                  var wordsToShow =
                      snapshot.data.where((hw) => !hw.deleted).toList();

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
                      Row(
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                                margin: const EdgeInsets.all(16),
                                child: Text(
                                    // 'number: ${wordsToShow.length}; sync at ${}'
                                    Intl.plural(wordsToShow.length,
                                        one: MinimalLocalizations.of(context)
                                            .syncStatusSingular
                                            .format(List<String>()
                                              ..add(
                                                  wordsToShow.length.toString())
                                              ..add(timeago
                                                  .format(DateTime.fromMillisecondsSinceEpoch(syncTimestramp),
                                                      locale:
                                                          MinimalLocalizations.of(context)
                                                              .locale
                                                              .languageCode))),
                                        other: MinimalLocalizations.of(context)
                                            .syncStatusPlural
                                            .format(List<String>()
                                              ..add(wordsToShow.length.toString())
                                              ..add(timeago.format(DateTime.fromMillisecondsSinceEpoch(syncTimestramp), locale: MinimalLocalizations.of(context).locale.languageCode)))))),
                          ),
                        ],
                      ),
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
                                      if (!row.deleted) {
                                        row.selected = value;
                                      }
                                    });
                                  }
                                },
                                columns: [
                                  DataColumn(
                                      onSort: (columnIndex, ascending) {
                                        setState(() {
                                          sortWord = !sortWord;
                                        });
                                      },
                                      numeric: false,
                                      label: Text(
                                          MinimalLocalizations.of(context)
                                              .wordTitle)),
                                  DataColumn(
                                      label: Text(
                                          MinimalLocalizations.of(context)
                                              .definisionTitle)),
                                  DataColumn(
                                      label: Text(
                                          MinimalLocalizations.of(context)
                                              .fromTitle)),
                                  DataColumn(
                                      label: Text(
                                          MinimalLocalizations.of(context)
                                              .toTitle)),
                                ],
                                rows: _buildRows(wordsToShow?.length ?? 0,
                                    (int index) {
                                  final HistoryWord h = wordsToShow[index];
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
                                        DataCell(Text(h.word)),
                                        DataCell(Text(h.definition)),
                                        DataCell(Text(h.from)),
                                        DataCell(Text(h.to)),
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

  void refresh(bool force) {
    setState(() {
      futureWords = fetchHistoryWords(force);
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
      await Chrome.Extension.storageLocalSet(Chrome.mapToJSObj(map))
          .then((value) => print('storage sync set'));
    } catch (e) {
      print('storeCache Caught e: $e');
    }
  }

  Future<List<HistoryWord>> _loadCache() async {
    print('loadCache');
    try {
      final result =
          await Chrome.Extension.storageLocalGet('word-history-snapshot');
      Map resultMap = Chrome.mapify(result);
      Map list = resultMap['word-history-snapshot'];
      var hw = <HistoryWord>[];
      if (list != null) {
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
      }

      if (hw.length > 0) {
        return hw;
      } else {
        throw Exception('cached word history is empty');
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

  Future<List<HistoryWord>> fetchHistoryWords(bool force) async {
    print('fetchHistoryWords: $force');
    if (mergeStrategy == null) {
      try {
        final resOptions = await Chrome.Extension.storageSyncGet(null);
        print(Chrome.stringify(resOptions));
        Map map = jsonDecode(Chrome.stringify(resOptions));
        if (map['cbvAlwaysMerge'] == true) {
          mergeStrategy = 0;
        } else {
          mergeStrategy = -1;
        }
        autoSync = map['cbvAutoSync'] ?? true;
        print('merge strategy init: $mergeStrategy, $autoSync');
      } catch (e) {
        print('err on load options: $e');
      }
    } else {
      print('mergeStrategy: $mergeStrategy');
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
      var ts = new DateTime.now().millisecondsSinceEpoch;
      if (autoSync || force) {
        final r = await Chrome.Extension.sendMessage2(
                "mgijmajocgfcbeboacabfgobmjgjcoja",
                new SendMessageMessage(getHistory: true),
                new SendMessageOptions(includeTlsChannelId: false))
            .timeout(const Duration(seconds: 5));

        Map obj = Chrome.mapify(r);
        syncTimestramp = ts;

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

        bool irr = isOriginReset(cachedHistoryWords, originHistoryWords);
        print('origin reset? $irr; merge strategy is $mergeStrategy');
        if (mergeStrategy == -1) {
          if (cachedHistoryWords.length > originHistoryWords.length) {
            print('origin become less');
            // dialog user for choosing merge or reset
            if (cachedHistoryWords.length > 0) {
              cachedHistoryWordsBackup.addAll(cachedHistoryWords);
            }

            if (originHistoryWords.length > 0) {
              originHistoryWordsBackup.addAll(originHistoryWords);
            }

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
            cachedHistoryWordsBackup.clear();
            cachedHistoryWords.clear();
            mergeHistoryWords(
                cachedHistoryWords, originHistoryWords, mergedHistoryWords);
          }
        }

        await _storeCache(mergedHistoryWords);
      } else {
        var cachedTimestramp = 0;
        cachedHistoryWords.forEach((hw) {
          if (hw.storeTimestamp > cachedTimestramp) {
            cachedTimestramp = hw.storeTimestamp;
          }
        });
        syncTimestramp = cachedTimestramp;
        mergedHistoryWords = cachedHistoryWords;
      }

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
      throw TimeoutException('retrieve word timeout');
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
