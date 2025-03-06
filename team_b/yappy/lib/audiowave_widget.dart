import 'dart:typed_data';
import 'package:flutter/material.dart';

class AudioWaveform extends StatefulWidget {
  final List<Float32List> audioSamples;
  final int sampleRate;
  final int height;
  final double width;

  const AudioWaveform({
    required this.audioSamples,
    required this.sampleRate,
    required this.height,
    required this.width,
    Key? key,
  }) : super(key: key);

  @override
  _AudioWaveformState createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform> {
  late List<double> _waveformData;

  @override
  void initState() {
    super.initState();
    _generateWaveformData();
  }

  @override
  void didUpdateWidget(covariant AudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioSamples != widget.audioSamples) {
      _generateWaveformData();
    }
  }

  // Generate waveform data by processing audio samples
  void _generateWaveformData() {
    _waveformData = [];

    // Process all audio samples
    final int sampleCount = widget.audioSamples.fold<int>(0, (sum, list) => sum + list.length);
    final int samplesPerPixel = (sampleCount / widget.width).round();

    int sampleIndex = 0;

    for (double i = 0.0; i < widget.width; i++) {
      double maxAmplitude = 0.0;
      for (int j = 0; j < samplesPerPixel; j++) {
        if (sampleIndex < widget.audioSamples.length) {
          final sample = widget.audioSamples[sampleIndex];
          maxAmplitude = maxAmplitude < sample.reduce((a, b) => a > b ? a : b)
              ? sample.reduce((a, b) => a > b ? a : b)
              : maxAmplitude;
        }
        sampleIndex++;
      }

      _waveformData.add(maxAmplitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height.toDouble(), // Ensure height is cast to double
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(
        painter: _WaveformPainter(_waveformData, widget.height.toDouble()), // Cast height to double here too
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final double height;

  _WaveformPainter(this.waveformData, this.height);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepPurpleAccent
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double centerY = height / 2;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i.toDouble();
      final amplitude = waveformData[i];

      // Draw the waveform
      canvas.drawLine(
        Offset(x, centerY - (amplitude * centerY)),
        Offset(x, centerY + (amplitude * centerY)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
