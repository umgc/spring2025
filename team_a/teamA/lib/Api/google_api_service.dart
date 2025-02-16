import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:learninglens_app/Api/google_classroom_api.dart'; // Import the updated API

class GoogleApiService {
  final GoogleClassroomApi _classroomApi = GoogleClassroomApi();

// -----------------------------------------------------------------------
// Parses XML quiz data and creates/assigns the quiz
// -----------------------------------------------------------------------
  Future<bool> createAndAssignQuizFromXml(
    String courseId,
    String quizName,
    String quizDescription,
    String quizAsXml, // The XML string
    String dueDate, // Format: YYYY-MM-DD-HH-MM
  ) async {
    try {
      // 1. Parse the XML
      final document = xml.XmlDocument.parse(quizAsXml);
      final questions = document.findAllElements('question').toList();

      // 2. Create the Google Form
      String? formId = await _classroomApi.createForm(quizName);
      if (formId == null) {
        print('Error: Failed to create Google Form.');
        return false;
      }

      // 3. Add questions to the form based on XML data
      for (var questionElement in questions) {
        String questionType = questionElement.getAttribute('type') ?? 'unknown';
        String questionText = questionElement
                .getElement('questiontext')
                ?.getElement('text')
                ?.text ??
            '';

        switch (questionType) {
          case 'multichoice':
            List<String> options = [];
            var answerElements =
                questionElement.findAllElements('answer').toList();
            for (var answerElement in answerElements) {
              options.add(answerElement.getElement('text')?.text ?? '');
            }
            bool added =
                await _classroomApi.addQuestion(formId, questionText, options);
            if (!added) {
              print('Error: Failed to add multiple choice question.');
              return false;
            }
            break;
          case 'truefalse':
            bool added = await _classroomApi
                .addQuestion(formId, questionText, ["True", "False"]);
            if (!added) {
              print('Error: Failed to add true/false question.');
              return false;
            }
            break;
          case 'shortanswer':
            bool added = await _classroomApi.addShortAnswerQuestion(
                formId, questionText);
            if (!added) {
              print('Error: Failed to add short answer question.');
              return false;
            }
            break;
          default:
            print('Warning: Unsupported question type: $questionType');
        }
      }

      // 4. Create the Classroom assignment and link the form
      String? assignmentId = await _classroomApi.createAssignment(
        courseId,
        quizName,
        quizDescription,
        formId,
        dueDate,
      );

      if (assignmentId == null) {
        print('Error: Failed to create Classroom assignment.');
        return false;
      }

      print(
          'Quiz created and assigned successfully! Assignment ID: $assignmentId');
      return true;
    } catch (e) {
      print('Error during quiz creation and assignment: $e');
      return false;
    }
  }
}
