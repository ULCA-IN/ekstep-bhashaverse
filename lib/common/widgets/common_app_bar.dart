import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_text_style.dart';

class CommonAppBar extends StatelessWidget {
  const CommonAppBar({
    super.key,
    required String title,
    required Function onBackPress,
  })  : _title = title,
        _onBackPress = onBackPress;

  final Function _onBackPress;
  final String _title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _onBackPress(),
            child: Padding(
              padding: AppEdgeInsets.instance.all(8.0),
              child: SvgPicture.asset(
                iconPrevious,
              ),
            ),
          ),
        ),
        Center(
          child: Text(
            _title,
            style: AppTextStyle().regular24BalticSea,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
