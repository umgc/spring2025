import 'package:flutter/material.dart';
import 'services/toast_service.dart';

/// Widget that displays persistent toast notifications across all screens
class ToastWidget extends StatefulWidget {
  final Widget child;
  
  const ToastWidget({super.key, required this.child});

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget> {
  final _toastService = ToastService();
  bool _visible = false;
  String _message = '';
  double _progress = 0.0;
  
  @override
  void initState() {
    super.initState();
    
    // Listen to service streams
    _toastService.messageStream.listen((message) {
      if (mounted) {
        setState(() => _message = message);
      }
    });
    
    _toastService.progressStream.listen((progress) {
      if (mounted) {
        setState(() => _progress = progress);
      }
    });
    
    _toastService.visibilityStream.listen((visible) {
      if (mounted) {
        setState(() => _visible = visible);
      }
    });
    
    _toastService.successStream.listen(_showSuccessSnackBar);
    _toastService.errorStream.listen(_showErrorSnackBar);
  }
  
  void _showSuccessSnackBar(String message) {
    // Use ScaffoldMessenger to show SnackBar globally
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    // Use ScaffoldMessenger to show SnackBar globally
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      // Ensure Material is available for elevation and visual elements
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Main content
          widget.child,
          
          // Toast notification
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _visible ? 32.0 : -100.0,
            left: 16.0,
            right: 16.0,
            child: SafeArea(
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
                              _message,
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
                        value: _progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}