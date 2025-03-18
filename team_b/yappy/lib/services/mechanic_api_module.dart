import 'package:flutter/material.dart';

import 'database_helper.dart';

class MechanicAPI {
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Fetch the latest transcription for a given user.
  // This function gets the transcript IDs for the user,
  // then retrieves the text from the most recent transcript.
  Future<String?> getLatestTranscription(int userId) async {
    List<int> transcriptIds = await dbHelper.getTranscriptIdsByUserId(userId);
    if (transcriptIds.isEmpty) return null;
    int latestTranscriptId = transcriptIds.last;
    final db = await dbHelper.database;
    List<Map<String, dynamic>> result = await db.query(
      'Transcript',
      columns: ['transcript_text_data'],
      where: 'transcript_id = ?',
      whereArgs: [latestTranscriptId],
    );
    if (result.isNotEmpty) {
      return result.first['transcript_text_data'] as String?;
    }
    return null;
  }

  // Simulated extraction function.
  // Since the NLP extraction and summarization are assumed to be completed already,
  // thisfunction returns processed details based on the transcription content.
  Map<String, String> extractMechanicData(String transcription) {
    if (transcription.contains("Honda")) {
      return {
        'vehicle': 'Honda Civic 2015',
        'diagnosis':
        'Brake pads require inspection, possible wear; engine knocking suggests immediate engine checkup.',
        'parts': 'Brake pads, Engine oil'
      };
    } else {
      return {
        'vehicle': 'Unknown Vehicle',
        'diagnosis': 'No diagnostic details available',
        'parts': 'N/A'
      };
    }
  }

  // Store the processed mechanic service details into the VehicleMaintenance table.
  // Note: The VehicleMaintenance table requires a vehicle_id.
  // if the vehicle is not directly identified, a dummy value (e.g., 0) is used.
  Future<void> storeMechanicService(
      int userId, int transcriptId, Map<String, String> mechanicData) async {
    int vehicleId = 1; // Ensure this is valid from DB

    await dbHelper.insertVehicleMaintenance({
      'transcript_id': transcriptId,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'vehicle_diagnosis_description': mechanicData['diagnosis'],
      'vehicle_required_parts': mechanicData['parts']
    });

    debugPrint(" Mechanic service stored successfully!");
  }

  // Combines steps: Fetch transcription, extract data, and store the report.
  // Returns a report containing the transcription and the processed mechanic data.
  Future<Map<String, dynamic>?> getLatestMechanicReport(int userId) async {
    String? transcription = await getLatestTranscription(userId);
    if (transcription == null) return null;
    Map<String, String> mechanicData = extractMechanicData(transcription);
    List<int> transcriptIds = await dbHelper.getTranscriptIdsByUserId(userId);
    int latestTranscriptId = transcriptIds.last;
    await storeMechanicService(userId, latestTranscriptId, mechanicData);
    return {
      'transcription': transcription,
      'vehicle': mechanicData['vehicle'],
      'diagnosis': mechanicData['diagnosis'],
      'parts': mechanicData['parts']
    };
  }

  // Retrieve the service history for the mechanic API.
  // This fetches all maintenance records associated with the user.
  Future<List<Map<String, dynamic>>> getMechanicServiceHistory(
      int userId) async {
    List<int> maintenanceIds = await dbHelper.getMaintenanceIdsByUserId(userId);
    final db = await dbHelper.database;
    List<Map<String, dynamic>> history = [];
    for (int id in maintenanceIds) {
      List<Map<String, dynamic>> result = await db.query(
        'VehicleMaintenance',
        where: 'maintenance_id = ?',
        whereArgs: [id],
      );
      if (result.isNotEmpty) {
        history.add(result.first);
      }
    }
    return history;
  }
}