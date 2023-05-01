import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_text_style.dart';

class CommonAppBar extends StatelessWidget {
  const CommonAppBar({
    super.key,
    required String title,
    bool showBackButton = true,
    VoidCallback? onBackPress,
  })  : _title = title,
        _showBackButton = showBackButton,
        _onBackPress = onBackPress;

  final VoidCallback? _onBackPress;
  final bool _showBackButton;
  final String _title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_showBackButton)
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _onBackPress,
              child: Padding(
                padding: AppEdgeInsets.instance.all(8.0),
                child: SvgPicture.asset(
                  iconPrevious,
                ),
              ),
            ),
          ),
        Center(
          child: Row(
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
                _title,
                style: AppTextStyle().regular24BalticSea,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
