class ApiConstants {
  // Domyslny adres dla uruchomienia lokalnego; mozna nadpisac przez --dart-define=API_BASE_URL=...
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  // Emulator Androida nie polaczy sie z hostem przez 127.0.0.1.
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api';
}
