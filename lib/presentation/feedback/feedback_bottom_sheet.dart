import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../localization/localization_keys.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/string_helper.dart';
import '../../utils/theme/app_text_style.dart';
import '../../utils/theme/app_theme_provider.dart';
import 'controller/feedback_controller.dart';
import '../../common/widgets/custom_elevated_button.dart';
import '../../common/widgets/custom_outline_button.dart';
import '../../common/widgets/generic_text_filed.dart';
import '../../common/widgets/transliteration_hints.dart';

Future showFeedbackBottomSheet({
  required BuildContext context,
}) {
  final appThemeProvider =
      Provider.of<AppThemeProvider>(context, listen: false);
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: appThemeProvider.theme.backgroundColor,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.0),
        topRight: Radius.circular(20.0),
      ),
    ),
    builder: (context) => const FeedbackBottomSheet(),
  );
}

class FeedbackBottomSheet extends StatefulWidget {
  const FeedbackBottomSheet({super.key});

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  final FeedbackController _feedbackController = Get.find();

  final TextEditingController _generalFeedbackController =
          TextEditingController(),
      _asrTextController = TextEditingController(),
      _transTextController = TextEditingController();

  final FocusNode _generalFeedbackFocusNode = FocusNode(),
      _asrFocusNode = FocusNode(),
      _transFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _feedbackController.transliterationHints.clear();

    return Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
            child: Obx(
              () => Padding(
                padding: AppEdgeInsets.instance.only(
                    top: 8,
                    left: 22,
                    right: 22,
                    bottom: MediaQuery.of(context).viewInsets.bottom +
                        (MediaQuery.of(context).viewInsets.bottom == 0 ||
                                _feedbackController.transliterationHints.isEmpty
                            ? 40.toHeight
                            : 105.toHeight)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      feedbackBottomsheetTitle.tr,
                      textAlign: TextAlign.center,
                      style: semibold22(context),
                    ),
                    SizedBox(height: 14.toHeight),
                    Text(
                      feedbackBottomsheetSubtitle.tr,
                      textAlign: TextAlign.center,
                      style: regular16(context)
                          .copyWith(color: context.appTheme.secondaryTextColor),
                    ),
                    SizedBox(height: 12.toHeight),
                    RatingBar(
                      filledIcon: Icons.star,
                      emptyIcon: Icons.star_border,
                      filledColor: context.appTheme.primaryColor,
                      onRatingChanged: (value) =>
                          _feedbackController.ovarralFeedback.value = value,
                      initialRating: _feedbackController.ovarralFeedback.value,
                      maxRating: 5,
                      alignment: Alignment.center,
                    ),
                    SizedBox(height: 18.toHeight),
                    Obx(
                      () => Visibility(
                        visible: _feedbackController.ovarralFeedback.value <
                                4 &&
                            _feedbackController.ovarralFeedback.value != 0.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Speech to text

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                rateSpeehToText.tr,
                                style: semibold18(context),
                              ),
                            ),
                            SizedBox(height: 12.toHeight),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                RatingBar(
                                  filledIcon: Icons.star,
                                  emptyIcon: Icons.star_border,
                                  filledColor: context.appTheme.primaryColor,
                                  onRatingChanged: (value) =>
                                      debugPrint('$value'),
                                  initialRating: 3,
                                  maxRating: 5,
                                  alignment: Alignment.center,
                                ),
                                CustomOutlineButton(
                                  title: suggestAndEdit.tr,
                                  backgroundColor: Colors.transparent,
                                  showBoarder: false,
                                  onTap: () {
                                    _feedbackController
                                        .showSpeechToTextEditor.value = true;
                                  },
                                )
                              ],
                            ),
                            SizedBox(
                                height: _feedbackController
                                        .showSpeechToTextEditor.value
                                    ? 12.toHeight
                                    : 0),

                            Visibility(
                              visible: _feedbackController
                                  .showSpeechToTextEditor.value,
                              child: GenericTextField(
                                controller: _asrTextController,
                                focusNode: _asrFocusNode,
                                onChange: (V) => _onTextChanged(
                                    _asrTextController,
                                    _feedbackController.oldSourceText),
                              ),
                            ),
                            SizedBox(height: 18.toHeight),

