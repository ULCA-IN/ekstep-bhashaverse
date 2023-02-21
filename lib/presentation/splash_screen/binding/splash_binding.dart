import 'package:get/get.dart';

import '../../../common/controller/language_model_controller.dart';
import '../../../services/socket_io_client.dart';
import '../../../services/translation_app_api_client.dart';
import '../controller/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(TranslationAppAPIClient.getAPIClientInstance(), permanent: true);
    Get.put(LanguageModelController());
    Get.put(SocketIOClient());
    Get.put(SplashController());
  }
}
