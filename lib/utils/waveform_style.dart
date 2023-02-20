import 'package:audio_waveforms/audio_waveforms.dart';
import 'screen_util/screen_util.dart';
import 'theme/app_colors.dart';

class WaveformStyle {
  static PlayerWaveStyle getDefaultPlayerStyle(
          {required bool isRecordedAudio}) =>
      PlayerWaveStyle(
          fixedWaveColor: primaryColor.withOpacity(0.3),
          liveWaveColor: primaryColor,
          scaleFactor: isRecordedAudio ? 200 : 70,
          waveThickness: 2);

  static double getDefaultWidth = (ScreenUtil.screenWidth / 1.5);
  static double getDefaultHeight = 40.toHeight;
}
