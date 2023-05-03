import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_theme_provider.dart';
import '../../utils/theme/app_text_style.dart';

class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required bool isRecordingStarted,
    required bool showLanguage,
    String languageName = '',
    required Function onMicButtonTap,
    Function? onLanguageTap,
  })  : _isRecordingStarted = isRecordingStarted,
        _showLanguage = showLanguage,
        _languageName = languageName,
        _onMicButtonTap = onMicButtonTap,
        _onLanguageTap = onLanguageTap;

  final bool _isRecordingStarted, _showLanguage;
  final String _languageName;
  final Function _onMicButtonTap;
  final Function? _onLanguageTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTapDown: (_) => _onMicButtonTap(true),
          onTapUp: (_) => _onMicButtonTap(false),
          onTapCancel: () => _onMicButtonTap(false),
          onPanEnd: (_) => _onMicButtonTap(false),
          child: PhysicalModel(
            color: Colors.transparent,
            shape: BoxShape.circle,
            elevation: 6,
            child: Container(
              decoration: BoxDecoration(
                color: _isRecordingStarted
                    ? context.appTheme.buttonSelectedColor
                    : context.appTheme.disabledOrangeColor,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding:
                    AppEdgeInsets.instance.all(_isRecordingStarted ? 28 : 20.0),
                child: SvgPicture.asset(
                  _isRecordingStarted ? iconMicStop : iconMicroPhone,
                  height: 32.toHeight,
                  width: 32.toWidth,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: _showLanguage ? 10.toHeight : 0),
        if (_showLanguage)
          Container(
            child: GestureDetector(
              onTap: () => _onLanguageTap != null ? _onLanguageTap!() : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: AutoSizeText(
                      _languageName,
                      maxLines: 2,
                      style: regular18Primary(context)
                          .copyWith(fontSize: 16.toFont),
                    ),
                  ),
                  SizedBox(width: 6.toWidth),
                  SvgPicture.asset(
                    iconDownArrow,
                    color: context.appTheme.primaryTextColor,
                    width: 8.toWidth,
                    height: 8.toWidth,
                  )
                ],
              ),
            ),
          )
      ],
    );
  }
}
