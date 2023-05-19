import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../services/transliteration_app_api_client.dart';
import '../../../utils/constants/app_constants.dart';
import '../../../common/controller/language_model_controller.dart';

class FeedbackController extends GetxController {
  RxBool getDetailedFeedback = false.obs,
      showSpeechToTextEditor = false.obs,
      showTranslationEditor = false.obs;

  RxDouble ovarralFeedback = 0.0.obs;
  String transliterationModelToUse = '', oldSourceText = '';

  late TransliterationAppAPIClient _translationAppAPIClient;
  // late DHRUVAAPIClient _dhruvaapiClient;
  late LanguageModelController _languageModelController;
  final transliterationHints = RxList([]);
  late final Box _hiveDBInstance;

  @override
  void onInit() {
    _translationAppAPIClient = Get.find();
    _languageModelController = Get.find();
    // _dhruvaapiClient = DHRUVAAPIClient.getAPIClientInstance();
    // transliterationHints.value = [];
    _hiveDBInstance = Hive.box(hiveDBName);
    super.onInit();
  }

  bool isTransliterationEnabled() {
    return _hiveDBInstance.get(enableTransliteration, defaultValue: true);
  }

  Future<List<String>> getTransliterationOutput(String sourceText) async {
    // currentlyTypedWordForTransliteration = sourceText;
    String? appLanguageCode = Get.locale?.languageCode;
    if (appLanguageCode == null || appLanguageCode == 'en') {
      return [];
    }
    transliterationModelToUse = _languageModelController
            .getAvailableTransliterationModelsForLanguage(appLanguageCode) ??
        '';
    if (transliterationModelToUse.isEmpty) {
      // clearTransliterationHints();
      return [];
    }
    var transliterationPayloadToSend = {};
    transliterationPayloadToSend['input'] = [
      {'source': sourceText}
    ];

    transliterationPayloadToSend['modelId'] = transliterationModelToUse;
    transliterationPayloadToSend['task'] = 'transliteration';
    transliterationPayloadToSend['userId'] = null;

    var response = await _translationAppAPIClient.sendTransliterationRequest(
        transliterationPayload: transliterationPayloadToSend);

    response?.when(
      success: (data) async {
        transliterationHints.value = [];
        transliterationHints.assignAll(data['output'][0]['target']);
        return transliterationHints;
      },
      failure: (_) {
        return [];
      },
    );
    return [];
  }
}
