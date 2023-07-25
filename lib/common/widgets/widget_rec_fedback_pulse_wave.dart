import 'dart:math';

import 'package:audio_wave/audio_wave.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/theme/app_theme_provider.dart';

class RecordingFeedbackPulseAndWave extends StatelessWidget {
  const RecordingFeedbackPulseAndWave({super.key});

  @override
  Widget build(BuildContext context) {
    return AudioWave(
        height: 0.06.sw,
        width: 0.52.sw,
        spacing: 3,
        bars: List.generate(50, (index) {
          return AudioWaveBar(
            heightFactor: Random().nextDouble(),
            color: context.appTheme.primaryColor,
          );
        }));
  }
}
