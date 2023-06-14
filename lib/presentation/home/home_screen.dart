import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../animation/lottie_animation.dart';
import '../../common/widgets/bhashini_title.dart';
import '../../localization/localization_keys.dart';
import '../../models/home_menu_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/theme/app_theme_provider.dart';
import 'controller/home_controller.dart';
import 'widgets/menu_item_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final HomeController _homeController;

// uncomment pending menus for demonstration purpose
  final List<HomeMenuModel> menuItems = [
    HomeMenuModel(name: text.tr, imagePath: imgText, isDisabled: false),
    HomeMenuModel(
        name: converse.tr, imagePath: imgVoiceSpeaking, isDisabled: false),
    HomeMenuModel(name: voice.tr, imagePath: imgMic, isDisabled: false),
    // HomeMenuModel(name: video.tr, imagePath: imgVideo, isDisabled: true),
    // HomeMenuModel(
    //     name: documents.tr, imagePath: imgDocuments, isDisabled: true),
    // HomeMenuModel(name: images.tr, imagePath: imgImages, isDisabled: true),
  ];

  @override
  void initState() {
    _homeController = Get.find();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
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
      backgroundColor: context.appTheme.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0).w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 16.h,
                  ),
                  Stack(
                    children: [
                      const Center(
                        child: BhashiniTitle(),
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.settingsRoute),
                          child: SvgPicture.asset(
                            iconSettings,
                            color: context.appTheme.primaryTextColor,
                            width: 26,
                            height: 26,
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 38.h,
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount:
                          MediaQuery.of(context).size.shortestSide > 600
                              ? 3
                              : 2,
                      crossAxisSpacing: 30,
                      mainAxisSpacing: 30,
                      shrinkWrap: true,
                      children: List.generate(menuItems.length, (index) {
                        return MenuItem(
                          title: menuItems[index].name,
                          image: menuItems[index].imagePath,
                          isDisabled: menuItems[index].isDisabled,
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
            if (_homeController.isMainConfigCallLoading.value ||
                _homeController.isTransConfigCallLoading.value) {
              return LottieAnimation(
                  context: context,
                  lottieAsset: animationLoadingLine,
                  footerText: _homeController.isMainConfigCallLoading.value ||
                          _homeController.isTransConfigCallLoading.value
                      ? kHomeLoadingAnimationText.tr
                      : kTranslationLoadingAnimationText.tr);
            } else {
              return const SizedBox.shrink();
            }
          })
        ],
      ),
    );
  }

  _handleMenuTap(int index) {
    switch (index) {
      case 0:
        Get.toNamed(AppRoutes.textTranslationRoute);
        break;
      case 1:
        Get.toNamed(AppRoutes.conversationRoute);
        break;
      case 2:
        Get.toNamed(AppRoutes.voiceTextTranslationRoute);
        break;
      default:
        showDefaultSnackbar(
            message: '${menuItems[index].name} not available currently');
        break;
    }
  }
}
