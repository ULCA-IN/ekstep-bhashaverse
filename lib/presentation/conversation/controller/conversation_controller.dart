import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:vibration/vibration.dart';

import '../../../common/controller/language_model_controller.dart';
import '../../../enums/current_mic.dart';
import '../../../enums/speaker_status.dart';
import '../../../enums/language_enum.dart';
import '../../../enums/mic_button_status.dart';
import '../../../localization/localization_keys.dart';
import '../../../services/dhruva_api_client.dart';
import '../../../services/socket_io_client.dart';
import '../../../utils/constants/api_constants.dart';
import '../../../utils/constants/app_constants.dart';
import '../../../utils/permission_handler.dart';
import '../../../utils/screen_util/screen_util.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../utils/voice_recorder.dart';
import '../../../utils/waveform_style.dart';

class ConversationController extends GetxController {
  late DHRUVAAPIClient _dhruvaapiClient;
  late LanguageModelController _languageModelController;

  TextEditingController sourceLangTextController = TextEditingController();
  TextEditingController targetLangTextController = TextEditingController();

  RxBool isTranslateCompleted = false.obs;
  bool isMicPermissionGranted = false;
  RxBool isLoading = false.obs,
      isSourceShareLoading = false.obs,
      isTargetShareLoading = false.obs;
  RxString selectedSourceLanguageCode = ''.obs,
      selectedTargetLanguageCode = ''.obs,
      sourceOutputText = ''.obs,
      targetOutputText = ''.obs,
      sourceLangTTSPath = ''.obs,
      targetLangTTSPath = ''.obs;
  dynamic ttsResponse;
  RxBool isRecordedViaMic = false.obs;
  RxBool isKeyboardVisible = false.obs;
  RxInt maxDuration = 0.obs, currentDuration = 0.obs;
  File? ttsAudioFile;
  late SocketIOClient _socketIOClient;
  Rx<MicButtonStatus> micButtonStatus = Rx(MicButtonStatus.released);
  DateTime? recordingStartTime;
  String beepSoundPath = '';
  late File beepSoundFile;
  PlayerController _playerController = PlayerController();
  late Directory appDirectory;
  Rx<SpeakerStatus> sourceSpeakerStatus = Rx(SpeakerStatus.disabled);
  Rx<SpeakerStatus> targetSpeakerStatus = Rx(SpeakerStatus.disabled);
  int samplingRate = 16000;
  Rx<CurrentlySelectedMic> currentMic = Rx(CurrentlySelectedMic.none);

  final VoiceRecorder _voiceRecorder = VoiceRecorder();

  late final Box _hiveDBInstance;

  final stopWatchTimer = StopWatchTimer(mode: StopWatchMode.countUp);

  late PlayerController controller;

  StreamSubscription<Uint8List>? micStreamSubscription;

  int silenceSize = 20;

  late Worker streamingResponseListener, socketIOErrorListener;

