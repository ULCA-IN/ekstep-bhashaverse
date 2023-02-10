import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../../enums/gender_enum.dart';
import '../../../../enums/language_enum.dart';
import '../../../../localization/localization_keys.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/constants/api_constants.dart';
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

class _BottomNavSettingsState extends State<BottomNavSettings> {
  late SettingsController _settingsController;
  late final Box _hiveDBInstance;
  String preferredLanguage = '';

  @override
  void initState() {
    _settingsController = Get.find();
    ScreenUtil().init();
    _hiveDBInstance = Hive.box(hiveDBName);
    super.initState();
    setPreferredLanguage();
    setPreferredGender();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: honeydew,
      body: SafeArea(
        child: Padding(
          padding: AppEdgeInsets.instance.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.toHeight),
              Text(
                kSettings.tr,
                style: AppTextStyle()
                    .semibold24BalticSea
                    .copyWith(fontSize: 20.toFont),
              ),
              SizedBox(height: 48.toHeight),
              _containerWidget(
                widget: _popupMenuBuilder(),
                title: appTheme.tr,
                subtitle: appInterfaceWillChange.tr,
              ),
              SizedBox(height: 24.toHeight),
              InkWell(
                onTap: () {
                  Get.toNamed(AppRoutes.appLanguageRoute)
                      ?.then((_) => setPreferredLanguage());
                },
                borderRadius: BorderRadius.circular(10),
                child: _containerWidget(
                  widget: Row(
                    children: [
                      Text(
                        preferredLanguage,
                        style: AppTextStyle()
                            .light16BalticSea
                            .copyWith(color: arsenicColor),
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
              _containerWidget(
                widget: Obx(
                  () => CupertinoSwitch(
                    value: _settingsController.isTransLiterationEnabled.value,
                    activeColor: japaneseLaurel,
                    trackColor: americanSilver,
                    onChanged: (value) {
                      _hiveDBInstance.put(enableTransliteration, value);
                      _settingsController.isTransLiterationEnabled.value =
                          value;
                    },
                  ),
                ),
                title: transLiteration.tr,
                subtitle: transLiterationWillInitiateWord.tr,
              ),
              SizedBox(height: 24.toHeight),
              Visibility(
                visible: false,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(10),
                  child: _containerWidget(
                    widget: SvgPicture.asset(iconArrowDown),
                    title: advanceSettings.tr,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _containerWidget({
    required Widget widget,
    required String title,
    String subtitle = '',
  }) {
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
              widget,
            ],
          ),
          if (subtitle.isNotEmpty) SizedBox(height: 16.toHeight),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: AppTextStyle().light16BalticSea.copyWith(
                    fontSize: 14.toFont,
                    color: dolphinGray,
                  ),
            ),
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
        onTap: () {
          _settingsController.selectedGender.value = currentGender;
          _hiveDBInstance.put(
              preferredVoiceAssistantGender, currentGender.name);
          setPreferredGender();
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              width: 1.toWidth,
              color: (_settingsController.selectedGender.value == currentGender)
                  ? japaneseLaurel
                  : americanSilver,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding:
              AppEdgeInsets.instance.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: <Widget>[
              SvgPicture.asset(
                (_settingsController.selectedGender.value == currentGender)
                    ? iconSelectedRadio
                    : iconUnSelectedRadio,
              ),
              SizedBox(width: 5.toWidth),
              Text(
                title,
                style: AppTextStyle().regular18DolphinGrey.copyWith(
                      fontSize: 16.toFont,
                      color: (_settingsController.selectedGender.value ==
                              currentGender)
                          ? japaneseLaurel
                          : dolphinGray,
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
          // _settingsController.selectedThemeMode.value = value;
          showDefaultSnackbar(message: featureAvailableSoonInfo.tr);
        },
        child: Row(
          children: [
            Text(
              _getThemeModeName(_settingsController.selectedThemeMode.value),
              style:
                  AppTextStyle().light16BalticSea.copyWith(color: arsenicColor),
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

  void setPreferredLanguage() {
    preferredLanguage = APIConstants.getLanguageCodeOrName(
        value: _hiveDBInstance.get(preferredAppLocale, defaultValue: 'en'),
        returnWhat: LanguageMap.nativeName,
        lang_code_map: APIConstants.LANGUAGE_CODE_MAP);
  }

  void setPreferredGender() {
    _settingsController.selectedGender.value = GenderEnum.values
        .byName(_hiveDBInstance.get(preferredVoiceAssistantGender));
  }
}
