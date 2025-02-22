import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:learninglens_app/Api/lms/google_classroom/google_classroom_api.dart'; // Import the updated API

class GoogleLmsService {
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
      Map<String, dynamic>? formResponse =
          await _classroomApi.createForm(quizName);
      if (formResponse == null) {
        print('Error: Failed to create Google Form.');
        return false;
      }

      final String formId = formResponse['formId'];
      final String responderUri = formResponse['responderUri'];

      // 3. Prepare the batch request for settings updates and question addition
      List<Map<String, dynamic>> requests = [];

      // Add request to update the form settings
      requests.add({
        'updateSettings': {
          'settings': {
            'emailCollectionType': 'DO_NOT_COLLECT',
            'quizSettings': {'isQuiz': true}
          },
          'updateMask': 'email_collection_type,quiz_settings',
        }
      });

      // 4. Add requests for adding questions to the form
      for (var questionElement in questions) {
        String questionType = questionElement.getAttribute('type') ?? 'unknown';
        String questionText = questionElement
                .getElement('questiontext')
                ?.getElement('text')
                ?.text ??
            '';

        // skip category questions
        if (questionType == 'category') {
          print(
              'Warning: Unsupported question type: $questionType. Skipping question.');
          continue; // Skip to the next question
        }

        switch (questionType) {
          case 'multichoice':
            List<String> options = [];
            var answerElements =
                questionElement.findAllElements('answer').toList();
            for (var answerElement in answerElements) {
              options.add(answerElement.getElement('text')?.text ?? '');
            }
            requests.add(
                _createMultipleChoiceQuestionRequest(questionText, options));
            break;
          case 'truefalse':
            requests.add(_createTrueFalseQuestionRequest(questionText));
            break;
          case 'shortanswer':
            requests.add(_createShortAnswerQuestionRequest(questionText));
            break;
          default:
            print('Warning: Unsupported question type: $questionType');
        }
      }

      // 5. Send the batch update request
      Map<String, dynamic>? batchResponse =
          await _classroomApi.batchUpdateForm(formId, requests);
      if (batchResponse == null) {
        print('Error: Failed to update Google Form.');
        return false;
      }

      // 6. Create the Classroom assignment and link the form
      String? assignmentId = await _classroomApi.createAssignment(
        courseId,
        quizName,
        quizDescription,
        responderUri, // Pass the responderUri
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

  // Helper function to create a multiple choice question request
  Map<String, dynamic> _createMultipleChoiceQuestionRequest(
      String questionText, List<String> options) {
    List<Map<String, dynamic>> choices = [];
    for (String option in options) {
      choices.add({
        'value': option,
      });
    }

    return {
      'createItem': {
        'item': {
          'title': questionText,
          'questionItem': {
            'question': {
              'required': true,
              'choiceQuestion': {
                'type': 'RADIO',
                'options': choices,
              }
            }
          }
        },
        'location': {'index': 0}
      }
    };
  }

  // Helper function to create a true/false question request
  Map<String, dynamic> _createTrueFalseQuestionRequest(String questionText) {
    return _createMultipleChoiceQuestionRequest(
        questionText, ["True", "False"]);
  }

  // Helper function to create a short answer question request
  Map<String, dynamic> _createShortAnswerQuestionRequest(String questionText) {
    return {
      'createItem': {
        'item': {
          'title': questionText,
          'questionItem': {
            'question': {
              'required': true,
              'textQuestion': {},
            }
          }
        },
        'location': {'index': 0}
      }
    };
  }
}
