import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../common/widgets/elevated_button.dart';
import '../../localization/localization_keys.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/remove_glow_effect.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/theme/app_text_style.dart';
import 'controller/onboarding_controller.dart';
import 'widgets/indicator.dart';
import 'widgets/onboarding_content.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  late OnboardingController _onboardingController;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _onboardingController = Get.put(OnboardingController());
    ScreenUtil().init(allowFontScaling: true);
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _onboardingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppEdgeInsets.instance.all(16),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _headerWidget(),
                SizedBox(height: 33.toHeight),
                _pageViewBuilder(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingController.getOnboardingPageList().length,
                    (index) => IndicatorWidget(
                      currentIndex: _onboardingController.getCurrentPageIndex(),
                      indicatorIndex: index,
                    ),
                  ),
                ),
                SizedBox(height: 32.toHeight),
                CustomElevetedButton(
                  buttonText: (_onboardingController.getCurrentPageIndex() ==
                          _onboardingController.getOnboardingPageList().length -
                              1)
                      ? getStarted.tr
                      : next.tr,
                  textStyle: AppTextStyle()
                      .semibold24BalticSea
                      .copyWith(fontSize: 18.toFont),
                  backgroundColor: primaryColor,
                  borderRadius: 16,
                  onButtonTap: (_onboardingController.getCurrentPageIndex() ==
                          _onboardingController.getOnboardingPageList().length -
                              1)
                      ? () => Get.offNamed(AppRoutes.voiceAssistantRoute)
                      : () {
                          _pageController?.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut);
                        },
                ),
                SizedBox(height: 48.toHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerWidget() {
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
            padding: AppEdgeInsets.instance.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(width: 1.toWidth, color: goastWhite),
            ),
            child: SvgPicture.asset(
              iconPrevious,
            ),
          ),
        ),
        const Spacer(),
        Visibility(
          visible: (_onboardingController.getCurrentPageIndex() ==
                  _onboardingController.getOnboardingPageList().length - 1)
              ? false
              : true,
          child: InkWell(
            onTap: () => Get.offNamed(AppRoutes.voiceAssistantRoute),
            child: Text(
              skip.tr,
              style: AppTextStyle().light16BalticSea.copyWith(
                    color: japaneseLaurel,
                  ),
            ),
          ),
        ),
        SizedBox(width: 4.toWidth),
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
          itemCount: _onboardingController.getOnboardingPageList().length,
          itemBuilder: (context, index) {
            return OnBoardingContentWidget(
                imagePath: _onboardingController
                        .getOnboardingPageList()[index]
                        .imagePath ??
                    '',
                headerText: _onboardingController
                        .getOnboardingPageList()[index]
                        .headerText ??
                    '',
                bodyText: _onboardingController
                        .getOnboardingPageList()[index]
                        .bodyText ??
                    '');
          },
        ),
      ),
    );
  }
}
