import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/widgets/custom_elevated_button.dart';
import '../../models/onboarding_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/remove_glow_effect.dart';
import '../../utils/theme/app_theme_provider.dart';
import '../../utils/theme/app_text_style.dart';
import 'controller/onboarding_controller.dart';
import 'widgets/indicator.dart';
import 'widgets/onboarding_content.dart';
import '../../i18n/strings.g.dart' as i18n;

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  late OnboardingController _onboardingController;
  PageController? _pageController;
  final List<OnboardingModel> onboardingPages = [];

  @override
  void initState() {
    super.initState();
    _onboardingController = Get.put(OnboardingController());
    _pageController = PageController(initialPage: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onboardingPages.addAll([
      OnboardingModel(
        imagePath: imgOnboarding1,
        headerText: i18n.Translations.of(context).speechRecognition,
        bodyText:
            i18n.Translations.of(context).automaticallyRecognizeAndConvert,
      ),
      OnboardingModel(
        imagePath: imgOnboarding2,
        headerText: i18n.Translations.of(context).speechToSpeechTranslation,
        bodyText:
            i18n.Translations.of(context).translateYourVoiceInOneIndianLanguage,
      ),
      OnboardingModel(
        imagePath: imgOnboarding3,
        headerText: i18n.Translations.of(context).languageTranslation,
        bodyText: i18n.Translations.of(context)
            .translateSentencesFromOneIndianLanguageToAnother,
      ),
      // TODO: uncomment after chat feature added
      // OnboardingModel(
      //   image: Image.asset(
      //     imgOnboarding4,
      //     fit: BoxFit.fitWidth,
      //   ),
      //   headerText: bhashaverseChatBot.tr,
      //   bodyText: translateSentencesFromOneIndianLanguageToAnother.tr,
      // )
    ]);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _onboardingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translation = i18n.Translations.of(context);
    return Scaffold(
      backgroundColor: context.appTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16).w,
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _headerWidget(context),
                SizedBox(height: 16.h),
                _pageViewBuilder(),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingPages.length,
                    (index) => IndicatorWidget(
                      currentIndex: _onboardingController.getCurrentPageIndex(),
                      indicatorIndex: index,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                CustomElevatedButton(
                  buttonText: (_onboardingController.getCurrentPageIndex() ==
                          onboardingPages.length - 1)
                      ? translation.getStarted
                      : translation.next,
                  backgroundColor: context.appTheme.primaryColor,
                  borderRadius: 16,
                  onButtonTap: (_onboardingController.getCurrentPageIndex() ==
                          onboardingPages.length - 1)
                      ? () => Get.offNamed(AppRoutes.voiceAssistantRoute)
                      : () {
                          _pageController?.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut);
                        },
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerWidget(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: (_onboardingController.getCurrentPageIndex() == 0)
              ? () => Get.back()
              : () {
                  _pageController?.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut);
                },
          child: Container(
            padding: const EdgeInsets.all(8).w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  width: 1.w, color: context.appTheme.containerColor),
            ),
            child: SvgPicture.asset(
              iconPrevious,
            ),
          ),
        ),
        const Spacer(),
        Visibility(
          visible: (_onboardingController.getCurrentPageIndex() ==
                  onboardingPages.length - 1)
              ? false
              : true,
          child: InkWell(
            onTap: () => Get.offNamed(AppRoutes.voiceAssistantRoute),
            child: Text(
              i18n.Translations.of(context).skip,
              style: regular14(context).copyWith(
                color: context.appTheme.highlightedBGColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pageViewBuilder() {
    return Expanded(
      child: ScrollConfiguration(
        behavior: RemoveScrollingGlowEffect(),
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.horizontal,
          onPageChanged: (index) {
            _onboardingController.setCurrentPageIndex(index);
          },
          itemCount: onboardingPages.length,
          itemBuilder: (context, index) {
            return OnBoardingContentWidget(
                image: Image.asset(
                  onboardingPages[index].imagePath,
                  fit: BoxFit.fitWidth,
                ),
                headerText: onboardingPages[index].headerText,
                bodyText: onboardingPages[index].bodyText);
          },
        ),
      ),
    );
  }
}
