import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';

import '../../../../common/controller/language_model_controller.dart';
import '../../../../common/widgets/asr_tts_actions.dart';
import '../../../../common/widgets/custom_outline_button.dart';
import '../../../../enums/mic_button_status.dart';
import '../../../../localization/localization_keys.dart';
import '../../../../routes/app_routes.dart';
import '../../../../services/socket_io_client.dart';
import '../../../../utils/constants/app_constants.dart';
import '../../../../utils/screen_util/screen_util.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../../utils/theme/app_colors.dart';
import '../../../../utils/theme/app_text_style.dart';
import '../../../../utils/date_time_utils.dart';
import 'controller/bottom_nav_translation_controller.dart';

class BottomNavTranslation extends StatefulWidget {
  const BottomNavTranslation({super.key});

  @override
  State<BottomNavTranslation> createState() => _BottomNavTranslationState();
}

class _BottomNavTranslationState extends State<BottomNavTranslation>
    with WidgetsBindingObserver {
  late BottomNavTranslationController _bottomNavTranslationController;
  late SocketIOClient _socketIOClient;
  late LanguageModelController _languageModelController;
  final FocusNode _sourceLangFocusNode = FocusNode();
  final FocusNode _transLangFocusNode = FocusNode();

  late final Box _hiveDBInstance;

  @override
  void initState() {
    _bottomNavTranslationController = Get.find();
    _languageModelController = Get.find();
    _socketIOClient = Get.find();
    _hiveDBInstance = Hive.box(hiveDBName);
    WidgetsBinding.instance.addObserver(this);

    _sourceLangFocusNode.addListener(() {
      _bottomNavTranslationController.isSourceInputActive.value =
          _sourceLangFocusNode.hasFocus;
    });

    _transLangFocusNode.addListener(() {
      _bottomNavTranslationController.isTargetInputActive.value =
          _transLangFocusNode.hasFocus;
    });

    ScreenUtil().init();
    super.initState();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final newValue = bottomInset > 0.0;
    if (newValue != _bottomNavTranslationController.isKeyboardVisible.value) {
      _bottomNavTranslationController.isKeyboardVisible.value = newValue;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppEdgeInsets.instance.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 18.toHeight,
          ),
          Text(
            appName.tr,
            style: AppTextStyle().semibold22BalticSea,
          ),
          SizedBox(
            height: 18.toHeight,
          ),
          Flexible(
            child: AnimatedContainer(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  border: Border.all(
                    color: americanSilver,
                  )),
              duration: const Duration(milliseconds: 500),
              child: Padding(
                padding: AppEdgeInsets.instance.all(16),
                child: Obx(
                  () => Column(
                    children: [
                      Visibility(
                        visible: !_bottomNavTranslationController
                                .isTargetInputActive.value ||
                            !_bottomNavTranslationController
                                .isKeyboardVisible.value,
                        child: Flexible(
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  _bottomNavTranslationController
                                          .getSelectedSourceLanguageName() ??
                                      '',
                                  style: AppTextStyle().regular16DolphinGrey,
                                ),
                              ),
                              SizedBox(height: 6.toHeight),
                              Flexible(child: _buildSourceLanguageInput()),
                              SizedBox(height: 6.toHeight),
                              if (_bottomNavTranslationController
                                  .isTranslateCompleted.value)
                                ASRAndTTSActions(
                                  isEnabled: _bottomNavTranslationController
                                          .isRecordedViaMic.value ||
                                      (_hiveDBInstance
                                              .get(isStreamingPreferred) &&
                                          _bottomNavTranslationController
                                              .isRecordedViaMic.value),
                                  textToShare: _bottomNavTranslationController
                                      .sourceLanTextController.text,
                                  currentDuration: DateTImeUtils()
                                      .getTimeFromMilliseconds(
                                          timeInMillisecond:
                                              _bottomNavTranslationController
                                                  .currentDuration.value),
                                  totalDuration: DateTImeUtils()
                                      .getTimeFromMilliseconds(
                                          timeInMillisecond:
                                              _bottomNavTranslationController
                                                  .maxDuration.value),
                                  isRecordedAudio: !_hiveDBInstance
                                      .get(isStreamingPreferred),
                                  isPlayingAudio: shouldShowWaveforms(false),
                                  onMusicPlayOrStop: () async {
                                    shouldShowWaveforms(false)
                                        ? await _bottomNavTranslationController
                                            .stopPlayer()
                                        : _bottomNavTranslationController
                                            .playTTSOutput(false);
                                  },
                                  playerController:
                                      _bottomNavTranslationController
                                          .controller,
                                )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 6.toHeight),
                      if (!_bottomNavTranslationController
                              .isTargetInputActive.value ||
                          !_bottomNavTranslationController
                              .isKeyboardVisible.value)
                        _buildPastOrTranslateActions(),
                      if (!_bottomNavTranslationController
                          .isKeyboardVisible.value)
                        const Divider(color: dolphinGray),
                      Visibility(
                        visible: !_bottomNavTranslationController
                                .isSourceInputActive.value ||
                            !_bottomNavTranslationController
                                .isKeyboardVisible.value,
                        child: Expanded(
                          child: Column(
                            children: [
                              SizedBox(height: 12.toHeight),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  _bottomNavTranslationController
                                          .getSelectedTargetLanguageName() ??
                                      '',
                                  style: AppTextStyle().regular16DolphinGrey,
                                ),
                              ),
                              SizedBox(height: 6.toHeight),
                              Flexible(
                                child: _buildTargetLanguageInput(),
                              ),
                              SizedBox(height: 6.toHeight),
                              ASRAndTTSActions(
                                isEnabled: _bottomNavTranslationController
                                    .isTranslateCompleted.value,
                                textToShare: _bottomNavTranslationController
                                    .targetLangTextController.text,
                                currentDuration: DateTImeUtils()
                                    .getTimeFromMilliseconds(
                                        timeInMillisecond:
                                            _bottomNavTranslationController
                                                .currentDuration.value),
                                totalDuration: DateTImeUtils()
                                    .getTimeFromMilliseconds(
                                        timeInMillisecond:
                                            _bottomNavTranslationController
                                                .maxDuration.value),
                                isRecordedAudio:
                                    !_hiveDBInstance.get(isStreamingPreferred),
                                isPlayingAudio: shouldShowWaveforms(true),
                                onMusicPlayOrStop: () async {
                                  shouldShowWaveforms(true)
                                      ? await _bottomNavTranslationController
                                          .stopPlayer()
                                      : _bottomNavTranslationController
                                          .playTTSOutput(true);
                                },
                                playerController:
                                    _bottomNavTranslationController.controller,
                              )
                              // _buildShareCopyPlayActions(
                              //     isForTargetSection: true),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildTransliterationHints(),
          SizedBox(height: 20.toHeight),
          Obx(
            () => _bottomNavTranslationController.isKeyboardVisible.value
                ? const SizedBox.shrink()
                : _buildSourceTargetLangButtons(),
          ),
          Obx(
            () => _bottomNavTranslationController.isKeyboardVisible.value
                ? const SizedBox.shrink()
                : _buildMicButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransliterationHints() {
    return Obx(() => _bottomNavTranslationController.isKeyboardVisible.value
        ? SizedBox(
            height: 85.toHeight,
            child: Column(
              children: [
                SingleChildScrollView(
                  controller: _bottomNavTranslationController
                      .transliterationHintsScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ..._bottomNavTranslationController
                          .transliterationWordHints
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
                                      // maxWidth: 300,
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
                Visibility(
                  visible: !_bottomNavTranslationController
                          .isScrolledTransliterationHints.value &&
                      _bottomNavTranslationController
                          .transliterationWordHints.isNotEmpty,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_forward_outlined,
                      color: Colors.grey.shade400,
                      size: 22.toHeight,
                    ),
                  ),
                )
              ],
            ),
          )
        : SizedBox(
            height: 8.toHeight,
          ));
  }

  Widget _buildSourceLanguageInput() {
    return TextField(
      controller: _bottomNavTranslationController.sourceLanTextController,
      focusNode: _sourceLangFocusNode,
      // readOnly: _bottomNavTranslationController.isTranslateCompleted.value,
      style: AppTextStyle().regular18balticSea,
      expands: true,
      maxLines: null,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: _bottomNavTranslationController.isTranslateCompleted.value
            ? null
            : isRecordingStarted()
                ? kListeningHintText.tr
                : _bottomNavTranslationController.micButtonStatus.value ==
                        MicButtonStatus.pressed
                    ? connecting.tr
                    : kTranslationHintText.tr,
        hintStyle:
            AppTextStyle().regular28balticSea.copyWith(color: mischkaGrey),
        hintMaxLines: _bottomNavTranslationController.isTranslateCompleted.value
            ? null
            : 2,
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (newText) {
        _bottomNavTranslationController.isTranslateCompleted.value = false;
        if (_bottomNavTranslationController.isTransliterationEnabled()) {
          getTransliterationHints(newText);
        } else {
          _bottomNavTranslationController.transliterationWordHints.clear();
        }
      },
    );
  }

  Widget _buildTargetLanguageInput() {
    return TextField(
      controller: _bottomNavTranslationController.targetLangTextController,
      focusNode: _transLangFocusNode,
      expands: true,
      maxLines: null,
      style: AppTextStyle().regular18balticSea,
      // readOnly: _bottomNavTranslationController.isTranslateCompleted.value,
      textInputAction: TextInputAction.done,

      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        hintText: 'Translation will appear here',
        hintStyle:
            AppTextStyle().regular18balticSea.copyWith(color: mischkaGrey),
      ),
    );
  }

  Widget _buildPastOrTranslateActions() {
    return Obx(
      () => Visibility(
        visible: !_bottomNavTranslationController.isTranslateCompleted.value,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomOutlineButton(
              icon: iconClipBoardText,
              title: kPaste.tr,
              onTap: () async {
                ClipboardData? clipboardData =
                    await Clipboard.getData(Clipboard.kTextPlain);
                if (clipboardData != null &&
                    (clipboardData.text ?? '').isNotEmpty) {
                  _bottomNavTranslationController.sourceLanTextController.text =
                      clipboardData.text ?? '';
                } else {
                  showDefaultSnackbar(message: errorNoTextInClipboard.tr);
                }
              },
            ),
            CustomOutlineButton(
              title: kTranslate.tr,
              isHighlighted: true,
              onTap: () {
                unFocusTextFields();
                if (_bottomNavTranslationController
                    .sourceLanTextController.text.isEmpty) {
                  showDefaultSnackbar(message: kErrorNoSourceText.tr);
                } else if (_bottomNavTranslationController
                    .isSourceAndTargetLangSelected()) {
                  _bottomNavTranslationController.translateSourceLanguage();
                } else {
                  showDefaultSnackbar(
                      message: kErrorSelectSourceAndTargetScreen.tr);
                }
              },
            ),
          ],
        ),
      ),
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
                _languageModelController.allAvailableSourceLanguages.toList();

            dynamic selectedSourceLangCode =
                await Get.toNamed(AppRoutes.languageSelectionRoute, arguments: {
              kLanguageList: sourceLanguageList,
              kIsSourceLanguage: true,
              selectedLanguage: _bottomNavTranslationController
                  .selectedSourceLanguageCode.value,
            });
            if (selectedSourceLangCode != null) {
              _bottomNavTranslationController.selectedSourceLanguageCode.value =
                  selectedSourceLangCode;
              if (selectedSourceLangCode ==
                  _bottomNavTranslationController
                      .selectedTargetLanguageCode.value) {
                _bottomNavTranslationController
                    .selectedTargetLanguageCode.value = '';
              }

              if (_bottomNavTranslationController.isTransliterationEnabled()) {
                _bottomNavTranslationController.setModelForTransliteration();
              }
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
                String selectedSourceLanguage = _bottomNavTranslationController
                        .selectedSourceLanguageCode.value.isNotEmpty
                    ? _bottomNavTranslationController
                        .getSelectedSourceLanguageName()!
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
            _bottomNavTranslationController.swapSourceAndTargetLanguage();
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

            List<dynamic> targetLanguageList =
                _languageModelController.allAvailableTargetLanguages.toList();

            if (_bottomNavTranslationController
                .selectedSourceLanguageCode.value.isNotEmpty) {
              targetLanguageList.removeWhere((eachAvailableTargetLanguage) {
                return eachAvailableTargetLanguage ==
                    _bottomNavTranslationController
                        .selectedSourceLanguageCode.value;
              });
            }

            dynamic selectedTargetLangCode =
                await Get.toNamed(AppRoutes.languageSelectionRoute, arguments: {
              kLanguageList: targetLanguageList,
              kIsSourceLanguage: false,
              selectedLanguage: _bottomNavTranslationController
                  .selectedTargetLanguageCode.value,
            });
            if (selectedTargetLangCode != null) {
              _bottomNavTranslationController.selectedTargetLanguageCode.value =
                  selectedTargetLangCode;
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
                String selectedTargetLanguage = _bottomNavTranslationController
                        .selectedTargetLanguageCode.value.isNotEmpty
                    ? _bottomNavTranslationController
                        .getSelectedTargetLanguageName()!
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
                decoration: const BoxDecoration(
                  color: flushOrangeColor,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: AppEdgeInsets.instance.all(20.0),
                  child: SvgPicture.asset(
                    _bottomNavTranslationController.micButtonStatus.value ==
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
      if (_bottomNavTranslationController
          .selectedSourceLanguageCode.value.isNotEmpty) {
        _bottomNavTranslationController.getTransliterationOutput(wordToSend);
      }
    } else {
      _bottomNavTranslationController.clearTransliterationHints();
    }
  }

  void replaceTextWithTransliterationHint(String currentHintText) {
    List<String> oldString = _bottomNavTranslationController
        .sourceLanTextController.text
        .trim()
        .split(' ');
    oldString.removeLast();
    oldString.add(currentHintText);
    _bottomNavTranslationController.sourceLanTextController.text =
        '${oldString.join(' ')} ';
    _bottomNavTranslationController.sourceLanTextController.selection =
        TextSelection.fromPosition(TextPosition(
            offset: _bottomNavTranslationController
                .sourceLanTextController.text.length));
    _bottomNavTranslationController.clearTransliterationHints();
  }

  bool shouldShowWaveforms(bool isForTargetSection) {
    return ((isForTargetSection &&
            _bottomNavTranslationController.isPlayingTarget.value) ||
        (!isForTargetSection &&
            _bottomNavTranslationController.isPlayingSource.value));
  }

  void unFocusTextFields() {
    _sourceLangFocusNode.unfocus();
    _transLangFocusNode.unfocus();
  }

  bool isRecordingStarted() {
    return _hiveDBInstance.get(isStreamingPreferred)
        ? _socketIOClient.isMicConnected.value
        : _bottomNavTranslationController.micButtonStatus.value ==
            MicButtonStatus.pressed;
  }

  void micButtonActions({required bool startMicRecording}) {
    if (_bottomNavTranslationController.isSourceAndTargetLangSelected()) {
      unFocusTextFields();

      if (startMicRecording) {
        _bottomNavTranslationController.micButtonStatus.value =
            MicButtonStatus.pressed;
        _bottomNavTranslationController.startVoiceRecording();
      } else {
        _bottomNavTranslationController.micButtonStatus.value =
            MicButtonStatus.released;
        _bottomNavTranslationController.stopVoiceRecordingAndGetResult();
      }
    } else if (startMicRecording) {
      showDefaultSnackbar(message: kErrorSelectSourceAndTargetScreen.tr);
    }
  }
}
