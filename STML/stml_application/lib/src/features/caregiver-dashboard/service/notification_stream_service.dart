// ignore_for_file: avoid_print, prefer_const_constructors
// Imported libraries and packages

import 'dart:async';


class NotificationStreamService {
  static final NotificationStreamService _instance = NotificationStreamService._internal();
  factory NotificationStreamService() => _instance;
  StreamController<List<Map<String, dynamic>>>? _notificationStreamController;
  bool _isDisposed = true;

  NotificationStreamService._internal() {
    _notificationStreamController =  StreamController.broadcast();
  }

  Stream<List<Map<String, dynamic>>> get stream {
    if(_notificationStreamController == null || _isDisposed) {
      _notificationStreamController = StreamController.broadcast();
      _isDisposed = false;
    }
    return _notificationStreamController!.stream;
  }

  void addData(List<Map<String, dynamic>> data) {
    if (_notificationStreamController != null && !_isDisposed) {
      _notificationStreamController!.add(data);
    } else {
      print("Stream is closed. Cannot add data.");
    }
  }
  void dispose() {
    if(_notificationStreamController != null && !_isDisposed) {
      _notificationStreamController!.close();
      _notificationStreamController = null;
      _isDisposed = true;
    }
  }
}