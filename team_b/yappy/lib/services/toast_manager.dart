import 'package:flutter/material.dart';

/// A service for showing persistent toast notifications
class ToastManager {
  static OverlayEntry? _currentToast;
  static bool _isVisible = false;

  /// Shows a persistent toast with progress at the bottom of the screen
  static void showPersistentToast({
    required BuildContext context,
    required String message,
    double progress = 0.0,
  }) {
    // Hide any existing toast first
    if (_isVisible) {
      hideToast();
    }

    // Create overlay entry
    final overlay = Overlay.of(context);
    _currentToast = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 32.0,
        left: 16.0,
        right: 16.0,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.black87,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Show the toast
    overlay.insert(_currentToast!);
    _isVisible = true;
  }

  /// Updates the existing toast message and progress
  static void updateToast({
    String? message,
    double? progress,
  }) {
    if (!_isVisible || _currentToast == null) return;
    
    // Force rebuild of the overlay
    _currentToast!.markNeedsBuild();
  }

  /// Hides the toast
  static void hideToast() {
    if (_currentToast != null) {
      _currentToast!.remove();
      _currentToast = null;
      _isVisible = false;
    }
  }
}