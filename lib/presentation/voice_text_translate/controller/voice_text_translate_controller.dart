import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:vibration/vibration.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

import '../../../common/controller/language_model_controller.dart';
import '../../../enums/speaker_status.dart';
import '../../../enums/mic_button_status.dart';
import '../../../services/dhruva_api_client.dart';
import '../../../services/socket_io_client.dart';
import '../../../utils/constants/api_constants.dart';
import '../../../utils/constants/app_constants.dart';
import '../../../utils/constants/language_map_translated.dart';
import '../../../utils/file_helper.dart';
import '../../../utils/network_utils.dart';
import '../../../utils/permission_handler.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../utils/voice_recorder.dart';
import '../../../i18n/strings.g.dart' as i18n;

class VoiceTextTranslateController extends GetxController {
  late DHRUVAAPIClient _dhruvaapiClient;
  late LanguageModelController _languageModelController;

  TextEditingController sourceLangTextController = TextEditingController(),
      targetLangTextController = TextEditingController();

  final ScrollController transliterationHintsScrollController =
      ScrollController();

  bool isMicPermissionGranted = false;
  RxBool isTranslateCompleted = false.obs,
      isLoading = false.obs,
      isKeyboardVisible = false.obs,
      isScrolledTransliterationHints = false.obs,
      isRecordedViaMic = false.obs,
      isSourceShareLoading = false.obs,
      isTargetShareLoading = false.obs,
      expandFeedbackIcon = true.obs;
  RxString selectedSourceLanguageCode = ''.obs,
      selectedTargetLanguageCode = ''.obs,
      targetOutputText = ''.obs,
      sourceLangTTSPath = ''.obs,
      targetLangTTSPath = ''.obs;
  String? sourceLangASRPath = '';
  RxInt maxDuration = 0.obs,
      currentDuration = 0.obs,
      sourceTextCharLimit = 0.obs;
  RxList transliterationWordHints = [].obs;
  String currentlyTypedWordForTransliteration = '', lastFinalOutput = '';
  Rx<MicButtonStatus> micButtonStatus = Rx(MicButtonStatus.released);
  Rx<SpeakerStatus> sourceSpeakerStatus = Rx(SpeakerStatus.disabled),
      targetSpeakerStatus = Rx(SpeakerStatus.disabled);

  List<dynamic> sourceLangListRegular = [],
      sourceLangListBeta = [],
      targetLangListRegular = [],
      targetLangListBeta = [];

  List<int> recordedData = [];
  late StreamSubscription<List<int>> listener;
  final VoiceRecorder _voiceRecorder = VoiceRecorder();
  final stopWatchTimer = StopWatchTimer(mode: StopWatchMode.countUp);
  late final just_audio.AudioPlayer player;
  StreamSubscription<List<int>>? micStreamSubscription;
  DateTime? recordingStartTime;
  int samplingRate = 16000, lastOffsetOfCursor = 0;
  late Worker streamingResponseListener,
      socketIOErrorListener,
      socketConnectionListener;

  late SocketIOClient _socketIOClient;

  late final Box _hiveDBInstance;
  Map<String, dynamic> lastComputeRequest = {};
  Map<String, dynamic> lastComputeResponse = {};

