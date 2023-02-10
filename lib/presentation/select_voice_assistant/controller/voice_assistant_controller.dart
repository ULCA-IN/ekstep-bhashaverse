import 'package:get/get.dart';

import '../../../enums/gender_enum.dart';

class VoiceAssistantController extends GetxController {
  final _selectedGender = Rxn<GenderEnum>();

  GenderEnum? getSelectedGender() => _selectedGender.value;

  void setSelectedGender(GenderEnum selectedGender) {
    _selectedGender.value = selectedGender;
  }
}
