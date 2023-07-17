import '../utils/constants/api_constants.dart';

class RESTComputeResponseModel {
  List<PipelineResponse>? pipelineResponse;

  RESTComputeResponseModel({pipelineResponse});

  RESTComputeResponseModel.fromJson(Map<String, dynamic> json) {
    if (json[APIConstants.kPipelineResponse] != null) {
      pipelineResponse = <PipelineResponse>[];
      json[APIConstants.kPipelineResponse].forEach((v) {
        pipelineResponse!.add(PipelineResponse.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (pipelineResponse != null) {
      data[APIConstants.kPipelineResponse] =
          pipelineResponse!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PipelineResponse {
  String? taskType;
  Config? config;
  List<Output>? output;
  List<Audio>? audio;

  PipelineResponse({taskType, config, output, audio});

  PipelineResponse.fromJson(Map<String, dynamic> json) {
    taskType = json[APIConstants.kTaskType];
    config = json[APIConstants.kConfig] != null
        ? Config.fromJson(json[APIConstants.kConfig])
        : null;
    if (json[APIConstants.kOutput] != null) {
      output = <Output>[];
      json[APIConstants.kOutput].forEach((v) {
        output!.add(Output.fromJson(v));
      });
    }
    if (json[APIConstants.kAudio] != null) {
      audio = <Audio>[];
      json[APIConstants.kAudio].forEach((v) {
        audio!.add(Audio.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data[APIConstants.kTaskType] = taskType;
    if (config != null) {
      data[APIConstants.kConfig] = config!.toJson();
    }
    if (output != null) {
      data[APIConstants.kOutput] = output!.map((v) => v.toJson()).toList();
    }
    if (audio != null) {
      data[APIConstants.kAudio] = audio!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Config {
  String? serviceId;
  Language? language;
  String? audioFormat;
  String? encoding;
  int? samplingRate;
  dynamic postProcessors;

  Config(
      {serviceId,
      language,
      audioFormat,
      encoding,
      samplingRate,
      postProcessors});

  Config.fromJson(Map<String, dynamic> json) {
    serviceId = json[APIConstants.kServiceId];
    language = json[APIConstants.kLanguage] != null
        ? Language.fromJson(json[APIConstants.kLanguage])
        : null;
    audioFormat = json[APIConstants.kAudioFormat];
    encoding = json[APIConstants.kEncoding];
    samplingRate = json[APIConstants.kSamplingRate];
    postProcessors = json[APIConstants.kPostProcessors];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data[APIConstants.kServiceId] = serviceId;
    if (language != null) {
      data[APIConstants.kLanguage] = language!.toJson();
    }
    data[APIConstants.kAudioFormat] = audioFormat;
    data[APIConstants.kEncoding] = encoding;
    data[APIConstants.kSamplingRate] = samplingRate;
    data[APIConstants.kPostProcessors] = postProcessors;
    return data;
  }
}

class Language {
  String? sourceLanguage;
  String? sourceScriptCode;

  Language({sourceLanguage, sourceScriptCode});

  Language.fromJson(Map<String, dynamic> json) {
    sourceLanguage = json[APIConstants.kSourceLanguage];
    sourceScriptCode = json[APIConstants.kSourceScriptCode];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data[APIConstants.kSourceLanguage] = sourceLanguage;
    data[APIConstants.kSourceScriptCode] = sourceScriptCode;
    return data;
  }
}

class Output {
  String? source;
  dynamic target;

  Output({source, target});

  Output.fromJson(Map<String, dynamic> json) {
    source = json[APIConstants.kSource];
    target = json[APIConstants.kTarget];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data[APIConstants.kSource] = source;
    data[APIConstants.kTarget] = target;
    return data;
  }
}

class Audio {
  String? audioContent;
  dynamic audioUri;

  Audio({audioContent, audioUri});

  Audio.fromJson(Map<String, dynamic> json) {
    audioContent = json[APIConstants.kAudioContent];
    audioUri = json[APIConstants.kAudioUri];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data[APIConstants.kAudioContent] = audioContent;
    data[APIConstants.kAudioUri] = audioUri;
    return data;
  }
}
