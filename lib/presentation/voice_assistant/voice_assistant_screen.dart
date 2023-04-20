import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../common/widgets/custom_elevated_button.dart';
import '../../enums/gender_enum.dart';
import '../../localization/localization_keys.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/theme/app_text_style.dart';
import 'controller/voice_assistant_controller.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  late VoiceAssistantController _voiceAssistantController;

  @override
  void initState() {
    _voiceAssistantController = Get.find();
    ScreenUtil().init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppEdgeInsets.instance.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.toHeight),
              Text(
                selectVoiceAssistant.tr,
                style: AppTextStyle().semibold24BalticSea,
              ),
              SizedBox(height: 8.toHeight),
              Text(
                youWillHearTheTranslationText.tr,
                style: AppTextStyle()
                    .light16BalticSea
                    .copyWith(color: dolphinGray),
              ),
              SizedBox(height: 56.toHeight),
              Row(
                children: [
                  _avatarWidgetBuilder(
                    GenderEnum.male,
                    imgMaleAvatar,
                    male.tr,
                  ),
                  SizedBox(width: 10.toWidth),
                  _avatarWidgetBuilder(
                    GenderEnum.female,
                    imgFemaleAvatar,
                    female.tr,
                  ),
                ],
              ),
              const Spacer(),
              CustomElevetedButton(
                buttonText: letsTranslate.tr,
                textStyle: AppTextStyle()
                    .semibold24BalticSea
                    .copyWith(fontSize: 18.toFont),
                backgroundColor: primaryColor,
                borderRadius: 16,
                onButtonTap: () {
                  Box hiveDBInstance = Hive.box(hiveDBName);
                  hiveDBInstance.put(introShownAlreadyKey, true);
                  Get.offAllNamed(AppRoutes.homeRoute);
                },
              ),
              SizedBox(height: 36.toHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarWidgetBuilder(
    GenderEnum gender,
    String avatarImage,
    String avatarTitle,
  ) {
    return Expanded(
      child: Obx(
        () => InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _voiceAssistantController.setSelectedGender(gender),
          child: Container(
            padding: AppEdgeInsets.instance.all(22),
            decoration: BoxDecoration(
              color: (_voiceAssistantController.getSelectedGender() == gender)
                  ? sassyGreen
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                width: 1.toWidth,
                color: (_voiceAssistantController.getSelectedGender() == gender)
                    ? japaneseLaurel
                    : americanSilver,
              ),
            ),
            child: Column(
              children: [
                Image.asset(avatarImage),
                SizedBox(height: 16.toHeight),
                Text(
                  avatarTitle,
                  style: AppTextStyle().regular18DolphinGrey.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
