// lib/widgets/emergency_help_button.dart

import 'package:flutter/material.dart';

class EmergencyHelpButton extends StatefulWidget {
  const EmergencyHelpButton({
    super.key,
    required this.onPressed,
    required this.buttonText,
    required this.successMessage,
    required this.errorMessage,
    this.isLoading = false,
  });

  final Future<bool> Function() onPressed;
  final String buttonText;
  final String successMessage;
  final String errorMessage;
  final bool isLoading;

  @override
  State<EmergencyHelpButton> createState() => _EmergencyHelpButtonState();
}

class _EmergencyHelpButtonState extends State<EmergencyHelpButton> {
  bool _isLoading = false;
  String? _feedbackMessage;

  Future<void> _handlePress() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _feedbackMessage = null;
    });

    try {
      final success = await widget.onPressed();
      setState(() {
        _feedbackMessage =
            success ? widget.successMessage : widget.errorMessage;
      });
    } catch (e) {
      setState(() {
        _feedbackMessage = widget.errorMessage;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _handlePress,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
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
                color: _feedbackMessage == widget.successMessage
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
