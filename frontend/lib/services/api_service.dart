import 'package:dio/dio.dart';
import 'dart:developer' as developer;

class ApiService {
  final Dio _dio;
  final String githubUsername;

  ApiService({
    required this.githubUsername,
    required String githubToken,
    required String aiProvider,
    required String aiApiKey,
  }) : _dio = Dio(BaseOptions(
          baseUrl: 'http://127.0.0.1:8000/api/v1',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 120),
          headers: {
            if (githubToken.isNotEmpty) 'x-github-token': githubToken,
            if (aiProvider.isNotEmpty) 'x-ai-provider': aiProvider,
            if (aiApiKey.isNotEmpty) 'x-ai-api-key': aiApiKey,
          },
        ));

  // Get User Stats
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _dio.get('/records/stats/$githubUsername');
      return response.data;
    } catch (e) {
      developer.log('Error fetching user stats: $e');
      rethrow;
    }
  }

  // Generate Trap PR (Auto)
  Future<Map<String, dynamic>> generateAutoTrapPR(
      String owner, String repo, String path) async {
    try {
      final data = <String, dynamic>{
        'creator_username': githubUsername,
      };
      if (path.isNotEmpty) {
        data['path'] = path;
      }
      
      final response = await _dio.post(
        '/agent/auto-trap-pr/$owner/$repo',
        data: data,
      );
      return response.data;
    } catch (e) {
      developer.log('Error generating auto trap PR: $e');
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
      developer.log('Error scoring review: $e');
      rethrow;
    }
  }

  // Start comment watcher (polling) for a specific PR
  Future<Map<String, dynamic>> startWatcher(String owner, String repo, int prNumber) async {
    try {
      final response = await _dio.post('/agent/start-watcher/$owner/$repo/$prNumber');
      return response.data;
    } catch (e) {
      developer.log('Error starting watcher: $e');
      rethrow;
    }
  }

  // Get GitHub Repos
  Future<List<String>> getGitHubRepos(String owner) async {
    try {
      final response = await _dio.get('/github/repos/$owner');
      final repos = response.data['repos'] as List<dynamic>;
      return repos.cast<String>();
    } catch (e) {
      developer.log('Error fetching github repos: $e');
      rethrow;
    }
  }

  // Get GitHub Repo Files
  Future<List<String>> getGitHubRepoFiles(String owner, String repo) async {
    try {
      final response = await _dio.get('/github/repos/$owner/$repo/files');
      final files = response.data['files'] as List<dynamic>;
      return files.cast<String>();
    } catch (e) {
      developer.log('Error fetching github repo files: $e');
      rethrow;
    }
  }

  // Get GitHub User Info
  Future<Map<String, dynamic>> getGitHubUserInfo(String username) async {
    try {
      final response = await _dio.get('/github/user/$username');
      return response.data;
    } catch (e) {
      developer.log('Error fetching user info: $e');
      rethrow;
    }
  }

  // Ask AI about a PR
  Future<Map<String, dynamic>> askAI(String owner, String repo, int prNumber, String question) async {
    try {
      final response = await _dio.post('/agent/ask-ai', data: {
        'owner': owner,
        'repo': repo,
        'pr_number': prNumber,
        'question': question,
      });
      return response.data;
    } catch (e) {
      developer.log('Error asking AI: $e');
      rethrow;
    }
  }

  // Get AI Chat History
  Future<Map<String, dynamic>> getAskAIHistory(String owner, String repo, int prNumber) async {
    try {
      final response = await _dio.get('/agent/ask-ai/$owner/$repo/$prNumber');
      return response.data;
    } catch (e) {
      developer.log('Error fetching AI history: $e');
      rethrow;
    }
  }
}
