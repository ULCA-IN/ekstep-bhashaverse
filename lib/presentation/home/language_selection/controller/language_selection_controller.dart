import 'package:get/get.dart';

class LanguageSelectionController extends GetxController {
  final RxList<dynamic> _languagesList = [].obs;
  final _selectedLanguageIndex = Rxn<int>();

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
