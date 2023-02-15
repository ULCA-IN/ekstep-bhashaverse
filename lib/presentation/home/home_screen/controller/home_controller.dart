import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../../common/controller/language_model_controller.dart';
import '../../../../services/translation_app_api_client.dart';
import '../../../../utils/constants/api_constants.dart';
import '../../../../utils/constants/app_constants.dart';
import '../../../../utils/snackbar_utils.dart';

class HomeController extends GetxController {
  RxInt bottomBarIndex = 0.obs;
  RxBool isModelsLoading = false.obs, isKeyboardVisible = false.obs;

  late TranslationAppAPIClient _translationAppAPIClient;
  late LanguageModelController _languageModelController;

  late final Box _hiveDBInstance;

  @override
  void onInit() {
    _translationAppAPIClient = Get.find();
    _languageModelController = Get.find();
    _hiveDBInstance = Hive.box(hiveDBName);

    super.onInit();
  }

  void calcAvailableSourceAndTargetLanguages() async {
    isModelsLoading.value = true;
    List<dynamic> taskPayloads = [];
    for (String eachModelType in APIConstants.TYPES_OF_MODELS_LIST) {
      taskPayloads.add({
        "task": eachModelType,
        "sourceLanguage": "",
        "targetLanguage": "",
        "domain": "All",
        "submitter": "All",
        "userId": null
      });
    }

    var allModelResponse =
        await _translationAppAPIClient.getAllModels(taskPayloads: taskPayloads);
    allModelResponse.when(
      success: ((data) {
        _languageModelController.calcAvailableSourceAndTargetLanguages(
          allModelList: data,
          isStreamingPreferred: _hiveDBInstance.get(isStreamingPreferred),
        );
        isModelsLoading.value = false;
      }),
      failure: (error) {
        isModelsLoading.value = false;
        showDefaultSnackbar(
            message: error.message ?? APIConstants.kErrorMessageGenericError);
      },
    );
  }
}
