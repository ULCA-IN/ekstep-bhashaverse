import 'package:flutter/material.dart';

import '../../../utils/screen_util/screen_util.dart';
import '../../../utils/theme/app_theme_provider.dart';

class IndicatorWidget extends StatelessWidget {
  final int currentIndex;
  final int indicatorIndex;
  const IndicatorWidget(
      {Key? key, required this.currentIndex, required this.indicatorIndex})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    ScreenUtil().init();
    return Container(
      height: 8.toHeight,
      width: currentIndex == indicatorIndex ? 30.toWidth : 10.toWidth,
      margin: AppEdgeInsets.instance.only(right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: currentIndex == indicatorIndex
            ? context.appTheme.highlightedBGColor
            : context.appTheme.lightBGColor,
      ),
    );
  }
}
