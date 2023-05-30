// ignore_for_file: invalid_use_of_protected_member

import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../animation/lottie_animation.dart';
import '../../common/widgets/common_app_bar.dart';
import '../../localization/localization_keys.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/string_helper.dart';
import '../../utils/theme/app_text_style.dart';
import '../../utils/theme/app_theme_provider.dart';
import 'controller/feedback_controller.dart';
import '../../common/widgets/custom_elevated_button.dart';
import '../../common/widgets/generic_text_filed.dart';
import '../../common/widgets/transliteration_hints.dart';
import 'widgets/rating_widget.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FeedbackController _feedbackController = Get.find();

  final TextEditingController _generalFeedbackController =
      TextEditingController();

  final FocusNode _generalFeedbackFocusNode = FocusNode();

  Map<String, dynamic>? computePayload = {};

  @override
  void initState() {
    computePayload = Get.arguments['requestPayload'];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(
          () => _feedbackController.isLoading.value
              ? LottieAnimation(
                  context: context,
                  lottieAsset: animationLoadingLine,
                  footerText: loading.tr)
              : Stack(
                  children: [
                    SingleChildScrollView(
                      child: Obx(
                        () => Padding(
                          padding: AppEdgeInsets.instance
                              .symmetric(vertical: 8, horizontal: 22),
                          child: Column(
                            children: [
                              SizedBox(height: 16.toHeight),
                              CommonAppBar(
                                title: feedback.tr,
                                showLogo: false,
                                onBackPress: () => Get.back(),
                              ),
                              SizedBox(height: 60.toHeight),
                              _buildCommonFeedback(context),
                              _buildTaskFeedback(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildTransliterationHints()),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(context),
    );
  }

  Column _buildCommonFeedback(BuildContext context) {
    return Column(
      children: [
        Text(
          _feedbackController.feedbackReqResponse['pipelineFeedback']
              ['commonFeedback'][0]['question'],
          textAlign: TextAlign.center,
          style: semibold22(context),
        ),
        SizedBox(height: 14.toHeight),
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
        GenericTextField(
          controller: _generalFeedbackController,
          focusNode: _generalFeedbackFocusNode,
          lines: 5,
          hintText: writeReviewHere.tr,
          onChange: (V) {
            _onTextChanged(
                _generalFeedbackController, _feedbackController.oldSourceText);
          },
        ),
        SizedBox(height: 18.toHeight),
      ],
    );
  }

  Obx _buildTaskFeedback() {
    return Obx(
      () => Visibility(
        visible: _feedbackController.ovarralFeedback.value < 4 &&
            _feedbackController.ovarralFeedback.value != 0.0,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ..._feedbackController.feedbackTypeModels.value.map((taskFeedback) {
            List<dynamic> taskList = computePayload?['pipelineTasks'];
            bool? isTaskAvailable = taskList.firstWhereOrNull((element) =>
                    element['taskType'] == taskFeedback.value.taskType) !=
                null;
            return isTaskAvailable
                ? Obx(
                    () => RatingWidget(
                      feedbackTypeModel: taskFeedback.value,
                      onRatingChanged: (value) =>
                          taskFeedback.value.taskRating.value = value,
                      onTextChanged: (v) => _onTextChanged(
                          taskFeedback.value.textController,
                          _feedbackController.oldSourceText),
                    ),
                  )
                : const SizedBox.shrink();
          })
        ]),
      ),
    );
  }

  Obx _buildSubmitButton(BuildContext context) {
    return Obx(
      () => !_feedbackController.isLoading.value
          ? Padding(
              padding: AppEdgeInsets.instance
                  .symmetric(vertical: 16, horizontal: 8.0),
              child: CustomElevetedButton(
                buttonText: submit.tr,
                textStyle: semibold22(context).copyWith(fontSize: 18.toFont),
                backgroundColor: context.appTheme.primaryColor,
                borderRadius: 16,
                onButtonTap: () {
                  _feedbackController.getDetailedFeedback.value = false;
                  _feedbackController.ovarralFeedback.value = 0;
                  Map<String, dynamic> submissionPayload = {};
                  submissionPayload['feedbackTimeStamp'] = DateTime.timestamp();
                  submissionPayload['feedbackLanguage'] =
                      Get.locale?.languageCode ?? defaultLangCode;
                  Get.back();
                },
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildTransliterationHints() {
    return MediaQuery.of(context).viewInsets.bottom != 0
        ? Obx(
            () {
              return Container(
                color: context.appTheme.backgroundColor,
                width: double.infinity,
                child: TransliterationHints(
                    scrollController: ScrollController(),
                    transliterationHints:
                        _feedbackController.transliterationHints.value,
                    showScrollIcon: false,
                    isScrollArrowVisible: false,
                    onSelected: (hintText) {
                      if (_generalFeedbackFocusNode.hasFocus) {
                        replaceWordWithHint(
                            _generalFeedbackController, hintText);
                        _feedbackController.transliterationHints.clear();
                      } else {
                        for (var taskFeedback
                            in _feedbackController.feedbackTypeModels) {
                          if (taskFeedback.value.focusNode.hasFocus) {
                            replaceWordWithHint(
                                taskFeedback.value.textController, hintText);
                            _feedbackController.transliterationHints.clear();
                            return;
                          }
                        }
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
