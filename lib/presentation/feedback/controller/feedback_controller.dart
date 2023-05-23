import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../models/feedback_type_model.dart';
import '../../../services/dhruva_api_client.dart';
import '../../../services/transliteration_app_api_client.dart';
import '../../../utils/constants/api_constants.dart';
import '../../../utils/constants/app_constants.dart';
import '../../../common/controller/language_model_controller.dart';
import '../../../utils/snackbar_utils.dart';

class FeedbackController extends GetxController {
  RxBool getDetailedFeedback = false.obs,
      showSpeechToTextEditor = false.obs,
      showTranslationEditor = false.obs;

  RxDouble ovarralFeedback = 0.0.obs;
  RxList<Rx<FeedbackTypeModel>> feedbackTypeModels = RxList([]);
  RxBool isLoading = false.obs;
  String transliterationModelToUse = '', oldSourceText = '';
  dynamic feedbackReqResponse;

  late TransliterationAppAPIClient _translationAppAPIClient;
  late DHRUVAAPIClient _dhruvaapiClient;
  late LanguageModelController _languageModelController;
  final transliterationHints = RxList([]);
  late final Box _hiveDBInstance;

  @override
  void onInit() {
    _translationAppAPIClient = Get.find();
    _languageModelController = Get.find();
    _dhruvaapiClient = DHRUVAAPIClient.getAPIClientInstance();
    _hiveDBInstance = Hive.box(hiveDBName);
    super.onInit();
  }

  @override
  void onClose() {
    feedbackTypeModels.clear();
    transliterationHints.clear();
    super.onClose();
  }

  bool isTransliterationEnabled() {
    return _hiveDBInstance.get(enableTransliteration, defaultValue: true);
  }

  Future<List<String>> getTransliterationOutput(String sourceText) async {
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

  Future<void> getFeedbackPipelines() async {
    isLoading.value = true;
    Map<String, dynamic> requestConfig = {
      "feedbackLanguage": "en",
      "supportedTasks": ["asr", "translation", "tts"]
    };
    var languageRequestResponse = await _dhruvaapiClient.sendFeedbackRequest(
        requestPayload: requestConfig);
    languageRequestResponse.when(
      success: ((dynamic response) async {
        feedbackReqResponse = response;
        if (response['taskFeedback'] != null &&
            response['taskFeedback'] is List) {
          for (var taskFeedback in response['taskFeedback']) {
            List<GranularFeedback> granularFeedbacks = [];
            if (taskFeedback['granularFeedback'] != null &&
                taskFeedback['granularFeedback'].isNotEmpty) {
              for (var granularFeedback in taskFeedback['granularFeedback']) {
                granularFeedbacks.add(GranularFeedback(
                  question: granularFeedback['question'],
                  mainRating: 0,
                  supportedFeedbackTypes:
                      granularFeedback['supportedFeedbackTypes'],
                  parameters: granularFeedback['parameters'] != null
                      ? granularFeedback['parameters']
                          .map((parameter) =>
                              Parameter(paramName: parameter, paramRating: 0))
                          .toList()
                      : [],
                ));
              }
            }
            feedbackTypeModels.add(FeedbackTypeModel(
                    taskType: taskFeedback['taskType'],
                    question: taskFeedback['commonFeedback'].length > 0
                        ? taskFeedback['commonFeedback'][0]['question']
                        : '',
                    textController: TextEditingController(),
                    focusNode: FocusNode(),
                    taskRating: 0.0.obs,
                    granularFeedbacks: granularFeedbacks)
                .obs);
          }
        }
        isLoading.value = false;
      }),
      failure: (error) {
        showDefaultSnackbar(
            message: error.message ?? APIConstants.kErrorMessageGenericError);
        isLoading.value = false;
      },
    );
  }
}
