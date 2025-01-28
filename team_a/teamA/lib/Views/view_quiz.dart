import 'package:flutter/material.dart';

class ViewQuiz extends StatelessWidget {
  final int quizId;

  ViewQuiz({required this.quizId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Quiz'),
      ),
      body: Center(
        child: Text('Quiz content goes here for quiz ID: $quizId'),
      ),
    );
  }
}