import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';

import '../../animation/lottie_animation.dart';
import '../../common/controller/language_model_controller.dart';
import '../../common/widgets/common_app_bar.dart';
import '../../common/widgets/mic_button.dart';
import '../../common/widgets/text_field_with_actions.dart';
import '../../common/widgets/transliteration_hints.dart';
import '../../enums/mic_button_status.dart';
import '../../enums/speaker_status.dart';
import '../../localization/localization_keys.dart';
import '../../routes/app_routes.dart';
import '../../services/socket_io_client.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/theme/app_text_style.dart';
import '../../utils/voice_recorder.dart';
import 'controller/voice_text_translate_controller.dart';

class VoiceTextTranslateScreen extends StatefulWidget {
  const VoiceTextTranslateScreen({super.key});

  @override
  State<VoiceTextTranslateScreen> createState() =>
      _VoiceTextTranslateScreenState();
}

class _VoiceTextTranslateScreenState extends State<VoiceTextTranslateScreen>
    with WidgetsBindingObserver {
  late VoiceTextTranslateController _voiceTextTransController;
  late SocketIOClient _socketIOClient;
  late LanguageModelController _languageModelController;
  final FocusNode _sourceLangFocusNode = FocusNode();
  final FocusNode _targetLangFocusNode = FocusNode();

  late final Box _hiveDBInstance;

  @override
  void initState() {
    _voiceTextTransController = Get.find();
    _languageModelController = Get.find();
    _socketIOClient = Get.find();
    _hiveDBInstance = Hive.box(hiveDBName);
    _voiceTextTransController.getSourceTargetLangFromDB();
    WidgetsBinding.instance.addObserver(this);

    ScreenUtil().init();
    super.initState();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != _voiceTextTransController.isKeyboardVisible.value) {
      _voiceTextTransController.isKeyboardVisible.value = newValue;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
                  SizedBox(height: 18.toHeight),
                  CommonAppBar(title: voice.tr, onBackPress: () => Get.back()),
                  SizedBox(height: 24.toHeight),
                  Expanded(
                    child: Column(
                      children: [
                        Obx(
                          () =>
                              _voiceTextTransController.isKeyboardVisible.value
                                  ? const SizedBox.shrink()
                                  : _buildSourceTargetLangButtons(),
                        ),
                        SizedBox(height: 20.toHeight),
                        _buildSourceTextField(),
                        _buildTargetTextField(),
                      ],
                    ),
                  ),
                  SizedBox(
                      height: _voiceTextTransController.isKeyboardVisible.value
                          ? 0
                          : 8.toHeight),
                  _buildTransliterationHints(),
                  Obx(
                    () => _voiceTextTransController.isKeyboardVisible.value
                        ? const SizedBox.shrink()
                        : _buildMicButton(),
                  ),
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
          textController: _voiceTextTransController.sourceLangTextController,
          focusNode: _sourceLangFocusNode,
          hintText: _voiceTextTransController.isTranslateCompleted.value
              ? null
              : isRecordingStarted()
                  ? kListeningHintText.tr
                  : _voiceTextTransController.micButtonStatus.value ==
                          MicButtonStatus.pressed
                      ? connecting.tr
                      : kTranslationHintText.tr,
          translateButtonTitle: kTranslate.tr,
          currentDuration: _voiceTextTransController.currentDuration.value,
          totalDuration: _voiceTextTransController.maxDuration.value,
          isRecordedAudio: !_hiveDBInstance.get(isStreamingPreferred),
          topBorderRadius: textFieldRadius,
          bottomBorderRadius: 0,
          showTranslateButton: true,
          showASRTTSActionButtons:
              _voiceTextTransController.isTranslateCompleted.value,
          isReadOnly: false,
          isShareButtonLoading:
              _voiceTextTransController.isSourceShareLoading.value,
          textToCopy: _voiceTextTransController.sourceLangTextController.text,
          onChanged: (newText) => _onSourceTextChanged(newText),
          onTranslateButtonTap: () => _onTranslateButtonTap(),
          onMusicPlayOrStop: () =>
              _voiceTextTransController.playStopTTSOutput(true),
          onFileShare: () =>
              _voiceTextTransController.shareAudioFile(isSourceLang: true),
          playerController: _voiceTextTransController.playerController,
          speakerStatus: _voiceTextTransController.sourceSpeakerStatus.value,
          rawTimeStream: _voiceTextTransController.stopWatchTimer.rawTime,
          sourceCharLength: _voiceTextTransController.sourceTextCharLimit.value,
          showMicButton: _voiceTextTransController.micButtonStatus.value ==
              MicButtonStatus.pressed,
        ),
      ),
    );
  }

  Widget _buildTargetTextField() {
    return Expanded(
      child: Obx(
        () => TextFieldWithActions(
            textController: _voiceTextTransController.targetLangTextController,
            focusNode: _targetLangFocusNode,
            currentDuration: _voiceTextTransController.currentDuration.value,
            totalDuration: _voiceTextTransController.maxDuration.value,
            isRecordedAudio: !_hiveDBInstance.get(isStreamingPreferred),
            topBorderRadius: 0,
            bottomBorderRadius: textFieldRadius,
            showTranslateButton: false,
            showASRTTSActionButtons: true,
            isReadOnly: true,
            isShareButtonLoading:
                _voiceTextTransController.isTargetShareLoading.value,
            textToCopy: _voiceTextTransController.targetOutputText.value,
            onFileShare: () =>
                _voiceTextTransController.shareAudioFile(isSourceLang: false),
            onMusicPlayOrStop: () =>
                _voiceTextTransController.playStopTTSOutput(false),
            playerController: _voiceTextTransController.playerController,
            speakerStatus: _voiceTextTransController.targetSpeakerStatus.value,
            showMicButton: false),
      ),
    );
  }

  Widget _buildTransliterationHints() {
    return Obx(() => _voiceTextTransController.isKeyboardVisible.value
        ? TransliterationHints(
            scrollController:
                _voiceTextTransController.transliterationHintsScrollController,
            // neet to send with .toList() because of GetX observation issue
            transliterationHints:
                _voiceTextTransController.transliterationWordHints.toList(),
            showScrollIcon: true,
            isScrollArrowVisible: !_voiceTextTransController
                    .isScrolledTransliterationHints.value &&
                _voiceTextTransController.transliterationWordHints.isNotEmpty,
            onSelected: (hintText) =>
                replaceTextWithTransliterationHint(hintText))
        : SizedBox.shrink());
  }

  Widget _buildSourceTargetLangButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () async {
            _sourceLangFocusNode.unfocus();
            _targetLangFocusNode.unfocus();

            List<dynamic> sourceLanguageList =
                _languageModelController.sourceTargetLanguageMap.keys.toList();

            dynamic selectedSourceLangCode =
                await Get.toNamed(AppRoutes.languageSelectionRoute, arguments: {
              kLanguageList: sourceLanguageList,
              kIsSourceLanguage: true,
              selectedLanguage:
                  _voiceTextTransController.selectedSourceLanguageCode.value,
            });
            if (selectedSourceLangCode != null) {
              _voiceTextTransController.selectedSourceLanguageCode.value =
                  selectedSourceLangCode;
              _hiveDBInstance.put(
                  preferredSourceLanguage, selectedSourceLangCode);
              String selectedTargetLangCode =
                  _voiceTextTransController.selectedTargetLanguageCode.value;
              if (selectedTargetLangCode.isNotEmpty) {
                if (!_languageModelController
                    .sourceTargetLanguageMap[selectedSourceLangCode]!
                    .contains(selectedTargetLangCode)) {
                  _voiceTextTransController.selectedTargetLanguageCode.value =
                      '';
                  _hiveDBInstance.put(preferredTargetLanguage, null);
                }
              }
              await _voiceTextTransController.resetAllValues();
              VoiceRecorder voiceRecorder = VoiceRecorder();
              await voiceRecorder.clearOldRecordings();
            }
          },
          child: Container(
            width: ScreenUtil.screenWidth / 2.8,
            height: 50.toHeight,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Obx(
              () {
                String selectedSourceLanguage = _voiceTextTransController
                        .selectedSourceLanguageCode.value.isNotEmpty
                    ? _voiceTextTransController.getSelectedSourceLanguageName()
                    : kTranslateSourceTitle.tr;
                return AutoSizeText(
                  selectedSourceLanguage,
                  maxLines: 2,
                  style: AppTextStyle()
                      .regular18DolphinGrey
                      .copyWith(fontSize: 16.toFont),
                );
              },
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            _voiceTextTransController.swapSourceAndTargetLanguage();
          },
          child: SvgPicture.asset(
            iconArrowSwapHorizontal,
            height: 32.toHeight,
            width: 32.toWidth,
          ),
        ),
        InkWell(
          onTap: () async {
            _sourceLangFocusNode.unfocus();
            _targetLangFocusNode.unfocus();
            if (_voiceTextTransController
                .selectedSourceLanguageCode.value.isEmpty) {
              showDefaultSnackbar(
                  message: 'Please select source language first');
              return;
            }

            List<dynamic> targetLanguageList = _languageModelController
                .sourceTargetLanguageMap[
                    _voiceTextTransController.selectedSourceLanguageCode.value]!
                .toList();

            dynamic selectedTargetLangCode =
                await Get.toNamed(AppRoutes.languageSelectionRoute, arguments: {
              kLanguageList: targetLanguageList,
              kIsSourceLanguage: false,
              selectedLanguage:
                  _voiceTextTransController.selectedTargetLanguageCode.value,
            });
            if (selectedTargetLangCode != null) {
              _voiceTextTransController.selectedTargetLanguageCode.value =
                  selectedTargetLangCode;
              _hiveDBInstance.put(
                  preferredTargetLanguage, selectedTargetLangCode);
              if (_voiceTextTransController
                  .sourceLangTextController.text.isNotEmpty)
                _voiceTextTransController.getComputeResponseASRTrans(
                    isRecorded: false, clearSourceTTS: false);
            }
          },
          child: Container(
            width: ScreenUtil.screenWidth / 2.8,
            height: 50.toHeight,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Obx(
              () {
                String selectedTargetLanguage = _voiceTextTransController
                        .selectedTargetLanguageCode.value.isNotEmpty
                    ? _voiceTextTransController.getSelectedTargetLanguageName()
                    : kTranslateTargetTitle.tr;
                return AutoSizeText(
                  selectedTargetLanguage,
                  style: AppTextStyle()
                      .regular18DolphinGrey
                      .copyWith(fontSize: 16.toFont),
                  maxLines: 2,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMicButton() {
    return Obx(
      () => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            opacity: isRecordingStarted() ? 1 : 0,
            duration: const Duration(milliseconds: 600),
            child: Padding(
              padding: AppEdgeInsets.instance.symmetric(horizontal: 16.0),
              child: LottieBuilder.asset(
                animationStaticWaveForRecording,
                fit: BoxFit.cover,
                animate: isRecordingStarted(),
              ),
            ),
          ),
          MicButton(
            isRecordingStarted:
                _voiceTextTransController.micButtonStatus.value ==
                    MicButtonStatus.pressed,
            showLanguage: false,
            onMicButtonTap: (isPressed) {
              micButtonActions(startMicRecording: isPressed);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return Obx(() {
      if (_voiceTextTransController.isLoading.value)
        return LottieAnimation(
            context: context,
            lottieAsset: animationLoadingLine,
            footerText: _voiceTextTransController.isLoading.value
                ? kHomeLoadingAnimationText.tr
                : kTranslationLoadingAnimationText.tr);
      else
        return const SizedBox.shrink();
    });
  }

  void _onSourceTextChanged(String newText) {
    _voiceTextTransController.sourceTextCharLimit.value = newText.length;
    _voiceTextTransController.isTranslateCompleted.value = false;
    _voiceTextTransController.ttsResponse = null;
    _voiceTextTransController.targetLangTextController.clear();
    if (_voiceTextTransController.playerController.playerState ==
        PlayerState.playing) _voiceTextTransController.stopPlayer();
    if (_voiceTextTransController.targetSpeakerStatus.value !=
        SpeakerStatus.disabled)
      _voiceTextTransController.targetSpeakerStatus.value =
          SpeakerStatus.disabled;

    bool isNewWordStarted =
        newText.isNotEmpty && (newText[newText.length - 1]) == ' ';

    if (_voiceTextTransController.isTransliterationEnabled()) {
      if (isNewWordStarted &&
          _voiceTextTransController.transliterationWordHints.isNotEmpty) {
        replaceTextWithTransliterationHint(
            _voiceTextTransController.transliterationWordHints.first);
      } else {
        getTransliterationHints(newText);
      }
    } else if (_voiceTextTransController.transliterationWordHints.isNotEmpty) {
      _voiceTextTransController.transliterationWordHints.clear();
    }
  }

  void _onTranslateButtonTap() {
    unFocusTextFields();
    _voiceTextTransController.sourceLangTTSPath.value = '';
    _voiceTextTransController.targetLangTTSPath.value = '';

    if (_voiceTextTransController.sourceLangTextController.text.isEmpty) {
      showDefaultSnackbar(message: kErrorNoSourceText.tr);
    } else if (_voiceTextTransController.isSourceAndTargetLangSelected()) {
      _voiceTextTransController.getComputeResponseASRTrans(
        isRecorded: false,
      );
      _voiceTextTransController.isRecordedViaMic.value = false;
    } else {
      showDefaultSnackbar(message: kErrorSelectSourceAndTargetScreen.tr);
    }
  }

  void getTransliterationHints(String newText) {
    String wordToSend = newText.split(" ").last;
    if (wordToSend.isNotEmpty) {
      if (_voiceTextTransController
          .selectedSourceLanguageCode.value.isNotEmpty) {
        _voiceTextTransController.getTransliterationOutput(wordToSend);
      }
    } else {
      _voiceTextTransController.clearTransliterationHints();
    }
  }

  void replaceTextWithTransliterationHint(String currentHintText) {
    List<String> oldString = _voiceTextTransController
        .sourceLangTextController.text
        .trim()
        .split(' ');
    oldString.removeLast();
    oldString.add(currentHintText);
    _voiceTextTransController.sourceLangTextController.text =
        '${oldString.join(' ')} ';
    _voiceTextTransController.sourceLangTextController.selection =
        TextSelection.fromPosition(TextPosition(
            offset: _voiceTextTransController
                .sourceLangTextController.text.length));
    _voiceTextTransController.sourceTextCharLimit.value =
        _voiceTextTransController.sourceLangTextController.text.length;
    _voiceTextTransController.clearTransliterationHints();
  }

  void unFocusTextFields() {
    _sourceLangFocusNode.unfocus();
    _targetLangFocusNode.unfocus();
  }

  bool isRecordingStarted() {
    return _hiveDBInstance.get(isStreamingPreferred)
        ? _socketIOClient.isMicConnected.value
        : _voiceTextTransController.micButtonStatus.value ==
            MicButtonStatus.pressed;
  }

  void micButtonActions({required bool startMicRecording}) {
    if (_voiceTextTransController.isSourceAndTargetLangSelected()) {
      unFocusTextFields();

      if (startMicRecording) {
        _voiceTextTransController.micButtonStatus.value =
            MicButtonStatus.pressed;
        _voiceTextTransController.startVoiceRecording();
      } else {
        if (_voiceTextTransController.micButtonStatus.value ==
            MicButtonStatus.pressed) {
          _voiceTextTransController.micButtonStatus.value =
              MicButtonStatus.released;
          _voiceTextTransController.stopVoiceRecordingAndGetResult();
        }
      }
    } else if (startMicRecording) {
      showDefaultSnackbar(message: kErrorSelectSourceAndTargetScreen.tr);
    }
  }
}
