import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../../common/controller/language_model_controller.dart';
import '../../../enums/speaker_status.dart';
import '../../../localization/localization_keys.dart';
import '../../../services/dhruva_api_client.dart';
import '../../../services/translation_app_api_client.dart';
import '../../../utils/constants/api_constants.dart';
import '../../../utils/constants/app_constants.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../utils/waveform_style.dart';

class TextTranslateController extends GetxController {
  TextEditingController sourceLanTextController = TextEditingController(),
      targetLangTextController = TextEditingController();

  late DHRUVAAPIClient _dhruvaapiClient;
  late TranslationAppAPIClient _translationAppAPIClient;
  late LanguageModelController _languageModelController;

  final ScrollController transliterationHintsScrollController =
      ScrollController();

  RxBool isTranslateCompleted = false.obs,
      isLoading = false.obs,
      isKeyboardVisible = false.obs,
      isScrolledTransliterationHints = false.obs;
  RxString selectedSourceLanguageCode = ''.obs,
      selectedTargetLanguageCode = ''.obs;
  String? transliterationModelToUse = '';
  String sourceLangTTSPath = '',
      targetLangTTSPath = '',
      currentlyTypedWordForTransliteration = '';
  RxInt maxDuration = 0.obs,
      currentDuration = 0.obs,
      sourceTextCharLimit = 0.obs;
  RxList transliterationWordHints = [].obs;
  File? ttsAudioFile;
  dynamic ttsResponse;
  Rx<SpeakerStatus> sourceSpeakerStatus = Rx(SpeakerStatus.disabled),
      targetSpeakerStatus = Rx(SpeakerStatus.disabled);
  late Directory appDirectory;
  late final Box _hiveDBInstance;
  late PlayerController playerController;

  @override
  void onInit() {
    _dhruvaapiClient = Get.find();
    _translationAppAPIClient = Get.find();
    _languageModelController = Get.find();
    _hiveDBInstance = Hive.box(hiveDBName);
    playerController = PlayerController();

    playerController.onCurrentDurationChanged.listen((duration) {
      currentDuration.value = duration;
    });

    playerController.onPlayerStateChanged.listen((_) {
      switch (playerController.playerState) {
        case PlayerState.initialized:
          maxDuration.value = playerController.maxDuration;
          break;
        case PlayerState.paused:
          sourceSpeakerStatus.value = SpeakerStatus.stopped;
          targetSpeakerStatus.value = SpeakerStatus.stopped;
          currentDuration.value = 0;
          break;
        case PlayerState.stopped:
          currentDuration.value = 0;
          break;
        default:
      }
    });

    transliterationHintsScrollController.addListener(() {
      isScrolledTransliterationHints.value = true;
    });
    super.onInit();
  }

  @override
  void onClose() async {
    sourceLanTextController.dispose();
    targetLangTextController.dispose();
    await disposePlayer();
    super.onClose();
  }

  void getSourceTargetLangFromDB() {
    String? _selectedSourceLanguage =
        _hiveDBInstance.get(preferredSourceLanguage);

    if (_selectedSourceLanguage == null || _selectedSourceLanguage.isEmpty) {
      _selectedSourceLanguage = _hiveDBInstance.get(preferredAppLocale);
    }

    if (_languageModelController.sourceTargetLanguageMap.keys
        .toList()
        .contains(_selectedSourceLanguage)) {
      selectedSourceLanguageCode.value = _selectedSourceLanguage ?? '';
      if (isTransliterationEnabled()) {
        setModelForTransliteration();
      }
    }

    String? _selectedTargetLanguage =
        _hiveDBInstance.get(preferredTargetLanguage);
    if (_selectedTargetLanguage != null &&
        _selectedTargetLanguage.isNotEmpty &&
        _languageModelController.sourceTargetLanguageMap.keys
            .toList()
            .contains(_selectedTargetLanguage)) {
      selectedTargetLanguageCode.value = _selectedTargetLanguage;
    }
  }

  void swapSourceAndTargetLanguage() {
    if (isSourceAndTargetLangSelected()) {
      if (_languageModelController.sourceTargetLanguageMap.keys
              .contains(selectedTargetLanguageCode.value) &&
          _languageModelController
                  .sourceTargetLanguageMap[selectedTargetLanguageCode.value] !=
              null &&
          _languageModelController
              .sourceTargetLanguageMap[selectedTargetLanguageCode.value]!
              .contains(selectedSourceLanguageCode.value)) {
        String tempSourceLanguage = selectedSourceLanguageCode.value;
        selectedSourceLanguageCode.value = selectedTargetLanguageCode.value;
        selectedTargetLanguageCode.value = tempSourceLanguage;
        _hiveDBInstance.put(
            preferredSourceLanguage, selectedSourceLanguageCode.value);
        _hiveDBInstance.put(
            preferredTargetLanguage, selectedTargetLanguageCode.value);
        resetAllValues();
      } else {
        String sourceLanguage = APIConstants.getLanguageNameFromCode(
            selectedSourceLanguageCode.value);
        String targetLanguage = APIConstants.getLanguageNameFromCode(
            selectedTargetLanguageCode.value);
        showDefaultSnackbar(
            message:
                '$targetLanguage - $sourceLanguage ${translationNotPossible.tr}');
      }
    } else {
      showDefaultSnackbar(message: kErrorSelectSourceAndTargetScreen.tr);
    }
  }

