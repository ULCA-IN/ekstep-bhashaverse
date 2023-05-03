import 'package:flutter/material.dart';

import '../../../utils/theme/app_text_style.dart';
import '../../../utils/theme/app_theme_provider.dart';
import '/utils/screen_util/screen_util.dart';

class OnBoardingContentWidget extends StatelessWidget {
  final String imagePath;
  final String headerText;
  final String bodyText;
  const OnBoardingContentWidget(
      {Key? key,
      required this.imagePath,
      required this.headerText,
      required this.bodyText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    ScreenUtil().init();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          headerText,
          textAlign: TextAlign.left,
          style: semibold24(context).copyWith(
            fontSize: 36.toFont,
          ),
        ),
        SizedBox(height: 8.toHeight),
        Text(
          bodyText,
          style: regular18Secondary(context)
              .copyWith(color: context.appTheme.highlightedTextColor),
        ),
        SizedBox(height: 100.toHeight),
        Image.asset(imagePath, height: 300.toHeight),
      ],
    );
  }
}
