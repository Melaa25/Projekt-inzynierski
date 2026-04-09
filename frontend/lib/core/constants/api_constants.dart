class ApiConstants {
  // Adres API mozna nadpisac przez --dart-define=API_BASE_URL=...
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://projekt-inzynierski-3wfv.onrender.com/api',
  );

  // Dla emulatora Androida nalezy uzyc 10.0.2.2 zamiast 127.0.0.1.
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api';
}
