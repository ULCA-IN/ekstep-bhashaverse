import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../localization/localization_keys.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/theme/app_text_style.dart';
import '../../utils/waveform_style.dart';

class ASRAndTTSActions extends StatelessWidget {
  const ASRAndTTSActions({
    super.key,
    required this.textToShare,
    required this.isEnabled,
    required PlayerController playerController,
    required bool isRecordedAudio,
    required bool isPlayingAudio,
    required String currentDuration,
    required String totalDuration,
    required Function onMusicPlayOrStop,
  })  : _playerController = playerController,
        _isRecordedAudio = isRecordedAudio,
        _isPlayingAudio = isPlayingAudio,
        _currentDuration = currentDuration,
        _totalDuration = totalDuration,
        _onAudioPlayOrStop = onMusicPlayOrStop;

  final bool isEnabled, _isRecordedAudio, _isPlayingAudio;
  final String textToShare;
  final Function _onAudioPlayOrStop;
  final PlayerController _playerController;
  final String _currentDuration;
  final String _totalDuration;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Visibility(
          visible: !_isPlayingAudio,
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  if (textToShare.isEmpty) {
                    showDefaultSnackbar(message: noTextForShare.tr);
                    return;
                  } else {
                    Share.share(textToShare);
                  }
                },
                child: Padding(
                  padding: AppEdgeInsets.instance.symmetric(vertical: 8),
                  child: SvgPicture.asset(
                    iconShare,
                    height: 24.toWidth,
                    width: 24.toWidth,
                    color: textToShare.isNotEmpty ? brightGrey : americanSilver,
                  ),
                ),
              ),
              SizedBox(width: 12.toWidth),
              InkWell(
                onTap: () async {
                  if (textToShare.isEmpty) {
                    showDefaultSnackbar(message: noTextForCopy.tr);
                    return;
                  } else {
                    await Clipboard.setData(ClipboardData(text: textToShare));
                    showDefaultSnackbar(message: textCopiedToClipboard.tr);
                  }
                },
                child: Padding(
                  padding: AppEdgeInsets.instance.symmetric(vertical: 8),
                  child: SvgPicture.asset(
                    iconCopy,
                    height: 24.toWidth,
                    width: 24.toWidth,
                    color: textToShare.isNotEmpty ? brightGrey : americanSilver,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Visibility(
            visible: _isPlayingAudio,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AudioFileWaveforms(
                  size: Size(WaveformStyle.getDefaultWidth,
                      WaveformStyle.getDefaultHeight),
                  playerController: _playerController,
                  waveformType: WaveformType.fitWidth,
                  playerWaveStyle: WaveformStyle.getDefaultPlayerStyle(
                    isRecordedAudio: _isRecordedAudio,
                  ),
                ),
                SizedBox(width: 8.toWidth),
                SizedBox(
                  width: WaveformStyle.getDefaultWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_currentDuration,
                          style: AppTextStyle()
                              .regular12Arsenic
                              .copyWith(color: manateeGray),
                          textAlign: TextAlign.start),
                      Text(_totalDuration,
                          style: AppTextStyle()
                              .regular12Arsenic
                              .copyWith(color: manateeGray),
                          textAlign: TextAlign.end),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.toWidth),
        InkWell(
          onTap: () {
            if (isEnabled) {
              _onAudioPlayOrStop();
            } else {
              showDefaultSnackbar(message: cannotPlayAudioAtTheMoment.tr);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled ? flushOrangeColor : goastWhite,
            ),
            padding: AppEdgeInsets.instance.all(8),
            child: SvgPicture.asset(
              _isPlayingAudio ? iconStopPlayback : iconSound,
              height: 24.toWidth,
              width: 24.toWidth,
              color: isEnabled ? balticSea : americanSilver,
            ),
          ),
        ),
      ],
    );
  }
}
