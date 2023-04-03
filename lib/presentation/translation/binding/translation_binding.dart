import 'package:get/get.dart';

import '../controller/translation_controller.dart';

class TranslationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TranslationController());
  }
}
