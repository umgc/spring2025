import 'package:flutter/material.dart';
import 'dart:math';
import 'services/speech_state.dart';

class AudiowaveWidget extends StatelessWidget {
  final SpeechState speechState;

  const AudiowaveWidget({super.key, required this.speechState});

  @override
  Widget build(BuildContext context) {

    // Listens for the change in data
    return ValueListenableBuilder<List<int>>(
      valueListenable: speechState.audioSamplesNotifier,
      builder: (context, samples, child) {
        return SizedBox(
          height: 100,
          width: MediaQuery.of(context).size.width,
          child: CustomPaint(
            // Paints the audiowave 
            painter: _WaveformPainter(
              samples.isNotEmpty 
                  ? samples 
                  : List.generate(100, (index) => (index % 2 == 0) ? 1000 : -1000),
              Colors.deepPurpleAccent,
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<int> audioSamples;
  final Color waveColor;

  _WaveformPainter(this.audioSamples, this.waveColor);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = waveColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Centers the waves on the screen
    final double midY = size.height / 2;

    // Creates spacing
    final double sampleSpacing = size.width / max(audioSamples.length, 1);

    // Actually paints the individual lines
    for (int i = 0; i < audioSamples.length; i++) {
      final double x = i * sampleSpacing;
      
      // Scale the sample but ensure it doesn't exceed half of the available height
      final double maxAmplitude = size.height / 2 - 4; // Subtract 4 for a small margin
      
      // Normalize then clamp the value between -maxAmplitude and maxAmplitude
      double normalizedSample = (audioSamples[i].toDouble() / 32768.0) * maxAmplitude;
      normalizedSample = normalizedSample.clamp(-maxAmplitude, maxAmplitude);
      
      final double yStart = midY - normalizedSample;
      final double yEnd = midY + normalizedSample;

      canvas.drawLine(Offset(x, yStart), Offset(x, yEnd), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.audioSamples != audioSamples;
  }
}