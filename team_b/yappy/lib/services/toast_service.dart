import 'dart:async';

/// A service that manages toast notifications through stream controllers
class ToastService {
  // Singleton pattern
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;
  ToastService._internal();
  
  // Stream controllers
  final _messageController = StreamController<String>.broadcast();
  final _progressController = StreamController<double>.broadcast();
  final _visibilityController = StreamController<bool>.broadcast();
  final _successController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  
  // Stream getters
  Stream<String> get messageStream => _messageController.stream;
  Stream<double> get progressStream => _progressController.stream;
  Stream<bool> get visibilityStream => _visibilityController.stream;
  Stream<String> get successStream => _successController.stream;
  Stream<String> get errorStream => _errorController.stream;
  
  // Methods to control the toast
  void showToast(String message, {double progress = 0.0}) {
    _messageController.add(message);
    _progressController.add(progress);
    _visibilityController.add(true);
  }
  
  void updateProgress(double progress) {
    _progressController.add(progress);
  }
  
  void updateMessage(String message) {
    _messageController.add(message);
  }
  
  void hideToast() {
    _visibilityController.add(false);
  }
  
  void showSuccess(String message) {
    _successController.add(message);
  }
  
  void showError(String message) {
    _errorController.add(message);
  }
  
  // Clean up resources
  void dispose() {
    _messageController.close();
    _progressController.close();
    _visibilityController.close();
    _successController.close();
    _errorController.close();
  }
}