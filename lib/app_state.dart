import 'package:flutter/material.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  String _aiGeneratedText = 'Empty String';
  String get aiGeneratedText => _aiGeneratedText;
  set aiGeneratedText(String value) {
    _aiGeneratedText = value;
    notifyListeners();
  }

  bool _searchisactive = false;
  bool get searchisactive => _searchisactive;
  set searchisactive(bool value) {
    _searchisactive = value;
    notifyListeners();
  }

  bool _notificationisseen = false;
  bool get notificationisseen => _notificationisseen;
  set notificationisseen(bool value) {
    _notificationisseen = value;
    notifyListeners();
  }
}
