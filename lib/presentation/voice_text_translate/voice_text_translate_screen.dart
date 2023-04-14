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
import '../../common/widgets/text_field_with_actions.dart';
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
  late VoiceTextTranslateController _voiceController;
  late SocketIOClient _socketIOClient;
  late LanguageModelController _languageModelController;
  final FocusNode _sourceLangFocusNode = FocusNode();
  final FocusNode _targetLangFocusNode = FocusNode();

  late final Box _hiveDBInstance;

  @override
  void initState() {
    _voiceController = Get.find();
    _languageModelController = Get.find();
    _socketIOClient = Get.find();
    _hiveDBInstance = Hive.box(hiveDBName);
    _voiceController.getSourceTargetLangFromDB();
    WidgetsBinding.instance.addObserver(this);

    ScreenUtil().init();
    super.initState();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != _voiceController.isKeyboardVisible.value) {
      _voiceController.isKeyboardVisible.value = newValue;
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
                  SizedBox(
                    height: 18.toHeight,
                  ),
                  CommonAppBar(title: voice.tr, onBackPress: () => Get.back()),
                  SizedBox(
                    height: 24.toHeight,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Obx(
                          () => _voiceController.isKeyboardVisible.value
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
                      height: _voiceController.isKeyboardVisible.value
                          ? 0
                          : 8.toHeight),
                  _buildTransliterationHints(),
                  Obx(
                    () => _voiceController.isKeyboardVisible.value
                        ? const SizedBox.shrink()
                        : _buildMicButton(),
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            if (_voiceController.isLoading.value)
              return LottieAnimation(
                  context: context,
                  lottieAsset: animationLoadingLine,
                  footerText: _voiceController.isLoading.value
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
          textController: _voiceController.sourceLangTextController,
          focusNode: _sourceLangFocusNode,
          hintText: _voiceController.isTranslateCompleted.value
              ? null
              : isRecordingStarted()
                  ? kListeningHintText.tr
                  : _voiceController.micButtonStatus.value ==
                          MicButtonStatus.pressed
                      ? connecting.tr
                      : kTranslationHintText.tr,
          translateButtonTitle: kTranslate.tr,
          currentDuration: _voiceController.currentDuration.value,
          totalDuration: _voiceController.maxDuration.value,
          isRecordedAudio: !_hiveDBInstance.get(isStreamingPreferred),
          topBorderRadius: 16, //TODO: change to conttand
          bottomBorderRadius: 0,
          showTranslateButton: true,
          showASRTTSActionButtons: _voiceController.isTranslateCompleted.value,
          isReadOnly: false,
          isShareButtonLoading: _voiceController.isSourceShareLoading.value,
          textToCopy: _voiceController.sourceLangTextController.text,
          onChanged: (newText) => _onSourceTextChanged(newText),
          onTranslateButtonTap: () => _onTranslateButtonTap(),
          onMusicPlayOrStop: () => _voiceController.playTTSOutput(true),
          onFileShare: () =>
              _voiceController.shareAudioFile(isSourceLang: true),
          playerController: _voiceController.controller,
          speakerStatus: _voiceController.sourceSpeakerStatus.value,
          rawTimeStream: _voiceController.stopWatchTimer.rawTime,
          showMicButton: _voiceController.isKeyboardVisible.value &&
              _voiceController.micButtonStatus.value == MicButtonStatus.pressed,
        ),
      ),
    );
  }

  Widget _buildTargetTextField() {
    return Expanded(
      child: Obx(
        () => TextFieldWithActions(
            textController: _voiceController.targetLangTextController,
            focusNode: _targetLangFocusNode,
            translateButtonTitle: kTranslate.tr,
            currentDuration: _voiceController.currentDuration.value,
            totalDuration: _voiceController.maxDuration.value,
            isRecordedAudio: !_hiveDBInstance.get(isStreamingPreferred),
            topBorderRadius: 0,
            bottomBorderRadius: 16, //TODO: change to conttand
            showTranslateButton: false,
            showASRTTSActionButtons: true,
            isReadOnly: true,
            isShareButtonLoading: _voiceController.isTargetShareLoading.value,
            textToCopy: _voiceController.targetOutputText.value,
            onFileShare: () =>
                _voiceController.shareAudioFile(isSourceLang: false),
            onMusicPlayOrStop: () => _voiceController.playTTSOutput(false),
            playerController: _voiceController.controller,
            speakerStatus: _voiceController.targetSpeakerStatus.value,
            rawTimeStream: _voiceController.stopWatchTimer.rawTime,
            showMicButton: _voiceController.isKeyboardVisible.value &&
                _voiceController.micButtonStatus.value ==
                    MicButtonStatus.pressed),
      ),
    );
  }

  Widget _buildTransliterationHints() {
    return Obx(() => _voiceController.isKeyboardVisible.value
        ? SizedBox(
            height: 85.toHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Visibility(
                  visible:
                      !_voiceController.isScrolledTransliterationHints.value &&
                          _voiceController.transliterationWordHints.isNotEmpty,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_forward_outlined,
                      color: Colors.grey.shade400,
                      size: 22.toHeight,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  controller:
                      _voiceController.transliterationHintsScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ..._voiceController.transliterationWordHints
                          .map((hintText) => GestureDetector(
                                onTap: () {
                                  replaceTextWithTransliterationHint(hintText);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: lilyWhite,
                                  ),
                                  margin: AppEdgeInsets.instance.all(4),
                                  padding: AppEdgeInsets.instance
                                      .symmetric(vertical: 4, horizontal: 6),
                                  alignment: Alignment.center,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      minWidth:
                                          (ScreenUtil.screenWidth / 6).toWidth,
                                    ),
                                    child: Text(
                                      hintText,
                                      style: AppTextStyle()
                                          .regular18DolphinGrey
                                          .copyWith(
                                            color: Colors.black,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              )),
                    ],
                  ),
                ),
              ],
            ),
          )
        : SizedBox.shrink());
  }

  void _onSourceTextChanged(String newText) {
    _voiceController.sourceTextCharLimit.value = newText.length;
    _voiceController.isTranslateCompleted.value = false;
    _voiceController.ttsResponse = null;
    _voiceController.targetLangTextController.clear();
    if (_voiceController.controller.playerState == PlayerState.playing)
      _voiceController.stopPlayer();
    if (_voiceController.targetSpeakerStatus.value != SpeakerStatus.disabled)
      _voiceController.targetSpeakerStatus.value = SpeakerStatus.disabled;
    if (_voiceController.isTransliterationEnabled()) {
      getTransliterationHints(newText);
    } else {
      _voiceController.transliterationWordHints.clear();
    }
  }

  void _onTranslateButtonTap() {
    unFocusTextFields();
    _voiceController.sourceLangTTSPath.value = '';
    _voiceController.targetLangTTSPath.value = '';

    if (_voiceController.sourceLangTextController.text.isEmpty) {
      showDefaultSnackbar(message: kErrorNoSourceText.tr);
    } else if (_voiceController.isSourceAndTargetLangSelected()) {
      _voiceController.getComputeResponseASRTrans(
        isRecorded: false,
      );
      _voiceController.isRecordedViaMic.value = false;
    } else {
      showDefaultSnackbar(message: kErrorSelectSourceAndTargetScreen.tr);
    }
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
                  _voiceController.selectedSourceLanguageCode.value,
            });
            if (selectedSourceLangCode != null) {
              _voiceController.selectedSourceLanguageCode.value =
                  selectedSourceLangCode;
              _hiveDBInstance.put(
                  preferredSourceLanguage, selectedSourceLangCode);
              String selectedTargetLangCode =
                  _voiceController.selectedTargetLanguageCode.value;
              if (selectedTargetLangCode.isNotEmpty) {
                if (!_languageModelController
                    .sourceTargetLanguageMap[selectedSourceLangCode]!
                    .contains(selectedTargetLangCode)) {
                  _voiceController.selectedTargetLanguageCode.value = '';
                }
              }
              await _voiceController.resetAllValues();
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
                String selectedSourceLanguage =
                    _voiceController.selectedSourceLanguageCode.value.isNotEmpty
                        ? _voiceController.getSelectedSourceLanguageName()
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
            _voiceController.swapSourceAndTargetLanguage();
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
            if (_voiceController.selectedSourceLanguageCode.value.isEmpty) {
              showDefaultSnackbar(
                  message: 'Please select source language first');
              return;
            }

            List<dynamic> targetLanguageList = _languageModelController
                .sourceTargetLanguageMap[
                    _voiceController.selectedSourceLanguageCode.value]!
                .toList();

            dynamic selectedTargetLangCode =
                await Get.toNamed(AppRoutes.languageSelectionRoute, arguments: {
              kLanguageList: targetLanguageList,
              kIsSourceLanguage: false,
              selectedLanguage:
                  _voiceController.selectedTargetLanguageCode.value,
            });
            if (selectedTargetLangCode != null) {
              _voiceController.selectedTargetLanguageCode.value =
                  selectedTargetLangCode;
              _hiveDBInstance.put(
                  preferredTargetLanguage, selectedTargetLangCode);
              if (_voiceController.sourceLangTextController.text.isNotEmpty)
                _voiceController.getComputeResponseASRTrans(
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
                String selectedTargetLanguage =
                    _voiceController.selectedTargetLanguageCode.value.isNotEmpty
                        ? _voiceController.getSelectedTargetLanguageName()
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
          GestureDetector(
            onTapDown: (_) => micButtonActions(startMicRecording: true),
            onTapUp: (_) => micButtonActions(startMicRecording: false),
            onTapCancel: () => micButtonActions(startMicRecording: false),
            onPanEnd: (_) => micButtonActions(startMicRecording: false),
            child: PhysicalModel(
              color: Colors.transparent,
              shape: BoxShape.circle,
              elevation: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: isRecordingStarted()
                      ? tangerineOrangeColor
                      : flushOrangeColor,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: AppEdgeInsets.instance
                      .all(isRecordingStarted() ? 28 : 20.0),
                  child: SvgPicture.asset(
                    _voiceController.micButtonStatus.value ==
                            MicButtonStatus.pressed
                        ? iconMicStop
                        : iconMicroPhone,
                    height: 32.toHeight,
                    width: 32.toWidth,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void getTransliterationHints(String newText) {
    String wordToSend = newText.split(" ").last;
    if (wordToSend.isNotEmpty) {
      if (_voiceController.selectedSourceLanguageCode.value.isNotEmpty) {
        _voiceController.getTransliterationOutput(wordToSend);
      }
    } else {
      _voiceController.clearTransliterationHints();
    }
  }

  void replaceTextWithTransliterationHint(String currentHintText) {
    List<String> oldString =
        _voiceController.sourceLangTextController.text.trim().split(' ');
    oldString.removeLast();
    oldString.add(currentHintText);
    _voiceController.sourceLangTextController.text = '${oldString.join(' ')} ';
    _voiceController.sourceLangTextController.selection =
        TextSelection.fromPosition(TextPosition(
            offset: _voiceController.sourceLangTextController.text.length));
    _voiceController.clearTransliterationHints();
  }

  void unFocusTextFields() {
    _sourceLangFocusNode.unfocus();
    _targetLangFocusNode.unfocus();
  }

  bool isRecordingStarted() {
    return _hiveDBInstance.get(isStreamingPreferred)
        ? _socketIOClient.isMicConnected.value
        : _voiceController.micButtonStatus.value == MicButtonStatus.pressed;
  }

  void micButtonActions({required bool startMicRecording}) {
    if (_voiceController.isSourceAndTargetLangSelected()) {
      unFocusTextFields();

      if (startMicRecording) {
        _voiceController.micButtonStatus.value = MicButtonStatus.pressed;
        _voiceController.startVoiceRecording();
      } else {
        if (_voiceController.micButtonStatus.value == MicButtonStatus.pressed) {
          _voiceController.micButtonStatus.value = MicButtonStatus.released;
          _voiceController.stopVoiceRecordingAndGetResult();
        }
      }
    } else if (startMicRecording) {
      showDefaultSnackbar(message: kErrorSelectSourceAndTargetScreen.tr);
    }
  }
}
