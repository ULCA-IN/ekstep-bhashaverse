import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../common/controller/language_model_controller.dart';
import '../../../enums/speaker_status.dart';
import '../../../localization/localization_keys.dart';
import '../../../services/dhruva_api_client.dart';
import '../../../services/transliteration_app_api_client.dart';
import '../../../utils/constants/api_constants.dart';
import '../../../utils/constants/app_constants.dart';
import '../../../utils/screen_util/screen_util.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../utils/waveform_style.dart';

class TextTranslateController extends GetxController {
  TextEditingController sourceLangTextController = TextEditingController(),
      targetLangTextController = TextEditingController();

  late DHRUVAAPIClient _dhruvaapiClient;
  late TransliterationAppAPIClient _transliterationAppAPIClient;
  late LanguageModelController _languageModelController;

  final ScrollController transliterationHintsScrollController =
      ScrollController();

  RxBool isTranslateCompleted = false.obs,
      isLoading = false.obs,
      isKeyboardVisible = false.obs,
      isScrolledTransliterationHints = false.obs,
      isSourceShareLoading = false.obs,
      isTargetShareLoading = false.obs;
  RxString selectedSourceLanguageCode = ''.obs,
      sourceLangTTSPath = ''.obs,
      targetLangTTSPath = ''.obs,
      targetOutputText = ''.obs,
      selectedTargetLanguageCode = ''.obs;
  String? transliterationModelToUse = '';
  String currentlyTypedWordForTransliteration = '';
  RxInt maxDuration = 0.obs,
      currentDuration = 0.obs,
      sourceTextCharLimit = 0.obs;
  RxList transliterationWordHints = [].obs;
  int lastOffsetOfCursor = 0;
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
    _transliterationAppAPIClient = Get.find();
    _languageModelController = Get.find();
    _hiveDBInstance = Hive.box(hiveDBName);
    playerController = PlayerController();

    sourceLangTextController
        .addListener(clearTransliterationHintsIfCursorMoved);

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
    sourceLangTextController
        .removeListener(clearTransliterationHintsIfCursorMoved);
    sourceLangTextController.dispose();
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

