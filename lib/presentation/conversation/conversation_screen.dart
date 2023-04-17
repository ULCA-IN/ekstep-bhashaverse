import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';

import '../../animation/lottie_animation.dart';
import '../../common/controller/language_model_controller.dart';
import '../../common/widgets/common_app_bar.dart';
import '../../common/widgets/mic_button.dart';
import '../../common/widgets/text_field_with_actions.dart';
import '../../enums/current_mic.dart';
import '../../enums/mic_button_status.dart';
import '../../enums/speaker_status.dart';
import '../../localization/localization_keys.dart';
import '../../routes/app_routes.dart';
import '../../services/socket_io_client.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/voice_recorder.dart';
import 'controller/conversation_controller.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late ConversationController _translationController;
  late SocketIOClient _socketIOClient;
  late LanguageModelController _languageModelController;

  late final Box _hiveDBInstance;

  @override
  void initState() {
    _translationController = Get.find();
    _languageModelController = Get.find();
    _socketIOClient = Get.find();
    _hiveDBInstance = Hive.box(hiveDBName);
    _translationController.getSourceTargetLangFromDB();
    ScreenUtil().init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: honeydew,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: AppEdgeInsets.instance.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 18.toHeight,
                  ),
                  CommonAppBar(
                      title: converse.tr, onBackPress: () => Get.back()),
                  SizedBox(
                    height: 24.toHeight,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: 20.toHeight),
                        _buildSourceTextField(),
                        _buildTargetTextField(),
                      ],
                    ),
                  ),
                  Obx(
                    () => SizedBox(
                        height: _translationController.isKeyboardVisible.value
                            ? 12.toHeight
                            : 30.toHeight),
                  ),
                  Obx(
                    () => _translationController.isKeyboardVisible.value
                        ? const SizedBox.shrink()
                        : _buildMicButton(),
                  ),
                  SizedBox(height: 8.toHeight),
                ],
              ),
            ),
          ),
          Obx(() {
            if (_translationController.isLoading.value)
              return LottieAnimation(
                  context: context,
                  lottieAsset: animationLoadingLine,
                  footerText: _translationController.isLoading.value
                      ? kHomeLoadingAnimationText.tr
                      : kTranslationLoadingAnimationText.tr);
            else
              return const SizedBox.shrink();
          })
        ],
      ),
    );
  }

  Widget _buildSourceTextField() {
    return Expanded(
      child: Obx(
        () => TextFieldWithActions(
            textController: _translationController.sourceLangTextController,
            focusNode: FocusNode(),
            hintText: isRecordingStarted()
                ? _translationController.currentMic.value ==
                        CurrentlySelectedMic.source
                    ? kListeningHintText.tr
                    : ''
                : _translationController.micButtonStatus.value ==
                        MicButtonStatus.pressed
                    ? connecting.tr
                    : converseHintText.tr,
            translateButtonTitle: kTranslate.tr,
            currentDuration: _translationController.currentDuration.value,
            totalDuration: _translationController.maxDuration.value,
            isRecordedAudio: !_hiveDBInstance.get(isStreamingPreferred),
            topBorderRadius: 16, //TODO: change to conttand
            bottomBorderRadius: 0,
            showTranslateButton: false,
            showASRTTSActionButtons: true,
            isReadOnly: true,
            isShareButtonLoading:
                _translationController.isTargetShareLoading.value,
            textToCopy: _translationController.sourceOutputText.value,
            onMusicPlayOrStop: () => _translationController.playTTSOutput(true),
            onFileShare: () =>
                _translationController.shareAudioFile(isSourceLang: true),
            playerController: _translationController.controller,
            speakerStatus: _translationController.sourceSpeakerStatus.value,
            rawTimeStream: _translationController.stopWatchTimer.rawTime,
            showMicButton: isRecordingStarted() &&
                _translationController.currentMic.value ==
                    CurrentlySelectedMic.source),
      ),
    );
  }

  Widget _buildTargetTextField() {
    return Expanded(
      child: Obx(
        () => TextFieldWithActions(
            textController: _translationController.targetLangTextController,
            focusNode: FocusNode(),
            hintText: isRecordingStarted()
                ? _translationController.currentMic.value ==
                        CurrentlySelectedMic.target
                    ? kListeningHintText.tr
                    : ''
                : _translationController.micButtonStatus.value ==
                        MicButtonStatus.pressed
                    ? connecting.tr
                    : converseHintText.tr,
            translateButtonTitle: kTranslate.tr,
            currentDuration: _translationController.currentDuration.value,
            totalDuration: _translationController.maxDuration.value,
            isRecordedAudio: !_hiveDBInstance.get(isStreamingPreferred),
            topBorderRadius: 0,
            bottomBorderRadius: 16, //TODO: change to conttand
            showTranslateButton: false,
            showASRTTSActionButtons: true,
            isReadOnly: true,
            isShareButtonLoading:
                _translationController.isSourceShareLoading.value,
            textToCopy: _translationController.targetOutputText.value,
            onFileShare: () =>
                _translationController.shareAudioFile(isSourceLang: false),
            onMusicPlayOrStop: () =>
                _translationController.playTTSOutput(false),
            playerController: _translationController.controller,
            speakerStatus: _translationController.targetSpeakerStatus.value,
            rawTimeStream: _translationController.stopWatchTimer.rawTime,
            showMicButton: isRecordingStarted() &&
                _translationController.currentMic.value ==
                    CurrentlySelectedMic.target),
      ),
    );
  }

  Widget _buildMicButton() {
    return Padding(
      padding: AppEdgeInsets.instance.symmetric(horizontal: 14.0),
      child: Stack(
        // mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          AnimatedOpacity(
            opacity: isRecordingStarted() ? 1 : 0,
            duration: const Duration(milliseconds: 600),
            child: LottieBuilder.asset(
              animationStaticWaveForRecording,
              fit: BoxFit.fitWidth,
              animate: isRecordingStarted(),
              repeat: true,
            ),
          ),
          Positioned(
            // alignment: Alignment.centerLeft,
            left: 30,
            child: Obx(() {
              String selectedSourceLanguage = _translationController
                      .selectedSourceLanguageCode.value.isNotEmpty
                  ? _translationController.getSelectedSourceLanguageName()
                  : kTranslateSourceTitle.tr;
              return MicButton(
                isRecordingStarted: isRecordingStarted() &&
                    _translationController.currentMic.value ==
                        CurrentlySelectedMic.source,
                showLanguage: true,
                languageName: selectedSourceLanguage,
                onMicButtonTap: (isPressed) {
                  _translationController.currentMic.value =
                      CurrentlySelectedMic.source;
                  micButtonActions(startMicRecording: isPressed);
                },
                onLanguageTap: () async {
                  List<dynamic> sourceLanguageList = _languageModelController
                      .sourceTargetLanguageMap.keys
                      .toList();

                  dynamic selectedSourceLangCode = await Get.toNamed(
                      AppRoutes.languageSelectionRoute,
                      arguments: {
                        kLanguageList: sourceLanguageList,
                        kIsSourceLanguage: true,
                        selectedLanguage: _translationController
                            .selectedSourceLanguageCode.value,
                      });
                  if (selectedSourceLangCode != null) {
                    _translationController.selectedSourceLanguageCode.value =
                        selectedSourceLangCode;
                    _hiveDBInstance.put(
                        preferredSourceLanguage, selectedSourceLangCode);
                    String selectedTargetLangCode =
                        _translationController.selectedTargetLanguageCode.value;
                    if (selectedTargetLangCode.isNotEmpty) {
                      if (!_languageModelController
                          .sourceTargetLanguageMap[selectedSourceLangCode]!
                          .contains(selectedTargetLangCode)) {
                        _translationController
                            .selectedTargetLanguageCode.value = '';
                        _hiveDBInstance.put(preferredTargetLanguage, null);
                      }
                    }
                    await _translationController.resetAllValues();
                    VoiceRecorder voiceRecorder = VoiceRecorder();
                    await voiceRecorder.clearOldRecordings();
                  }
                },
              );
            }),
          ),
          Positioned(
            right: 30,
            child: Obx(() {
              String selectedTargetLanguage = _translationController
                      .selectedTargetLanguageCode.value.isNotEmpty
                  ? _translationController.getSelectedTargetLanguageName()
                  : kTranslateTargetTitle.tr;
              return MicButton(
                isRecordingStarted: isRecordingStarted() &&
                    _translationController.currentMic.value ==
                        CurrentlySelectedMic.target,
                showLanguage: true,
                languageName: selectedTargetLanguage,
                onMicButtonTap: (isPressed) {
                  _translationController.currentMic.value =
                      CurrentlySelectedMic.target;
                  micButtonActions(startMicRecording: isPressed);
                },
                onLanguageTap: () async {
                  if (_translationController
                      .selectedSourceLanguageCode.value.isEmpty) {
                    showDefaultSnackbar(
                        message: 'Please select source language first');
                    return;
                  }

                  List<dynamic> targetLanguageList = _languageModelController
                      .sourceTargetLanguageMap[_translationController
                          .selectedSourceLanguageCode.value]!
                      .toList();

                  dynamic selectedTargetLangCode = await Get.toNamed(
                      AppRoutes.languageSelectionRoute,
                      arguments: {
                        kLanguageList: targetLanguageList,
                        kIsSourceLanguage: false,
                        selectedLanguage: _translationController
                            .selectedTargetLanguageCode.value,
                      });
                  if (selectedTargetLangCode != null) {
                    _translationController.selectedTargetLanguageCode.value =
                        selectedTargetLangCode;
                    _hiveDBInstance.put(
                        preferredTargetLanguage, selectedTargetLangCode);
                    await _translationController.resetAllValues();
                    if (_translationController
                        .sourceLangTextController.text.isNotEmpty)
                      _translationController.getComputeResponseASRTrans(
                          isRecorded: false);
                  }
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  bool isAudioPlaying() {
    return (_translationController.targetSpeakerStatus.value ==
            SpeakerStatus.playing ||
        _translationController.sourceSpeakerStatus.value ==
            SpeakerStatus.playing);
  }

  bool isRecordingStarted() {
    return _hiveDBInstance.get(isStreamingPreferred)
        ? _socketIOClient.isMicConnected.value
        : _translationController.micButtonStatus.value ==
            MicButtonStatus.pressed;
  }

  void micButtonActions({required bool startMicRecording}) {
    if (_translationController.isSourceAndTargetLangSelected()) {
      if (startMicRecording) {
        _translationController.micButtonStatus.value = MicButtonStatus.pressed;
        _translationController.startVoiceRecording();
      } else {
        if (_translationController.micButtonStatus.value ==
            MicButtonStatus.pressed) {
          _translationController.micButtonStatus.value =
              MicButtonStatus.released;
          _translationController.stopVoiceRecordingAndGetResult();
        }
      }
    } else if (startMicRecording) {
      showDefaultSnackbar(message: kErrorSelectSourceAndTargetScreen.tr);
    }
  }
}
