import 'package:get/get.dart';

import '../../../localization/localization_keys.dart';
import '/models/onboarding_model.dart';
import '/utils/constants/app_constants.dart';

class OnboardingController extends GetxController {
  final RxInt _currentPageIndex = 0.obs;

  int getCurrentPageIndex() => _currentPageIndex.value;

  void setCurrentPageIndex(int index) {
    _currentPageIndex.value = index;
  }

  List<OnboardingModel> _onboardingPageList() {
    List<OnboardingModel> pages = <OnboardingModel>[];

    pages.add(OnboardingModel(
      imagePath: imgOnboarding1,
      headerText: speechRecognition.tr,
      bodyText: automaticallyRecognizeAndConvert.tr,
    ));
    pages.add(OnboardingModel(
      imagePath: imgOnboarding2,
      headerText: speechToSpeechTranslation.tr,
      bodyText: translateYourVoiceInOneIndianLanguage.tr,
    ));
    pages.add(OnboardingModel(
      imagePath: imgOnboarding3,
      headerText: languageTranslation.tr,
      bodyText: translateSentencesFromOneIndianLanguageToAnother.tr,
    ));
    pages.add(OnboardingModel(
      imagePath: imgOnboarding4,
      headerText: bhashaverseChatBot.tr,
      bodyText: translateSentencesFromOneIndianLanguageToAnother.tr,
    ));

    return pages;
  }

  List<OnboardingModel> getOnboardingPageList() => _onboardingPageList();
}
