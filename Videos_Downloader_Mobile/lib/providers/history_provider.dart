import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_item.dart';

class HistoryProvider extends ChangeNotifier {
  List<DownloadItem> _items = [];
  List<DownloadItem> get items => List.unmodifiable(_items);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('download_history');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _items = list
            .map((e) => DownloadItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    notifyListeners();
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString('download_history', raw);
  }

  void add(DownloadItem item) {
    _items.insert(0, item);
    notifyListeners();
    _save();
  }

  void remove(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
      _save();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _save();
  }
}