  @override
  void onInit() {
    _dhruvaapiClient = Get.find();
    _socketIOClient = Get.find();
    _languageModelController = Get.find();
    _hiveDBInstance = Hive.box(hiveDBName);
    player = just_audio.AudioPlayer();

//  Connectivity listener
    Connectivity()
        .checkConnectivity()
        .then((newConnectivity) => updateSamplingRate(newConnectivity));

    Connectivity().onConnectivityChanged.listen(
          (newConnectivity) => updateSamplingRate(newConnectivity),
        );

// Audio player current duration listener
    player.positionStream.listen((duration) {
      currentDuration.value = duration.inMilliseconds;
    });

    player.playerStateStream.listen((state) {
      if (state.processingState == just_audio.ProcessingState.completed) {
        currentDuration.value = 0;
        sourceSpeakerStatus.value = SpeakerStatus.stopped;
        targetSpeakerStatus.value = SpeakerStatus.stopped;
      }
    });

// Transliteration listener
    sourceLangTextController
        .addListener(clearTransliterationHintsIfCursorMoved);

    transliterationHintsScrollController.addListener(() {
      isScrolledTransliterationHints.value = true;
    });

// Stopwatch listener for mic recording time
    stopWatchTimer.rawTime.listen((event) {
      if (micButtonStatus.value == MicButtonStatus.pressed &&
          (event + 1) >= recordingMaxTimeLimit) {
        stopWatchTimer.onStopTimer();
        micButtonStatus.value = MicButtonStatus.released;
        stopVoiceRecordingAndGetResult();
      }
    });

    super.onInit();

// Socket IO connection listeners
    socketConnectionListener =
        ever(_socketIOClient.isMicConnected, (isConnected) async {
      if (isConnected) {
        stopWatchTimer.onStartTimer();
      }
    }, condition: () => _socketIOClient.isMicConnected.value);

// Socket IO response listeners
    streamingResponseListener =
        ever(_socketIOClient.socketResponse, (response) async {
      await displaySocketIOResponse(response);
      if (!isRecordedViaMic.value) isRecordedViaMic.value = true;
      if (!_socketIOClient.isMicConnected.value) {
        isRecordedViaMic.value = true;
        sourceSpeakerStatus.value = SpeakerStatus.stopped;
        sourceLangASRPath =
            await saveStreamAudioToFile(recordedData, samplingRate);

        var socketIOInputData = json.encode({
          APIConstants.kData: [
            {
              APIConstants.kAudio: [
                {
                  APIConstants.kAudioContent:
                      base64Encode(File(sourceLangASRPath!).readAsBytesSync())
                }
              ]
            },
            {APIConstants.kResTaskSequenceDepth: 2},
            true,
            true
          ]
        });
        lastComputeRequest[APIConstants.kInputData] =
            json.decode(socketIOInputData);
        lastComputeResponse = response[0];
      }
    }, condition: () => _socketIOClient.isMicConnected.value);

// Socket IO error listeners
    socketIOErrorListener = ever(_socketIOClient.hasError, (isAborted) {
      if (isAborted && micButtonStatus.value == MicButtonStatus.pressed) {
        micButtonStatus.value = MicButtonStatus.released;
        showDefaultSnackbar(
            message: _socketIOClient.socketError ?? i18n.t.somethingWentWrong);
      }
    }, condition: !_socketIOClient.isConnected());
  }

  @override
  void onClose() async {
    sourceLangTextController
        .removeListener(clearTransliterationHintsIfCursorMoved);
    streamingResponseListener.dispose();
    socketIOErrorListener.dispose();
    socketConnectionListener.dispose();
    _socketIOClient.disconnect();
    sourceLangTextController.dispose();
    targetLangTextController.dispose();
    await stopWatchTimer.dispose();
    disposePlayer();
    super.onClose();
  }

  void getSourceTargetLangFromDB() {
    String? selectedSourceLanguage =
        _hiveDBInstance.get(preferredSourceLanguage);

    if (selectedSourceLanguage == null || selectedSourceLanguage.isEmpty) {
      selectedSourceLanguage = _hiveDBInstance.get(preferredAppLocale);
    }

    if (_languageModelController.sourceTargetLanguageMap.keys
            .toList()
            .contains(selectedSourceLanguage) &&
        !voiceSkipSourceLang.contains(selectedSourceLanguage)) {
      selectedSourceLanguageCode.value = selectedSourceLanguage ?? '';
    }

    String? selectedTargetLanguage =
        _hiveDBInstance.get(preferredTargetLanguage);
    if (selectedTargetLanguage != null &&
        selectedTargetLanguage.isNotEmpty &&
        selectedSourceLanguageCode.value.isNotEmpty &&
        _languageModelController
            .sourceTargetLanguageMap[selectedSourceLanguageCode.value]!
            .toList()
            .contains(selectedTargetLanguage) &&
        !voiceSkipTargetLang.contains(selectedTargetLanguage)) {
      selectedTargetLanguageCode.value = selectedTargetLanguage;
    }
  }

