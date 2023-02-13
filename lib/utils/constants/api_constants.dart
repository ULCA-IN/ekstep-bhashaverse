// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import '../../enums/language_enum.dart';

class APIConstants {
  static const String ASR_CALLBACK_AZURE_URL = 'https://meity-dev-asr.ulcacontrib.org/asr/v1/recognize';
  static const String ASR_CALLBACK_CDAC_URL = 'https://cdac.ulcacontrib.org/asr/v1/recognize';
  static const String STS_BASE_URL = 'https://meity-auth.ulcacontrib.org/ulca/apis';

  static const String SEARCH_REQ_URL = '/v0/model/search';
  static const String TRANSLITERATION_REQ_URL = '/v0/model/compute';
  static const String ASR_REQ_URL = '/asr/v1/model/compute';
  static const String TRANS_REQ_URL = '/v0/model/compute';
  static const String TTS_REQ_URL = '/v0/model/compute';

  static const int kApiUnknownErrorCode = 0;
  static const int kApiCanceledCode = -1;
  static const int kApiConnectionTimeoutCode = -2;
  static const int kApiDefaultCode = -3;
  static const int kApiReceiveTimeoutCode = -4;
  static const int kApiSendTimeoutCode = -5;
  static const int kApiUnAuthorizedExceptionErrorCode = 401;
  static const int kApiDataConflictCode = 409;

  static const String kApiUnknownError = 'UNKNOWN_ERROR';
  static const String kApiCanceled = 'API_CANCELED';
  static const String kApiConnectionTimeout = 'CONNECT_TIMEOUT';
  static const String kApiDefault = 'DEFAULT';
  static const String kApiReceiveTimeout = 'RECEIVE_TIMEOUT';
  static const String kApiSendTimeout = 'SEND_TIMEOUT';
  static const String kApiResponseError = 'RESPONSE_ERROR';
  static const String kApiDataConflict = 'DATA_CONFLICT';

  // Common masked error messages
  static const String kErrorMessageConnectionTimeout = 'Connection timed out';
  static const String kErrorMessageNetworkError = 'Network error';
  static const String kErrorMessageGenericError = 'Something went wrong';

  // HandshakeException
  static const String kApiAuthExceptionError = 'AUTH_EXCEPTION';
  static const String kErrorMessageUnAuthorizedException = 'UnAuthorized. Please login again';

// This shall be same as keys in DEFAULT_MODEL_ID, DEFAULT_MODEL_TYPES
  static final List<String> TYPES_OF_MODELS_LIST = [
    'asr',
    'translation',
    'tts',
    'transliteration',
  ];

  // Keys shall be same as values in TYPES_OF_MODELS_LIST
  static final DEFAULT_MODEL_TYPES = {
    TYPES_OF_MODELS_LIST[0]: 'OpenAI,AI4Bharat,batch,stream',
    TYPES_OF_MODELS_LIST[1]: 'AI4Bharat,',
    TYPES_OF_MODELS_LIST[2]: 'AI4Bharat,',
    TYPES_OF_MODELS_LIST[3]: 'AI4Bharat,',
  };

  static final ASR_MODEL_TYPES = [
    'streaming',
    'batch',
  ];

  static const kNativeName = 'native_name';
  static const kEnglishName = 'english_name';
  static const kLanguageCode = 'language_code';
  static const kLanguageCodeList = 'language_code_list';

  static final LANGUAGE_CODE_MAP = {
    kLanguageCodeList: [
      {kNativeName: 'English', kLanguageCode: 'en', kEnglishName: 'English'},
      {kNativeName: 'हिन्दी', kLanguageCode: 'hi', kEnglishName: 'Hindi'},
      {kNativeName: 'मराठी', kLanguageCode: 'mr', kEnglishName: 'Marathi'},
      {kNativeName: 'বাংলা', kLanguageCode: 'bn', kEnglishName: 'Bangla'},
      {kNativeName: 'ਪੰਜਾਬੀ', kLanguageCode: 'pa', kEnglishName: 'Punjabi'},
      {kNativeName: 'ગુજરાતી', kLanguageCode: 'gu', kEnglishName: 'Gujarati'},
      {kNativeName: 'ଓଡିଆ', kLanguageCode: 'or', kEnglishName: 'Oriya'},
      {kNativeName: 'தமிழ்', kLanguageCode: 'ta', kEnglishName: 'Tamil'},
      {kNativeName: 'తెలుగు', kLanguageCode: 'te', kEnglishName: 'Telugu'},
      {kNativeName: 'ಕನ್ನಡ', kLanguageCode: 'kn', kEnglishName: 'Kannada'},
      {kNativeName: 'اردو', kLanguageCode: 'ur', kEnglishName: 'Urdu'},
      {kNativeName: 'डोगरी', kLanguageCode: 'doi', kEnglishName: 'Dogri'},
      {kNativeName: 'नेपाली', kLanguageCode: 'ne', kEnglishName: 'Nepali'},
      {kNativeName: 'සිංහල', kLanguageCode: 'si', kEnglishName: 'Sinhala'},
      {kNativeName: 'संस्कृत', kLanguageCode: 'sa', kEnglishName: 'Sanskrit'},
      {kNativeName: 'অসমীয়া', kLanguageCode: 'as', kEnglishName: 'Assamese'},
      {kNativeName: 'मैथिली', kLanguageCode: 'mai', kEnglishName: 'Maithili'},
      {kNativeName: 'भोजपुरी', kLanguageCode: 'bho', kEnglishName: 'Bhojpuri'},
      {kNativeName: 'മലയാളം', kLanguageCode: 'ml', kEnglishName: 'Malayalam'},
      {kNativeName: 'राजस्थानी', kLanguageCode: 'raj', kEnglishName: 'Rajasthani'},
      {kNativeName: 'Bodo', kLanguageCode: 'brx', kEnglishName: 'Bodo'},
      {kNativeName: 'মানিপুরি', kLanguageCode: 'mni', kEnglishName: 'Manipuri'},
    ]
  };

  static String getLanguageCodeOrName(
      {required String value, required LanguageMap returnWhat, required Map<String, List<Map<String, String>>> lang_code_map}) {
    // If Language Code is to be returned that means the value received is a language name
    try {
      switch (returnWhat) {
        case LanguageMap.nativeName:
          var returningLangPair = lang_code_map[kLanguageCodeList]!
              .firstWhere((eachLanguageCodeNamePair) => eachLanguageCodeNamePair[kLanguageCode]!.toLowerCase() == value.toLowerCase());
          return returningLangPair[kNativeName] ?? 'No Language Name Found';

        case LanguageMap.englishName:
          var returningLangPair = lang_code_map[kLanguageCodeList]!
              .firstWhere((eachLanguageCodeNamePair) => eachLanguageCodeNamePair[kNativeName]!.toLowerCase() == value.toLowerCase());
          return returningLangPair[kEnglishName] ?? 'No Language Name Found';

        case LanguageMap.languageCode:
          var returningLangPair = lang_code_map[kLanguageCodeList]!
              .firstWhere((eachLanguageCodeNamePair) => eachLanguageCodeNamePair[kNativeName]!.toLowerCase() == value.toLowerCase());
          return returningLangPair[kLanguageCode] ?? 'No Language Code Found';
      }
    } catch (e) {
      return 'No Language Found';
    }
  }
}
