import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../localization/localization_keys.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/theme/app_text_style.dart';
import '../../utils/screen_util/screen_util.dart';

class BhashiniTitle extends StatelessWidget {
  const BhashiniTitle({
    super.key,
    Widget action = const SizedBox.shrink(),
  }) : _action = action;

  final Widget? _action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          imgAppLogoSmall,
          height: 30.toHeight,
          width: 30.toWidth,
        ),
        SizedBox(
          width: 8.toWidth,
        ),
        Text(
          bhashiniTitle.tr,
          textAlign: TextAlign.center,
          style: bold24(context),
        ),
        if (_action != null) _action!
      ],
    );
  }
}
