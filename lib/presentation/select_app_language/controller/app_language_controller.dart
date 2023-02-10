import 'dart:ui';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../utils/constants/api_constants.dart';
import '../../../utils/constants/app_constants.dart';

class AppLanguageController extends GetxController {
  final _selectedLanguage = Rxn<int>();
  final RxList<Map<String, dynamic>> _languageList =
      <Map<String, dynamic>>[].obs;
  late final Box _hiveDBInstance;

  @override
  void onInit() {
    _hiveDBInstance = Hive.box(hiveDBName);
    super.onInit();
    _setAllLanguageList();
  }

  int? getSelectedLanguageIndex() {
    return _selectedLanguage.value;
  }

  void setSelectedLanguageIndex(int index) {
    _selectedLanguage.value = index;
  }

  void setSelectedAppLocale(String selectedLocale) {
    _hiveDBInstance.put(preferredAppLocale, selectedLocale);
    Get.updateLocale(Locale(selectedLocale));
  }

  void _setAllLanguageList() {
    _languageList.clear();
    for (var language
        in APIConstants.LANGUAGE_CODE_MAP[APIConstants.kLanguageCodeList]!) {
      _languageList.add(language);
    }
  }

  void _setCustomAppLanguageList(
      List<Map<String, dynamic>> customLanguageList) {
    _languageList.clear();
    _languageList.addAll(customLanguageList);
  }

  setAllLanguageList() => _setAllLanguageList();

  setCustomLanguageList(List<Map<String, dynamic>> customLanguageList) =>
      _setCustomAppLanguageList(customLanguageList);

  List<Map<String, dynamic>> getAppLanguageList() => _languageList;
}
