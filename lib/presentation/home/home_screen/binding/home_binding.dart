import 'package:get/get.dart';

import '../../bottom_nav_screens/bottom_nav_settings/controller/settings_controller.dart';
import '../../bottom_nav_screens/bottom_nav_translation/controller/bottom_nav_translation_controller.dart';
import '../controller/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => BottomNavTranslationController());
    Get.lazyPut(() => SettingsController());
  }
}
