import 'dart:convert';

import 'package:eduos_student_app/api_client.dart';
import 'package:eduos_student_app/api_models.dart';
import 'package:eduos_student_app/api_services.dart';
import 'package:eduos_student_app/app.dart';
import 'package:eduos_student_app/mock_services.dart';
import 'package:eduos_student_app/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('EduOS starts on student login', (tester) async {
    await tester.pumpWidget(const EduOSApp());
    expect(find.text('EduOS'), findsOneWidget);
    expect(find.text('Student Login'), findsOneWidget);
    expect(find.text('Continue as Student'), findsOneWidget);
  });

  test('reassessment updates Factorization mastery', () {
    final session = StudentSession();
    final before = session.conceptMastery['Factorization']!;
    session.applyReassessment(concept: 'Factorization', correct: true);
    expect(session.conceptMastery['Factorization'], greaterThan(before));
  });

  test('AuthResponseDto deserializes backend response', () {
    final json = {
      'access_token': 'test_token_123',
      'refresh_token': 'refresh_xyz',
      'token_type': 'bearer',
      'user': {
        'id': 'usr_456',
        'role': 'STUDENT',
        'display_name': 'Test Student',
      },
    };

    final dto = AuthResponseDto.fromJson(json);
    expect(dto.accessToken, 'test_token_123');
    expect(dto.refreshToken, 'refresh_xyz');
    expect(dto.tokenType, 'bearer');
    expect(dto.user.id, 'usr_456');
    expect(dto.user.role, 'STUDENT');
    expect(dto.user.displayName, 'Test Student');
  });

  test('StudentSession stores token and user info', () {
    final session = StudentSession();
    expect(session.isAuthenticated, false);

    session.setAuth(
      accessToken: 'token_abc',
      refreshToken: 'ref_123',
      tokenType: 'bearer',
      user: const AuthUserDto(
        id: 'u1',
        role: 'STUDENT',
        displayName: 'Alex',
      ),
    );

    expect(session.isAuthenticated, true);
    expect(session.accessToken, 'token_abc');
    expect(session.refreshToken, 'ref_123');
    expect(session.user?.displayName, 'Alex');

    session.clearAuth();
    expect(session.isAuthenticated, false);
    expect(session.accessToken, isNull);
  });

  test('ApiClient sends Authorization Bearer header when token is present',
      () async {
    String? capturedAuthHeader;

    final mockHttpClient = MockClient((request) async {
      capturedAuthHeader = request.headers['Authorization'];
      return http.Response(
        jsonEncode({
          'access_token': 'jwt_token_sample',
          'token_type': 'bearer',
          'user': {'id': '1', 'role': 'STUDENT', 'display_name': 'Sample'},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final client = ApiClient(
      baseUrl: 'http://localhost:8000/api/v1',
      accessTokenProvider: () async => 'active_jwt_token',
      client: mockHttpClient,
    );

    await client.get('/test');
    expect(capturedAuthHeader, 'Bearer active_jwt_token');
  });

  test('AuthApiService connects to /auth/login and parses response', () async {
    final mockHttpClient = MockClient((request) async {
      expect(request.url.path, '/api/v1/auth/login');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['email'], 'student@eduos.app');
      expect(body['password'], 'secret');

      return http.Response(
        jsonEncode({
          'access_token': 'jwt_logged_in_token',
          'token_type': 'bearer',
          'user': {
            'id': 'std-100',
            'role': 'STUDENT',
            'display_name': 'Jane Doe',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final client = ApiClient(
      baseUrl: 'http://localhost:8000/api/v1',
      client: mockHttpClient,
    );
    final authService = AuthApiService(client);

    final res = await authService.login(
      email: 'student@eduos.app',
      password: 'secret',
    );

    expect(res.accessToken, 'jwt_logged_in_token');
    expect(res.user.displayName, 'Jane Doe');
    expect(res.user.role, 'STUDENT');
  });

  test('ApiClient parses FastAPI 401 error detail', () async {
    final mockHttpClient = MockClient((request) async {
      return http.Response(
        jsonEncode({'detail': 'Invalid email or password'}),
        401,
        headers: {'content-type': 'application/json'},
      );
    });

    final client = ApiClient(
      baseUrl: 'http://localhost:8000/api/v1',
      client: mockHttpClient,
    );

    expect(
      () => client.post('/auth/login', body: {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', 'Invalid email or password'),
      ),
    );
  });

  test('MockAuthService remains intact as fallback', () async {
    final mockAuth = MockAuthService();
    final ok = await mockAuth.login('student@eduos.app', 'demo123');
    expect(ok, true);

    final fail = await mockAuth.login('bad', '12');
    expect(fail, false);
  });
}

