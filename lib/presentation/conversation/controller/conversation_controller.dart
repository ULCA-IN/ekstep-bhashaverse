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
import '../../../enums/current_mic.dart';
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

class ConversationController extends GetxController {
  late DHRUVAAPIClient _dhruvaapiClient;
  late LanguageModelController _languageModelController;

  TextEditingController sourceLangTextController = TextEditingController();
  TextEditingController targetLangTextController = TextEditingController();

  RxBool isTranslateCompleted = false.obs;
  bool isMicPermissionGranted = false;
  RxBool isLoading = false.obs,
      isSourceShareLoading = false.obs,
      isTargetShareLoading = false.obs,
      expandFeedbackIcon = true.obs;
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
  Rx<MicButtonStatus> micButtonStatus = Rx(MicButtonStatus.released);
  Rx<SpeakerStatus> sourceSpeakerStatus = Rx(SpeakerStatus.disabled);
  Rx<SpeakerStatus> targetSpeakerStatus = Rx(SpeakerStatus.disabled);
  Rx<CurrentlySelectedMic> currentMic = Rx(CurrentlySelectedMic.none);
  String? base64EncodedAudioContent;
  String sourceLangCode = '', targetLangCode = '';

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
  int samplingRate = 16000;
  late Worker streamingResponseListener,
      socketIOErrorListener,
      socketConnectionListener;

  late SocketIOClient _socketIOClient;

  late final Box _hiveDBInstance;

  // for sending payload in feedback API
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
    Connectivity().checkConnectivity().then((newConnectivity) {
      updateSamplingRate(newConnectivity);
    });

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
        targetSpeakerStatus.value = SpeakerStatus.stopped;

        String recordedAudioPath =
            await saveStreamAudioToFile(recordedData, samplingRate);
        currentMic.value == CurrentlySelectedMic.source
            ? sourceLangTTSPath.value = recordedAudioPath
            : targetLangTTSPath.value = recordedAudioPath;
        base64EncodedAudioContent =
            base64Encode(File(recordedAudioPath).readAsBytesSync());

