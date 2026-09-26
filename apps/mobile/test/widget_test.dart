import 'dart:convert';

import 'package:eduos_student_app/api_client.dart';
import 'package:eduos_student_app/api_models.dart';
import 'package:eduos_student_app/models.dart';
import 'package:eduos_student_app/mock_services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('StudentSession stores only in-memory request state', () {
    final session = StudentSession();
    expect(session.isAuthenticated, false);
    session.setAuth(accessToken:'token_abc',refreshToken:'ref_123',user:const AuthUserDto(id:'u1',role:'STUDENT',displayName:'Alex'));
    expect(session.isAuthenticated, true);
    expect(session.user?.displayName, 'Alex');
    session.clearAuth();
    expect(session.isAuthenticated, false);
    expect(session.accessToken, isNull);
  });

  test('ApiClient sends current bearer token', () async {
    String? captured;
    final mock=MockClient((request) async { captured=request.headers['Authorization']; return http.Response(jsonEncode({'ok':true}),200); });
    final client=ApiClient(baseUrl:'http://localhost:8000/api/v1',accessTokenProvider:() async=>'active_jwt_token',client:mock);
    await client.get('/test');
    expect(captured,'Bearer active_jwt_token');
  });

  test('educational mock services contain no authentication service', () async {
    final questions=await MockAssessmentService().getQuestions('Factorization');
    expect(questions,isNotEmpty);
    expect(questions.first.topic,'Factorization');
  });
}
