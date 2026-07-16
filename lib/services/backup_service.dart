import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';

class BackupService {
  static const List<String> _systemBoxes = [
    'cookbooks',
    'cookbook_covers',
    'meal_planner',
    'shopping_list',
    'collections',
  ];

  static Future<Map<String, dynamic>> createBackup() async {
    final Map<String, dynamic> backup = {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'boxes': <String, dynamic>{},
    };

    final Map<String, dynamic> boxes =
        backup['boxes'] as Map<String, dynamic>;

    for (final String boxName in _systemBoxes) {
      if (!await Hive.boxExists(boxName)) {
        continue;
      }

      final Box box = Hive.isBoxOpen(boxName)
          ? Hive.box(boxName)
          : await Hive.openBox(boxName);

      boxes[boxName] = _serialiseBox(box);
    }

    final Box cookbookListBox =
        Hive.isBoxOpen('cookbooks')
            ? Hive.box('cookbooks')
            : await Hive.openBox('cookbooks');

    for (final dynamic cookbookValue
        in cookbookListBox.values) {
      final String cookbookName =
          cookbookValue.toString().trim();

      if (cookbookName.isEmpty) {
        continue;
      }

      if (!await Hive.boxExists(cookbookName)) {
        continue;
      }

      final Box cookbookBox =
          Hive.isBoxOpen(cookbookName)
              ? Hive.box(cookbookName)
              : await Hive.openBox(cookbookName);

      boxes[cookbookName] =
          _serialiseBox(cookbookBox);
    }

    return backup;
  }

  static Map<String, dynamic> _serialiseBox(
    Box box,
  ) {
    final Map<String, dynamic> serialised = {};

    for (final dynamic key in box.keys) {
      serialised[key.toString()] =
          _encodeValue(box.get(key));
    }

    return serialised;
  }

  static dynamic _encodeValue(
    dynamic value,
  ) {
    if (value is Uint8List) {
      return <String, dynamic>{
        '__type': 'bytes',
        'data': base64Encode(value),
      };
    }

    if (value is List<int>) {
      return <String, dynamic>{
        '__type': 'bytes',
        'data': base64Encode(
          Uint8List.fromList(value),
        ),
      };
    }

    if (value is Map) {
      return value.map(
        (
          dynamic key,
          dynamic mapValue,
        ) {
          return MapEntry(
            key.toString(),
            _encodeValue(mapValue),
          );
        },
      );
    }

    if (value is List) {
      return value
          .map(_encodeValue)
          .toList();
    }

    return value;
  }

  static String backupToJson(
    Map<String, dynamic> backup,
  ) {
    return const JsonEncoder.withIndent(
      '  ',
    ).convert(backup);
  }

  static Map<String, dynamic> backupFromJson(
    String jsonText,
  ) {
    final dynamic decoded =
        jsonDecode(jsonText);

    if (decoded is! Map) {
      throw const FormatException(
        'The backup file is not valid.',
      );
    }

    return Map<String, dynamic>.from(
      decoded,
    );
  }

  static Future<void> restoreBackup(
    Map<String, dynamic> backup,
  ) async {
    final dynamic savedBoxes =
        backup['boxes'];

    if (savedBoxes is! Map) {
      throw const FormatException(
        'The backup does not contain any data.',
      );
    }

    for (final dynamic entry
        in savedBoxes.entries) {
      final String boxName =
          entry.key.toString();

      final dynamic savedValues =
          entry.value;

      if (savedValues is! Map) {
        continue;
      }

      final Box box =
          Hive.isBoxOpen(boxName)
              ? Hive.box(boxName)
              : await Hive.openBox(boxName);

      await box.clear();

      for (final dynamic valueEntry
          in savedValues.entries) {
        await box.put(
          valueEntry.key.toString(),
          _decodeValue(
            valueEntry.value,
          ),
        );
      }
    }
  }

  static dynamic _decodeValue(
    dynamic value,
  ) {
    if (value is Map) {
      if (value['__type'] == 'bytes') {
        final String encoded =
            value['data']?.toString() ?? '';

        return base64Decode(encoded);
      }

      return value.map(
        (
          dynamic key,
          dynamic mapValue,
        ) {
          return MapEntry(
            key.toString(),
            _decodeValue(mapValue),
          );
        },
      );
    }

    if (value is List) {
      return value
          .map(_decodeValue)
          .toList();
    }

    return value;
  }
}