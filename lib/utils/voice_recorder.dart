import 'dart:convert';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

import 'constants/app_constants.dart';
import 'snackbar_utils.dart';

class VoiceRecorder {
  final FlutterSoundRecorder _audioRec = FlutterSoundRecorder();
  String appDocPath = "";
  String recordedAudioFileName =
      '$defaultAudioRecordingName${DateTime.now().millisecondsSinceEpoch}.wav';
  File? audioWavInputFile;
  String _speechToBase64 = '';

  Future<void> startRecordingVoice() async {
    await _audioRec.openRecorder();
    final session = await AudioSession.instance;

    if (Platform.isIOS) {
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
    }

    Directory? appDocDir = await getApplicationDocumentsDirectory();
    appDocPath = appDocDir.path;
    await _audioRec.startRecorder(
      toFile: '$appDocPath/$recordedAudioFileName',
    );
  }

  Future<String?> stopRecordingVoiceAndGetOutput() async {
    if (_audioRec.isRecording) {
      await _audioRec.stopRecorder();
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

  void _disposeRecorder() {
    _audioRec.isRecording ? _audioRec.closeRecorder() : null;
  }
}
