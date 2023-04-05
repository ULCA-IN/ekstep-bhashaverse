import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/theme/app_text_style.dart';

class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required bool isRecordingStarted,
    bool expandWhenRecording = true,
    required String languageName,
    required Function onMicButtonTap,
    required Function onLanguageTap,
  })  : _isRecordingStarted = isRecordingStarted,
        _expandWhenRecording = expandWhenRecording,
        _languageName = languageName,
        _onMicButtonTap = onMicButtonTap,
        _onLanguageTap = onLanguageTap;

  final bool _isRecordingStarted, _expandWhenRecording;
  final String _languageName;
  final Function _onMicButtonTap, _onLanguageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.redAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            // color: Colors.blueAccent,
            child: GestureDetector(
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
                        ? tangerineOrangeColor
                        : flushOrangeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: AppEdgeInsets.instance.all(
                        _isRecordingStarted && _expandWhenRecording
                            ? 28
                            : 20.0),
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
          ),
          SizedBox(height: 14.toHeight),
          Container(
            // color: flushOrangeColor,
            // padding: AppEdgeInsets.instance.all(6),
            child: GestureDetector(
              onTap: () => _onLanguageTap(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AutoSizeText(
                    _languageName,
                    maxLines: 2,
                    style: AppTextStyle()
                        .regular18balticSea
                        .copyWith(fontSize: 16.toFont),
                  ),
                  SizedBox(width: 6.toWidth),
                  // Icon(
                  //   Icons.arrow_drop_down,
                  //   size: 40.toWidth,
                  // )
                  SvgPicture.asset(
                    iconDownArrow,
                    width: 8.toWidth,
                    height: 8.toWidth,
                  )
                  // Icon(Icons.arrow_drop_down_outlined),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
