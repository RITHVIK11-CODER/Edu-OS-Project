import 'package:eduos_student_app/app.dart';
import 'package:eduos_student_app/models.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
