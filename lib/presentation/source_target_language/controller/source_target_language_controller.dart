import 'package:get/get.dart';

import '../../../utils/constants/language_map_translated.dart';

class SourceTargetLanguageController extends GetxController {
  final RxList<dynamic> _languagesList = [].obs;
  final _selectedLanguageIndex = Rxn<int>();

  Map<String, String>? selectedLanguageMap = {};

  @override
  void onInit() {
    selectedLanguageMap =
        TranslatedLanguagesMap.language[Get.locale?.languageCode];
    super.onInit();
  }

  List<dynamic> getLanguageList() {
    return _languagesList;
  }

  void setLanguageList(List<dynamic> languageList) {
    _languagesList.clear();
    _languagesList.addAll(languageList);
  }

  int? getSelectedLanguageIndex() {
    return _selectedLanguageIndex.value;
  }

  void setSelectedLanguageIndex(int index) {
    _selectedLanguageIndex.value = index;
  }
}