  void swapSourceAndTargetLanguage() {
    bool isTargetLangSkippedInSource =
        voiceSkipTargetLang.contains(selectedSourceLanguageCode.value);

    bool isSourceLangSkippedInTarget =
        voiceSkipSourceLang.contains(selectedTargetLanguageCode.value);

    if (isSourceAndTargetLangSelected()) {
      if (_languageModelController.sourceTargetLanguageMap.keys
              .contains(selectedTargetLanguageCode.value) &&
          _languageModelController
                  .sourceTargetLanguageMap[selectedTargetLanguageCode.value] !=
              null &&
          _languageModelController
              .sourceTargetLanguageMap[selectedTargetLanguageCode.value]!
              .contains(selectedSourceLanguageCode.value) &&
          !isTargetLangSkippedInSource &&
          !isSourceLangSkippedInTarget) {
        String tempSourceLanguage = selectedSourceLanguageCode.value;
        selectedSourceLanguageCode.value = selectedTargetLanguageCode.value;
        selectedTargetLanguageCode.value = tempSourceLanguage;
        _hiveDBInstance.put(
            preferredSourceLanguage, selectedSourceLanguageCode.value);
        _hiveDBInstance.put(
            preferredTargetLanguage, selectedTargetLanguageCode.value);
        setSourceLanguageList();
        setTargetLanguageList();
        resetAllValues();
      } else {
        showDefaultSnackbar(
            message:
                '${APIConstants.getLanNameInAppLang(selectedTargetLanguageCode.value)} - ${APIConstants.getLanNameInAppLang(selectedSourceLanguageCode.value)} ${i18n.t.translationNotPossible}');
      }
    } else {
      showDefaultSnackbar(message: i18n.t.kErrorSelectSourceAndTargetScreen);
    }
  }

  bool isSourceAndTargetLangSelected() =>
      selectedSourceLanguageCode.value.isNotEmpty &&
      selectedTargetLanguageCode.value.isNotEmpty;

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
        await vibrateDevice();

