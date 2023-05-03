import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'screen_util/screen_util.dart';
import 'theme/app_theme_provider.dart';

class WaveformStyle {
  static PlayerWaveStyle getDefaultPlayerStyle({
    required bool isRecordedAudio,
  }) {
    final _appTheme =
        Provider.of<AppThemeProvider>(Get.context!, listen: false).theme;
    return PlayerWaveStyle(
        fixedWaveColor: _appTheme.primaryColor.withOpacity(0.3),
        liveWaveColor: _appTheme.primaryColor,
        scaleFactor: isRecordedAudio ? 200 : 70,
        waveThickness: 2);
  }

  static double getDefaultWidth = (ScreenUtil.screenWidth / 1.5);
  static double getDefaultHeight = 40.toHeight;
}
