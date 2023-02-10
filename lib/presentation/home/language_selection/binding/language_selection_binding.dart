import 'package:get/get.dart';

import '../controller/language_selection_controller.dart';

class LanguageSelectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LanguageSelectionController());
  }
}
