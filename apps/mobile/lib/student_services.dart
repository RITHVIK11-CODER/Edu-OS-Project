import 'api_client.dart';
import 'api_models.dart';
import 'api_services.dart';

abstract interface class StudentAppServices {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<LearningTwinDto> learningTwin();
  Future<AssessmentAttemptDto> startAssessment(String assessmentId);
  Future<void> submitAnswer({
    required String attemptId,
    required String questionId,
    required dynamic studentAnswer,
    required int timeTakenSeconds,
  });
  Future<AssessmentResultDto> submitAssessment(String attemptId);
  Future<RecommendationDto> recommend(String conceptId);
}

class BackendStudentAppServices implements StudentAppServices {
  BackendStudentAppServices(ApiClient client)
      : auth = AuthApiService(client),
        assessments = AssessmentApiService(client),
        twin = LearningTwinApiService(client),
        pathAi = PathAiApiService(client);

  final AuthApiService auth;
  final AssessmentApiService assessments;
  final LearningTwinApiService twin;
  final PathAiApiService pathAi;

  @override
  Future<Map<String, dynamic>> login(String email, String password) =>
      auth.login(email: email, password: password);

  @override
  Future<LearningTwinDto> learningTwin() => twin.me();

  @override
  Future<AssessmentAttemptDto> startAssessment(String assessmentId) =>
      assessments.start(assessmentId);

  @override
  Future<void> submitAnswer({
    required String attemptId,
    required String questionId,
    required dynamic studentAnswer,
    required int timeTakenSeconds,
  }) =>
      assessments.submitAnswer(
        attemptId: attemptId,
        questionId: questionId,
        studentAnswer: studentAnswer,
        timeTakenSeconds: timeTakenSeconds,
      );

  @override
  Future<AssessmentResultDto> submitAssessment(String attemptId) =>
      assessments.submit(attemptId);

  @override
  Future<RecommendationDto> recommend(String conceptId) =>
      pathAi.recommend(conceptId: conceptId);
}