        var socketIOInputData = json.encode({
          APIConstants.kData: [
            {
              APIConstants.kAudio: [
                {APIConstants.kAudioContent: base64EncodedAudioContent}
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
        !converseSkipSourceLang.contains(selectedSourceLanguage)) {
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
            .contains(selectedTargetLanguage)) {
      selectedTargetLanguageCode.value = selectedTargetLanguage;
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

          getLanguageCodeBasedOnMic();

          List<Map<String, dynamic>> initialRequestData =
              APIConstants.createSocketIOComputePayload(
                  srcLanguage: sourceLangCode,
                  targetLanguage: targetLangCode,
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
                  sampleRate: 44100,
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
        base64EncodedAudioContent =
            await _voiceRecorder.stopRecordingVoiceAndGetOutput();
        String recordedAudioPath = _voiceRecorder.getAudioFilePath()!;
        currentMic.value == CurrentlySelectedMic.source
            ? sourceLangTTSPath.value = recordedAudioPath
            : targetLangTTSPath.value = recordedAudioPath;
        if (base64EncodedAudioContent == null ||
            (base64EncodedAudioContent ?? '').isEmpty) {
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

  Future<void> getComputeResponseASRTrans({
    required bool isRecorded,
    String? base64Value,
    String? sourceText,
  }) async {
    isLoading.value = true;
    String asrServiceId = '';
    String translationServiceId = '';

    getLanguageCodeBasedOnMic();

    asrServiceId = APIConstants.getTaskTypeServiceID(
            _languageModelController.taskSequenceResponse,
            APIConstants.kASR,
            sourceLangCode) ??
        '';
    translationServiceId = APIConstants.getTaskTypeServiceID(
            _languageModelController.taskSequenceResponse,
            APIConstants.kTranslation,
            sourceLangCode,
            targetLangCode) ??
        '';

    var asrPayloadToSend = APIConstants.createComputePayload(
        srcLanguage: sourceLangCode,
        targetLanguage: targetLangCode,
        isRecorded: isRecorded,
        inputData: isRecorded ? base64Value! : sourceText!,
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

    await response.when(
      success: (taskResponse) async {
        lastComputeResponse = taskResponse.toJson();
        String targetOutputText = taskResponse.pipelineResponse
                ?.firstWhere(
                    (element) => element.taskType == APIConstants.kTranslation)
                .output
                ?.first
                .target
                ?.trim() ??
            '';
        if (targetOutputText.isEmpty) {
          // something went wrong in API call
          isLoading.value = false;
          showDefaultSnackbar(message: i18n.t.responseNotReceived);
          return;
        }

        String sourceOutputText = taskResponse.pipelineResponse
                ?.firstWhere((element) => element.taskType == APIConstants.kASR)
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
          );
        }
        sourceSpeakerStatus.value = SpeakerStatus.stopped;
        targetSpeakerStatus.value = SpeakerStatus.stopped;
        isTranslateCompleted.value = true;
      },
      failure: (error) {
        isLoading.value = false;
        showDefaultSnackbar(message: i18n.t.somethingWentWrong);
      },
    );
  }

  void getLanguageCodeBasedOnMic() {
    if (currentMic.value == CurrentlySelectedMic.target) {
      sourceLangCode = selectedTargetLanguageCode.value;
      targetLangCode = selectedSourceLanguageCode.value;
    } else {
      sourceLangCode = selectedSourceLanguageCode.value;
      targetLangCode = selectedTargetLanguageCode.value;
    }
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

    var response = await _dhruvaapiClient.sendComputeRequest(
        baseUrl: _languageModelController
            .taskSequenceResponse.pipelineInferenceAPIEndPoint?.callbackUrl,
        authorizationKey: _languageModelController.taskSequenceResponse
            .pipelineInferenceAPIEndPoint?.inferenceApiKey?.name,
        authorizationValue: _languageModelController.taskSequenceResponse
            .pipelineInferenceAPIEndPoint?.inferenceApiKey?.value,
        computePayload: asrPayloadToSend);

    lastComputeRequest[APIConstants.kPipelineTasks]
        .addAll(asrPayloadToSend[APIConstants.kPipelineTasks]);

    response.when(
      success: (taskResponse) async {
        lastComputeResponse[APIConstants.kPipelineResponse]
            .addAll(taskResponse.toJson()[APIConstants.kPipelineResponse]);
        ttsResponse = taskResponse.pipelineResponse
            ?.firstWhere((element) => element.taskType == APIConstants.kTTS)
            .audio?[0]
            .audioContent;

        // Save and Play TTS audio
        if (ttsResponse != null) {
          String ttsFilePath = await createTTSAudioFIle(ttsResponse);
          isTargetLanguage
              ? targetLangTTSPath.value = ttsFilePath
              : sourceLangTTSPath.value = ttsFilePath;
          isLoading.value = false;
          playStopTTSOutput(!isTargetLanguage);
          Future.delayed(const Duration(seconds: 3))
              .then((value) => expandFeedbackIcon.value = false);
        } else {
          showDefaultSnackbar(message: i18n.t.noVoiceAssistantAvailable);
          return;
        }
      },
      failure: (error) {
        showDefaultSnackbar(message: i18n.t.somethingWentWrong);
        return;
      },
    );
  }

  void shareAudioFile({required bool isSourceLang}) async {
    if (isTranslateCompleted.value) {
      String? audioPathToShare =
          isSourceLang ? sourceLangTTSPath.value : targetLangTTSPath.value;

      if (audioPathToShare.isEmpty) {
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

  void connectToSocket() {
    if (_socketIOClient.isConnected()) {
      _socketIOClient.disconnect();
    }
    _socketIOClient.socketConnect();
  }

  Future<void> displaySocketIOResponse(response) async {
    if (response != null) {
      //  used for get ASR
      String sourceOutputText = response[0][APIConstants.kPipelineResponse]?[0]
              [APIConstants.kOutput]?[0][APIConstants.kSource] ??
          '';
      if (currentMic.value == CurrentlySelectedMic.source) {
        sourceLangTextController.text = sourceOutputText;
        this.sourceOutputText.value = sourceOutputText;
      } else {
        targetOutputText.value = sourceOutputText;
        targetLangTextController.text = sourceOutputText;
      }
      // used for get Translation
      if ((response[0][APIConstants.kPipelineResponse].length ?? 0) > 1) {
        String targetText = response[0][APIConstants.kPipelineResponse][1]
                [APIConstants.kOutput]?[0][APIConstants.kTarget] ??
            '';
        if (currentMic.value == CurrentlySelectedMic.target) {
          sourceLangTextController.text = targetText;
          this.sourceOutputText.value = targetText;
        } else {
          targetLangTextController.text = targetText;
          targetOutputText.value = targetText;
        }

        //  used for get TTS
        if ((response[0][APIConstants.kPipelineResponse].length ?? 0) > 2) {
          String ttsResponse = response[0][APIConstants.kPipelineResponse][2]
              [APIConstants.kAudio][0][APIConstants.kAudioContent];
          isTranslateCompleted.value = true;
          isLoading.value = false;
          sourceLangTTSPath.value = '';
          targetLangTTSPath.value = '';
          sourceSpeakerStatus.value = SpeakerStatus.stopped;
          targetSpeakerStatus.value = SpeakerStatus.stopped;
          if (ttsResponse.isNotEmpty) {
            String ttsFilePath = await createTTSAudioFIle(ttsResponse);
            currentMic.value == CurrentlySelectedMic.source
                ? targetLangTTSPath.value = ttsFilePath
                : sourceLangTTSPath.value = ttsFilePath;

            playStopTTSOutput(currentMic.value != CurrentlySelectedMic.source);
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

    if (audioPath.isNotEmpty) {
      isPlayingSource
          ? sourceSpeakerStatus.value = SpeakerStatus.playing
          : targetSpeakerStatus.value = SpeakerStatus.playing;

      await preparePlayer(audioPath,
          isRecordedAudio: true, isTargetLanguage: !isPlayingSource);
    }
  }

  setSourceLanguageList() {
    sourceLangListRegular.clear();
    sourceLangListBeta.clear();

    sourceLangListRegular =
        _languageModelController.sourceTargetLanguageMap.keys.toList();

    for (int i = 0; i < sourceLangListRegular.length; i++) {
      var language = sourceLangListRegular[i];
      if (converseSkipSourceLang.contains(language)) {
        sourceLangListRegular.removeAt(i);
        i--;
      } else if (converseBetaSourceLang.contains(language)) {
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
      if (converseSkipTargetLang.contains(language)) {
        targetLangListRegular.removeAt(i);
        i--;
      } else if (converseBetaTargetLang.contains(language)) {
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
    recordedData = [];
    _socketIOClient.disconnect();
    base64EncodedAudioContent = null;
    isSourceShareLoading.value = false;
    isTargetShareLoading.value = false;
    lastComputeRequest.clear();
    lastComputeResponse.clear();
  }

  disposePlayer() async {
    await player.stop();
    await player.dispose();
  }
}
