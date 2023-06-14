import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../utils/theme/app_text_style.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          headerText,
          textAlign: TextAlign.left,
          style: semibold30(context),
        ),
        SizedBox(height: 8.w),
        Text(
          bodyText,
          style: secondary14(context),
        ),
        Expanded(
          child: Image.asset(
            imagePath,
            fit: BoxFit.fitWidth,
          ),
        ),
      ],
    );
  }
}