  bool isSourceAndTargetLangSelected() =>
      selectedSourceLanguageCode.value.isNotEmpty &&
      selectedTargetLanguageCode.value.isNotEmpty;

  Future<void> getTransliterationOutput(String sourceText) async {
    currentlyTypedWordForTransliteration = sourceText;
    if (transliterationModelToUse == null ||
        transliterationModelToUse!.isEmpty) {
      clearTransliterationHints();
      return;
    }
    var transliterationPayloadToSend = {};
    transliterationPayloadToSend['input'] = [
      {'source': sourceText}
    ];

    transliterationPayloadToSend['modelId'] = transliterationModelToUse;
    transliterationPayloadToSend['task'] = 'transliteration';
    transliterationPayloadToSend['userId'] = null;

    var response = await _translationAppAPIClient.sendTransliterationRequest(
        transliterationPayload: transliterationPayloadToSend);

    response?.when(
      success: (data) async {
        if (currentlyTypedWordForTransliteration ==
            data['output'][0]['source']) {
          transliterationWordHints.value = data['output'][0]['target'];
          if (!transliterationWordHints
              .contains(currentlyTypedWordForTransliteration)) {
            transliterationWordHints.add(currentlyTypedWordForTransliteration);
          }
        }
      },
      failure: (_) {},
    );
  }

  Future<void> getComputeResponseASRTrans() async {
    isLoading.value = true;
    // String asrServiceId = '';
    String translationServiceId = '';

    translationServiceId = APIConstants.getTaskTypeServiceID(
            _languageModelController.taskSequenceResponse,
            'translation',
            selectedSourceLanguageCode.value) ??
        '';

    var asrPayloadToSend = APIConstants.createComputePayloadASRTrans(
        srcLanguage: selectedSourceLanguageCode.value,
        targetLanguage: selectedTargetLanguageCode.value,
        isRecorded: false,
        inputData: sourceLanTextController.text,
        translationServiceID: translationServiceId,
        preferredGender: _hiveDBInstance.get(preferredVoiceAssistantGender));

    var response = await _dhruvaapiClient.sendComputeRequest(
        baseUrl: _languageModelController
            .taskSequenceResponse.pipelineInferenceAPIEndPoint?.callbackUrl,
        authorizationKey: _languageModelController.taskSequenceResponse
            .pipelineInferenceAPIEndPoint?.inferenceApiKey?.name,
        authorizationValue: _languageModelController.taskSequenceResponse
            .pipelineInferenceAPIEndPoint?.inferenceApiKey?.value,
        computePayload: asrPayloadToSend);

    response.when(
      success: (taskResponse) async {
        String outputTargetText = taskResponse.pipelineResponse
                ?.firstWhere((element) => element.taskType == 'translation')
                .output
                ?.first
                .target
                ?.trim() ??
            '';
        if (outputTargetText.isEmpty) {
          isLoading.value = false;
          showDefaultSnackbar(message: responseNotReceived.tr);
          return;
        }
        targetLangTextController.text = outputTargetText;
        isTranslateCompleted.value = true;
        isLoading.value = false;
        sourceLangTTSPath = '';
        targetLangTTSPath = '';
        sourceSpeakerStatus.value = SpeakerStatus.stopped;
        targetSpeakerStatus.value = SpeakerStatus.stopped;
      },
      failure: (error) {
        isLoading.value = false;
        showDefaultSnackbar(
            message: error.message ?? APIConstants.kErrorMessageGenericError);
      },
    );
  }

