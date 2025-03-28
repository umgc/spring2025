import 'package:flutter/material.dart';

class TranscriptDialog extends StatefulWidget {
  final String localTranscript;
  final String awsTranscript;
  final bool awsAvailable;
  final int userId;
  final int transcriptId;
  final String industry;
  final Function(int userId, int transcriptId, String text, String industry) onSave;

  const TranscriptDialog({
    super.key,
    required this.localTranscript,
    required this.awsTranscript,
    required this.awsAvailable,
    required this.userId,
    required this.transcriptId,
    required this.industry,
    required this.onSave,
  });

  @override
  State<TranscriptDialog> createState() => _TranscriptDialogState();
}

class _TranscriptDialogState extends State<TranscriptDialog> {
  late TextEditingController _localController;
  late TextEditingController _awsController;
  bool _showAwsTranscript = false;

  @override
  void initState() {
    super.initState();
    _localController = TextEditingController(text: widget.localTranscript);
    _awsController = TextEditingController(text: widget.awsTranscript);
    if (!widget.awsAvailable) {
      _showAwsTranscript = false;
    }
  }

  @override
  void dispose() {
    _localController.dispose();
    _awsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text('Edit Transcript'),
          Spacer(),
          ToggleButtons(
            isSelected: [!_showAwsTranscript, _showAwsTranscript],
            onPressed: (index) {
              if (index == 0 || widget.awsAvailable) {
                setState(() {
                  _showAwsTranscript = index == 1;
                });
              } else if (index == 1 && !widget.awsAvailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('AWS transcription is not available'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.fixed,
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Local'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'AWS',
                  style: TextStyle(
                    color: widget.awsAvailable 
                        ? null 
                        : Theme.of(context).disabledColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showAwsTranscript)
                Text(
                  'AWS Transcription',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                )
              else
                Text(
                  'Local Transcription',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              SizedBox(height: 8),
              TextField(
                controller: _showAwsTranscript ? _awsController : _localController,
                decoration: InputDecoration(
                  hintText: 'Edit the transcript text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            // Save the currently selected transcript
            final textToSave = _showAwsTranscript 
                ? _awsController.text 
                : _localController.text;
            
            await widget.onSave(
              widget.userId,
              widget.transcriptId,
              textToSave,
              widget.industry,
            );
            
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Text('Save'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}