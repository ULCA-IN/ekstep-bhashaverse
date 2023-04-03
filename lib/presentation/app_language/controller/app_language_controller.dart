import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../utils/constants/api_constants.dart';
import '../../../utils/constants/app_constants.dart';

class AppLanguageController extends GetxController {
  final _selectedLanguageIndex = Rxn<int>();
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
    return _selectedLanguageIndex.value;
  }

  void setSelectedLanguageIndex(int? index) {
    _selectedLanguageIndex.value = index;
  }

  String getSelectedLanguageCode() {
    return getAppLanguageList()[getSelectedLanguageIndex() ?? 0]
        [APIConstants.kLanguageCode];
  }

  void saveSelectedLocaleInDB() {
    _hiveDBInstance.put(preferredAppLocale, getSelectedLanguageCode());
  }

  void _setAllLanguageList() {
    _languageList.clear();
    for (var i = 0;
        i <
            APIConstants
                .LANGUAGE_CODE_MAP[APIConstants.kLanguageCodeList]!.length;
        i++) {
      var language =
          APIConstants.LANGUAGE_CODE_MAP[APIConstants.kLanguageCodeList]![i];
      _languageList.add(language);
      if (language[APIConstants.kLanguageCode] == Get.locale?.languageCode) {
        setSelectedLanguageIndex(i);
      }
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
