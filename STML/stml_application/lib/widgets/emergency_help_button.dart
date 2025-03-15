// lib/widgets/emergency_help_button.dart
// By sandrine

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A customizable emergency help button widget that provides visual feedback
/// and handles emergency requests with accessibility support.
class EmergencyHelpButton extends StatefulWidget {
  const EmergencyHelpButton({
    super.key,
    required this.onPressed,
    this.buttonText = 'EMERGENCY HELP',
    this.successMessage = 'Help is on the way!',
    this.errorMessage = 'Failed to send help request. Please try again.',
    this.pendingMessage = 'Request sent but no confirmation received.',
  });

  /// Callback function triggered when the button is pressed
  final Future<bool> Function() onPressed;

  /// Customizable text properties for internationalization
  final String buttonText;
  final String successMessage;
  final String errorMessage;
  final String pendingMessage;

  @override
  State<EmergencyHelpButton> createState() => _EmergencyHelpButtonState();
}

class _EmergencyHelpButtonState extends State<EmergencyHelpButton> {
  bool _isLoading = false;
  String? _feedbackMessage;

  Future<void> _handlePress() async {
    if (_isLoading) return;

    // Provide haptic feedback for button press
    HapticFeedback.heavyImpact();

    setState(() {
      _isLoading = true;
      _feedbackMessage = null;
    });

    try {
      final success = await widget.onPressed();
      setState(() {
        _feedbackMessage =
            success ? widget.successMessage : widget.pendingMessage;
      });
    } catch (e) {
      setState(() {
        _feedbackMessage = widget.errorMessage;
      });
      debugPrint('Emergency help request error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !_isLoading,
      label: 'Emergency help button',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: _isLoading ? null : _handlePress,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(200, 60),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.buttonText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          if (_feedbackMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _feedbackMessage!,
                style: TextStyle(
                  color: _feedbackMessage! == widget.errorMessage
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
                semanticsLabel: _feedbackMessage,
              ),
            ),
        ],
      ),
    );
  }
}