        recordingStartTime = DateTime.now();
        if (_hiveDBInstance.get(isStreamingPreferred)) {
          connectToSocket();

          List<Map<String, dynamic>> initialRequestData =
              APIConstants.createSocketIOComputePayload(
                  srcLanguage: selectedSourceLanguageCode.value,
                  targetLanguage: selectedTargetLanguageCode.value,
                  preferredGender:
                      _hiveDBInstance.get(preferredVoiceAssistantGender));

          lastComputeRequest[APIConstants.kPipelineTasks] = initialRequestData;

          _socketIOClient.socketEmit(
            emittingStatus: APIConstants.kStart,
            emittingData: [
              initialRequestData,
              {APIConstants.kResFrequencyInSecs: 1}
            ],
            isDataToSend: true,
          );

          micStreamSubscription = MicStream.microphone(
                  audioSource: AudioSource.DEFAULT,
                  sampleRate: samplingRate,
                  channelConfig: ChannelConfig.CHANNEL_IN_MONO,
                  audioFormat: AudioFormat.ENCODING_PCM_16BIT)
              .listen((value) {
            _socketIOClient.socketEmit(
                emittingStatus: APIConstants.kData,
                emittingData: [
                  {
                    APIConstants.kAudio: [
                      {APIConstants.kAudioContent: value.sublist(0)}
                    ]
                  },
                  {APIConstants.kResTaskSequenceDepth: 2},
                  false,
                  false
                ],
                isDataToSend: true);
            recordedData.addAll(value.sublist(0));
          });
        } else {
          stopWatchTimer.onStartTimer();
          await _voiceRecorder.startRecordingVoice(samplingRate);
        }
      }
    } else {
      showDefaultSnackbar(message: i18n.t.errorMicPermission);
    }
  }

  void stopVoiceRecordingAndGetResult() async {
    await vibrateDevice();

    int timeTakenForLastRecording = stopWatchTimer.rawTime.value;
    stopWatchTimer.onResetTimer();

    if (timeTakenForLastRecording < tapAndHoldMinDuration &&
        isMicPermissionGranted) {
      showDefaultSnackbar(message: i18n.t.tapAndHoldForRecording);
      if (!_hiveDBInstance.get(isStreamingPreferred)) {
        return;
      }
    }

    recordingStartTime = null;

    if (_hiveDBInstance.get(isStreamingPreferred)) {
      micStreamSubscription?.cancel();
      if (_socketIOClient.isMicConnected.value) {
        _socketIOClient.socketEmit(
            emittingStatus: APIConstants.kData,
            emittingData: [
              null,
              {APIConstants.kResTaskSequenceDepth: 2},
              true,
              true
            ],
            isDataToSend: true);
        micButtonStatus.value = MicButtonStatus.loading;
      }
    } else {
      if (await _voiceRecorder.isVoiceRecording()) {
        String? base64EncodedAudioContent =
            await _voiceRecorder.stopRecordingVoiceAndGetOutput();
        sourceLangASRPath = _voiceRecorder.getAudioFilePath()!;
        if (base64EncodedAudioContent == null ||
            base64EncodedAudioContent.isEmpty) {
          showDefaultSnackbar(message: i18n.t.errorInRecording);
          return;
        } else {
          await getComputeResponseASRTrans(
              isRecorded: true, base64Value: base64EncodedAudioContent);
          isRecordedViaMic.value = true;
        }
      }
    }
  }

  Future<void> getTransliterationOutput(String sourceText) async {
    currentlyTypedWordForTransliteration = sourceText;

    String transliterationServiceId = '';

    transliterationServiceId = APIConstants.getTaskTypeServiceID(
          _languageModelController.transliterationConfigResponse!,
          APIConstants.kTransliteration,
          defaultLangCode,
          selectedSourceLanguageCode.value,
        ) ??
        '';

    var transliterationPayloadToSend = APIConstants.createComputePayload(
        srcLanguage: defaultLangCode,
        targetLanguage: selectedSourceLanguageCode.value,
        isRecorded: false,
        inputData: sourceText,
        transliterationServiceID: transliterationServiceId,
        isTransliteration: true);

    var response = await _dhruvaapiClient.sendComputeRequest(
        baseUrl: _languageModelController.transliterationConfigResponse
            ?.pipelineInferenceAPIEndPoint?.callbackUrl,
        authorizationKey: _languageModelController.transliterationConfigResponse
            ?.pipelineInferenceAPIEndPoint?.inferenceApiKey?.name,
        authorizationValue: _languageModelController
            .transliterationConfigResponse
            ?.pipelineInferenceAPIEndPoint
            ?.inferenceApiKey
            ?.value,
        computePayload: transliterationPayloadToSend);

    response.when(
      success: (data) async {
        if (currentlyTypedWordForTransliteration ==
            data.pipelineResponse?.first.output?.first.source) {
          transliterationWordHints.value =
              data.pipelineResponse?.first.output?.first.target;
          if (!transliterationWordHints
              .contains(currentlyTypedWordForTransliteration)) {
            transliterationWordHints.add(currentlyTypedWordForTransliteration);
          }
        }
      },
      failure: (_) {},
    );
  }

  Future<void> getComputeResponseASRTrans({
    required bool isRecorded,
    String? base64Value,
    bool clearSourceTTS = true,
  }) async {
    isLoading.value = true;
    String asrServiceId = '';
    String translationServiceId = '';

    asrServiceId = APIConstants.getTaskTypeServiceID(
            _languageModelController.taskSequenceResponse,
            APIConstants.kASR,
            selectedSourceLanguageCode.value) ??
        '';
    translationServiceId = APIConstants.getTaskTypeServiceID(
            _languageModelController.taskSequenceResponse,
            APIConstants.kTranslation,
            selectedSourceLanguageCode.value,
            selectedTargetLanguageCode.value) ??
        '';

    var asrPayloadToSend = APIConstants.createComputePayload(
        srcLanguage: selectedSourceLanguageCode.value,
        targetLanguage: selectedTargetLanguageCode.value,
        isRecorded: isRecorded,
        inputData: isRecorded ? base64Value! : sourceLangTextController.text,
        audioFormat: Platform.isIOS ? APIConstants.kFlac : APIConstants.kWav,
        asrServiceID: asrServiceId,
        translationServiceID: translationServiceId,
        preferredGender: _hiveDBInstance.get(preferredVoiceAssistantGender),
        samplingRate: samplingRate);

    lastComputeRequest = asrPayloadToSend;

    var response = await _dhruvaapiClient.sendComputeRequest(
        baseUrl: _languageModelController
            .taskSequenceResponse.pipelineInferenceAPIEndPoint?.callbackUrl,
        authorizationKey: _languageModelController.taskSequenceResponse
            .pipelineInferenceAPIEndPoint?.inferenceApiKey?.name,
        authorizationValue: _languageModelController.taskSequenceResponse
            .pipelineInferenceAPIEndPoint?.inferenceApiKey?.value,
        computePayload: asrPayloadToSend);
    json.encode(asrPayloadToSend);
    response.when(
      success: (taskResponse) async {
        lastComputeResponse = taskResponse.toJson();
        if (isRecorded) {
          sourceLangTextController.text = taskResponse.pipelineResponse
                  ?.firstWhere(
                      (element) => element.taskType == APIConstants.kASR)
                  .output
                  ?.first
                  .source
                  ?.trim() ??
              '';
        }
        targetOutputText.value = taskResponse.pipelineResponse
                ?.firstWhere(
                    (element) => element.taskType == APIConstants.kTranslation)
                .output
                ?.first
                .target
                ?.trim() ??
            '';
        if (targetOutputText.value.isEmpty) {
          isLoading.value = false;
          showDefaultSnackbar(message: i18n.t.responseNotReceived);
          return;
        }
        targetLangTextController.text = targetOutputText.value;
        isTranslateCompleted.value = true;
        isLoading.value = false;
        Future.delayed(const Duration(seconds: 3))
            .then((value) => expandFeedbackIcon.value = false);
        if (clearSourceTTS) sourceLangTTSPath.value = '';
        targetLangTTSPath.value = '';
        sourceSpeakerStatus.value = SpeakerStatus.stopped;
        targetSpeakerStatus.value = SpeakerStatus.stopped;
      },
      failure: (error) {
        isLoading.value = false;
        showDefaultSnackbar(message: i18n.t.somethingWentWrong);
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
            APIConstants.kTTS,
            languageCode) ??
        '';

    var asrPayloadToSend = APIConstants.createComputePayloadTTS(
      srcLanguage: languageCode,
      inputData: sourceText,
      ttsServiceID: ttsServiceId,
      preferredGender: _hiveDBInstance.get(preferredVoiceAssistantGender),
      samplingRate: samplingRate,
    );

    lastComputeRequest[APIConstants.kPipelineTasks]
        .addAll(asrPayloadToSend[APIConstants.kPipelineTasks]);

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
        lastComputeResponse[APIConstants.kPipelineResponse]
            .addAll(taskResponse.toJson()[APIConstants.kPipelineResponse]);
        dynamic ttsResponse = taskResponse.pipelineResponse
            ?.firstWhere((element) => element.taskType == APIConstants.kTTS)
            .audio?[0]
            .audioContent;

        // Save TTS audio to file
        if (ttsResponse != null) {
          String ttsFilePath = await createTTSAudioFIle(ttsResponse);
          isTargetLanguage
              ? targetLangTTSPath.value = ttsFilePath
              : sourceLangTTSPath.value = ttsFilePath;
        } else {
          showDefaultSnackbar(message: i18n.t.noVoiceAssistantAvailable);
          return;
        }
      },
      failure: (error) {
        isTargetLanguage
            ? targetSpeakerStatus.value = SpeakerStatus.stopped
            : sourceSpeakerStatus.value = SpeakerStatus.stopped;
        showDefaultSnackbar(message: i18n.t.somethingWentWrong);
        return;
      },
    );
  }

  bool isTransliterationEnabled() {
    return _hiveDBInstance.get(enableTransliteration, defaultValue: true) &&
        selectedSourceLanguageCode.value != defaultLangCode &&
        _languageModelController.transliterationConfigResponse != null;
  }

  void clearTransliterationHints() {
    transliterationWordHints.clear();
    currentlyTypedWordForTransliteration = '';
  }

  Future<void> preparePlayer(
    String filePath, {
    required bool isRecordedAudio,
    required bool isTargetLanguage,
  }) async {
    await stopPlayer();
    if (isTargetLanguage) {
      targetSpeakerStatus.value = SpeakerStatus.playing;
    } else {
      sourceSpeakerStatus.value = SpeakerStatus.playing;
    }
    startOrPausePlayer(filePath);
  }

  void startOrPausePlayer(String filePath) async {
    if (player.playing) {
      await player.stop();
    } else {
      await player.setFilePath(filePath);
      maxDuration.value = player.duration!.inMilliseconds;
      await player.play();
    }
  }

  Future<void> stopPlayer() async {
    if (player.playing) {
      await player.stop();
    }
    targetSpeakerStatus.value = SpeakerStatus.stopped;
    sourceSpeakerStatus.value = SpeakerStatus.stopped;
  }

  void clearTransliterationHintsIfCursorMoved() {
    int difference =
        lastOffsetOfCursor - sourceLangTextController.selection.base.offset;
    if (difference > 0 || difference < -1) {
      clearTransliterationHints();
    }
    lastOffsetOfCursor = sourceLangTextController.selection.base.offset;
  }

  void shareAudioFile({required bool isSourceLang}) async {
    if (isTranslateCompleted.value) {
      String? audioPathToShare = isSourceLang
          ? isRecordedViaMic.value
              ? sourceLangASRPath
              : sourceLangTTSPath.value
          : targetLangTTSPath.value;

      if (audioPathToShare == null || audioPathToShare.isEmpty) {
        if (!await isNetworkConnected()) {
          showDefaultSnackbar(message: i18n.t.errorNoInternetTitle);
          return;
        }

        String sourceText = isSourceLang
            ? sourceLangTextController.text
            : targetLangTextController.text;

        String languageCode = isSourceLang
            ? selectedSourceLanguageCode.value
            : selectedTargetLanguageCode.value;

        if (sourceText.isEmpty) {
          showDefaultSnackbar(message: i18n.t.noAudioFoundToShare);
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
            0, 0, ScreenUtil().screenWidth, ScreenUtil().screenHeight / 2),
      );
    } else {
      showDefaultSnackbar(message: i18n.t.noAudioFoundToShare);
    }
  }

  void connectToSocket() {
    if (_socketIOClient.isConnected()) {
      _socketIOClient.disconnect();
    }
    _socketIOClient.socketConnect();
  }

  Future<void> displaySocketIOResponse(response) async {
    if (response != null) {
      //  used for get ASR
      sourceLangTextController.text = response[0]
                  [APIConstants.kPipelineResponse]?[0][APIConstants.kOutput]?[0]
              [APIConstants.kSource] ??
          '';

      // used for get Translation
      if ((response[0][APIConstants.kPipelineResponse].length ?? 0) > 1) {
        String targetText = response[0][APIConstants.kPipelineResponse][1]
                [APIConstants.kOutput]?[0][APIConstants.kTarget] ??
            '';
        targetLangTextController.text = targetText;
        targetOutputText.value = targetText;

        //  used for get TTS
        if ((response[0][APIConstants.kPipelineResponse].length ?? 0) > 2) {
          String ttsResponse = response[0][APIConstants.kPipelineResponse][2]
              [APIConstants.kAudio][0][APIConstants.kAudioContent];
          isTranslateCompleted.value = true;
          isLoading.value = false;
          Future.delayed(const Duration(seconds: 3))
              .then((value) => expandFeedbackIcon.value = false);
          sourceLangTTSPath.value = '';
          targetLangTTSPath.value = '';
          sourceSpeakerStatus.value = SpeakerStatus.stopped;
          targetSpeakerStatus.value = SpeakerStatus.stopped;
          if (ttsResponse.isNotEmpty) {
            targetLangTTSPath.value = '';
            String ttsFilePath = await createTTSAudioFIle(ttsResponse);
            targetLangTTSPath.value = ttsFilePath;
          }
          // disconnect socket io after final response received
          micButtonStatus.value = MicButtonStatus.released;
          _socketIOClient.disconnect();
        }
      }
    }
  }

  void updateSamplingRate(ConnectivityResult newConnectivity) {
    if (newConnectivity == ConnectivityResult.mobile) {
      samplingRate = 8000;
    } else {
      samplingRate = 16000;
    }
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

  void playStopTTSOutput(bool isPlayingSource) async {
    if (player.playing) {
      await stopPlayer();
      return;
    }

    String? audioPath = '';

    if (isPlayingSource && isRecordedViaMic.value) {
      audioPath = sourceLangASRPath;
    } else {
      if (isPlayingSource) {
        if (sourceLangTTSPath.value.isEmpty) {
          if (!await isNetworkConnected()) {
            showDefaultSnackbar(message: i18n.t.errorNoInternetTitle);
            return;
          }
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
          if (!await isNetworkConnected()) {
            showDefaultSnackbar(message: i18n.t.errorNoInternetTitle);
            return;
          }
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

    if (audioPath != null && audioPath.isNotEmpty) {
      isPlayingSource
          ? sourceSpeakerStatus.value = SpeakerStatus.playing
          : targetSpeakerStatus.value = SpeakerStatus.playing;

      await preparePlayer(audioPath,
          isRecordedAudio: isPlayingSource && isRecordedViaMic.value,
          isTargetLanguage: !isPlayingSource);
    }
  }

  setSourceLanguageList() {
    sourceLangListRegular.clear();
    sourceLangListBeta.clear();

    sourceLangListRegular =
        _languageModelController.sourceTargetLanguageMap.keys.toList();

    for (int i = 0; i < sourceLangListRegular.length; i++) {
      var language = sourceLangListRegular[i];
      if (voiceSkipSourceLang.contains(language)) {
        sourceLangListRegular.removeAt(i);
        i--;
      } else if (voiceBetaSourceLang.contains(language)) {
        sourceLangListBeta.add(sourceLangListRegular[i]);
        sourceLangListRegular.removeAt(i);
        i--;
      }
    }
  }

  void setTargetLanguageList() {
    if (selectedSourceLanguageCode.value.isEmpty) {
      return;
    }

    targetLangListRegular.clear();
    targetLangListBeta.clear();

    targetLangListRegular = _languageModelController
        .sourceTargetLanguageMap[selectedSourceLanguageCode.value]!
        .toList();

    for (int i = 0; i < targetLangListRegular.length; i++) {
      var language = targetLangListRegular[i];
      if (voiceSkipTargetLang.contains(language)) {
        targetLangListRegular.removeAt(i);
        i--;
      } else if (voiceBetaTargetLang.contains(language)) {
        targetLangListBeta.add(targetLangListRegular[i]);
        targetLangListRegular.removeAt(i);
        i--;
      }
    }
  }

  Future<void> resetAllValues() async {
    sourceLangTextController.clear();
    targetLangTextController.clear();
    isTranslateCompleted.value = false;
    isRecordedViaMic.value = false;
    sourceTextCharLimit.value = 0;
    maxDuration.value = 0;
    currentDuration.value = 0;
    sourceLangASRPath = '';
    await stopPlayer();
    sourceSpeakerStatus.value = SpeakerStatus.disabled;
    targetSpeakerStatus.value = SpeakerStatus.disabled;
    targetOutputText.value = '';
    sourceLangASRPath = '';
    sourceLangTTSPath.value = '';
    targetLangTTSPath.value = '';
    recordedData = [];
    isSourceShareLoading.value = false;
    isTargetShareLoading.value = false;
    lastComputeRequest.clear();
    lastComputeResponse.clear();
    _socketIOClient.disconnect();
    if (isTransliterationEnabled()) {
      clearTransliterationHints();
    }
  }

  disposePlayer() async {
    await player.stop();
    await player.dispose();
  }
}
