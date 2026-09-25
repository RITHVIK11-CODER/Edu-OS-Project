import 'api_client.dart';
import 'api_models.dart';

class AuthApiService {
  const AuthApiService(this.client);
  final ApiClient client;

  Future<AuthResponseDto> login({
    required String email,
    required String password,
  }) async {
    final response = await client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return AuthResponseDto.fromJson(response);
  }

  Future<Map<String, dynamic>> loginRaw({
    required String email,
    required String password,
  }) =>
      client.post('/auth/login', body: {
        'email': email,
        'password': password,
      });

  Future<AuthUserDto> me() async =>
      AuthUserDto.fromJson(await client.get('/auth/me'));
}

class StudentApiService {
  const StudentApiService(this.client);
  final ApiClient client;

  Future<StudentProfileDto> profile() async =>
      StudentProfileDto.fromJson(await client.get('/students/me'));
}

class AssessmentApiService {
  const AssessmentApiService(this.client);
  final ApiClient client;

  Future<List<Map<String, dynamic>>> listAssessments() async {
    final data = await client.get('/assessments');
    final value = data['value'];
    return value is List
        ? value.whereType<Map<String, dynamic>>().toList()
        : const [];
  }

  Future<AssessmentAttemptDto> start(String assessmentId) async =>
      AssessmentAttemptDto.fromJson(
        await client.post('/assessments/$assessmentId/start'),
      );

  Future<List<Map<String, dynamic>>> questions(String assessmentId) async {
    final data = await client.get('/assessments/$assessmentId/questions');
    final value = data['value'];
    return value is List
        ? value.whereType<Map<String, dynamic>>().toList()
        : const [];
  }

  Future<void> submitAnswer({
    required String attemptId,
    required String questionId,
    required dynamic studentAnswer,
    required int timeTakenSeconds,
  }) async {
    await client.post('/attempts/$attemptId/answers', body: {
      'question_id': questionId,
      'student_answer': studentAnswer,
      'time_taken_seconds': timeTakenSeconds,
    });
  }

  Future<AssessmentResultDto> submit(String attemptId) async =>
      AssessmentResultDto.fromJson(
        await client.post('/attempts/$attemptId/submit'),
      );

  Future<AssessmentResultDto> result(String attemptId) async =>
      AssessmentResultDto.fromJson(
        await client.get('/attempts/$attemptId/result'),
      );
}

class MindTraceApiService {
  const MindTraceApiService(this.client);
  final ApiClient client;

  Future<MindTraceDto> analyze({required String answerId}) async =>
      MindTraceDto.fromJson(
        await client.post('/mindtrace/analyze', body: {
          'answer_id': answerId,
        }),
      );
}

class LearningTwinApiService {
  const LearningTwinApiService(this.client);
  final ApiClient client;

  Future<LearningTwinDto> me() async =>
      LearningTwinDto.fromJson(await client.get('/learning-twin/me'));
}

class PathAiApiService {
  const PathAiApiService(this.client);
  final ApiClient client;

  Future<RecommendationDto> recommend({required String conceptId}) async =>
      RecommendationDto.fromJson(
        await client.post('/pathai/recommend', body: {
          'concept_id': conceptId,
        }),
      );
}