                            // Translateed text

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                rateTranslationText.tr,
                                style: semibold18(context),
                              ),
                            ),
                            SizedBox(height: 12.toHeight),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                RatingBar(
                                  filledIcon: Icons.star,
                                  emptyIcon: Icons.star_border,
                                  filledColor: context.appTheme.primaryColor,
                                  onRatingChanged: (value) =>
                                      debugPrint('$value'),
                                  initialRating: 3,
                                  maxRating: 5,
                                  alignment: Alignment.center,
                                ),
                                CustomOutlineButton(
                                  title: suggestAndEdit.tr,
                                  backgroundColor: Colors.transparent,
                                  showBoarder: false,
                                  onTap: () {
                                    _feedbackController
                                        .showTranslationEditor.value = true;
                                  },
                                )
                              ],
                            ),
                            SizedBox(
                                height: _feedbackController
                                        .showTranslationEditor.value
                                    ? 12.toHeight
                                    : 0),
                            Visibility(
                              visible: _feedbackController
                                  .showTranslationEditor.value,
                              child: GenericTextField(
                                controller: _transTextController,
                                focusNode: _transFocusNode,
                                onChange: (V) => _onTextChanged(
                                    _transTextController,
                                    _feedbackController.oldSourceText),
                              ),
                            ),
                            SizedBox(height: 18.toHeight),

                            // Translateed speech

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                rateTranslatedSpeechText.tr,
                                style: semibold18(context),
                              ),
                            ),
                            SizedBox(height: 12.toHeight),
                            RatingBar(
                              filledIcon: Icons.star,
                              emptyIcon: Icons.star_border,
                              filledColor: context.appTheme.primaryColor,
                              onRatingChanged: (value) => debugPrint('$value'),
                              initialRating: 3,
                              maxRating: 5,
                              alignment: Alignment.centerLeft,
                            ),
                            SizedBox(height: 18.toHeight),

                            // General feedback

                            GenericTextField(
                              controller: _generalFeedbackController,
                              focusNode: _generalFeedbackFocusNode,
                              lines: 4,
                              hintText: writeReviewHere.tr,
                              onChange: (V) => _onTextChanged(
                                  _generalFeedbackController,
                                  _feedbackController.oldSourceText),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 14.toHeight),
                    SizedBox(
                      width: double.infinity,
                      child: CustomElevetedButton(
                        buttonText: submit.tr,
                        textStyle:
                            semibold22(context).copyWith(fontSize: 18.toFont),
                        backgroundColor: context.appTheme.primaryColor,
                        borderRadius: 16,
                        onButtonTap: () {
                          _feedbackController.getDetailedFeedback.value = false;
                          _feedbackController.ovarralFeedback.value = 0;
                          _feedbackController.showSpeechToTextEditor.value =
                              false;
                          _feedbackController.showTranslationEditor.value =
                              false;
                          Get.back();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            child: _buildTransliterationHints(context)),
      ],
    );
  }

  Widget _buildTransliterationHints(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom != 0
        ? Obx(
            () {
              return Container(
                color: context.appTheme.backgroundColor,
                child: TransliterationHints(
                    scrollController: ScrollController(),
                    transliterationHints:
                        // ignore: invalid_use_of_protected_member
                        _feedbackController.transliterationHints.value,
                    showScrollIcon: false,
                    isScrollArrowVisible: false,
                    // !_feedbackController.isScrolledTransliterationHints.value &&
                    //     _feedbackController.transliterationHints.isNotEmpty,
                    onSelected: (hintText) {
                      if (_asrFocusNode.hasFocus) {
                        replaceWordWithHint(_asrTextController, hintText);
                        _feedbackController.transliterationHints.clear();
                      } else if (_transFocusNode.hasFocus) {
                        replaceWordWithHint(_transTextController, hintText);
                        _feedbackController.transliterationHints.clear();
                      } else if (_generalFeedbackFocusNode.hasFocus) {
                        replaceWordWithHint(
                            _generalFeedbackController, hintText);
                      }
                      _feedbackController.transliterationHints.clear();
                    }),
              );
            },
          )
        : const SizedBox.shrink();
  }

  void _onTextChanged(TextEditingController controller, oldText) {
    if (controller.text.length > oldText.length) {
      if (_feedbackController.isTransliterationEnabled()) {
        int cursorPosition = controller.selection.base.offset;
        String sourceText = controller.text;
        if (sourceText.trim().isNotEmpty &&
            sourceText[cursorPosition - 1] != ' ') {
          getTransliterationHints(
              getWordFromCursorPosition(sourceText, cursorPosition));
        } else if (sourceText.trim().isNotEmpty &&
            _feedbackController.transliterationHints.isNotEmpty) {
          String wordTOReplace = _feedbackController.transliterationHints.first;
          replaceWordWithHint(controller, wordTOReplace);
          _feedbackController.transliterationHints.clear();
        } else if (_feedbackController.transliterationHints.isNotEmpty) {
          _feedbackController.transliterationHints.clear();
        }
      } else if (_feedbackController.transliterationHints.isNotEmpty) {
        _feedbackController.transliterationHints.clear();
      }
    }
    oldText = controller.text;
  }

  void getTransliterationHints(String newText) {
    String wordToSend = newText.split(" ").last;
    if (wordToSend.isNotEmpty) {
      if (Get.locale?.languageCode != null) {
        _feedbackController.getTransliterationOutput(wordToSend);
      }
    } else {
      _feedbackController.transliterationHints.clear();
    }
  }
}
