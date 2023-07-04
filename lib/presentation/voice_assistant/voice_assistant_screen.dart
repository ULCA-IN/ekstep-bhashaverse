import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../common/widgets/custom_elevated_button.dart';
import '../../enums/gender_enum.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/theme/app_theme_provider.dart';
import '../../utils/theme/app_text_style.dart';
import 'controller/voice_assistant_controller.dart';
import '../../i18n/strings.g.dart' as i18n;

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  late VoiceAssistantController _voiceAssistantController;
  late dynamic translation;

  @override
  void initState() {
    _voiceAssistantController = Get.find();

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    translation = i18n.Translations.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appTheme.listingScreenBGColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16).w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.w),
              Text(
                translation.selectVoiceAssistant,
                style: semibold24(context),
              ),
              SizedBox(height: 8.w),
              Text(
                translation.youWillHearTheTranslationText,
                style: regular14(context)
                    .copyWith(color: context.appTheme.secondaryTextColor),
              ),
              SizedBox(height: 56.w),
              Row(
                children: [
                  _avatarWidgetBuilder(
                    GenderEnum.male,
                    imgMaleAvatar,
                    translation.male,
                  ),
                  SizedBox(width: 10.w),
                  _avatarWidgetBuilder(
                    GenderEnum.female,
                    imgFemaleAvatar,
                    translation.female,
                  ),
                ],
              ),
              const Spacer(),
              CustomElevatedButton(
                buttonText: translation.letsTranslate,
                backgroundColor: context.appTheme.primaryColor,
                borderRadius: 16,
                onButtonTap: () {
                  Box hiveDBInstance = Hive.box(hiveDBName);
                  hiveDBInstance.put(introShownAlreadyKey, true);
                  Get.offAllNamed(AppRoutes.homeRoute);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarWidgetBuilder(
    GenderEnum gender,
    String avatarPath,
    String avatarTitle,
  ) {
    return Expanded(
      child: Obx(
        () => InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _voiceAssistantController.setSelectedGender(gender),
          child: Container(
            padding: const EdgeInsets.all(22).w,
            decoration: BoxDecoration(
              color: (_voiceAssistantController.getSelectedGender() == gender)
                  ? context.appTheme.lightBGColor
                  : context.appTheme.voiceAssistantBGColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                width: 1.w,
                color: (_voiceAssistantController.getSelectedGender() == gender)
                    ? context.appTheme.highlightedBorderColor
                    : context.appTheme.disabledBGColor,
              ),
            ),
            child: Column(
              children: [
                Image.asset(avatarPath),
                SizedBox(height: 16.w),
                Text(
                  avatarTitle,
                  style: regular18Primary(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
