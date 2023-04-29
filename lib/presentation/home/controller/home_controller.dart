import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../../../common/controller/language_model_controller.dart';
import '../../../localization/localization_keys.dart';
import '../../../services/dhruva_api_client.dart';
import '../../../services/transliteration_app_api_client.dart';
import '../../../utils/constants/api_constants.dart';
import '../../../utils/network_utils.dart';
import '../../../utils/snackbar_utils.dart';

class HomeController extends GetxController {
  RxBool isLoading = false.obs, isKeyboardVisible = false.obs;

  late DHRUVAAPIClient _dhruvaapiClient;
  late TransliterationAppAPIClient _translationAppAPIClient;
  late LanguageModelController _languageModelController;
  late StreamSubscription<ConnectivityResult> subscription;

  @override
  void onInit() {
    _dhruvaapiClient = Get.find();
    _translationAppAPIClient = Get.find();
    _languageModelController = Get.find();

    isNetworkConnected().then((isConnected) {
      if (isConnected) {
        fetchConfigData();
      } else {
        showDefaultSnackbar(message: errorNoInternetTitle.tr);
      }
      listenNetworkChange();
    });

    super.onInit();
  }

  @override
  void onClose() {
    subscription.cancel();
    super.onClose();
  }

  void fetchConfigData() {
    isLoading.value = true;
    getAvailableLanguagesInTask().then((_) {
      getTransliterationModels().then((_) {
        isLoading.value = false;
      });
    });
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

    var transliterationResponse = await _translationAppAPIClient
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

  void listenNetworkChange() {
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none &&
          result != ConnectivityResult.vpn) {
        if (_languageModelController.sourceTargetLanguageMap.isEmpty &&
            !isLoading.value) {
          fetchConfigData();
        }
      }
    });
  }
}
