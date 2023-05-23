import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:flutter/material.dart';

import '../../../common/widgets/generic_text_filed.dart';
import '../../../models/feedback_type_model.dart';
import '../../../utils/theme/app_text_style.dart';
import '../../../utils/theme/app_theme_provider.dart';
import '../../../utils/screen_util/screen_util.dart';

class RatingWidget extends StatelessWidget {
  const RatingWidget({
    super.key,
    required String title,
    required double rating,
    required bool expandWidget,
    TextEditingController? textController,
    FocusNode? focusNode,
    required List<GranularFeedback> granularFeedbackList,
    Function(double value)? onRatingChanged,
    Function(String value)? onTextChanged,
  })  : _title = title,
        _rating = rating,
        _expandWidget = expandWidget,
        _textController = textController,
        _focusNode = focusNode,
        _granularFeedbackList = granularFeedbackList,
        _onRatingChanged = onRatingChanged,
        _onTextChanged = onTextChanged;

  final String _title;
  final double _rating;
  final bool _expandWidget;
  final TextEditingController? _textController;
  final FocusNode? _focusNode;
  final List<GranularFeedback> _granularFeedbackList;
  final Function(double value)? _onRatingChanged;
  final Function(String value)? _onTextChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _title,
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
              onRatingChanged: _onRatingChanged,
              initialRating: _rating,
              maxRating: 5,
              alignment: Alignment.center,
            ),
          ],
        ),
        SizedBox(height: _expandWidget ? 12.toHeight : 0),
        Visibility(
          visible: _expandWidget,
          child: Column(
            children: [
              GenericTextField(
                controller: _textController ?? TextEditingController(),
                focusNode: _focusNode,
                onChange: _onTextChanged,
              ),
              ..._granularFeedbackList.map((feedback) {
                return feedback.supportedFeedbackTypes.contains('rating')
                    ? DepthRatings(
                        question: feedback.question,
                        rating: feedback.mainRating,
                        isRating:
                            feedback.supportedFeedbackTypes.contains('rating'),
                      )
                    : const SizedBox.shrink();
              })
            ],
          ),
        ),
        SizedBox(height: 10.toHeight),
        const Divider(),
        SizedBox(height: 18.toHeight),
      ],
    );
  }
}

class DepthRatings extends StatelessWidget {
  const DepthRatings({
    super.key,
    required String question,
    required bool isRating,
    double? rating,
  })  : _question = question,
        _rating = rating,
        _isRating = isRating;

  final String _question;
  final double? _rating;
  final bool _isRating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppEdgeInsets.instance.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _question,
            style: regular16(context),
          ),
          SizedBox(height: 14.toHeight),
          if (_isRating)
            RatingBar(
              filledIcon: Icons.star,
              emptyIcon: Icons.star_border,
              filledColor: context.appTheme.primaryColor,
              initialRating: _rating ?? 0,
              maxRating: 5,
              onRatingChanged: (p0) {},
            ),
        ],
      ),
    );
  }
}
