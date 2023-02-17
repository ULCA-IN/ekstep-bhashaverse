import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'constants/app_constants.dart';
import 'snackbar_utils.dart';

class VoiceRecorder {
  final Record _audioRec = Record();

  String appDocPath = "";
  String recordedAudioFileName =
      '$defaultAudioRecordingName${DateTime.now().millisecondsSinceEpoch}${Platform.isAndroid ? '.wave' : '.flac'}';
  File? audioWavInputFile;
  String _speechToBase64 = '';

  Future<void> startRecordingVoice() async {
    Directory? appDocDir = await getApplicationDocumentsDirectory();
    appDocPath = appDocDir.path;
    await _audioRec.start(
      encoder: Platform.isAndroid ? AudioEncoder.wav : AudioEncoder.flac,
      path: '$appDocPath/$recordedAudioFileName',
    );
  }

  Future<String?> stopRecordingVoiceAndGetOutput() async {
    if (await _audioRec.isRecording()) {
      await _audioRec.stop();
      _disposeRecorder();
    }
    audioWavInputFile = File('$appDocPath/$recordedAudioFileName');
    if (audioWavInputFile != null && !await audioWavInputFile!.exists()) {
      showDefaultSnackbar(message: errorRetrievingRecordingFile);
      return null;
    }
    final bytes = audioWavInputFile?.readAsBytesSync();
    _speechToBase64 = base64Encode(bytes!);
    _disposeRecorder();
    return _speechToBase64;
  }

  String? getAudioFilePath() {
    return audioWavInputFile?.path;
  }

  void deleteRecordedFile() async {
    if (audioWavInputFile != null && await audioWavInputFile!.exists()) {
      await audioWavInputFile?.delete();
    }
  }

  void _disposeRecorder() async {
    if (await _audioRec.isRecording()) {
      _audioRec.dispose();
    }
  }
}
