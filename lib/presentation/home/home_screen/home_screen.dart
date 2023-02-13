import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../animation/lottie_animation.dart';
import '../../../localization/localization_keys.dart';
import '../widgets/custom_bottom_bar.dart';
import '../../../utils/constants/app_constants.dart';
import '../../../utils/theme/app_colors.dart';
import '../../home/home_screen/controller/home_controller.dart';
import '../bottom_nav_screens/bottom_nav_translation/controller/bottom_nav_translation_controller.dart';
import '../bottom_nav_screens/bottom_nav_settings/bottom_nav_settings.dart';
import '../bottom_nav_screens/bottom_nav_translation/bottom_nav_translation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final HomeController _homeController;
  late BottomNavTranslationController _bottomNavTranslationController;

  @override
  void initState() {
    _homeController = Get.find();
    _bottomNavTranslationController = Get.find();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _homeController.calcAvailableSourceAndTargetLanguages();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != _homeController.isKeyboardVisible.value) {
      _homeController.isKeyboardVisible.value = newValue;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: honeydew,
      body: SafeArea(
        child: Obx(
          () => Stack(
            children: [
              Column(
                children: [
                  Expanded(child: getCurrentBottomWidget(_homeController.bottomBarIndex.value)),
                  _homeController.isKeyboardVisible.value
                      ? const SizedBox.shrink()
                      : CustomBottomBar(
                          currentIndex: _homeController.bottomBarIndex.value,
                          onChanged: (int index) {
                            _homeController.bottomBarIndex.value = index;
                          },
                        )
                ],
              ),
              if (_homeController.isModelsLoading.value || _bottomNavTranslationController.isLsLoading.value)
                LottieAnimation(
                    context: context,
                    lottieAsset: animationLoadingLine,
                    footerText: _homeController.isModelsLoading.value ? kHomeLoadingAnimationText.tr : kTranslationLoadingAnimationText.tr),
            ],
          ),
        ),
      ),
    );
  }

  Widget getCurrentBottomWidget(int index) {
    switch (index) {
      case 0:
        return const BottomNavTranslation();
      // case 1:
      //   return const BottomNavChat();
      case 1:
        return const BottomNavSettings();
      default:
        return const BottomNavTranslation();
    }
  }
}
