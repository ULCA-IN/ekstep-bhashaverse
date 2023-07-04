import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../i18n/strings.g.dart' as i18n;
import '../../routes/app_routes.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/theme/app_theme_provider.dart';
import '../../utils/theme/app_text_style.dart';
import '../../utils/voice_recorder.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Box _hiveDBInstance;
  bool isIntroShownAlready = false;
  late dynamic translation;

  @override
  void initState() {
    _hiveDBInstance = Hive.box(hiveDBName);
    isIntroShownAlready =
        _hiveDBInstance.get(introShownAlreadyKey, defaultValue: false);
    super.initState();
    Future.delayed(const Duration(seconds: 3)).then((value) {
      Get.offNamed(isIntroShownAlready
          ? AppRoutes.homeRoute
          : AppRoutes.appLanguageRoute);
    });
    VoiceRecorder voiceRecorder = VoiceRecorder();
    voiceRecorder.clearOldRecordings();
  }

  @override
  void didChangeDependencies() {
    // Precache splash screen logo
    precacheImage(Image.asset(imgAppLogoSmall).image, context);

    // Precache home screen menu images
    precacheImage(Image.asset(imgText).image, context);
    precacheImage(Image.asset(imgVoiceSpeaking).image, context);
    precacheImage(Image.asset(imgMic).image, context);
/*     precacheImage(Image.asset(imgVideo).image, context);
    precacheImage(Image.asset(imgDocuments).image, context);
    precacheImage(Image.asset(imgImages).image, context); */

    if (!isIntroShownAlready) {
      // Precache Onboarding screen images
      precacheImage(Image.asset(imgOnboarding1).image, context);
      precacheImage(Image.asset(imgOnboarding2).image, context);
      precacheImage(Image.asset(imgOnboarding3).image, context);
      // precacheImage(Image.asset(imgOnboarding4).image, context);

      // Precache voice assistant screen images
      precacheImage(Image.asset(imgMaleAvatar).image, context);
      precacheImage(Image.asset(imgFemaleAvatar).image, context);
    }
    super.didChangeDependencies();
    translation = i18n.Translations.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appTheme.splashScreenBGColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                imgAppLogoSmall,
                height: 100.h,
                width: 100.w,
              ),
              SizedBox(
                height: 24.h,
              ),
              Text(
                translation.bhashiniTitle,
                textAlign: TextAlign.center,
                style: bold24(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
