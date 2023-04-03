import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

import '../../animation/lottie_animation.dart';
import '../../common/controller/language_model_controller.dart';
import '../../common/widgets/asr_tts_actions.dart';
import '../../common/widgets/common_app_bar.dart';
import '../../common/widgets/custom_outline_button.dart';
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
import '../../utils/date_time_utils.dart';
import '../../utils/voice_recorder.dart';
import 'controller/text_translate_controller.dart';

class TextTranslateScreen extends StatefulWidget {
  const TextTranslateScreen({super.key});

  @override
  State<TextTranslateScreen> createState() => _TextTranslateScreenState();
}

class _TextTranslateScreenState extends State<TextTranslateScreen>
    with WidgetsBindingObserver {
  late TextTranslateController _translationController;
  late SocketIOClient _socketIOClient;
  late LanguageModelController _languageModelController;
  final FocusNode _sourceLangFocusNode = FocusNode();
  final FocusNode _transLangFocusNode = FocusNode();

  late final Box _hiveDBInstance;

  @override
  void initState() {
    _translationController = Get.find();
    _languageModelController = Get.find();
    _socketIOClient = Get.find();
    _hiveDBInstance = Hive.box(hiveDBName);
    _translationController.getSourceTargetLangFromDB();
    WidgetsBinding.instance.addObserver(this);

    ScreenUtil().init();
    super.initState();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != _translationController.isKeyboardVisible.value) {
      _translationController.isKeyboardVisible.value = newValue;
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
                  CommonAppBar(
                      title: converge.tr, onBackPress: () => Get.back()),
                  SizedBox(
                    height: 24.toHeight,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Obx(
                          () => _translationController.isKeyboardVisible.value
                              ? const SizedBox.shrink()
                              : _buildSourceTargetLangButtons(),
                        ),
                        SizedBox(height: 20.toHeight),
                        Expanded(
                          child: AnimatedContainer(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topLeft: textFieldRadius,
                                  topRight: textFieldRadius,
                                ),
                                border: Border.all(
                                  color: americanSilver,
                                )),
                            duration: const Duration(milliseconds: 500),
                            child: Padding(
                              padding: AppEdgeInsets.instance.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Obx(() => Flexible(
                                      child: _buildSourceLanguageInput())),
                                  SizedBox(height: 6.toHeight),
                                  Obx(
                                    () => _translationController
                                                .isTranslateCompleted.value ||
                                            _hiveDBInstance
                                                .get(isStreamingPreferred)
                                        ? ASRAndTTSActions(
                                            textToCopy: _translationController
                                                .sourceLanTextController.text
                                                .trim(),
                                            audioPathToShare:
                                                _translationController
                                                    .sourceLangASRPath,
                                            currentDuration: DateTImeUtils()
                                                .getTimeFromMilliseconds(
                                                    timeInMillisecond:
                                                        _translationController
                                                            .currentDuration
                                                            .value),
                                            totalDuration: DateTImeUtils()
                                                .getTimeFromMilliseconds(
                                                    timeInMillisecond:
                                                        _translationController
                                                            .maxDuration.value),
                                            isRecordedAudio: !_hiveDBInstance
                                                .get(isStreamingPreferred),
                                            onMusicPlayOrStop: () async {
                                              if (isAudioPlaying(
                                                  isForTargetSection: false)) {
                                                await _translationController
                                                    .stopPlayer();
                                              } else if (_translationController
                                                  .isRecordedViaMic.value) {
                                                _translationController
                                                    .playTTSOutput();
                                              } else {
                                                _translationController
                                                    .getComputeResTTS(
                                                  sourceText:
                                                      _translationController
                                                          .sourceLanTextController
                                                          .text,
                                                  languageCode:
                                                      _translationController
                                                          .selectedSourceLanguageCode
                                                          .value,
                                                  isTargetLanguage: false,
                                                );
                                              }
                                            },
                                            playerController:
                                                _translationController
                                                    .controller,
                                            speakerStatus:
                                                _translationController
                                                    .sourceSpeakerStatus.value,
                                          )
                                        : _buildLimitCountAndTranslateButton(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                            child: AnimatedContainer(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: textFieldRadius,
                                      bottomRight: textFieldRadius,
                                    ),
                                    border: Border.all(
                                      color: americanSilver,
                                    )),
                                duration: const Duration(milliseconds: 500),
                                child: Padding(
                                  padding: AppEdgeInsets.instance.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                          child: _buildTargetLanguageInput()),
                                      SizedBox(height: 6.toHeight),
                                      Obx(
                                        () => ASRAndTTSActions(
                                          textToCopy: _translationController
                                              .targetLangTextController.text
                                              .trim(),
                                          audioPathToShare:
                                              _translationController
                                                  .targetLangTTSPath,
                                          currentDuration: DateTImeUtils()
                                              .getTimeFromMilliseconds(
                                                  timeInMillisecond:
                                                      _translationController
                                                          .currentDuration
                                                          .value),
                                          totalDuration: DateTImeUtils()
                                              .getTimeFromMilliseconds(
                                                  timeInMillisecond:
                                                      _translationController
                                                          .maxDuration.value),
                                          isRecordedAudio: !_hiveDBInstance
                                              .get(isStreamingPreferred),
                                          onMusicPlayOrStop: () async {
                                            if (isAudioPlaying(
                                                isForTargetSection: true)) {
                                              await _translationController
                                                  .stopPlayer();
                                            } else {
                                              _translationController
                                                  .getComputeResTTS(
                                                sourceText:
                                                    _translationController
                                                        .targetLangTextController
                                                        .text,
                                                languageCode:
                                                    _translationController
                                                        .selectedTargetLanguageCode
                                                        .value,
                                                isTargetLanguage: true,
                                              );
                                            }
                                          },
                                          playerController:
                                              _translationController.controller,
                                          speakerStatus: _translationController
                                              .targetSpeakerStatus.value,
                                        ),
                                      )
                                    ],
                                  ),
                                ))),
                      ],
                    ),
                  ),
                  SizedBox(
                      height: _translationController.isKeyboardVisible.value
                          ? 0
                          : 8.toHeight),
                  _buildTransliterationHints(),
                  Obx(
                    () => _translationController.isKeyboardVisible.value
                        ? const SizedBox.shrink()
                        : _buildMicButton(),
                  ),
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

  Widget _buildTransliterationHints() {
    return Obx(() => _translationController.isKeyboardVisible.value
        ? SizedBox(
            height: 85.toHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Visibility(
                  visible: !_translationController
                          .isScrolledTransliterationHints.value &&
                      _translationController
                          .transliterationWordHints.isNotEmpty,
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
                  controller: _translationController
                      .transliterationHintsScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ..._translationController.transliterationWordHints
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

  Widget _buildSourceLanguageInput() {
    return TextField(
      controller: _translationController.sourceLanTextController,
      focusNode: _sourceLangFocusNode,
      style: AppTextStyle().regular18balticSea,
      maxLines: null,
      expands: true,
      maxLength: asrTextCharMaxLength,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: _translationController.isTranslateCompleted.value
            ? null
            : isRecordingStarted()
                ? kListeningHintText.tr
                : _translationController.micButtonStatus.value ==
                        MicButtonStatus.pressed
                    ? connecting.tr
                    : kTranslationHintText.tr,
        hintStyle:
            AppTextStyle().regular24BalticSea.copyWith(color: mischkaGrey),
        hintMaxLines: 4,
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        counterText: '',
      ),
      onChanged: (newText) {
        _translationController.sourceTextCharLimit.value = newText.length;
        _translationController.isTranslateCompleted.value = false;
        _translationController.ttsResponse = null;
        _translationController.targetLangTextController.clear();
        if (_translationController.controller.playerState ==
            PlayerState.playing) _translationController.stopPlayer();
        if (_translationController.targetSpeakerStatus.value !=
            SpeakerStatus.disabled)
          _translationController.targetSpeakerStatus.value =
              SpeakerStatus.disabled;
        if (_translationController.isTransliterationEnabled()) {
          getTransliterationHints(newText);
        } else {
          _translationController.transliterationWordHints.clear();
        }
      },
    );
  }

  Widget _buildTargetLanguageInput() {
    return TextField(
      controller: _translationController.targetLangTextController,
      focusNode: _transLangFocusNode,
      maxLines: null,
      expands: true,
      style: AppTextStyle().regular18balticSea,
      readOnly: true,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildLimitCountAndTranslateButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _translationController.micButtonStatus.value == MicButtonStatus.pressed
            ? Row(
                children: [
                  AvatarGlow(
                    animate: true,
                    repeat: true,
                    glowColor: brickRed,
                    endRadius: 16,
                    shape: BoxShape.circle,
                    showTwoGlows: true,
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.mic_none,
                      color: frolyRed,
                    ),
                  ),
                  SizedBox(width: 4.toWidth),
                  Padding(
                    padding: AppEdgeInsets.instance.symmetric(vertical: 0),
                    child: StreamBuilder<int>(
                      stream: _translationController.stopWatchTimer.rawTime,
                      initialData: 0,
                      builder: (context, snap) {
                        final value = snap.data;
                        final displayTime = StopWatchTimer.getDisplayTime(
                            recordingMaxTimeLimit - (value ?? 0),
                            hours: false,
                            minute: false,
                            milliSecond: true);
                        return Text(
                          '-$displayTime',
                          style: AppTextStyle().grey14Arsenic.copyWith(
                              color: (recordingMaxTimeLimit - (value ?? 0)) >=
                                      5000
                                  ? manateeGray
                                  : (recordingMaxTimeLimit - (value ?? 0)) >=
                                          2000
                                      ? frolyRed
                                      : brickRed),
                        );
                      },
                    ),
                  ),
                ],
              )
            : Obx(
                () {
                  int sourceCharLength =
                      _translationController.sourceTextCharLimit.value;
                  return Text(
                    '$sourceCharLength/$asrTextCharMaxLength',
                    style: AppTextStyle().grey14Arsenic.copyWith(
                        color: sourceCharLength >= asrTextCharMaxLength
                            ? brickRed
                            : sourceCharLength >= asrTextCharMaxLength - 20
                                ? frolyRed
                                : manateeGray),
                  );
                },
              ),
        CustomOutlineButton(
          title: kTranslate.tr,
          isHighlighted: true,
          onTap: () {
            unFocusTextFields();
            _translationController.sourceLangTTSPath = '';
            _translationController.targetLangTTSPath = '';

            if (_translationController.sourceLanTextController.text.isEmpty) {
              showDefaultSnackbar(message: kErrorNoSourceText.tr);
            } else if (_translationController.isSourceAndTargetLangSelected()) {
              _translationController.getComputeResponseASRTrans(
                  isRecorded: false,
                  sourceText:
                      _translationController.sourceLanTextController.text);
              _translationController.isRecordedViaMic.value = false;
            } else {
              showDefaultSnackbar(
                  message: kErrorSelectSourceAndTargetScreen.tr);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSourceTargetLangButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () async {
            _sourceLangFocusNode.unfocus();
            _transLangFocusNode.unfocus();

            List<dynamic> sourceLanguageList =
                _languageModelController.sourceTargetLanguageMap.keys.toList();

            dynamic selectedSourceLangCode =
                await Get.toNamed(AppRoutes.languageSelectionRoute, arguments: {
              kLanguageList: sourceLanguageList,
              kIsSourceLanguage: true,
              selectedLanguage:
                  _translationController.selectedSourceLanguageCode.value,
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
                  _translationController.selectedTargetLanguageCode.value = '';
                }
              }
              await _translationController.resetAllValues();
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
                String selectedSourceLanguage = _translationController
                        .selectedSourceLanguageCode.value.isNotEmpty
                    ? _translationController.getSelectedSourceLanguageName()
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
            _translationController.swapSourceAndTargetLanguage();
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
            _transLangFocusNode.unfocus();
            if (_translationController
                .selectedSourceLanguageCode.value.isEmpty) {
              showDefaultSnackbar(
                  message: 'Please select source language first');
              return;
            }

            List<dynamic> targetLanguageList = _languageModelController
                .sourceTargetLanguageMap[
                    _translationController.selectedSourceLanguageCode.value]!
                .toList();

            dynamic selectedTargetLangCode =
                await Get.toNamed(AppRoutes.languageSelectionRoute, arguments: {
              kLanguageList: targetLanguageList,
              kIsSourceLanguage: false,
              selectedLanguage:
                  _translationController.selectedTargetLanguageCode.value,
            });
            if (selectedTargetLangCode != null) {
              _translationController.selectedTargetLanguageCode.value =
                  selectedTargetLangCode;
              _hiveDBInstance.put(
                  preferredTargetLanguage, selectedTargetLangCode);
              if (_translationController
                  .sourceLanTextController.text.isNotEmpty)
                _translationController.getComputeResponseASRTrans(
                    isRecorded: false);
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
                String selectedTargetLanguage = _translationController
                        .selectedTargetLanguageCode.value.isNotEmpty
                    ? _translationController.getSelectedTargetLanguageName()
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
                    _translationController.micButtonStatus.value ==
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
      if (_translationController.selectedSourceLanguageCode.value.isNotEmpty) {
        _translationController.getTransliterationOutput(wordToSend);
      }
    } else {
      _translationController.clearTransliterationHints();
    }
  }

  void replaceTextWithTransliterationHint(String currentHintText) {
    List<String> oldString =
        _translationController.sourceLanTextController.text.trim().split(' ');
    oldString.removeLast();
    oldString.add(currentHintText);
    _translationController.sourceLanTextController.text =
        '${oldString.join(' ')} ';
    _translationController.sourceLanTextController.selection =
        TextSelection.fromPosition(TextPosition(
            offset:
                _translationController.sourceLanTextController.text.length));
    _translationController.clearTransliterationHints();
  }

  bool isAudioPlaying({required bool isForTargetSection}) {
    return ((isForTargetSection &&
            _translationController.targetSpeakerStatus.value ==
                SpeakerStatus.playing) ||
        (!isForTargetSection &&
            _translationController.sourceSpeakerStatus.value ==
                SpeakerStatus.playing));
  }

  void unFocusTextFields() {
    _sourceLangFocusNode.unfocus();
    _transLangFocusNode.unfocus();
  }

  bool isRecordingStarted() {
    return _hiveDBInstance.get(isStreamingPreferred)
        ? _socketIOClient.isMicConnected.value
        : _translationController.micButtonStatus.value ==
            MicButtonStatus.pressed;
  }

  void micButtonActions({required bool startMicRecording}) {
    if (_translationController.isSourceAndTargetLangSelected()) {
      unFocusTextFields();

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
