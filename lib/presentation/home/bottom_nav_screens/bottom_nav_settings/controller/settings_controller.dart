import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../enums/gender_enum.dart';

class SettingsController extends GetxController {
  RxBool isTransLiterationEnabled = true.obs;
  Rx<GenderEnum> selectedGender = (GenderEnum.male).obs;
  Rx<ThemeMode> selectedThemeMode = (ThemeMode.light).obs;
}
