import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../common/controller/language_model_controller.dart';
import '../../../models/task_sequence_response_model.dart';
import '../../../services/dhruva_api_client.dart';
import '../../../utils/constants/api_constants.dart';
import '../../../utils/constants/app_constants.dart';
import '../../../utils/network_utils.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../i18n/strings.g.dart' as i18n;

class HomeController extends GetxController {
  RxBool isMainConfigCallLoading = false.obs,
      isTransConfigCallLoading = false.obs,
      isTransliterationConfigCallLoading = false.obs;

  late DHRUVAAPIClient _dhruvaapiClient;
  late LanguageModelController _languageModelController;
  StreamSubscription<ConnectivityResult>? subscription;
  late final Box _hiveDBInstance;

  @override
  void onInit() {
    _dhruvaapiClient = Get.find();
    _languageModelController = Get.find();
    _hiveDBInstance = Hive.box(hiveDBName);

    // Get main config call response from cache

    DateTime? configCacheTime = _hiveDBInstance.get(configCacheLastUpdatedKey);
    dynamic taskSequenceResponse = _hiveDBInstance.get(configCacheKey);

    if (configCacheTime != null &&
        taskSequenceResponse != null &&
        configCacheTime.isAfter(DateTime.now())) {
      // load data from cache
      _languageModelController.setTaskSequenceResponse(
          TaskSequenceResponse.fromJson(taskSequenceResponse));
      _languageModelController.populateLanguagePairs();
    } else {
      // clear cache and get new data
      _hiveDBInstance.put(configCacheLastUpdatedKey, null);
      _hiveDBInstance.put(configCacheKey, null);
      isNetworkConnected().then((isConnected) {
        if (isConnected) {
          getAvailableLanguagesInTask();
        } else {
          showDefaultSnackbar(message: i18n.t.errorNoInternetTitle);
        }
      });
      if (subscription == null) listenNetworkChange();
    }

    // Get translation config call response from cache

    DateTime? transConfigCacheTime =
        _hiveDBInstance.get(transConfigCacheLastUpdatedKey);
    dynamic transTaskSequenceResponse =
        _hiveDBInstance.get(transConfigCacheKey);

    if (transConfigCacheTime != null &&
        transTaskSequenceResponse != null &&
        transConfigCacheTime.isAfter(DateTime.now())) {
      // load data from cache
      _languageModelController.setTranslationConfigResponse(
          TaskSequenceResponse.fromJson(transTaskSequenceResponse));
      _languageModelController.populateTranslationLanguagePairs();
    } else {
      // clear cache and get new data
      _hiveDBInstance.put(transConfigCacheLastUpdatedKey, null);
      _hiveDBInstance.put(transConfigCacheKey, null);
      isNetworkConnected().then((isConnected) {
        if (isConnected) {
          getAvailableLangTranslation();
        } else {
          showDefaultSnackbar(message: i18n.t.errorNoInternetTitle);
        }
      });
      if (subscription == null) listenNetworkChange();
    }

    // Get transliteration config call response from cache

    DateTime? transliterationConfigCacheTime =
        _hiveDBInstance.get(transliterationConfigCacheLastUpdatedKey);
    dynamic transliterationTaskSequenceResponse =
        _hiveDBInstance.get(transliterationConfigCacheKey);

    if (transliterationConfigCacheTime != null &&
        transliterationTaskSequenceResponse != null &&
        transliterationConfigCacheTime.isAfter(DateTime.now())) {
      // load data from cache
      _languageModelController.setTransliterationConfigResponse(
          TaskSequenceResponse.fromJson(transliterationTaskSequenceResponse));
    } else {
      // clear cache and get new data
      _hiveDBInstance.put(transliterationConfigCacheLastUpdatedKey, null);
      _hiveDBInstance.put(transliterationConfigCacheKey, null);
      isNetworkConnected().then((isConnected) {
        if (isConnected) {
          getTransliterationConfig();
        } else {
          showDefaultSnackbar(message: i18n.t.errorNoInternetTitle);
        }
      });
      if (subscription == null) listenNetworkChange();
    }

    super.onInit();
  }

