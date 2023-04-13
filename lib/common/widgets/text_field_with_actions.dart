import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

import '../../enums/speaker_status.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/date_time_utils.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/theme/app_text_style.dart';
import 'asr_tts_actions.dart';
import 'custom_outline_button.dart';
import 'text_and_mic_limit.dart';

class TextFieldWithActions extends StatelessWidget {
  const TextFieldWithActions({
    super.key,
    required TextEditingController textController,
    required FocusNode focusNode,
    required String? hintText,
    required String translateButtonTitle,
    required int currentDuration,
    required int totalDuration,
    int sourceCharLength = 0,
    required bool isRecordedAudio,
    bool showMicButton = false,
    bool showTranslateButton = true,
    required bool isReadOnly,
    required bool showASRTTSActionButtons,
    required double topBorderRadius,
    required double bottomBorderRadius,
    Function? onChanged,
    Function? onSubmitted,
    Function? onTranslateButtonTap,
    required Function onMusicPlayOrStop,
    required Function onFileShare,
    required PlayerController playerController,
    required SpeakerStatus speakerStatus,
    Stream<int>? rawTimeStream,
  })  : _textController = textController,
        _focusNode = focusNode,
        _hintText = hintText,
        _translateButtonTitle = translateButtonTitle,
        _currentDuration = currentDuration,
        _totalDuration = totalDuration,
        _sourceCharLength = sourceCharLength,
        _isRecordedAudio = isRecordedAudio,
        _showMicButton = showMicButton,
        _isReadOnly = isReadOnly,
        _showTranslateButton = showTranslateButton,
        _showASRTTSActionButtons = showASRTTSActionButtons,
        _topBorderRadius = topBorderRadius,
        _bottomBorderRadius = bottomBorderRadius,
        _onChanged = onChanged,
        _onSubmitted = onSubmitted,
        _onMusicPlayOrStop = onMusicPlayOrStop,
        _onTranslateButtonTap = onTranslateButtonTap,
        _onFileShare = onFileShare,
        _playerController = playerController,
        _speakerStatus = speakerStatus,
        _rawTimeStream = rawTimeStream;

  final TextEditingController _textController;
  final FocusNode _focusNode;
  final String _translateButtonTitle;
  final String? _hintText;
  final int _currentDuration, _totalDuration, _sourceCharLength;
  final bool _isRecordedAudio,
      _showMicButton,
      _showASRTTSActionButtons,
      _showTranslateButton,
      _isReadOnly;
  final double _topBorderRadius, _bottomBorderRadius;

  final Function _onMusicPlayOrStop, _onFileShare;
  final Function? _onTranslateButtonTap, _onChanged, _onSubmitted;

  final PlayerController _playerController;
  final SpeakerStatus _speakerStatus;
  final Stream<int>? _rawTimeStream;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(_topBorderRadius),
            topRight: Radius.circular(_topBorderRadius),
            bottomLeft: Radius.circular(_bottomBorderRadius),
            bottomRight: Radius.circular(_bottomBorderRadius),
          ),
          border: Border.all(
            color: americanSilver,
          )),
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: AppEdgeInsets.instance.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: AppTextStyle().regular18balticSea,
                maxLines: null,
                expands: true,
                maxLength: textCharMaxLength,
                textInputAction: TextInputAction.done,
                readOnly: _isReadOnly,
                decoration: InputDecoration(
                  hintText: _hintText,
                  hintStyle: AppTextStyle()
                      .regular24BalticSea
                      .copyWith(color: mischkaGrey),
                  hintMaxLines: 4,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
                onChanged: (newText) =>
                    _onChanged != null ? _onChanged!(newText) : null,
                onSubmitted: (newText) =>
                    _onSubmitted != null ? _onSubmitted!(newText) : null,
              ),
            ),
            SizedBox(height: 6.toHeight),
            _showASRTTSActionButtons && !_showMicButton
                ? ASRAndTTSActions(
                    textToCopy: _textController.text.trim(),
                    currentDuration: DateTImeUtils().getTimeFromMilliseconds(
                        timeInMillisecond: _currentDuration),
                    totalDuration: DateTImeUtils().getTimeFromMilliseconds(
                        timeInMillisecond: _totalDuration),
                    isRecordedAudio: _isRecordedAudio,
                    playerController: _playerController,
                    speakerStatus: _speakerStatus,
                    onMusicPlayOrStop: () => _onMusicPlayOrStop(),
                    onFileShare: () => _onFileShare(),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextAndMicLimit(
                        showMicButton: _showMicButton,
                        sourceCharLength: _sourceCharLength,
                        rawTimeStream: _rawTimeStream,
                      ),
                      if (_showTranslateButton)
                        CustomOutlineButton(
                          title: _translateButtonTitle,
                          isHighlighted: true,
                          onTap: () => _onTranslateButtonTap != null
                              ? _onTranslateButtonTap!()
                              : null,
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
