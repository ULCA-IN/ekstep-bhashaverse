import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../../../common/controller/language_model_controller.dart';
import '../../../../../enums/gender_enum.dart';
import '../../../../../enums/language_enum.dart';
import '../../../../../utils/constants/api_constants.dart';
import '../../../../../utils/constants/app_constants.dart';

class SettingsController extends GetxController {
  RxBool isTransLiterationEnabled = true.obs;
  RxBool isStreamingEnabled = true.obs;
  RxString preferredLanguage = ''.obs;

  Rx<GenderEnum> preferredVoiceAssistant = (GenderEnum.male).obs;
  Rx<ThemeMode> selectedThemeMode = (ThemeMode.light).obs;
  RxBool isAdvanceMenuOpened = false.obs;

  late final Box _hiveDBInstance;

  @override
  void onInit() {
    _hiveDBInstance = Hive.box(hiveDBName);

    isTransLiterationEnabled.value = _hiveDBInstance.get(enableTransliteration);
    isStreamingEnabled.value = _hiveDBInstance.get(isStreamingPreferred);
    preferredVoiceAssistant.value = GenderEnum.values
        .byName(_hiveDBInstance.get(preferredVoiceAssistantGender));
    getPreferredLanguage();
    super.onInit();
  }

  void getPreferredLanguage() {
    preferredLanguage.value = APIConstants.getLanguageCodeOrName(
        value: _hiveDBInstance.get(preferredAppLocale, defaultValue: 'en'),
        returnWhat: LanguageMap.nativeName,
        lang_code_map: APIConstants.LANGUAGE_CODE_MAP);
  }

  void changeVoiceAssistantPref(GenderEnum updatedVoiceAssistant) {
    _hiveDBInstance.put(
        preferredVoiceAssistantGender, updatedVoiceAssistant.name);
    preferredVoiceAssistant.value =
        GenderEnum.values.byName(updatedVoiceAssistant.name);
  }

  void changeTransliterationPref(bool isEnabled) {
    _hiveDBInstance.put(enableTransliteration, isEnabled);
    isTransLiterationEnabled.value = isEnabled;
  }

  void changeStreamingPref(bool isEnabled) {
    _hiveDBInstance.put(isStreamingPreferred, isEnabled);
    isStreamingEnabled.value = isEnabled;
    LanguageModelController languageModelController = Get.find();
    languageModelController.calcAvailableSourceAndTargetLanguages(
        isStreamingPreferred: isEnabled);
  }
}
