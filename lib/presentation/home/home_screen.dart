import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../animation/lottie_animation.dart';
import '../../common/widgets/bhashini_title.dart';
import '../../localization/localization_keys.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/theme/app_colors.dart';
import 'controller/home_controller.dart';
import 'widgets/menu_item_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final HomeController _homeController;

  final List<Map<String, String>> menuItems = [
    {text.tr: imgText},
    {converge.tr: imgVoiceSpeaking},
    {voice.tr: imgMic},
    {video.tr: imgVideo},
    {documents.tr: imgDocuments},
    {images.tr: imgImages},
  ];

  @override
  void initState() {
    _homeController = Get.find();
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    _homeController.isLoading.value = true;
    _homeController.getAvailableLanguagesInTask().then((_) {
      _homeController.getTransliterationModels().then((_) {
        _homeController.isLoading.value = false;
      });
    });
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
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20.toHeight,
                  ),
                  Stack(
                    children: [
                      Center(
                        child: BhashiniTitle(),
                      ),
                      Positioned(
                        right: 0.toWidth,
                        child: GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.settingsRoute),
                          child: SvgPicture.asset(
                            iconSettings,
                            width: 30.toWidth,
                            height: 30.toHeight,
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 60.toHeight,
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 30,
                      mainAxisSpacing: 30,
                      shrinkWrap: true,
                      children: List.generate(menuItems.length, (index) {
                        return MenuItem(
                          title: menuItems[index].keys.first,
                          image: menuItems[index].values.first,
                          isDisabled: index != 1,
                          onTap: () => _handleMenuTap(index),
                        );
                      }),
                    ),
                  )
                ],
              ),
            ),
          ),
          Obx(() {
            if (_homeController.isLoading.value)
              return LottieAnimation(
                  context: context,
                  lottieAsset: animationLoadingLine,
                  footerText: _homeController.isLoading.value
                      ? kHomeLoadingAnimationText.tr
                      : kTranslationLoadingAnimationText.tr);
            else
              return const SizedBox.shrink();
          })
        ],
      ),
    );
  }

  _handleMenuTap(int index) {
    switch (index) {
      case 1:
        Get.toNamed(AppRoutes.textTranslationRoute);
        break;
      default:
        showDefaultSnackbar(
            message: '${menuItems[index].keys.first} not available currently');
        break;
    }
  }
}