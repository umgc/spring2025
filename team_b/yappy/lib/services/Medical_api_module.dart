import 'database_helper.dart';

class MedicalAPI {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Retrieve the latest transcription of a patient consultation
  Future<String?> getConsultationTranscription(int patientId) async {
    return await dbHelper.getLatestTranscriptByPatient(patientId);
  }

  // Extract symptoms & diagnosis from the transcribed conversation
  Future<Map<String, String>> extractSymptomsAndDiagnosis(String transcription) async {
    // Dummy NLP-based extraction logic (replace with real NLP model later)
    Map<String, String> extractedData = {
      'symptoms': 'Cough, Fever',
      'diagnosis': 'Flu'
    };
    return extractedData;
  }

  // Integrate transcribed consultation with patient medical records
  Future<void> saveConsultation(int patientId, String transcription) async {
    final extractedData = await extractSymptomsAndDiagnosis(transcription);
    await dbHelper.storeMedicalRecord(patientId, transcription, extractedData['symptoms']!, extractedData['diagnosis']!);
  }

  // Retrieve patient's medical records securely
  Future<List<Map<String, dynamic>>> getPatientMedicalRecords(int patientId) async {
    return await dbHelper.getMedicalRecordsByPatient(patientId);
  }
}