    var response =
        await _transliterationAppAPIClient.sendTransliterationRequest(
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
    String translationServiceId = '';

    translationServiceId = APIConstants.getTaskTypeServiceID(
            _languageModelController.taskSequenceResponse,
            'translation',
            selectedSourceLanguageCode.value,
            selectedTargetLanguageCode.value) ??
        '';

    var asrPayloadToSend = APIConstants.createComputePayloadASRTrans(
        srcLanguage: selectedSourceLanguageCode.value,
        targetLanguage: selectedTargetLanguageCode.value,
        isRecorded: false,
        inputData: sourceLangTextController.text,
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
        targetOutputText.value = taskResponse.pipelineResponse
                ?.firstWhere((element) => element.taskType == 'translation')
                .output
                ?.first
                .target
                ?.trim() ??
            '';
        if (targetOutputText.value.isEmpty) {
          isLoading.value = false;
          showDefaultSnackbar(message: responseNotReceived.tr);
          return;
        }
        targetLangTextController.text = targetOutputText.value;
        isTranslateCompleted.value = true;
        isLoading.value = false;
        sourceLangTTSPath.value = '';
        targetLangTTSPath.value = '';
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

    await response.when(
      success: (taskResponse) async {
        ttsResponse = taskResponse.pipelineResponse
            ?.firstWhere((element) => element.taskType == 'tts')
            .audio[0]['audioContent'];

        // Save TTS audio to file
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
              ? targetLangTTSPath.value = ttsFilePath
              : sourceLangTTSPath.value = ttsFilePath;
          ttsAudioFile = File(ttsFilePath);
          if (ttsAudioFile != null && !await ttsAudioFile!.exists()) {
            await ttsAudioFile?.writeAsBytes(fileAsBytes);
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
  }

  void playStopTTSOutput(bool isPlayingSource) async {
    if (playerController.playerState.isPlaying) {
      await stopPlayer();
      return;
    }

    String? audioPath = '';

    if (isPlayingSource) {
      if (sourceLangTTSPath.value.isEmpty) {
        sourceSpeakerStatus.value = SpeakerStatus.loading;
        await getComputeResTTS(
          sourceText: sourceLangTextController.text,
          languageCode: selectedSourceLanguageCode.value,
          isTargetLanguage: false,
        );
      }
      audioPath = sourceLangTTSPath.value;
      sourceSpeakerStatus.value = SpeakerStatus.playing;
    } else {
      if (targetLangTTSPath.value.isEmpty) {
        targetSpeakerStatus.value = SpeakerStatus.loading;
        await getComputeResTTS(
          sourceText: targetOutputText.value,
          languageCode: selectedTargetLanguageCode.value,
          isTargetLanguage: true,
        );
      }
      audioPath = targetLangTTSPath.value;
      targetSpeakerStatus.value = SpeakerStatus.playing;
    }

    if (audioPath.isNotEmpty) {
      isPlayingSource
          ? sourceSpeakerStatus.value = SpeakerStatus.playing
          : targetSpeakerStatus.value = SpeakerStatus.playing;

      await preparePlayerAndWaveforms(audioPath,
          isRecordedAudio: false, isTargetLanguage: !isPlayingSource);
    }
  }

  void shareAudioFile({required bool isSourceLang}) async {
    if (isTranslateCompleted.value) {
      String? audioPathToShare =
          isSourceLang ? sourceLangTTSPath.value : targetLangTTSPath.value;

      if (audioPathToShare.isEmpty) {
        String sourceText = isSourceLang
            ? sourceLangTextController.text
            : targetLangTextController.text;

        String languageCode = isSourceLang
            ? selectedSourceLanguageCode.value
            : selectedTargetLanguageCode.value;

        if (sourceText.isEmpty) {
          showDefaultSnackbar(message: noAudioFoundToShare.tr);
          return;
        }

        isSourceLang
            ? isSourceShareLoading.value = true
            : isTargetShareLoading.value = true;

        await getComputeResTTS(
          sourceText: sourceText,
          languageCode: languageCode,
          isTargetLanguage: !isSourceLang,
        );
        audioPathToShare =
            isSourceLang ? sourceLangTTSPath.value : targetLangTTSPath.value;
        isSourceLang
            ? isSourceShareLoading.value = false
            : isTargetShareLoading.value = false;
      }

      await Share.shareXFiles(
        [XFile(audioPathToShare)],
        sharePositionOrigin: Rect.fromLTWH(
            0, 0, ScreenUtil.screenWidth, ScreenUtil.screenHeight / 2),
      );
    } else {
      showDefaultSnackbar(message: noAudioFoundToShare.tr);
    }
  }

  void setModelForTransliteration() {
    transliterationModelToUse =
        _languageModelController.getAvailableTransliterationModelsForLanguage(
            selectedSourceLanguageCode.value);
  }

  void clearTransliterationHintsIfCursorMoved() {
    int difference =
        lastOffsetOfCursor - sourceLangTextController.selection.base.offset;
    if (difference > 0 || difference < -1) {
      clearTransliterationHints();
    }
    lastOffsetOfCursor = sourceLangTextController.selection.base.offset;
  }

  void clearTransliterationHints() {
    transliterationWordHints.clear();
    currentlyTypedWordForTransliteration = '';
  }

  Future<void> resetAllValues() async {
    sourceLangTextController.clear();
    targetLangTextController.clear();
    isTranslateCompleted.value = false;
    sourceTextCharLimit.value = 0;
    ttsResponse = null;
    maxDuration.value = 0;
    currentDuration.value = 0;
    await stopPlayer();
    sourceSpeakerStatus.value = SpeakerStatus.disabled;
    targetSpeakerStatus.value = SpeakerStatus.disabled;
    sourceLangTTSPath.value = '';
    targetLangTTSPath.value = '';
    targetOutputText.value = '';
    isSourceShareLoading.value = false;
    isTargetShareLoading.value = false;
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
