import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'constants/app_constants.dart';
import 'snackbar_utils.dart';

class VoiceRecorder {
  final Record _audioRec = Record();

  String recordingPath = "";
  String recordedAudioFileName =
      '$defaultAudioRecordingName${DateTime.now().millisecondsSinceEpoch}${Platform.isAndroid ? '.wav' : '.flac'}';
  File? audioWavInputFile;
  String _speechToBase64 = '';

  Future<void> startRecordingVoice() async {
    Directory? appDocDir = await getApplicationDocumentsDirectory();

    recordingPath = '${appDocDir.path}/recordings';
    if (!await Directory(recordingPath).exists()) {
      Directory(recordingPath).create();
    }

    await _audioRec.start(
      encoder: Platform.isAndroid ? AudioEncoder.wav : AudioEncoder.flac,
      path: '$recordingPath/$recordedAudioFileName',
    );
  }

  Future<String?> stopRecordingVoiceAndGetOutput() async {
    if (await isVoiceRecording()) {
      await _audioRec.stop();
      _disposeRecorder();
    }
    audioWavInputFile = File('$recordingPath/$recordedAudioFileName');
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

  void _disposeRecorder() async {
    if (await isVoiceRecording()) {
      _audioRec.dispose();
    }
  }

  Future<bool> isVoiceRecording() async {
    return _audioRec.isRecording();
  }
}
