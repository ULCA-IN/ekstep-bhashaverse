import 'package:get/get.dart';

class FeedbackController extends GetxController {
  RxBool getDetailedFeedback = false.obs,
      showSpeechToTextEditor = false.obs,
      showTranslationEditor = false.obs;

  RxDouble ovarralFeedback = 0.0.obs;
}
