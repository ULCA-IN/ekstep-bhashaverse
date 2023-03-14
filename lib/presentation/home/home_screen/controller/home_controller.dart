import 'package:get/get.dart';

import '../../../../common/controller/language_model_controller.dart';
import '../../../../services/dhruva_api_client.dart';
import '../../../../services/translation_app_api_client.dart';
import '../../../../utils/constants/api_constants.dart';
import '../../../../utils/snackbar_utils.dart';

class HomeController extends GetxController {
  RxInt bottomBarIndex = 0.obs;
  RxBool isLoading = false.obs, isKeyboardVisible = false.obs;

  late DHRUVAAPIClient _dhruvaapiClient;
  late TranslationAppAPIClient _translationAppAPIClient;
  late LanguageModelController _languageModelController;

  @override
  void onInit() {
    _dhruvaapiClient = Get.find();
    _translationAppAPIClient = Get.find();
    _languageModelController = Get.find();

    super.onInit();
  }

  void getTransliterationModels() async {
    Map<String, dynamic> taskPayloads = {
      "task": APIConstants.TYPES_OF_MODELS_LIST[3],
      "sourceLanguage": "",
      "targetLanguage": "",
      "domain": "All",
      "submitter": "All",
      "userId": null
    };

    var transliterationResponse = await _translationAppAPIClient
        .getTransliterationModels(taskPayloads: taskPayloads);
    transliterationResponse.when(
      success: ((data) {
        _languageModelController.calcAvailableTransliterationModels(
            transliterationModel: data);
        isLoading.value = false;
      }),
      failure: (error) {
        isLoading.value = false;
        showDefaultSnackbar(
            message: error.message ?? APIConstants.kErrorMessageGenericError);
      },
    );
  }

  void getAvailableLanguagesInTask() async {
    isLoading.value = true;
    var languageRequestResponse = await _dhruvaapiClient.getTaskSequence(
        requestPayload: APIConstants.payloadForLanguageConfig);
    languageRequestResponse.when(
      success: ((taskSequenceResponse) {
        _languageModelController.setTaskSequenceResponse(taskSequenceResponse);
        _languageModelController.populateLanguagePairs();
        isLoading.value = false;
      }),
      failure: (error) {
        isLoading.value = false;
        showDefaultSnackbar(
            message: error.message ?? APIConstants.kErrorMessageGenericError);
      },
    );
  }
}