  @override
  void onInit() {
    _dhruvaapiClient = Get.find();
    _socketIOClient = Get.find();
    _languageModelController = Get.find();
    _hiveDBInstance = Hive.box(hiveDBName);
    controller = PlayerController();
    Connectivity().onConnectivityChanged.listen(
          (newConnectivity) => updateSamplingRate(newConnectivity),
        );
    setBeepSoundFile();
    controller.onCompletion.listen((event) {
      sourceSpeakerStatus.value = SpeakerStatus.stopped;
      targetSpeakerStatus.value = SpeakerStatus.stopped;
    });

    controller.onCurrentDurationChanged.listen((duration) {
      currentDuration.value = duration;
    });

    controller.onPlayerStateChanged.listen((_) {
      switch (controller.playerState) {
        case PlayerState.initialized:
          maxDuration.value = controller.maxDuration;
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

    stopWatchTimer.rawTime.listen((event) {
      if (micButtonStatus.value == MicButtonStatus.pressed &&
          (event + 1) >= recordingMaxTimeLimit) {
        stopWatchTimer.onStopTimer();
        micButtonStatus.value = MicButtonStatus.released;
        stopVoiceRecordingAndGetResult();
      }
    });

    super.onInit();
    streamingResponseListener =
        ever(_socketIOClient.socketResponseText, (socketResponseText) {
      sourceLangTextController.text = socketResponseText;
      if (!isRecordedViaMic.value) isRecordedViaMic.value = true;
      if (!_socketIOClient.isMicConnected.value) {
        streamingResponseListener.dispose();
      }
    }, condition: () => _socketIOClient.isMicConnected.value);

    socketIOErrorListener = ever(_socketIOClient.hasError, (isAborted) {
      if (isAborted) {
        micButtonStatus.value = MicButtonStatus.released;
        showDefaultSnackbar(message: somethingWentWrong.tr);
      }
    }, condition: !_socketIOClient.isConnected());
  }

  @override
  void onClose() async {
    streamingResponseListener.dispose();
    socketIOErrorListener.dispose();
    _socketIOClient.disconnect();
    sourceLangTextController.dispose();
    targetLangTextController.dispose();
    await stopWatchTimer.dispose();
    disposePlayer();
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

  setBeepSoundFile() async {
    appDirectory = await getApplicationDocumentsDirectory();
    beepSoundPath = "${appDirectory.path}/mic_tap_sound.wav";
    beepSoundFile = File(beepSoundPath);
    if (!await beepSoundFile.exists()) {
      await beepSoundFile.writeAsBytes(
          (await rootBundle.load(micBeepSound)).buffer.asUint8List());
    }
  }

  bool isSourceAndTargetLangSelected() =>
      selectedSourceLanguageCode.value.isNotEmpty &&
      selectedTargetLanguageCode.value.isNotEmpty;

  String getSelectedSourceLanguageName() {
    return APIConstants.getLanguageCodeOrName(
        value: selectedSourceLanguageCode.value,
        returnWhat: LanguageMap.languageNameInAppLanguage,
        lang_code_map: APIConstants.LANGUAGE_CODE_MAP);
  }

  String getSelectedTargetLanguageName() {
    return APIConstants.getLanguageCodeOrName(
        value: selectedTargetLanguageCode.value,
        returnWhat: LanguageMap.languageNameInAppLanguage,
        lang_code_map: APIConstants.LANGUAGE_CODE_MAP);
  }

  void startVoiceRecording() async {
    await PermissionHandler.requestPermissions().then((isPermissionGranted) {
      isMicPermissionGranted = isPermissionGranted;
    });
    if (isMicPermissionGranted) {
      // clear previous recording files and
      // update state
      resetAllValues();

      //if user quickly released tap than Socket continue emit the data
      //So need to check before starting mic streaming
      if (micButtonStatus.value == MicButtonStatus.pressed) {
        await playBeepSound();
        await vibrateDevice();
        // wait until beep sound finished
        await Future.delayed(const Duration(milliseconds: 600));

        recordingStartTime = DateTime.now();
        if (_hiveDBInstance.get(isStreamingPreferred)) {
          connectToSocket();

          _socketIOClient.socketEmit(
            emittingStatus: 'start',
            emittingData: [
              APIConstants.createSocketIOComputePayload(
                  srcLanguage: selectedSourceLanguageCode.value,
                  targetLanguage: selectedTargetLanguageCode.value,
                  preferredGender:
                      _hiveDBInstance.get(preferredVoiceAssistantGender))
            ],
            isDataToSend: true,
          );

          MicStream.microphone(
                  audioSource: AudioSource.DEFAULT,
                  sampleRate: 44100,
                  channelConfig: ChannelConfig.CHANNEL_IN_MONO,
                  audioFormat: AudioFormat.ENCODING_PCM_16BIT)
              .then((stream) {
            List<int> checkSilenceList = List.generate(silenceSize, (i) => 0);
            micStreamSubscription = stream?.listen((value) {
              double meanSquared = meanSquare(value.buffer.asInt8List());
              _socketIOClient.socketEmit(
                  emittingStatus: 'data',
                  emittingData: [
                    {
                      "audio": [
                        {"audioContent": value}
                      ]
                    },
                    {"response_depth": 1},
                    false,
                    false
                  ],
                  isDataToSend: true);

              if (meanSquared >= 0.3) {
                checkSilenceList.add(0);
              }
              if (meanSquared < 0.3) {
                checkSilenceList.add(1);

                if (checkSilenceList.length > silenceSize) {
                  checkSilenceList = checkSilenceList
                      .sublist(checkSilenceList.length - silenceSize);
                }
                int sumValue = checkSilenceList
                    .reduce((value, element) => value + element);
                if (sumValue == silenceSize) {
                  _socketIOClient.socketEmit(
                      emittingStatus: 'data',
                      emittingData: [
                        {
                          "audio": [
                            {"audioContent": value}
                          ]
                        },
                        {"response_depth": 2},
                        true,
                        false
                      ],
                      isDataToSend: true);
                  checkSilenceList.clear();
                }
              }
            });
          });
        } else {
          stopWatchTimer.onStartTimer();
          await _voiceRecorder.startRecordingVoice(samplingRate);
        }
      }
    } else {
      showDefaultSnackbar(message: errorMicPermission.tr);
    }
  }

  void stopVoiceRecordingAndGetResult() async {
    await playBeepSound();
    await vibrateDevice();

    int timeTakenForLastRecording = stopWatchTimer.rawTime.value;
    stopWatchTimer.onResetTimer();

    if (timeTakenForLastRecording < tapAndHoldMinDuration &&
        isMicPermissionGranted) {
      showDefaultSnackbar(message: tapAndHoldForRecording.tr);
      if (!_hiveDBInstance.get(isStreamingPreferred)) {
        return;
      }
    }

    recordingStartTime = null;

    if (_hiveDBInstance.get(isStreamingPreferred)) {
      micStreamSubscription?.cancel();
      if (_socketIOClient.isMicConnected.value) {
        _socketIOClient.socketEmit(
            emittingStatus: 'data',
            emittingData: [
              null,
              {"response_depth": 2},
              true,
              true
            ],
            isDataToSend: true);
        await Future.delayed(const Duration(seconds: 5));
      }
      _socketIOClient.disconnect();
    } else {
      if (await _voiceRecorder.isVoiceRecording()) {
        String? base64EncodedAudioContent =
            await _voiceRecorder.stopRecordingVoiceAndGetOutput();
        String recordedAudioPath = _voiceRecorder.getAudioFilePath()!;
        currentMic.value == CurrentlySelectedMic.source
            ? sourceLangTTSPath.value = recordedAudioPath
            : targetLangTTSPath.value = recordedAudioPath;
        if (base64EncodedAudioContent == null ||
            base64EncodedAudioContent.isEmpty) {
          showDefaultSnackbar(message: errorInRecording.tr);
          return;
        } else {
          await getComputeResponseASRTrans(
              isRecorded: true, base64Value: base64EncodedAudioContent);
          isRecordedViaMic.value = true;
        }
      }
    }
  }

  Future<void> getComputeResponseASRTrans({
    required bool isRecorded,
    String? base64Value,
    String? sourceText,
  }) async {
    isLoading.value = true;
    String asrServiceId = '';
    String translationServiceId = '';

    String sourceLangCode = '', targetLangCode = '';
    if (currentMic.value == CurrentlySelectedMic.target) {
      sourceLangCode = selectedTargetLanguageCode.value;
      targetLangCode = selectedSourceLanguageCode.value;
    } else {
      sourceLangCode = selectedSourceLanguageCode.value;
      targetLangCode = selectedTargetLanguageCode.value;
    }

    asrServiceId = APIConstants.getTaskTypeServiceID(
            _languageModelController.taskSequenceResponse,
            'asr',
            sourceLangCode) ??
        '';
    translationServiceId = APIConstants.getTaskTypeServiceID(
            _languageModelController.taskSequenceResponse,
            'translation',
            sourceLangCode,
            targetLangCode) ??
        '';

    var asrPayloadToSend = APIConstants.createComputePayloadASRTrans(
        srcLanguage: sourceLangCode,
        targetLanguage: targetLangCode,
        isRecorded: isRecorded,
        inputData: isRecorded ? base64Value! : sourceText!,
        audioFormat: Platform.isIOS ? 'flac' : 'wav',
        asrServiceID: asrServiceId,
        translationServiceID: translationServiceId,
        preferredGender: _hiveDBInstance.get(preferredVoiceAssistantGender),
        samplingRate: samplingRate);

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
        String targetOutputText = taskResponse.pipelineResponse
                ?.firstWhere((element) => element.taskType == 'translation')
                .output
                ?.first
                .target
                ?.trim() ??
            '';
        if (targetOutputText.isEmpty) {
          // something went wrong in API call
          isLoading.value = false;
          showDefaultSnackbar(message: responseNotReceived.tr);
          return;
        }

        String sourceOutputText = taskResponse.pipelineResponse
                ?.firstWhere((element) => element.taskType == 'asr')
                .output
                ?.first
                .source
                ?.trim() ??
            '';

        // if voice recorded from target mic, then add source response value in it

        if (currentMic.value == CurrentlySelectedMic.source) {
          sourceLangTextController.text = sourceOutputText;
          targetLangTextController.text = targetOutputText;
          this.sourceOutputText.value = sourceOutputText;
          this.targetOutputText.value = targetOutputText;
          targetLangTTSPath.value = '';

          await getComputeResTTS(
            sourceText: targetOutputText,
            languageCode: targetLangCode,
            isTargetLanguage: true,
            // shouldPlayAudio: true
          );
        } else {
          targetLangTextController.text = sourceOutputText;
          sourceLangTextController.text = targetOutputText;
          this.targetOutputText.value = sourceOutputText;
          this.sourceOutputText.value = targetOutputText;
          sourceLangTTSPath.value = '';
          await getComputeResTTS(
            sourceText: targetOutputText,
            languageCode: targetLangCode,
            isTargetLanguage: false,
            // shouldPlayAudio: true
          );
        }
        sourceSpeakerStatus.value = SpeakerStatus.stopped;
        targetSpeakerStatus.value = SpeakerStatus.stopped;
        playTTSOutput(currentMic.value != CurrentlySelectedMic.source);
        isTranslateCompleted.value = true;
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
              ? targetLangTTSPath.value = ttsFilePath
              : sourceLangTTSPath.value = ttsFilePath;
          ttsAudioFile = File(ttsFilePath);
          if (ttsAudioFile != null && !await ttsAudioFile!.exists()) {
            await ttsAudioFile?.writeAsBytes(fileAsBytes);
          }
          isLoading.value = false;
        } else {
          showDefaultSnackbar(message: noVoiceAssistantAvailable.tr);
          return;
        }
      },
      failure: (error) {
        showDefaultSnackbar(
            message: error.message ?? APIConstants.kErrorMessageGenericError);
        return;
      },
    );
  }

  void playTTSOutput(bool isPlayingSource) async {
    String? audioPath = '';
    if (isPlayingSource && isRecordedViaMic.value) {
      audioPath = sourceLangTTSPath.value;
    } else {
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
    }

    if (audioPath.isNotEmpty) {
      isPlayingSource
          ? sourceSpeakerStatus.value = SpeakerStatus.playing
          : targetSpeakerStatus.value = SpeakerStatus.playing;

      await prepareWaveforms(audioPath,
          isRecordedAudio: true, isTargetLanguage: !isPlayingSource);
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

  Future<void> resetAllValues() async {
    sourceLangTextController.clear();
    targetLangTextController.clear();
    isTranslateCompleted.value = false;
    isRecordedViaMic.value = false;
    ttsResponse = null;
    maxDuration.value = 0;
    currentDuration.value = 0;
    await stopPlayer();
    sourceSpeakerStatus.value = SpeakerStatus.disabled;
    targetSpeakerStatus.value = SpeakerStatus.disabled;
    sourceOutputText.value = '';
    targetOutputText.value = '';
    sourceLangTTSPath.value = '';
    targetLangTTSPath.value = '';
    isSourceShareLoading.value = false;
    isTargetShareLoading.value = false;
  }

  Future<void> prepareWaveforms(
    String filePath, {
    required bool isRecordedAudio,
    required bool isTargetLanguage,
  }) async {
    await stopPlayer();
    if (isTargetLanguage)
      targetSpeakerStatus.value = SpeakerStatus.playing;
    else
      sourceSpeakerStatus.value = SpeakerStatus.playing;
    await controller.preparePlayer(
        path: filePath,
        noOfSamples: WaveformStyle.getDefaultPlayerStyle(
                isRecordedAudio: isRecordedAudio)
            .getSamplesForWidth(WaveformStyle.getDefaultWidth));
    maxDuration.value = controller.maxDuration;
    startOrStopPlayer();
  }

  void startOrStopPlayer() async {
    controller.playerState.isPlaying
        ? await controller.pausePlayer()
        : await controller.startPlayer(
            finishMode: FinishMode.pause,
          );
  }

  disposePlayer() async {
    await stopPlayer();
    controller.dispose();
  }

  Future<void> stopPlayer() async {
    if (controller.playerState.isPlaying ||
        controller.playerState == PlayerState.paused) {
      await controller.stopPlayer();
    }
    targetSpeakerStatus.value = SpeakerStatus.stopped;
    sourceSpeakerStatus.value = SpeakerStatus.stopped;
  }

  void connectToSocket() {
    if (_socketIOClient.isConnected()) {
      _socketIOClient.disconnect();
    }
    _socketIOClient.socketConnect();
  }

  double meanSquare(Int8List value) {
    var sqrValue = 0;
    for (int indValue in value) {
      sqrValue = indValue * indValue;
    }
    return (sqrValue / value.length) * 1000;
  }

  Future<void> vibrateDevice() async {
    await Vibration.cancel();
    if (await Vibration.hasVibrator() ?? false) {
      if (await Vibration.hasCustomVibrationsSupport() ?? false) {
        await Vibration.vibrate(duration: 130);
      } else {
        await Vibration.vibrate();
      }
    }
  }

  Future<void> playBeepSound() async {
    if (_playerController.playerState == PlayerState.playing ||
        _playerController.playerState == PlayerState.paused) {
      await _playerController.stopPlayer();
    }
    await _playerController.preparePlayer(
      path: beepSoundFile.path,
      shouldExtractWaveform: false,
    );
    await _playerController.startPlayer(finishMode: FinishMode.pause);
  }

  void updateSamplingRate(ConnectivityResult newConnectivity) {
    if (newConnectivity == ConnectivityResult.mobile) {
      samplingRate = 8000;
    } else {
      samplingRate = 16000;
    }
  }
}
