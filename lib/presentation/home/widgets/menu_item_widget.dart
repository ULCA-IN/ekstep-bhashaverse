import 'package:flutter/material.dart';

import '../../../utils/screen_util/screen_util.dart';
import '../../../utils/theme/app_theme_provider.dart';
import '../../../utils/theme/app_text_style.dart';

class MenuItem extends StatelessWidget {
  const MenuItem({
    super.key,
    required String title,
    required String image,
    required bool isDisabled,
    required Function onTap,
  })  : _title = title,
        _image = image,
        _isDisabled = isDisabled,
        _onTap = onTap;

  final String _title, _image;
  final bool _isDisabled;
  final Function _onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.appTheme.cardBGColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Flexible(
                  child: Padding(
                    padding: AppEdgeInsets.instance.all(16.0),
                    child: Image.asset(_image),
                  ),
                ),
                Text(
                  _title,
                  style: semibold22(context),
                ),
                SizedBox(height: 16.toHeight)
              ],
            ),
          ),
          if (_isDisabled)
            Container(
              decoration: BoxDecoration(
                color: context.appTheme.disabledBGColor.withOpacity(.6),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
        ],
      ),
    );
  }
}
