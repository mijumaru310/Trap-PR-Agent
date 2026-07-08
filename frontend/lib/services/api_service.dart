import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8000/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // Get User Stats
  Future<Map<String, dynamic>> getUserStats(String owner) async {
    try {
      final response = await _dio.get('/records/stats/$owner');
      return response.data;
    } catch (e) {
      print('Error fetching user stats: $e');
      rethrow;
    }
  }

  // Generate Trap PR (Auto)
  Future<Map<String, dynamic>> generateAutoTrapPR(
      String owner, String repo, String path, String language, String branchName) async {
    try {
      final response = await _dio.post(
        '/agent/auto-trap-pr/$owner/$repo',
        data: {
          'path': path,
          'language': language,
          'branch_name': branchName,
        },
      );
      return response.data;
    } catch (e) {
      print('Error generating auto trap PR: $e');
      rethrow;
    }
  }

  // Score Review
  Future<Map<String, dynamic>> scoreReview(
      String owner, String repo, int prNumber) async {
    try {
      final response = await _dio.post('/agent/score-review/$owner/$repo/$prNumber');
      return response.data;
    } catch (e) {
      print('Error scoring review: $e');
      rethrow;
    }
  }
}
