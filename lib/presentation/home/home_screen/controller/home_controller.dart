import 'package:get/get.dart';

import '../../../../common/controller/language_model_controller.dart';
import '../../../../services/dhruva_api_client.dart';
import '../../../../services/transliteration_app_api_client.dart';
import '../../../../utils/constants/api_constants.dart';
import '../../../../utils/snackbar_utils.dart';

class HomeController extends GetxController {
  RxInt bottomBarIndex = 0.obs;
  RxBool isLoading = false.obs, isKeyboardVisible = false.obs;

  late DHRUVAAPIClient _dhruvaapiClient;
  late TransliterationAppAPIClient _transliterationAppAPIClient;
  late LanguageModelController _languageModelController;

  @override
  void onInit() {
    _dhruvaapiClient = Get.find();
    _transliterationAppAPIClient = Get.find();
    _languageModelController = Get.find();

    super.onInit();
  }

  Future<void> getAvailableLanguagesInTask() async {
    var languageRequestResponse = await _dhruvaapiClient.getTaskSequence(
        requestPayload: APIConstants.payloadForLanguageConfig);
    languageRequestResponse.when(
      success: ((taskSequenceResponse) {
        _languageModelController.setTaskSequenceResponse(taskSequenceResponse);
        _languageModelController.populateLanguagePairs();
      }),
      failure: (error) {
        showDefaultSnackbar(
            message: error.message ?? APIConstants.kErrorMessageGenericError);
      },
    );
  }

  Future<void> getTransliterationModels() async {
    Map<String, dynamic> taskPayloads = {
      "task": APIConstants.TYPES_OF_MODELS_LIST[3],
      "sourceLanguage": "",
      "targetLanguage": "",
      "domain": "All",
      "submitter": "All",
      "userId": null
    };

    var transliterationResponse = await _transliterationAppAPIClient
        .getTransliterationModels(taskPayloads: taskPayloads);
    transliterationResponse.when(
      success: ((data) {
        _languageModelController.calcAvailableTransliterationModels(
            transliterationModel: data);
      }),
      failure: (error) {
        showDefaultSnackbar(
            message: error.message ?? APIConstants.kErrorMessageGenericError);
      },
    );
  }
}