  @override
  void onClose() {
    subscription?.cancel();
    super.onClose();
  }

  Future<void> getAvailableLanguagesInTask() async {
    isMainConfigCallLoading.value = true;
    var languageRequestResponse = await _dhruvaapiClient.getTaskSequence(
        requestPayload: APIConstants.payloadForLanguageConfig);
    languageRequestResponse.when(
      success: ((TaskSequenceResponse taskSequenceResponse) async {
        _languageModelController.setTaskSequenceResponse(taskSequenceResponse);
        await addMainConfigResponseInCache(taskSequenceResponse.toJson());
        _languageModelController.populateLanguagePairs();
        isMainConfigCallLoading.value = false;
      }),
      failure: (error) {
        isMainConfigCallLoading.value = false;
        showDefaultSnackbar(message: i18n.t.somethingWentWrong);
      },
    );
  }

  Future<void> getAvailableLangTranslation() async {
    isTransConfigCallLoading.value = true;
    Map<String, dynamic> transPayload =
        json.decode(json.encode(APIConstants.payloadForLanguageConfig));

    (transPayload[APIConstants.kPipelineTasks]).removeWhere((element) =>
        element[APIConstants.kTaskType] != APIConstants.kTranslation);
    var languageRequestResponse =
        await _dhruvaapiClient.getTaskSequence(requestPayload: transPayload);
    languageRequestResponse.when(
      success: ((TaskSequenceResponse taskSequenceResponse) async {
        _languageModelController
            .setTranslationConfigResponse(taskSequenceResponse);
        await addTransConfigResponseInCache(taskSequenceResponse.toJson());
        _languageModelController.populateTranslationLanguagePairs();
        isTransConfigCallLoading.value = false;
      }),
      failure: (error) {
        isTransConfigCallLoading.value = false;
        showDefaultSnackbar(message: i18n.t.somethingWentWrong);
      },
    );
  }

  Future<void> getTransliterationConfig() async {
    isTransliterationConfigCallLoading.value = true;
    Map<String, dynamic> transliterationPayload =
        json.decode(json.encode(APIConstants.payloadForTransliterationConfig));

    var transliterationResponse = await _dhruvaapiClient.getTaskSequence(
        requestPayload: transliterationPayload);
    transliterationResponse.when(
      success: ((TaskSequenceResponse taskSequenceResponse) async {
        _languageModelController
            .setTransliterationConfigResponse(taskSequenceResponse);
        await addTransliterationConfigResponseInCache(
            taskSequenceResponse.toJson());
        isTransliterationConfigCallLoading.value = false;
      }),
      failure: (error) {
        isTransliterationConfigCallLoading.value = false;
        showDefaultSnackbar(message: i18n.t.somethingWentWrong);
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
            !isMainConfigCallLoading.value) {
          getAvailableLanguagesInTask();
        }

        if (_languageModelController.translationLanguageMap.isEmpty &&
            !isTransConfigCallLoading.value) {
          getAvailableLangTranslation();
        }

        if (_languageModelController.transliterationConfigResponse == null &&
            !isTransliterationConfigCallLoading.value) {
          getTransliterationConfig();
        }
      }
    });
  }

  Future<void> addMainConfigResponseInCache(responseData) async {
    await _hiveDBInstance.put(configCacheKey, responseData);
    await _hiveDBInstance.put(
      configCacheLastUpdatedKey,
      DateTime.now().add(
        const Duration(days: 1),
      ),
    );
  }

  Future<void> addTransConfigResponseInCache(responseData) async {
    await _hiveDBInstance.put(transConfigCacheKey, responseData);
    await _hiveDBInstance.put(
      transConfigCacheLastUpdatedKey,
      DateTime.now().add(
        const Duration(days: 1),
      ),
    );
  }

  Future<void> addTransliterationConfigResponseInCache(responseData) async {
    await _hiveDBInstance.put(transliterationConfigCacheKey, responseData);
    await _hiveDBInstance.put(
      transliterationConfigCacheLastUpdatedKey,
      DateTime.now().add(
        const Duration(days: 1),
      ),
    );
  }
}
