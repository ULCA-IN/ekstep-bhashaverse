import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../enums/speaker_status.dart';
import '../../localization/localization_keys.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/theme/app_theme_provider.dart';
import '../../utils/theme/app_text_style.dart';
import '../../utils/waveform_style.dart';
import '../custom_circular_loading.dart';

class ASRAndTTSActions extends StatelessWidget {
  const ASRAndTTSActions({
    super.key,
    required String textToCopy,
    required PlayerController playerController,
    required bool isRecordedAudio,
    required bool isShareButtonLoading,
    required String currentDuration,
    required String totalDuration,
    required SpeakerStatus speakerStatus,
    required Function onMusicPlayOrStop,
    required Function onFileShare,
  })  : _textToCopy = textToCopy,
        _playerController = playerController,
        _isRecordedAudio = isRecordedAudio,
        _isShareButtonLoading = isShareButtonLoading,
        _currentDuration = currentDuration,
        _totalDuration = totalDuration,
        _speakerStatus = speakerStatus,
        _onAudioPlayOrStop = onMusicPlayOrStop,
        _onFileShare = onFileShare;

  final bool _isRecordedAudio, _isShareButtonLoading;
  final String _textToCopy;
  final PlayerController _playerController;
  final String _currentDuration;
  final String _totalDuration;
  final SpeakerStatus _speakerStatus;
  final Function _onAudioPlayOrStop, _onFileShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Visibility(
          visible: _speakerStatus != SpeakerStatus.playing,
          child: Row(
            children: [
              InkWell(
                onTap: () async => _onFileShare(),
                child: Padding(
                  padding: AppEdgeInsets.instance.symmetric(vertical: 8),
                  child: _isShareButtonLoading
                      ? SizedBox(
                          height: 24.toWidth,
                          width: 24.toWidth,
                          child: const CustomCircularLoading(),
                        )
                      : SvgPicture.asset(
                          iconShare,
                          height: 24.toWidth,
                          width: 24.toWidth,
                          color: _textToCopy.isNotEmpty
                              ? context.appTheme.disabledTextColor
                              : context.appTheme.disabledIconOutlineColor,
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
                    color: _textToCopy.isNotEmpty
                        ? context.appTheme.disabledTextColor
                        : context.appTheme.disabledIconOutlineColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Visibility(
            visible: _speakerStatus == SpeakerStatus.playing,
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
                          style: regular12(context)
                              .copyWith(color: context.appTheme.titleTextColor),
                          textAlign: TextAlign.start),
                      Text(_totalDuration,
                          style: regular12(context)
                              .copyWith(color: context.appTheme.titleTextColor),
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
            if (_speakerStatus != SpeakerStatus.disabled) {
              _onAudioPlayOrStop();
            } else {
              showDefaultSnackbar(message: cannotPlayAudioAtTheMoment.tr);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _speakerStatus != SpeakerStatus.disabled
                  ? context.appTheme.buttonSelectedColor
                  : context.appTheme.speackerColor,
            ),
            padding: AppEdgeInsets.instance.all(8),
            child: SizedBox(
              height: 24.toWidth,
              width: 24.toWidth,
              child: _speakerStatus == SpeakerStatus.loading
                  ? const CustomCircularLoading()
                  : SvgPicture.asset(
                      _speakerStatus == SpeakerStatus.playing
                          ? iconStopPlayback
                          : iconSound,
                      color: _speakerStatus != SpeakerStatus.disabled
                          ? context.appTheme.iconOutlineColor
                          : context.appTheme.disabledIconOutlineColor,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
