import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/constants/app_constants.dart';
import '../../utils/theme/app_text_style.dart';
import '../../i18n/strings.g.dart' as i18n;

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
          height: 0.05.sh,
          width: 0.05.sh,
        ),
        SizedBox(
          width: 0.01.sh,
        ),
        Text(
          i18n.Translations.of(context).bhashiniTitle,
          textAlign: TextAlign.center,
          style: semibold22(context),
        ),
        if (_action != null) _action!
      ],
    );
  }
}
