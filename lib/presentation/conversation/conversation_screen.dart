import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../animation/lottie_animation.dart';
import '../../common/controller/language_model_controller.dart';
import '../../common/widgets/common_app_bar.dart';
import '../../common/widgets/mic_button.dart';
import '../../common/widgets/text_field_with_actions.dart';
import '../../enums/current_mic.dart';
import '../../enums/mic_button_status.dart';
import '../../enums/speaker_status.dart';
import '../../routes/app_routes.dart';
import '../../services/socket_io_client.dart';
import '../../utils/constants/api_constants.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/network_utils.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/theme/app_theme_provider.dart';
import 'controller/conversation_controller.dart';
import '../../i18n/strings.g.dart' as i18n;

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late ConversationController _converseController;
  late SocketIOClient _socketIOClient;
  late LanguageModelController _languageModelController;
  late final Box _hiveDBInstance;
  late dynamic translation;

  @override
  void initState() {
    _converseController = Get.find();
    _languageModelController = Get.find();
    _socketIOClient = Get.find();
    _hiveDBInstance = Hive.box(hiveDBName);
    _converseController.getSourceTargetLangFromDB();
    _converseController.setSourceLanguageList();
    _converseController.setTargetLanguageList();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    translation = i18n.Translations.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appTheme.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14).w,
              child: Column(
                children: [
                  SizedBox(
                    height: 16.h,
                  ),
                  CommonAppBar(
                      title: translation.converse,
                      onBackPress: () => Get.back()),
                  SizedBox(
                    height: 8.h,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: 20.w),
                        _buildSourceTextField(),
                        _buildTargetTextField(),
                      ],
                    ),
                  ),
                  Obx(
                    () => SizedBox(
                        height: _converseController.isKeyboardVisible.value
                            ? 12.h
                            : 20.h),
                  ),
                  Obx(
                    () => _converseController.isKeyboardVisible.value
                        ? const SizedBox.shrink()
                        : _buildMicButton(),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
          _buildLoadingAnimation()
        ],
      ),
    );
  }

  Widget _buildSourceTextField() {
    return Expanded(
      child: Obx(
        () => TextFieldWithActions(
            textController: _converseController.sourceLangTextController,
            focusNode: FocusNode(),
            backgroundColor: context.appTheme.normalTextFieldColor,
            borderColor: context.appTheme.disabledBGColor,
            hintText: isCurrentlyRecording()
                ? _converseController.currentMic.value ==
                        CurrentlySelectedMic.source
                    ? translation.kListeningHintText
                    : ''
                : _converseController.micButtonStatus.value ==
                        MicButtonStatus.pressed
                    ? translation.connecting
                    : translation.converseHintText,
            translateButtonTitle: translation.kTranslate,
            currentDuration: _converseController.currentDuration.value,
            totalDuration: _converseController.maxDuration.value,
            topBorderRadius: textFieldRadius,
            bottomBorderRadius: 0,
            showTranslateButton: false,
            showASRTTSActionButtons: true,
            showFeedbackIcon: _converseController.isTranslateCompleted.value &&
                _converseController.currentMic.value ==
                    CurrentlySelectedMic.source,
            expandFeedbackIcon: _converseController.expandFeedbackIcon.value,
            isReadOnly: true,
            isShareButtonLoading:
                _converseController.isTargetShareLoading.value,
            textToCopy: _converseController.sourceOutputText.value,
            onMusicPlayOrStop: () =>
                _converseController.playStopTTSOutput(true),
            onFileShare: () =>
                _converseController.shareAudioFile(isSourceLang: true),
            onFeedbackButtonTap: () {
              Get.toNamed(AppRoutes.feedbackRoute, arguments: {
                // Fixes Dart shallow copy issue:
                APIConstants.kRequestPayload: json.decode(
                    json.encode(_converseController.lastComputeRequest)),
                APIConstants.kRequestResponse: json.decode(
                    json.encode(_converseController.lastComputeResponse))
              });
            },
            speakerStatus: _converseController.sourceSpeakerStatus.value,
            rawTimeStream: _converseController.stopWatchTimer.rawTime,
            showMicButton: isCurrentlyRecording() &&
                _converseController.currentMic.value ==
                    CurrentlySelectedMic.source),
      ),
    );
  }

  Widget _buildTargetTextField() {
    return Expanded(
      child: Obx(
        () => TextFieldWithActions(
          textController: _converseController.targetLangTextController,
          focusNode: FocusNode(),
          backgroundColor: context.appTheme.normalTextFieldColor,
          borderColor: context.appTheme.disabledBGColor,
          hintText: isCurrentlyRecording()
              ? _converseController.currentMic.value ==
                      CurrentlySelectedMic.target
                  ? translation.kListeningHintText
                  : ''
              : _converseController.micButtonStatus.value ==
                      MicButtonStatus.pressed
                  ? translation.connecting
                  : translation.converseHintText,
          translateButtonTitle: translation.kTranslate,
          currentDuration: _converseController.currentDuration.value,
          totalDuration: _converseController.maxDuration.value,
          topBorderRadius: 0,
          bottomBorderRadius: textFieldRadius,
          showTranslateButton: false,
          showFeedbackIcon: _converseController.isTranslateCompleted.value &&
              _converseController.currentMic.value ==
                  CurrentlySelectedMic.target,
          expandFeedbackIcon: _converseController.expandFeedbackIcon.value,
          showASRTTSActionButtons: true,
          isReadOnly: true,
          isShareButtonLoading: _converseController.isSourceShareLoading.value,
          textToCopy: _converseController.targetOutputText.value,
          onFileShare: () =>
              _converseController.shareAudioFile(isSourceLang: false),
          onMusicPlayOrStop: () => _converseController.playStopTTSOutput(false),
          speakerStatus: _converseController.targetSpeakerStatus.value,
          rawTimeStream: _converseController.stopWatchTimer.rawTime,
          showMicButton: isCurrentlyRecording() &&
              _converseController.currentMic.value ==
                  CurrentlySelectedMic.target,
          onFeedbackButtonTap: () {
            Get.toNamed(AppRoutes.feedbackRoute, arguments: {
              // Fixes Dart shallow copy issue:
              APIConstants.kRequestPayload: json
                  .decode(json.encode(_converseController.lastComputeRequest)),
              APIConstants.kRequestResponse: json
                  .decode(json.encode(_converseController.lastComputeResponse))
            });
          },
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.0.w, vertical: 8.h),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedOpacity(
            opacity: isCurrentlyRecording() ? 1 : 0,
            duration: const Duration(milliseconds: 600),
            child: LottieBuilder.asset(
              animationStaticWaveForRecording,
              fit: BoxFit.fitWidth,
              animate: isCurrentlyRecording(),
              repeat: true,
            ),
          ),
          Positioned(
            left: 20,
            child: Obx(() {
              String sourceLangCode =
                      _converseController.selectedSourceLanguageCode.value,
                  selectedSourceLang = "";

              selectedSourceLang = sourceLangCode.isNotEmpty &&
                      (_converseController.sourceLangListRegular
                              .contains(sourceLangCode) ||
                          _converseController.sourceLangListBeta
                              .contains(sourceLangCode))
                  ? APIConstants.getLanNameInAppLang(
                      _converseController.selectedSourceLanguageCode.value)
                  : translation.kTranslateSourceTitle;
              return MicButton(
                micButtonStatus: _converseController.currentMic.value ==
                        CurrentlySelectedMic.source
                    ? _converseController.micButtonStatus.value
                    : MicButtonStatus.released,
                showLanguage: true,
                languageName: selectedSourceLang,
                onMicButtonTap: (isPressed) {
                  if (_converseController.currentMic.value ==
                          CurrentlySelectedMic.target &&
                      isCurrentlyRecording()) return;
                  _converseController.currentMic.value =
                      CurrentlySelectedMic.source;
                  micButtonActions(startMicRecording: isPressed);
                },
                onLanguageTap: () async {
                  dynamic selectedSourceLangCode = await Get.toNamed(
                      AppRoutes.languageSelectionRoute,
                      arguments: {
                        kLanguageListRegular:
                            _converseController.sourceLangListRegular,
                        kLanguageListBeta:
                            _converseController.sourceLangListBeta,
                        kIsSourceLanguage: true,
                        selectedLanguage: _converseController
                            .selectedSourceLanguageCode.value,
                      });
                  if (selectedSourceLangCode != null) {
                    _converseController.selectedSourceLanguageCode.value =
                        selectedSourceLangCode;
                    _hiveDBInstance.put(
                        preferredSourceLanguage, selectedSourceLangCode);
                    String selectedTargetLangCode =
                        _converseController.selectedTargetLanguageCode.value;
                    if (selectedTargetLangCode.isNotEmpty) {
                      if (!_languageModelController
                          .sourceTargetLanguageMap[selectedSourceLangCode]!
                          .contains(selectedTargetLangCode)) {
                        _converseController.selectedTargetLanguageCode.value =
                            '';
                        _hiveDBInstance.put(preferredTargetLanguage, null);
                        await _converseController.resetAllValues();
                      } else if (_converseController.currentMic.value ==
                              CurrentlySelectedMic.target &&
                          _converseController
                              .selectedTargetLanguageCode.value.isNotEmpty &&
                          (_converseController.base64EncodedAudioContent ?? '')
                              .isNotEmpty &&
                          await isNetworkConnected()) {
                        _converseController.getComputeResponseASRTrans(
                            isRecorded: true,
                            base64Value:
                                _converseController.base64EncodedAudioContent);
                      } else {
                        await _converseController.resetAllValues();
                      }
                    }
                  }
                },
              );
            }),
          ),
          Positioned(
            right: 20,
            child: Obx(() {
              String targetLangCode =
                      _converseController.selectedTargetLanguageCode.value,
                  selectedTargetLang = "";

              selectedTargetLang = targetLangCode.isNotEmpty &&
                      (_converseController.targetLangListRegular
                              .contains(targetLangCode) ||
                          _converseController.targetLangListBeta
                              .contains(targetLangCode))
                  ? APIConstants.getLanNameInAppLang(
                      _converseController.selectedTargetLanguageCode.value)
                  : translation.kTranslateTargetTitle;
              return MicButton(
                micButtonStatus: _converseController.currentMic.value ==
                        CurrentlySelectedMic.target
                    ? _converseController.micButtonStatus.value
                    : MicButtonStatus.released,
                showLanguage: true,
                languageName: selectedTargetLang,
                onMicButtonTap: (isPressed) {
                  if (_converseController.currentMic.value ==
                          CurrentlySelectedMic.source &&
                      isCurrentlyRecording()) return;
                  _converseController.currentMic.value =
                      CurrentlySelectedMic.target;
                  micButtonActions(startMicRecording: isPressed);
                },
                onLanguageTap: () async {
                  if (_converseController
                      .selectedSourceLanguageCode.value.isEmpty) {
                    showDefaultSnackbar(
                        message: translation.errorSelectSourceLangFirst);
                    return;
                  }

                  _converseController.setTargetLanguageList();

                  dynamic selectedTargetLangCode = await Get.toNamed(
                      AppRoutes.languageSelectionRoute,
                      arguments: {
                        kLanguageListRegular:
                            _converseController.targetLangListRegular,
                        kLanguageListBeta:
                            _converseController.targetLangListBeta,
                        kIsSourceLanguage: false,
                        selectedLanguage: _converseController
                            .selectedTargetLanguageCode.value,
                      });
                  if (selectedTargetLangCode != null) {
                    _converseController.selectedTargetLanguageCode.value =
                        selectedTargetLangCode;
                    _hiveDBInstance.put(
                        preferredTargetLanguage, selectedTargetLangCode);

                    if (_converseController.currentMic.value ==
                            CurrentlySelectedMic.source &&
                        _converseController
                            .selectedSourceLanguageCode.value.isNotEmpty &&
                        (_converseController.base64EncodedAudioContent ?? '')
                            .isNotEmpty &&
                        await isNetworkConnected()) {
                      _converseController.getComputeResponseASRTrans(
                          isRecorded: true,
                          base64Value:
                              _converseController.base64EncodedAudioContent);
                    } else {
                      await _converseController.resetAllValues();
                    }
                  }
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return Obx(() {
      if (_converseController.isLoading.value) {
        return LottieAnimation(
            context: context,
            lottieAsset: animationLoadingLine,
            footerText: _converseController.isLoading.value
                ? translation.computeCallLoadingText
                : translation.kTranslationLoadingAnimationText);
      } else {
        return const SizedBox.shrink();
      }
    });
  }

  bool isAudioPlaying() {
    return (_converseController.targetSpeakerStatus.value ==
            SpeakerStatus.playing ||
        _converseController.sourceSpeakerStatus.value == SpeakerStatus.playing);
  }

  bool isCurrentlyRecording() {
    return _hiveDBInstance.get(isStreamingPreferred)
        ? _socketIOClient.isMicConnected.value &&
            _converseController.micButtonStatus.value == MicButtonStatus.pressed
        : _converseController.micButtonStatus.value == MicButtonStatus.pressed;
  }

  void micButtonActions({required bool startMicRecording}) async {
    if (!await isNetworkConnected()) {
      showDefaultSnackbar(message: translation.errorNoInternetTitle);
    } else if (_converseController.isSourceAndTargetLangSelected()) {
      if (startMicRecording) {
        _converseController.micButtonStatus.value = MicButtonStatus.pressed;
        _converseController.startVoiceRecording();
      } else {
        if (_converseController.micButtonStatus.value ==
            MicButtonStatus.pressed) {
          _converseController.micButtonStatus.value = MicButtonStatus.released;
          _converseController.stopVoiceRecordingAndGetResult();
        }
      }
    } else if (startMicRecording) {
      showDefaultSnackbar(
          message: translation.kErrorSelectSourceAndTargetScreen);
    }
  }
}
