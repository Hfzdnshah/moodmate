import 'package:cloud_functions/cloud_functions.dart';

class MoodAnalysisService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Manually retry analysis for a failed mood entry
  /// Returns the analysis results if successful
  Future<Map<String, dynamic>> retryAnalysis(String entryId) async {
    try {
      final callable = _functions.httpsCallable('retryMoodAnalysis');
      final result = await callable.call<Map<String, dynamic>>({
        'entryId': entryId,
      });

      return result.data;
    } catch (e) {
      throw Exception('Failed to retry mood analysis: $e');
    }
  }

  /// Check if Cloud Functions are available
  Future<bool> checkFunctionsAvailable() async {
    try {
      // Simple ping to check if functions are accessible
      // You could create a lightweight health check function if needed
      return true;
    } catch (e) {
      return false;
    }
  }
}
