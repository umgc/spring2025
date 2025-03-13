import 'database_helper.dart';

class MedicalAPI {
  final DatabaseHelper dbHelper = DatabaseHelper();

  /// 📌 Step 3.1: Retrieve the latest transcription of a patient's consultation.
  Future<String?> getConsultationTranscription(int visitId) async {
  Map<String, dynamic>? visitData = await dbHelper.getDoctorVisitById(visitId);

  // Extract the transcription text if available, otherwise return null
  return visitData?['transcription_text'] as String? ?? "No Transcription Available";
}

  /// 📌 Step 3.2: Retrieve symptoms & diagnosis already stored in the database.
  Future<Map<String, String>?> getSymptomsAndDiagnosis(int patientId) async {
    final records = await dbHelper.getDoctorVisitsByPatientId(patientId);

    if (records.isNotEmpty) {
      final latestRecord = records.last; // Get the most recent visit entry
      return {
        'symptoms': latestRecord['doctor_visit_symptoms'] ?? 'Unknown',
        'diagnosis': latestRecord['doctor_visit_diagnosis'] ?? 'Unknown',
      };
    }

    return null; // No records found
  }

  /// 📌 Step 4.1: Store the visit into the DoctorVisit table
  Future<int> storeDoctorVisit({
    required int userId,
    required int patientId,
    required int transcriptId,
    required String symptoms,
    required String diagnosis,
  }) async {
    final visitMap = {
      'user_id': userId,
      'transcript_id': transcriptId,
      'patient_id': patientId,
      'doctor_visit_symptoms': symptoms,
      'doctor_visit_diagnosis': diagnosis,
    };

    int visitId = await dbHelper.insertDoctorVisit(visitMap);
    return visitId;
  }

  /// 📌 Step 4.2: Ensure only authorized users can access records.
  /// (For now, we're assuming a secure retrieval function is in place)
  Future<bool> authorizeUser(int userId) async {
    // Assume only doctors or the patient themselves can access
    // You can implement role-based access checks here.
    return true; // Placeholder for now
  }

  /// 📌 Step 5.1: Retrieve ALL medical records for a given patient.
  Future<List<Map<String, dynamic>>> getPatientMedicalRecords(
      int patientId) async {
    return await dbHelper.getDoctorVisitsByPatientId(patientId);
  }

  /// 📌 Step 5.2: Retrieve past consultations (Transcript + Diagnosis).
  Future<List<Map<String, dynamic>>> getPastConsultations(int patientId) async {
    final medicalRecords = await getPatientMedicalRecords(patientId);

    // Ensure pastConsultations list is initialized
    List<Map<String, dynamic>> pastConsultations = [];

    for (var record in medicalRecords) {
      int? transcriptId =
          record['transcript_id'] as int?; // Ensure transcriptId is nullable

      // Safely retrieve transcript
      String? transcriptText;
    if (transcriptId != null) {
      Map<String, dynamic>? transcriptData = await dbHelper.getTranscriptById(transcriptId);

      // Extract the actual transcript text if available
      transcriptText = transcriptData?['transcript_text'] as String? ?? "No Transcript Available";
    } else {
      transcriptText = "No Transcript Available"; // Fallback for null transcriptId
    }

    // Add the record with the transcript to the consultations list
    pastConsultations.add({
      ...record,
      'transcript_text': transcriptText, // Include transcript text in the result
    });

    }

    return pastConsultations;
  }
}