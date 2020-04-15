// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_history_fragment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
