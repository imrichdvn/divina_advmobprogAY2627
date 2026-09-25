import 'package:flutter_dotenv/flutter_dotenv.dart';

const int demoUserId = 1;

String get apiHost {
  final configuredHost = dotenv.isInitialized ? dotenv.env['API_HOST'] : null;
  return (configuredHost ?? 'https://dummyjson.com').replaceFirst(
    RegExp(r'/$'),
    '',
  );
}
