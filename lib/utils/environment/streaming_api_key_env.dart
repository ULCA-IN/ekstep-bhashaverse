import '../constants/api_constants.dart';

String get streamingAPIKey {
  return const String.fromEnvironment(APIConstants.kAuthorizationKeyStreaming,
      defaultValue: '');
}
