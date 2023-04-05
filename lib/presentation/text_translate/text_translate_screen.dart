import 'dart:ui' as ui;

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../animation/lottie_animation.dart';
import '../../common/controller/language_model_controller.dart';
import '../../common/widgets/asr_tts_actions.dart';
import '../../common/widgets/common_app_bar.dart';
import '../../common/widgets/custom_outline_button.dart';
import '../../enums/speaker_status.dart';
import '../../localization/localization_keys.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants/api_constants.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/theme/app_text_style.dart';
import '../../utils/date_time_utils.dart';
import 'controller/text_translate_controller.dart';

class TextTranslateScreen extends StatefulWidget {
  const TextTranslateScreen({super.key});

  @override
  State<TextTranslateScreen> createState() => _TextTranslateScreenState();
}

class _TextTranslateScreenState extends State<TextTranslateScreen>
    with WidgetsBindingObserver {
  late TextTranslateController _textTranslationController;
  late LanguageModelController _languageModelController;
  final FocusNode _sourceLangFocusNode = FocusNode();
  final FocusNode _transLangFocusNode = FocusNode();
  late final Box _hiveDBInstance;

  @override
  void initState() {
    _textTranslationController = Get.find();
    _languageModelController = Get.find();
    _hiveDBInstance = Hive.box(hiveDBName);
    _textTranslationController.getSourceTargetLangFromDB();
    WidgetsBinding.instance.addObserver(this);

    ScreenUtil().init();
    super.initState();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != _textTranslationController.isKeyboardVisible.value) {
      _textTranslationController.isKeyboardVisible.value = newValue;
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
          SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: AppEdgeInsets.instance.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: 18.toHeight,
                        ),
                        CommonAppBar(
                            title: text.tr, onBackPress: () => Get.back()),
                        SizedBox(
                          height: 24.toHeight,
                        ),
                        _buildSourceTargetLangButtons(),
                        SizedBox(
                          height: 18.toHeight,
                        ),
                        Container(
                            height: (MediaQueryData.fromWindow(ui.window)
                                        .size
                                        .height *
                                    0.57) -
                                (MediaQueryData.fromWindow(ui.window)
                                    .padding
                                    .top) -
                                (MediaQuery.of(context).padding.bottom),
                            decoration: BoxDecoration(
                                color: lilyGrey,
                                borderRadius:
                                    const BorderRadius.all(textFieldRadius),
                                border: Border.all(
                                  color: magicMint,
                                )),
                            child: Padding(
                              padding: AppEdgeInsets.instance.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(child: _buildTargetLanguageInput()),
                                  SizedBox(height: 6.toHeight),
                                  Obx(
                                    () => ASRAndTTSActions(
                                      textToCopy: _textTranslationController
                                          .targetLangTextController.text
                                          .trim(),
                                      audioPathToShare:
                                          _textTranslationController
                                              .targetLangTTSPath,
                                      currentDuration: DateTImeUtils()
                                          .getTimeFromMilliseconds(
                                              timeInMillisecond:
                                                  _textTranslationController
                                                      .currentDuration.value),
                                      totalDuration: DateTImeUtils()
                                          .getTimeFromMilliseconds(
                                              timeInMillisecond:
                                                  _textTranslationController
                                                      .maxDuration.value),
                                      isRecordedAudio: !_hiveDBInstance
                                          .get(isStreamingPreferred),
                                      onMusicPlayOrStop: () async {
                                        if (isAudioPlaying(
                                            isForTargetSection: true)) {
                                          await _textTranslationController
                                              .stopPlayer();
                                        } else {
                                          _textTranslationController
                                              .getComputeResTTS(
                                            sourceText:
                                                _textTranslationController
                                                    .targetLangTextController
                                                    .text,
                                            languageCode:
                                                _textTranslationController
                                                    .selectedTargetLanguageCode
                                                    .value,
                                            isTargetLanguage: true,
                                          );
                                        }
                                      },
                                      playerController:
                                          _textTranslationController
                                              .playerController,
                                      speakerStatus: _textTranslationController
                                          .targetSpeakerStatus.value,
                                    ),
                                  )
                                ],
                              ),
                            )),
                        SizedBox(
                            height: _textTranslationController
                                    .isKeyboardVisible.value
                                ? 0
                                : 8.toHeight),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: true,
            child: Obx(
              () => Container(
                color: _textTranslationController.isKeyboardVisible.value
                    ? balticSea.withOpacity(0.4)
                    : Colors.transparent,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: ScreenUtil.screenHeight * 0.23,
                    margin: AppEdgeInsets.instance.all(18),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(textFieldRadius),
                        border: Border.all(
                          color: americanSilver,
                        )),
                    child: Padding(
                      padding: AppEdgeInsets.instance
                          .symmetric(vertical: 8, horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(() =>
                              Flexible(child: _buildSourceLanguageInput())),
                          SizedBox(height: 12.toHeight),
                          _buildTransliterationHints(),
                          Obx(
                            () => _textTranslationController
                                        .isTranslateCompleted.value ||
                                    _hiveDBInstance.get(isStreamingPreferred)
                                ? ASRAndTTSActions(
                                    textToCopy: _textTranslationController
                                        .sourceLanTextController.text
                                        .trim(),
                                    audioPathToShare: _textTranslationController
                                        .sourceLangTTSPath,
                                    currentDuration: DateTImeUtils()
                                        .getTimeFromMilliseconds(
                                            timeInMillisecond:
                                                _textTranslationController
                                                    .currentDuration.value),
                                    totalDuration: DateTImeUtils()
                                        .getTimeFromMilliseconds(
                                            timeInMillisecond:
                                                _textTranslationController
                                                    .maxDuration.value),
                                    isRecordedAudio: !_hiveDBInstance
                                        .get(isStreamingPreferred),
                                    onMusicPlayOrStop: () async {
                                      if (isAudioPlaying(
                                          isForTargetSection: false)) {
                                        await _textTranslationController
                                            .stopPlayer();
                                      } else {
                                        _textTranslationController
                                            .getComputeResTTS(
                                          sourceText: _textTranslationController
                                              .sourceLanTextController.text,
                                          languageCode:
                                              _textTranslationController
                                                  .selectedSourceLanguageCode
                                                  .value,
                                          isTargetLanguage: false,
                                        );
                                      }
                                    },
                                    playerController: _textTranslationController
                                        .playerController,
                                    speakerStatus: _textTranslationController
                                        .sourceSpeakerStatus.value,
                                  )
                                : _buildLimitCountAndTranslateButton(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            if (_textTranslationController.isLoading.value)
              return LottieAnimation(
                  context: context,
                  lottieAsset: animationLoadingLine,
                  footerText: _textTranslationController.isLoading.value
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
    return Obx(() => _textTranslationController.isKeyboardVisible.value || true
        ? SingleChildScrollView(
            controller:
                _textTranslationController.transliterationHintsScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ..._textTranslationController.transliterationWordHints
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
                                minWidth: (ScreenUtil.screenWidth / 7).toWidth,
                              ),
                              child: Text(
                                hintText,
                                style: AppTextStyle().regular14Arsenic.copyWith(
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
          )
        : SizedBox.shrink());
  }

  Widget _buildSourceLanguageInput() {
    return TextField(
      controller: _textTranslationController.sourceLanTextController,
      focusNode: _sourceLangFocusNode,
      style: AppTextStyle().regular18balticSea,
      maxLines: null,
      expands: true,
      maxLength: textCharMaxLength,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: _textTranslationController.isTranslateCompleted.value
            ? null
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
        _textTranslationController.sourceTextCharLimit.value = newText.length;
        _textTranslationController.isTranslateCompleted.value = false;
        _textTranslationController.ttsResponse = null;
        _textTranslationController.targetLangTextController.clear();
        if (_textTranslationController.playerController.playerState ==
            PlayerState.playing) _textTranslationController.stopPlayer();
        if (_textTranslationController.targetSpeakerStatus.value !=
            SpeakerStatus.disabled)
          _textTranslationController.targetSpeakerStatus.value =
              SpeakerStatus.disabled;
        if (_textTranslationController.isTransliterationEnabled()) {
          getTransliterationHints(newText);
        } else {
          _textTranslationController.transliterationWordHints.clear();
        }
      },
    );
  }

  Widget _buildTargetLanguageInput() {
    return TextField(
      controller: _textTranslationController.targetLangTextController,
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
        Obx(
          () {
            int sourceCharLength =
                _textTranslationController.sourceTextCharLimit.value;
            return Text(
              '$sourceCharLength/$textCharMaxLength',
              style: AppTextStyle().grey14Arsenic.copyWith(
                  color: sourceCharLength >= textCharMaxLength
                      ? brickRed
                      : sourceCharLength >= textCharMaxLength - 20
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
            _textTranslationController.sourceLangTTSPath = '';
            _textTranslationController.targetLangTTSPath = '';

            if (_textTranslationController
                .sourceLanTextController.text.isEmpty) {
              showDefaultSnackbar(message: kErrorNoSourceText.tr);
            } else if (_textTranslationController
                .isSourceAndTargetLangSelected()) {
              _textTranslationController.getComputeResponseASRTrans();
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
                  _textTranslationController.selectedSourceLanguageCode.value,
            });
            if (selectedSourceLangCode != null) {
              _textTranslationController.selectedSourceLanguageCode.value =
                  selectedSourceLangCode;
              _hiveDBInstance.put(
                  preferredSourceLanguage, selectedSourceLangCode);
              String selectedTargetLangCode =
                  _textTranslationController.selectedTargetLanguageCode.value;
              if (selectedTargetLangCode.isNotEmpty) {
                if (!_languageModelController
                    .sourceTargetLanguageMap[selectedSourceLangCode]!
                    .contains(selectedTargetLangCode)) {
                  _textTranslationController.selectedTargetLanguageCode.value =
                      '';
                }
              }
              await _textTranslationController.resetAllValues();
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
                String selectedSourceLanguage = _textTranslationController
                        .selectedSourceLanguageCode.value.isNotEmpty
                    ? APIConstants.getLanguageNameFromCode(
                        _textTranslationController
                            .selectedSourceLanguageCode.value)
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
            _textTranslationController.swapSourceAndTargetLanguage();
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
            if (_textTranslationController
                .selectedSourceLanguageCode.value.isEmpty) {
              showDefaultSnackbar(
                  message: 'Please select source language first');
              return;
            }

            List<dynamic> targetLanguageList = _languageModelController
                .sourceTargetLanguageMap[_textTranslationController
                    .selectedSourceLanguageCode.value]!
                .toList();

            dynamic selectedTargetLangCode =
                await Get.toNamed(AppRoutes.languageSelectionRoute, arguments: {
              kLanguageList: targetLanguageList,
              kIsSourceLanguage: false,
              selectedLanguage:
                  _textTranslationController.selectedTargetLanguageCode.value,
            });
            if (selectedTargetLangCode != null) {
              _textTranslationController.selectedTargetLanguageCode.value =
                  selectedTargetLangCode;
              _hiveDBInstance.put(
                  preferredTargetLanguage, selectedTargetLangCode);
              if (_textTranslationController
                  .sourceLanTextController.text.isNotEmpty)
                _textTranslationController.getComputeResponseASRTrans();
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
                String selectedTargetLanguage = _textTranslationController
                        .selectedTargetLanguageCode.value.isNotEmpty
                    ? APIConstants.getLanguageNameFromCode(
                        _textTranslationController
                            .selectedTargetLanguageCode.value)
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

  void getTransliterationHints(String newText) {
    String wordToSend = newText.split(" ").last;
    if (wordToSend.isNotEmpty) {
      if (_textTranslationController
          .selectedSourceLanguageCode.value.isNotEmpty) {
        _textTranslationController.getTransliterationOutput(wordToSend);
      }
    } else {
      _textTranslationController.clearTransliterationHints();
    }
  }

  void replaceTextWithTransliterationHint(String currentHintText) {
    List<String> oldString = _textTranslationController
        .sourceLanTextController.text
        .trim()
        .split(' ');
    oldString.removeLast();
    oldString.add(currentHintText);
    _textTranslationController.sourceLanTextController.text =
        '${oldString.join(' ')} ';
    _textTranslationController.sourceLanTextController.selection =
        TextSelection.fromPosition(TextPosition(
            offset: _textTranslationController
                .sourceLanTextController.text.length));
    _textTranslationController.clearTransliterationHints();
  }

  bool isAudioPlaying({required bool isForTargetSection}) {
    return ((isForTargetSection &&
            _textTranslationController.targetSpeakerStatus.value ==
                SpeakerStatus.playing) ||
        (!isForTargetSection &&
            _textTranslationController.sourceSpeakerStatus.value ==
                SpeakerStatus.playing));
  }

  void unFocusTextFields() {
    _sourceLangFocusNode.unfocus();
    _transLangFocusNode.unfocus();
  }
}
