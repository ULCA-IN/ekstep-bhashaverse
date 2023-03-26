import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../localization/localization_keys.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_colors.dart';
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

  @override
  void initState() {
    _hiveDBInstance = Hive.box(hiveDBName);
    isIntroShownAlready =
        _hiveDBInstance.get(introShownAlreadyKey, defaultValue: false);
    super.initState();
    ScreenUtil().init();
    Future.delayed(const Duration(seconds: 3)).then((value) {
      Get.offNamed(isIntroShownAlready
          ? AppRoutes.homeRoute
          : AppRoutes.appLanguageRoute);
    });
    VoiceRecorder voiceRecorder = VoiceRecorder();
    voiceRecorder.clearOldRecordings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bisqueOrangeColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                imgAppLogoSmall,
                height: 100.toHeight,
                width: 100.toWidth,
              ),
              SizedBox(
                height: 24.toHeight,
              ),
              Text(
                bhashiniTitle.tr,
                textAlign: TextAlign.center,
                style: AppTextStyle().bold24BalticSea,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
