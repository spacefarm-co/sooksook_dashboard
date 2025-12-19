class AppConfig {
  static final AppConfig _instance = AppConfig._internal();

  factory AppConfig() {
    return _instance;
  }

  AppConfig._internal();

  final String thingsBoardApiEndpoint = 'https://sook.spacefarm.co.kr';

  final Map<String, String> headers = {};
}
