import 'models.dart';

class MockAuthService {
  Future<bool> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return email.trim().isNotEmpty && password.length >= 4;
  }
}

class MockAssessmentService {
  final List<AssessmentQuestion> questions = const [
    AssessmentQuestion(
      id: 'q1',
      topic: 'Factorization',
      question: 'Factorize x² + 5x + 6',
      expectedAnswer: '(x + 2)(x + 3)',
      reasoningHint: 'Find two numbers whose product is 6 and sum is 5.',
    ),
    AssessmentQuestion(
      id: 'q2',
      topic: 'Quadratic Equations',
      question: 'Solve x² - 5x + 6 = 0',
      expectedAnswer: 'x = 2, 3',
      reasoningHint: 'Factorize the quadratic and set each factor to zero.',
    ),
  ];

  Future<List<AssessmentQuestion>> getQuestions(String topic) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return questions.where((q) => q.topic == topic).toList();
  }
}

class MockAIAnalysisService {
  Future<MindTraceResult> analyze({
    required AssessmentQuestion question,
    required String answer,
    String? reasoning,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final normalized = answer.trim().toLowerCase();
    final expected = question.expectedAnswer.toLowerCase();

    if (normalized == expected) {
      return MindTraceResult(
        isCorrect: true,
        concept: question.topic,
        misconception: 'No misconception detected',
        rootCause: 'The response matches the expected solution.',
        evidence: 'Answer and reasoning are consistent with the target concept.',
        confidence: 0.96,
      );
    }

    return MindTraceResult(
      isCorrect: false,
      concept: question.topic,
      misconception: question.topic == 'Factorization'
          ? 'Incorrect factor-pair selection'
          : 'Incorrect root identification',
      rootCause: question.topic == 'Factorization'
          ? 'The selected factors do not satisfy both the product and middle-coefficient conditions.'
          : 'The response suggests the student has not yet connected factorization with the roots of the quadratic.',
      evidence: 'The submitted response does not match the expected solution pattern.',
      confidence: 0.91,
    );
  }
}

class MockRecommendationService {
  Future<Recommendation> recommend(String concept) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return Recommendation(
      action: concept == 'Factorization'
          ? 'Review factor-pair selection'
          : 'Review how factors map to roots',
      reason: 'A targeted recovery step is recommended from the latest analysis.',
      durationMinutes: 5,
      steps: const ['EXPLAIN', 'PRACTICE', 'REASSESS'],
      practiceCount: 3,
    );
  }
}