  Future<void> getComputeResTTS({
    required String sourceText,
    required String languageCode,
    required bool isTargetLanguage,
  }) async {
    if ((isTargetLanguage && targetLangTTSPath.isEmpty) ||
        (!isTargetLanguage && sourceLangTTSPath.isEmpty)) {
      isTargetLanguage
          ? targetSpeakerStatus.value = SpeakerStatus.loading
          : sourceSpeakerStatus.value = SpeakerStatus.loading;

      String ttsServiceId = APIConstants.getTaskTypeServiceID(
              _languageModelController.taskSequenceResponse,
              'tts',
              languageCode) ??
          '';

      var asrPayloadToSend = APIConstants.createComputePayloadTTS(
          srcLanguage: languageCode,
          inputData: sourceText,
          ttsServiceID: ttsServiceId,
          preferredGender: _hiveDBInstance.get(preferredVoiceAssistantGender));

      var response = await _dhruvaapiClient.sendComputeRequest(
          baseUrl: _languageModelController
              .taskSequenceResponse.pipelineInferenceAPIEndPoint?.callbackUrl,
          authorizationKey: _languageModelController.taskSequenceResponse
              .pipelineInferenceAPIEndPoint?.inferenceApiKey?.name,
          authorizationValue: _languageModelController.taskSequenceResponse
              .pipelineInferenceAPIEndPoint?.inferenceApiKey?.value,
          computePayload: asrPayloadToSend);

      response.when(
        success: (taskResponse) async {
          ttsResponse = taskResponse.pipelineResponse
              ?.firstWhere((element) => element.taskType == 'tts')
              .audio[0]['audioContent'];

          // Save and Play TTS audio
          if (ttsResponse != null) {
            Uint8List? fileAsBytes = base64Decode(ttsResponse);
            Directory appDocDir = await getApplicationDocumentsDirectory();
            String recordingPath = '${appDocDir.path}/$recordingFolderName';
            if (!await Directory(recordingPath).exists()) {
              Directory(recordingPath).create();
            }

            String ttsFilePath =
                '$recordingPath/$defaultTTSPlayName${DateTime.now().millisecondsSinceEpoch}.wav';
            isTargetLanguage
                ? targetLangTTSPath = ttsFilePath
                : sourceLangTTSPath = ttsFilePath;
            ttsAudioFile = File(ttsFilePath);
            if (ttsAudioFile != null && !await ttsAudioFile!.exists()) {
              await ttsAudioFile?.writeAsBytes(fileAsBytes);

              await preparePlayerAndWaveforms(ttsFilePath,
                  isRecordedAudio: false, isTargetLanguage: isTargetLanguage);
            }
          } else {
            showDefaultSnackbar(message: noVoiceAssistantAvailable.tr);
            return;
          }
        },
        failure: (error) {
          isTargetLanguage
              ? targetSpeakerStatus.value = SpeakerStatus.stopped
              : sourceSpeakerStatus.value = SpeakerStatus.stopped;
          showDefaultSnackbar(
              message: error.message ?? APIConstants.kErrorMessageGenericError);
          return;
        },
      );
    } else {
      await preparePlayerAndWaveforms(
          isTargetLanguage ? targetLangTTSPath : sourceLangTTSPath,
          isRecordedAudio: false,
          isTargetLanguage: isTargetLanguage);
    }
  }

  void setModelForTransliteration() {
    transliterationModelToUse =
        _languageModelController.getAvailableTransliterationModelsForLanguage(
            selectedSourceLanguageCode.value);
  }

  void clearTransliterationHints() {
    transliterationWordHints.clear();
    currentlyTypedWordForTransliteration = '';
  }

  Future<void> resetAllValues() async {
    sourceLanTextController.clear();
    targetLangTextController.clear();
    isTranslateCompleted.value = false;
    sourceTextCharLimit.value = 0;
    ttsResponse = null;
    maxDuration.value = 0;
    currentDuration.value = 0;
    await stopPlayer();
    sourceSpeakerStatus.value = SpeakerStatus.disabled;
    targetSpeakerStatus.value = SpeakerStatus.disabled;
    sourceLangTTSPath = '';
    targetLangTTSPath = '';
    if (isTransliterationEnabled()) {
      setModelForTransliteration();
      clearTransliterationHints();
    }
  }

  Future<void> preparePlayerAndWaveforms(
    String filePath, {
    required bool isRecordedAudio,
    required bool isTargetLanguage,
  }) async {
    await stopPlayer();
    if (isTargetLanguage)
      targetSpeakerStatus.value = SpeakerStatus.playing;
    else
      sourceSpeakerStatus.value = SpeakerStatus.playing;
    await playerController.preparePlayer(
        path: filePath,
        noOfSamples: WaveformStyle.getDefaultPlayerStyle(
                isRecordedAudio: isRecordedAudio)
            .getSamplesForWidth(WaveformStyle.getDefaultWidth));
    maxDuration.value = playerController.maxDuration;
    startOrPausePlayer();
  }

  void startOrPausePlayer() async {
    playerController.playerState.isPlaying
        ? await playerController.pausePlayer()
        : await playerController.startPlayer(
            finishMode: FinishMode.pause,
          );
  }

  Future<void> stopPlayer() async {
    if (playerController.playerState.isPlaying ||
        playerController.playerState == PlayerState.paused) {
      await playerController.stopPlayer();
    }
    targetSpeakerStatus.value = SpeakerStatus.stopped;
    sourceSpeakerStatus.value = SpeakerStatus.stopped;
  }

  Future<void> disposePlayer() async {
    await stopPlayer();
    playerController.dispose();
  }

  bool isTransliterationEnabled() {
    return _hiveDBInstance.get(enableTransliteration, defaultValue: true) &&
        selectedSourceLanguageCode.value != 'en';
  }
}
