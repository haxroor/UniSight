import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class Data {
  static Future<String> get _filePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/course_data.json';
  }

  static Future<List<Map<String, dynamic>>> loadData() async {
    try {
      final file = File(await _filePath);
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) {
        return [];
      }
      return await compute(_decodeJson, contents);
    } catch (e) {
      print("Error loading data: $e");
      return [];
    }
  }

  static Future<void> saveData(List<Map<String, dynamic>> data) async {
    try {
      final file = File(await _filePath);
      final encodedData = await compute(_encodeJson, data);
      await file.writeAsString(encodedData);
    } catch (e) {
      print("Error saving data: $e");
    }
  }
}

List<Map<String, dynamic>> _decodeJson(String jsonString) {
  return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
}

String _encodeJson(List<Map<String, dynamic>> data) {
  return jsonEncode(data);
}