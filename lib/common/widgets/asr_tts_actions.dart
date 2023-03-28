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
    required String textToCopy,
    String? audioPathToShare,
    required bool isEnabled,
    required PlayerController playerController,
    required bool isRecordedAudio,
    required bool isPlayingAudio,
    required String currentDuration,
    required String totalDuration,
    required Function onMusicPlayOrStop,
    required bool isLoading,
  })  : _isEnabled = isEnabled,
        _textToCopy = textToCopy,
        _audioPathToShare = audioPathToShare,
        _playerController = playerController,
        _isRecordedAudio = isRecordedAudio,
        _isPlayingAudio = isPlayingAudio,
        _currentDuration = currentDuration,
        _totalDuration = totalDuration,
        _onAudioPlayOrStop = onMusicPlayOrStop,
        _isLoading = isLoading;

  final bool _isEnabled, _isRecordedAudio, _isPlayingAudio;
  final String _textToCopy;
  final String? _audioPathToShare;
  final Function _onAudioPlayOrStop;
  final PlayerController _playerController;
  final String _currentDuration;
  final String _totalDuration;
  final bool _isLoading;

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
                onTap: () async {
                  if (_audioPathToShare == null || _audioPathToShare!.isEmpty) {
                    showDefaultSnackbar(message: noAudioFoundToShare.tr);
                    return;
                  } else {
                    await Share.shareXFiles(
                      [XFile(_audioPathToShare!)],
                      sharePositionOrigin: Rect.fromLTWH(0, 0,
                          ScreenUtil.screenWidth, ScreenUtil.screenHeight / 2),
                    );
                  }
                },
                child: Padding(
                  padding: AppEdgeInsets.instance.symmetric(vertical: 8),
                  child: SvgPicture.asset(
                    iconShare,
                    height: 24.toWidth,
                    width: 24.toWidth,
                    color: _textToCopy.isNotEmpty ? brightGrey : americanSilver,
                  ),
                ),
              ),
              SizedBox(width: 12.toWidth),
              InkWell(
                onTap: () async {
                  if (_textToCopy.isEmpty) {
                    showDefaultSnackbar(message: noTextForCopy.tr);
                    return;
                  } else {
                    await Clipboard.setData(ClipboardData(text: _textToCopy));
                    showDefaultSnackbar(message: textCopiedToClipboard.tr);
                  }
                },
                child: Padding(
                  padding: AppEdgeInsets.instance.symmetric(vertical: 8),
                  child: SvgPicture.asset(
                    iconCopy,
                    height: 24.toWidth,
                    width: 24.toWidth,
                    color: _textToCopy.isNotEmpty ? brightGrey : americanSilver,
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
            if (_isEnabled) {
              _onAudioPlayOrStop();
            } else {
              showDefaultSnackbar(message: cannotPlayAudioAtTheMoment.tr);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isEnabled ? flushOrangeColor : goastWhite,
            ),
            padding: AppEdgeInsets.instance.all(8),
            child: SizedBox(
              height: 24.toWidth,
              width: 24.toWidth,
              child: _isLoading
                  ? CircularProgressIndicator(
                      color: balticSea,
                      strokeWidth: 2,
                    )
                  : SvgPicture.asset(
                      _isPlayingAudio ? iconStopPlayback : iconSound,
                      color: _isEnabled ? balticSea : americanSilver,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
