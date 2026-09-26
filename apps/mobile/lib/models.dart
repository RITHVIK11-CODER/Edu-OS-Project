import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'api_config.dart';
import 'api_models.dart';
import 'api_services.dart';
import 'supabase_client.dart';

class AssessmentQuestion {
  const AssessmentQuestion({
    required this.id,
    required this.topic,
    required this.question,
    required this.expectedAnswer,
    this.reasoningHint,
  });

  final String id;
  final String topic;
  final String question;
  final String expectedAnswer;
  final String? reasoningHint;
}

class MindTraceResult {
  const MindTraceResult({
    required this.isCorrect,
    required this.concept,
    required this.misconception,
    required this.rootCause,
    required this.evidence,
    required this.confidence,
  });

  final bool isCorrect;
  final String concept;
  final String misconception;
  final String rootCause;
  final String evidence;
  final double confidence;
}

class Recommendation {
  const Recommendation({
    required this.action,
    required this.reason,
    required this.durationMinutes,
    required this.steps,
    required this.practiceCount,
  });

  final String action;
  final String reason;
  final int durationMinutes;
  final List<String> steps;
  final int practiceCount;
}

class ConceptProgress {
  const ConceptProgress({
    required this.name,
    required this.mastery,
    required this.status,
  });

  final String name;
  final int mastery;
  final String status;
}

class StudentSession extends ChangeNotifier {
  StudentSession({
    ApiClient? client,
    AuthApiService? authService,
  }) {
    apiClient = client ??
        ApiClient(
          baseUrl: ApiConfig.baseUrl,
          accessTokenProvider: () async => supabaseClient.auth.currentSession?.accessToken ?? accessToken,
        );
    this.authService = authService ?? AuthApiService(apiClient);
  }

  late final ApiClient apiClient;
  late final AuthApiService authService;

  String? accessToken;
  String? refreshToken;
  String? tokenType;
  AuthUserDto? user;

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;

  void setAuth({
    required String accessToken,
    String? refreshToken,
    String? tokenType,
    AuthUserDto? user,
  }) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.tokenType = tokenType ?? 'bearer';
    this.user = user;
    notifyListeners();
  }

  void clearAuth() {
    accessToken = null;
    refreshToken = null;
    tokenType = null;
    user = null;
    notifyListeners();
  }

  int overallMastery = 68;
  final Map<String, int> conceptMastery = {
    'Factorization': 41,
    'Quadratic Equations': 57,
  };

  MindTraceResult? lastAnalysis;
  Recommendation? recommendation;

  List<ConceptProgress> get concepts => conceptMastery.entries
      .map(
        (entry) => ConceptProgress(
          name: entry.key,
          mastery: entry.value,
          status: _statusFor(entry.value),
        ),
      )
      .toList();

  void setAnalysis(MindTraceResult result) {
    lastAnalysis = result;
    notifyListeners();
  }

  void setRecommendation(Recommendation value) {
    recommendation = value;
    notifyListeners();
  }

  void applyReassessment({required String concept, required bool correct}) {
    if (correct) {
      conceptMastery[concept] =
          ((conceptMastery[concept] ?? 0) + 18).clamp(0, 100);
      overallMastery = (overallMastery + 5).clamp(0, 100);
    }
    notifyListeners();
  }

  String _statusFor(int mastery) {
    if (mastery >= 80) return 'STRONG';
    if (mastery >= 60) return 'DEVELOPING';
    return 'WEAK';
  }
}
