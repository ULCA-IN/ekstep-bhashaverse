import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../localization/localization_keys.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_text_style.dart';
import '../../utils/theme/app_theme_provider.dart';
import '../controller/feedback_controller.dart';
import 'custom_elevated_button.dart';
import 'custom_outline_button.dart';
import 'generic_text_filed.dart';

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
    builder: (context) => FeedbackBottomSheet(),
  );
}

class FeedbackBottomSheet extends StatelessWidget {
  FeedbackBottomSheet({super.key});

  final FeedbackController _feedbackController = Get.find();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding:
              AppEdgeInsets.instance.symmetric(vertical: 8, horizontal: 22),
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
                  visible: _feedbackController.ovarralFeedback.value < 4 &&
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
                            onRatingChanged: (value) => debugPrint('$value'),
                            initialRating: 3,
                            maxRating: 5,
                            alignment: Alignment.center,
                          ),
                          CustomOutlineButton(
                            title: suggestAndEdit.tr,
                            backgroundColor: Colors.transparent,
                            showBoarder: false,
                            onTap: () {
                              _feedbackController.showSpeechToTextEditor.value =
                                  true;
                            },
                          )
                        ],
                      ),
                      SizedBox(
                          height:
                              _feedbackController.showSpeechToTextEditor.value
                                  ? 12.toHeight
                                  : 0),

                      Visibility(
                        visible:
                            _feedbackController.showSpeechToTextEditor.value,
                        child: GenericTextField(
                          controller: TextEditingController(),
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
                            onRatingChanged: (value) => debugPrint('$value'),
                            initialRating: 3,
                            maxRating: 5,
                            alignment: Alignment.center,
                          ),
                          CustomOutlineButton(
                            title: suggestAndEdit.tr,
                            backgroundColor: Colors.transparent,
                            showBoarder: false,
                            onTap: () {
                              _feedbackController.showTranslationEditor.value =
                                  true;
                            },
                          )
                        ],
                      ),
                      SizedBox(
                          height:
                              _feedbackController.showTranslationEditor.value
                                  ? 12.toHeight
                                  : 0),
                      Visibility(
                        visible:
                            _feedbackController.showTranslationEditor.value,
                        child: GenericTextField(
                          controller: TextEditingController(),
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
                        controller: TextEditingController(),
                        lines: 4,
                        hintText: writeReviewHere.tr,
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
                  textStyle: semibold22(context).copyWith(fontSize: 18.toFont),
                  backgroundColor: context.appTheme.primaryColor,
                  borderRadius: 16,
                  onButtonTap: () {
                    _feedbackController.getDetailedFeedback.value = false;
                    _feedbackController.ovarralFeedback.value = 0;
                    _feedbackController.showSpeechToTextEditor.value = false;
                    _feedbackController.showTranslationEditor.value = false;
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
