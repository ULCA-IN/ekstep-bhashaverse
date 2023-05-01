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
import '../../common/widgets/text_field_with_actions.dart';
import '../../common/widgets/transliteration_hints.dart';
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
  final FocusNode _targetLangFocusNode = FocusNode();
  late final Box _hiveDBInstance;
  String oldSourceText = '';

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
                        SizedBox(height: 18.toHeight),
                        CommonAppBar(
                            title: text.tr, onBackPress: () => Get.back()),
                        SizedBox(height: 24.toHeight),
                        _buildSourceTargetLangButtons(),
                        SizedBox(height: 18.toHeight),
                        _buildTargetLangInput(),
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
          _buildBackdropContainer(),
          _buildSourceLangInput(),
          _buildLoadingAnimation(),
        ],
      ),
    );
  }

  Widget _buildSourceLangInput() {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: ScreenUtil.screenHeight * 0.34,
              margin: AppEdgeInsets.instance.all(18),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.all(Radius.circular(textFieldRadius)),
                  border: Border.all(
                    color: americanSilver,
                  )),
              child: Padding(
                padding: AppEdgeInsets.instance
                    .symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() => Flexible(child: _buildSourceLangTextField())),
                    SizedBox(height: 12.toHeight),
                    _buildTransliterationHints(),
                    Obx(
                      () => _textTranslationController
                                  .isTranslateCompleted.value ||
                              _hiveDBInstance.get(isStreamingPreferred)
                          ? ASRAndTTSActions(
                              textToCopy: _textTranslationController
                                  .sourceLangTextController.text
                                  .trim(),
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
                              isRecordedAudio:
                                  !_hiveDBInstance.get(isStreamingPreferred),
                              isShareButtonLoading: _textTranslationController
                                  .isSourceShareLoading.value,
                              onMusicPlayOrStop: () =>
                                  _textTranslationController
                                      .playStopTTSOutput(true),
                              onFileShare: () => _textTranslationController
                                  .shareAudioFile(isSourceLang: true),
                              playerController:
                                  _textTranslationController.playerController,
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
    );
  }

  Widget _buildSourceLangTextField() {
    return TextField(
      controller: _textTranslationController.sourceLangTextController,
      focusNode: _sourceLangFocusNode,
      style: AppTextStyle().regular18balticSea,
      maxLines: null,
      expands: true,
      maxLength: textCharMaxLength,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: _textTranslationController.isTranslateCompleted.value
            ? null
            : textTranslateHintText.tr,
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

        if (newText.length > oldSourceText.length) {
          if (_textTranslationController.isTransliterationEnabled()) {
            int cursorPosition = _textTranslationController
                .sourceLangTextController.selection.base.offset;
            String sourceText =
                _textTranslationController.sourceLangTextController.text;
            if (sourceText.trim().isNotEmpty &&
                sourceText[cursorPosition - 1] != ' ') {
              getTransliterationHints(
                  getWordFromCursorPosition(sourceText, cursorPosition));
            } else if (sourceText.trim().isNotEmpty &&
                _textTranslationController
                    .transliterationWordHints.isNotEmpty) {
              String wordTOReplace =
                  _textTranslationController.transliterationWordHints.first;
              replaceTranslietrationHint(wordTOReplace);
            } else if (_textTranslationController
                .transliterationWordHints.isNotEmpty) {
              _textTranslationController.transliterationWordHints.clear();
            }
          } else if (_textTranslationController
              .transliterationWordHints.isNotEmpty) {
            _textTranslationController.transliterationWordHints.clear();
          }
        }
        oldSourceText = newText;
      },
    );
  }

  Widget _buildBackdropContainer() {
    return IgnorePointer(
      ignoring: true,
      child: Obx(
        () => Container(
          color: _textTranslationController.isKeyboardVisible.value
              ? balticSea.withOpacity(0.4)
              : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildTargetLangInput() {
    return Container(
      height: (ScreenUtil.screenHeight * 0.46) -
          ScreenUtil.statusBarHeight -
          ScreenUtil.bottomBarHeightPx,
      decoration: BoxDecoration(
          color: lilyGrey,
          borderRadius: const BorderRadius.all(
            Radius.circular(textFieldRadius),
          ),
          border: Border.all(
            color: magicMint,
          )),
      child: Obx(
        () => TextFieldWithActions(
          textController: _textTranslationController.targetLangTextController,
          focusNode: _targetLangFocusNode,
          backgroundColor: Colors.transparent,
          currentDuration: _textTranslationController.currentDuration.value,
          totalDuration: _textTranslationController.maxDuration.value,
          isRecordedAudio: false,
          topBorderRadius: textFieldRadius,
          bottomBorderRadius: 16,
          showTranslateButton: false,
          showASRTTSActionButtons: true,
          isReadOnly: true,
          isShareButtonLoading:
              _textTranslationController.isTargetShareLoading.value,
          textToCopy: _textTranslationController.targetOutputText.value,
          onMusicPlayOrStop: () =>
              _textTranslationController.playStopTTSOutput(false),
          onFileShare: () =>
              _textTranslationController.shareAudioFile(isSourceLang: false),
          playerController: _textTranslationController.playerController,
          speakerStatus: _textTranslationController.targetSpeakerStatus.value,
          showMicButton: false,
        ),
      ),
    );
  }

  Widget _buildTransliterationHints() {
    return Obx(() => _textTranslationController.isKeyboardVisible.value
        ? TransliterationHints(
            scrollController:
                _textTranslationController.transliterationHintsScrollController,
            // need to send with .toList() because of GetX observation issue
            transliterationHints:
                _textTranslationController.transliterationWordHints.toList(),
            showScrollIcon: false,
            isScrollArrowVisible: false,
            onSelected: (hintText) => replaceTranslietrationHint(hintText))
        : SizedBox.shrink());
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
        Obx(
          () => CustomOutlineButton(
            title: kTranslate.tr,
            isDisabled: _textTranslationController.sourceTextCharLimit.value >
                textCharMaxLength,
            onTap: () {
              unFocusTextFields();
              _textTranslationController.sourceLangTTSPath.value = '';
              _textTranslationController.targetLangTTSPath.value = '';

              if (_textTranslationController
                  .sourceLangTextController.text.isEmpty) {
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
            _targetLangFocusNode.unfocus();

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
                  _hiveDBInstance.put(preferredTargetLanguage, null);
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
            _targetLangFocusNode.unfocus();
            if (_textTranslationController
                .selectedSourceLanguageCode.value.isEmpty) {
              showDefaultSnackbar(message: errorSelectSourceLangFirst.tr);
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
                  .sourceLangTextController.text.isNotEmpty)
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

  Widget _buildLoadingAnimation() {
    return Obx(() {
      if (_textTranslationController.isLoading.value)
        return LottieAnimation(
            context: context,
            lottieAsset: animationLoadingLine,
            footerText: _textTranslationController.isLoading.value
                ? kHomeLoadingAnimationText.tr
                : kTranslationLoadingAnimationText.tr);
      else
        return const SizedBox.shrink();
    });
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

  String getWordFromCursorPosition(String text, int cursorPosition) {
    int? startingPosition = getStartingIndexOfWord(text, cursorPosition);
    int endPosition = getEndIndexOfWord(text, startingPosition ?? 0);
    if (startingPosition != null)
      return text.substring(startingPosition, endPosition);
    else
      return '';
  }

  int? getStartingIndexOfWord(String text, int cursorPosition) {
    int? startingPosOfWord;
    for (var i = (cursorPosition - 1); i >= 0 && text[i] != ' '; i--) {
      startingPosOfWord = i;
    }
    return startingPosOfWord;
  }

  int getEndIndexOfWord(String text, int startingPosition) {
    int endPosition = startingPosition;
    for (var i = startingPosition; i < (text.length) && text[i] != ' '; i++) {
      endPosition = i;
    }
    return endPosition + 1;
  }

  void replaceTranslietrationHint(String wordTOReplace) {
    String sourceText =
        _textTranslationController.sourceLangTextController.text;
    int cursorPosition = _textTranslationController
        .sourceLangTextController.selection.base.offset;
    int? startingPosition =
        getStartingIndexOfWord(sourceText, cursorPosition - 1);
    int? endingPosition = getEndIndexOfWord(sourceText, startingPosition ?? 0);
    String firstHalf = sourceText.substring(0, startingPosition);
    String secondtHalf =
        sourceText.substring(endingPosition, (sourceText.length));

    String newSentence =
        '${firstHalf.trim()} $wordTOReplace ${secondtHalf.trim()}';
    _textTranslationController.sourceLangTextController.text = newSentence;

    _textTranslationController.sourceLangTextController.selection =
        TextSelection.fromPosition(
            TextPosition(offset: '${firstHalf.trim()} $wordTOReplace '.length));

    _textTranslationController.sourceTextCharLimit.value =
        _textTranslationController.sourceLangTextController.text.length;
    _textTranslationController.clearTransliterationHints();
  }

  void unFocusTextFields() {
    _sourceLangFocusNode.unfocus();
    _targetLangFocusNode.unfocus();
  }
}
