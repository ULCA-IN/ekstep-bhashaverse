import 'dart:collection';
import 'package:get/get.dart';

import '../../models/search_model.dart';
import '../../models/task_sequence_response_model.dart';

class LanguageModelController extends GetxController {
  final SplayTreeMap<String, SplayTreeSet<String>> sourceTargetLanguageMap =
      SplayTreeMap<String, SplayTreeSet<String>>();

  final SplayTreeMap<String, SplayTreeSet<String>> translationLanguageMap =
      SplayTreeMap<String, SplayTreeSet<String>>();

  late final TaskSequenceResponse _taskSequenceResponse;
  late final TaskSequenceResponse _translationConfigResponse;
  late final TaskSequenceResponse _transliterationConfigResponse;

  TaskSequenceResponse get taskSequenceResponse => _taskSequenceResponse;
  void setTaskSequenceResponse(TaskSequenceResponse taskSequenceResponse) =>
      _taskSequenceResponse = taskSequenceResponse;

  TaskSequenceResponse get translationConfigResponse =>
      _translationConfigResponse;
  void setTranslationConfigResponse(TaskSequenceResponse translationResponse) =>
      _translationConfigResponse = translationResponse;

  TaskSequenceResponse get transliterationConfigResponse =>
      _transliterationConfigResponse;
  void setTransliterationConfigResponse(
          TaskSequenceResponse translationResponse) =>
      _transliterationConfigResponse = translationResponse;

  void populateLanguagePairs() {
    taskSequenceResponse.languages?.forEach((languagePair) {
      if (languagePair.sourceLanguage != null &&
          languagePair.targetLanguageList != null &&
          languagePair.targetLanguageList!.isNotEmpty) {
        sourceTargetLanguageMap[languagePair.sourceLanguage!] =
            SplayTreeSet.from(languagePair.targetLanguageList!);
      }
    });
  }

  void populateTranslationLanguagePairs() {
    translationConfigResponse.languages?.forEach((languagePair) {
      if (languagePair.sourceLanguage != null &&
          languagePair.targetLanguageList != null &&
          languagePair.targetLanguageList!.isNotEmpty) {
        translationLanguageMap[languagePair.sourceLanguage!] =
            SplayTreeSet.from(languagePair.targetLanguageList!);
      }
    });
  }

  SearchModel? _availableTransliterationModels;
  SearchModel? get availableTransliterationModels =>
      _availableTransliterationModels;

  void calcAvailableTransliterationModels(
      {required SearchModel transliterationModel}) {
    _availableTransliterationModels = transliterationModel;

    Set<String> availableTransliterationModelLanguagesSet = {};
    if (_availableTransliterationModels != null) {
      for (SearchModelData eachTransliterationModel
          in _availableTransliterationModels!.data) {
        availableTransliterationModelLanguagesSet.add(
            eachTransliterationModel.languages[0].sourceLanguage.toString());
      }
    }
  }
}
