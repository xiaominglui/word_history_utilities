// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_history_fragment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WordHistorySnapshot _$WordHistorySnapshotFromJson(Map<String, dynamic> json) {
  return WordHistorySnapshot(
    timestamp: json['timestamp'] as int,
    historyWords: (json['history_words'] as List)
        ?.map((e) =>
            e == null ? null : HistoryWord.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$WordHistorySnapshotToJson(
        WordHistorySnapshot instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'history_words': instance.historyWords?.map((e) => e?.toJson())?.toList(),
    };

HistoryWord _$HistoryWordFromJson(Map<String, dynamic> json) {
  return HistoryWord(
    from: json['from'] as String,
    to: json['to'] as String,
    word: json['word'] as String,
    definition: json['definition'] as String,
    storeTimestamp: json['storeTimestamp'] as int,
    isNew: json['isNew'] as bool,
    deleted: json['deleted'] as bool,
  );
}

Map<String, dynamic> _$HistoryWordToJson(HistoryWord instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'word': instance.word,
      'definition': instance.definition,
      'storeTimestamp': instance.storeTimestamp,
      'isNew': instance.isNew,
      'deleted': instance.deleted,
    };
