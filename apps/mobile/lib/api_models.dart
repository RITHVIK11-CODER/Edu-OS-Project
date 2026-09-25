class AuthUserDto {
  const AuthUserDto({
    required this.id,
    required this.role,
    required this.displayName,
  });

  final String id;
  final String role;
  final String displayName;

  factory AuthUserDto.fromJson(Map<String, dynamic> json) => AuthUserDto(
        id: (json['id'] ?? '').toString(),
        role: (json['role'] ?? 'STUDENT').toString(),
        displayName: (json['display_name'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'display_name': displayName,
      };
}

class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'bearer',
    required this.user,
  });

  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final AuthUserDto user;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    final userMap = userRaw is Map<String, dynamic>
        ? userRaw
        : <String, dynamic>{};

    return AuthResponseDto(
      accessToken: (json['access_token'] ?? '').toString(),
      refreshToken: json['refresh_token']?.toString(),
      tokenType: (json['token_type'] ?? 'bearer').toString(),
      user: AuthUserDto.fromJson(userMap),
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        if (refreshToken != null) 'refresh_token': refreshToken,
        'token_type': tokenType,
        'user': user.toJson(),
      };
}

class StudentProfileDto {
  const StudentProfileDto({
    required this.id,
    required this.displayName,
    required this.grade,
    required this.section,
  });

  final String id;
  final String displayName;
  final int? grade;
  final String? section;

  factory StudentProfileDto.fromJson(Map<String, dynamic> json) =>
      StudentProfileDto(
        id: json['id'].toString(),
        displayName: (json['display_name'] ?? '').toString(),
        grade: json['grade'] as int?,
        section: json['section']?.toString(),
      );
}

class ConceptDto {
  const ConceptDto({
    required this.id,
    required this.name,
    required this.mastery,
    required this.status,
  });

  final String id;
  final String name;
  final int mastery;
  final String status;

  factory ConceptDto.fromJson(Map<String, dynamic> json) => ConceptDto(
        id: json['id'].toString(),
        name: (json['name'] ?? '').toString(),
        mastery: (json['mastery'] as num?)?.round() ?? 0,
        status: (json['status'] ?? 'WEAK').toString(),
      );
}

class LearningTwinDto {
  const LearningTwinDto({
    required this.overallMastery,
    required this.concepts,
  });

  final int overallMastery;
  final List<ConceptDto> concepts;

  factory LearningTwinDto.fromJson(Map<String, dynamic> json) =>
      LearningTwinDto(
        overallMastery: (json['overall_mastery'] as num?)?.round() ?? 0,
        concepts: (json['concepts'] as List<dynamic>? ?? const [])
            .map((item) => ConceptDto.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class AssessmentAttemptDto {
  const AssessmentAttemptDto({
    required this.attemptId,
    required this.status,
    required this.startedAt,
  });

  final String attemptId;
  final String status;
  final String startedAt;

  factory AssessmentAttemptDto.fromJson(Map<String, dynamic> json) =>
      AssessmentAttemptDto(
        attemptId: json['attempt_id'].toString(),
        status: json['status'].toString(),
        startedAt: json['started_at'].toString(),
      );
}

class AssessmentResultDto {
  const AssessmentResultDto({
    required this.attemptId,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.weakConcepts,
  });

  final String attemptId;
  final num score;
  final int correctAnswers;
  final int totalQuestions;
  final List<dynamic> weakConcepts;

  factory AssessmentResultDto.fromJson(Map<String, dynamic> json) =>
      AssessmentResultDto(
        attemptId: json['attempt_id'].toString(),
        score: (json['score'] as num?) ?? 0,
        correctAnswers: (json['correct_answers'] as num?)?.toInt() ?? 0,
        totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
        weakConcepts: json['weak_concepts'] as List<dynamic>? ?? const [],
      );
}

class MindTraceDto {
  const MindTraceDto({
    required this.analysisId,
    required this.conceptId,
    required this.conceptName,
    required this.misconceptionTitle,
    required this.misconceptionDescription,
    required this.rootConceptId,
    required this.confidence,
    required this.recommendedAction,
    required this.isCorrect,
  });

  final String analysisId;
  final String conceptId;
  final String conceptName;
  final String misconceptionTitle;
  final String misconceptionDescription;
  final String? rootConceptId;
  final double confidence;
  final String recommendedAction;
  final bool? isCorrect;

  factory MindTraceDto.fromJson(Map<String, dynamic> json) {
    final misconception =
        json['misconception'] as Map<String, dynamic>? ?? const {};
    final concept = json['concept'] as Map<String, dynamic>? ?? const {};

    return MindTraceDto(
      analysisId: json['analysis_id'].toString(),
      conceptId: (json['concept_id'] ?? concept['id']).toString(),
      conceptName: (concept['name'] ?? '').toString(),
      misconceptionTitle: (misconception['title'] ?? '').toString(),
      misconceptionDescription:
          (misconception['description'] ?? '').toString(),
      rootConceptId: misconception['root_concept_id']?.toString(),
      confidence: (misconception['confidence'] as num?)?.toDouble() ?? 0,
      recommendedAction: (json['recommended_action'] ?? '').toString(),
      isCorrect: json['is_correct'] as bool?,
    );
  }
}

class RecommendationDto {
  const RecommendationDto({
    required this.recommendationId,
    required this.conceptId,
    required this.action,
    required this.reason,
    required this.durationMinutes,
    required this.steps,
  });

  final String recommendationId;
  final String? conceptId;
  final String action;
  final String reason;
  final int durationMinutes;
  final List<String> steps;

  factory RecommendationDto.fromJson(Map<String, dynamic> json) =>
      RecommendationDto(
        recommendationId: json['recommendation_id'].toString(),
        conceptId: json['concept_id']?.toString(),
        action: (json['action'] ?? '').toString(),
        reason: (json['reason'] ?? '').toString(),
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
        steps: (json['steps'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList(),
      );
}
