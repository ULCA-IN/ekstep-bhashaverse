import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../animation/lottie_animation.dart';
import '../../common/widgets/bhashini_title.dart';
import '../../models/home_menu_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/theme/app_theme_provider.dart';
import 'controller/home_controller.dart';
import 'widgets/menu_item_widget.dart';
import '../../i18n/strings.g.dart' as i18n;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _homeController;
  final List<HomeMenuModel> menuItems = [];

  @override
  void initState() {
    _homeController = Get.find();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    menuItems.clear();
    menuItems.addAll([
      HomeMenuModel(
          name: i18n.Translations.of(context).text,
          imagePath: imgText,
          isDisabled: false),
      HomeMenuModel(
          name: i18n.Translations.of(context).converse,
          imagePath: imgVoiceSpeaking,
          isDisabled: false),
      HomeMenuModel(
          name: i18n.Translations.of(context).voice,
          imagePath: imgMic,
          isDisabled: false),
      // HomeMenuModel(name: video, preCachedImage: Image.asset(imgVideo), isDisabled: true),
      // HomeMenuModel(
      //     name: documents, preCachedImage: Image.asset(imgDocuments), isDisabled: true),
      // HomeMenuModel(name: images, preCachedImage: Image.asset(imgImages), isDisabled: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final translation = i18n.Translations.of(context);
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
                            width: 0.037.sh,
                            height: 0.037.sh,
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
                          image: Image.asset(menuItems[index].imagePath),
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
                      ? translation.kHomeLoadingAnimationText
                      : translation.kTranslationLoadingAnimationText);
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
    }
  }
}
