import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'dart:math' show pi;

import '../../../../enums/gender_enum.dart';
import '../../../../localization/localization_keys.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/constants/app_constants.dart';
import '../../../../utils/screen_util/screen_util.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../../utils/theme/app_colors.dart';
import '../../../../utils/theme/app_text_style.dart';
import 'controller/settings_controller.dart';

class BottomNavSettings extends StatefulWidget {
  const BottomNavSettings({super.key});

  @override
  State<BottomNavSettings> createState() => _BottomNavSettingsState();
}

class _BottomNavSettingsState extends State<BottomNavSettings> with SingleTickerProviderStateMixin {
  late SettingsController _settingsController;
  late AnimationController _controller;
  late Animation<double> _animation;
  Duration defaultAnimationTime = const Duration(milliseconds: 300);

  @override
  void initState() {
    _settingsController = Get.find();

    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: defaultAnimationTime,
    );
    _animation = Tween<double>(
      begin: pi / 2,
      end: 0.0,
    ).animate(_controller);
    ScreenUtil().init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: honeydew,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppEdgeInsets.instance.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 16.toHeight),
                Text(
                  kSettings.tr,
                  style: AppTextStyle().semibold24BalticSea.copyWith(fontSize: 20.toFont),
                ),
                SizedBox(height: 48.toHeight),
                _settingHeading(
                  action: _popupMenuBuilder(),
                  title: appTheme.tr,
                  subtitle: appInterfaceWillChange.tr,
                ),
                SizedBox(height: 24.toHeight),
                InkWell(
                  onTap: () {
                    Get.toNamed(AppRoutes.appLanguageRoute)?.then((_) => _settingsController.getPreferredLanguage());
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: _settingHeading(
                    action: Row(
                      children: [
                        Text(
                          _settingsController.preferredLanguage.value,
                          style: AppTextStyle().light16BalticSea.copyWith(color: arsenicColor),
                        ),
                        SizedBox(width: 8.toWidth),
                        RotatedBox(
                          quarterTurns: 3,
                          child: SvgPicture.asset(iconArrowDown),
                        ),
                      ],
                    ),
                    title: appLanguage.tr,
                    subtitle: appInterfaceWillChangeInSelected.tr,
                  ),
                ),
                SizedBox(height: 24.toHeight),
                _voiceAssistantTileWidget(),
                SizedBox(height: 24.toHeight),
                _settingHeading(
                  action: Obx(
                    () => CupertinoSwitch(
                      value: _settingsController.isTransLiterationEnabled.value,
                      activeColor: japaneseLaurel,
                      trackColor: americanSilver,
                      onChanged: (value) => _settingsController.changeTransliterationPref(value),
                    ),
                  ),
                  title: transLiteration.tr,
                  subtitle: transLiterationWillInitiateWord.tr,
                ),
                SizedBox(height: 24.toHeight),
                Obx(
                  () => InkWell(
                    onTap: () {
                      _settingsController.isAdvanceMenuOpened.value = !_settingsController.isAdvanceMenuOpened.value;
                      _settingsController.isAdvanceMenuOpened.value ? _controller.forward() : _controller.reverse();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: _expandableSettingHeading(
                      height: _settingsController.isAdvanceMenuOpened.value ? 130.toHeight : 60.toHeight,
                      action: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..rotateZ(
                                  _animation.value,
                                )
                                ..invert(),
                              child: SvgPicture.asset(iconArrowDown),
                            );
                          }),
                      title: advanceSettings.tr,
                      child: AnimatedOpacity(
                        opacity: _settingsController.isAdvanceMenuOpened.value ? 1 : 0,
                        duration: defaultAnimationTime,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(child: SizedBox(height: 8.toHeight)),
                            const Flexible(child: Divider()),
                            Flexible(child: SizedBox(height: 14.toHeight)),
                            Flexible(
                              child: Row(
                                children: [
                                  ///TODO: localize title
                                  Text(
                                    'S2S Streaming',
                                    style: AppTextStyle().regular18DolphinGrey.copyWith(
                                          fontSize: 18.toFont,
                                          color: balticSea,
                                        ),
                                  ),
                                  const Spacer(),
                                  Obx(
                                    () => CupertinoSwitch(
                                      value: _settingsController.isStreamingEnabled.value,
                                      activeColor: japaneseLaurel,
                                      trackColor: americanSilver,
                                      onChanged: (value) {
                                        _settingsController.changeStreamingPref(value);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // SizedBox(height: 16.toHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingHeading({
    required String title,
    required Widget action,
    String? subtitle,
    Widget? child,
    double? height,
  }) {
    return AnimatedContainer(
      duration: defaultAnimationTime,
      padding: AppEdgeInsets.instance.all(16),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          width: 1.toWidth,
          color: goastWhite,
        ),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppTextStyle().regular18DolphinGrey.copyWith(
                      fontSize: 20.toFont,
                      color: balticSea,
                    ),
              ),
              const Spacer(),
              action,
            ],
          ),
          if (subtitle != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 16.toHeight),
                Text(
                  subtitle,
                  style: AppTextStyle().light16BalticSea.copyWith(
                        fontSize: 14.toFont,
                        color: dolphinGray,
                      ),
                ),
              ],
            ),
          if (child != null) Expanded(child: child),
        ],
      ),
    );
  }

  Widget _expandableSettingHeading({
    required String title,
    required Widget action,
    Widget? child,
    double? height,
  }) {
    return AnimatedContainer(
      duration: defaultAnimationTime,
      padding: AppEdgeInsets.instance.only(top: 16, left: 16, right: 16),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          width: 1.toWidth,
          color: goastWhite,
        ),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              action,
              SizedBox(width: 20.toWidth),
              Text(
                title,
                style: AppTextStyle().regular18DolphinGrey.copyWith(
                      fontSize: 20.toFont,
                      color: balticSea,
                    ),
              ),
            ],
          ),
          if (child != null) Flexible(child: child),
        ],
      ),
    );
  }

  Widget _voiceAssistantTileWidget() {
    return Container(
      padding: AppEdgeInsets.instance.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          width: 1.toWidth,
          color: goastWhite,
        ),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              voiceAssistant.tr,
              style: AppTextStyle().regular18DolphinGrey.copyWith(
                    fontSize: 20.toFont,
                    color: balticSea,
                  ),
            ),
          ),
          _radioWidgetBuilder(
            GenderEnum.male,
            male.tr,
          ),
          SizedBox(width: 8.toWidth),
          _radioWidgetBuilder(
            GenderEnum.female,
            female.tr,
          ),
        ],
      ),
    );
  }

  Widget _radioWidgetBuilder(
    GenderEnum currentGender,
    String title,
  ) {
    return Obx(
      () => InkWell(
        onTap: () => _settingsController.changeVoiceAssistantPref(currentGender),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              width: 1.toWidth,
              color: (_settingsController.preferredVoiceAssistant.value == currentGender) ? japaneseLaurel : americanSilver,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: AppEdgeInsets.instance.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: <Widget>[
              SvgPicture.asset(
                (_settingsController.preferredVoiceAssistant.value == currentGender) ? iconSelectedRadio : iconUnSelectedRadio,
              ),
              SizedBox(width: 5.toWidth),
              Text(
                title,
                style: AppTextStyle().regular18DolphinGrey.copyWith(
                      fontSize: 16.toFont,
                      color: (_settingsController.preferredVoiceAssistant.value == currentGender) ? japaneseLaurel : dolphinGray,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _popupMenuBuilder() {
    return Obx(
      () => PopupMenuButton(
        onSelected: (value) {
          showDefaultSnackbar(message: featureAvailableSoonInfo.tr);
        },
        child: Row(
          children: [
            Text(
              _getThemeModeName(_settingsController.selectedThemeMode.value),
              style: AppTextStyle().light16BalticSea.copyWith(color: arsenicColor),
            ),
            SizedBox(width: 8.toWidth),
            SvgPicture.asset(iconArrowDown),
          ],
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: ThemeMode.light,
            child: Text((light.tr)),
          ),
          PopupMenuItem(
            value: ThemeMode.dark,
            child: Text(dark.tr),
          ),
          PopupMenuItem(
            value: ThemeMode.system,
            child: Text(systemDefault.tr),
          ),
        ],
      ),
    );
  }

  String _getThemeModeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return systemDefault.tr;
      case ThemeMode.light:
        return light.tr;
      case ThemeMode.dark:
        return dark.tr;
    }
  }
}
