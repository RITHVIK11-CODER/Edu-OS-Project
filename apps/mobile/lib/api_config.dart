class ApiConfig {
  const ApiConfig._();

  /// Override with:
  /// flutter run --dart-define=API_BASE_URL=http://<host>:8000/api/v1
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );
}
