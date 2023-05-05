// To parse this JSON data, do
//
//     final socketIoComputeResponseModel = socketIoComputeResponseModelFromJson(jsonString);

import 'dart:convert';

SocketIoComputeResponseModel socketIoComputeResponseModelFromJson(String str) =>
    SocketIoComputeResponseModel.fromJson(json.decode(str));

String socketIoComputeResponseModelToJson(SocketIoComputeResponseModel data) =>
    json.encode(data.toJson());

class SocketIoComputeResponseModel {
  List<PipelineResponse> pipelineResponse;

  SocketIoComputeResponseModel({
    required this.pipelineResponse,
  });

  factory SocketIoComputeResponseModel.fromJson(Map<String, dynamic> json) =>
      SocketIoComputeResponseModel(
        pipelineResponse: List<PipelineResponse>.from(
            json["pipelineResponse"].map((x) => PipelineResponse.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "pipelineResponse":
            List<dynamic>.from(pipelineResponse.map((x) => x.toJson())),
      };
}

class PipelineResponse {
  String taskType;
  Config? config;
  List<Output>? output;
  List<Audio>? audio;

  PipelineResponse({
    required this.taskType,
    this.config,
    this.output,
    this.audio,
  });

  factory PipelineResponse.fromJson(Map<String, dynamic> json) =>
      PipelineResponse(
        taskType: json["taskType"],
        config: json["config"] == null ? null : Config.fromJson(json["config"]),
        output: json["output"] == null
            ? []
            : List<Output>.from(json["output"]!.map((x) => Output.fromJson(x))),
        audio: json["audio"] == null
            ? []
            : List<Audio>.from(json["audio"]!.map((x) => Audio.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "taskType": taskType,
        "config": config?.toJson(),
        "output": output == null
            ? []
            : List<dynamic>.from(output!.map((x) => x.toJson())),
        "audio": audio == null
            ? []
            : List<dynamic>.from(audio!.map((x) => x.toJson())),
      };
}

class Audio {
  String audioContent;

  Audio({
    required this.audioContent,
  });

  factory Audio.fromJson(Map<String, dynamic> json) => Audio(
        audioContent: json["audioContent"],
      );

  Map<String, dynamic> toJson() => {
        "audioContent": audioContent,
      };
}

class Config {
  String? serviceId;
  Language language;
  String? audioFormat;
  String? encoding;
  int samplingRate;
  dynamic postProcessors;

  Config({
    this.serviceId,
    required this.language,
    this.audioFormat,
    this.encoding,
    required this.samplingRate,
    this.postProcessors,
  });

  factory Config.fromJson(Map<String, dynamic> json) => Config(
        serviceId: json["serviceId"],
        language: Language.fromJson(json["language"]),
        audioFormat: json["audioFormat"],
        encoding: json["encoding"],
        samplingRate: json["samplingRate"],
        postProcessors: json["postProcessors"],
      );

  Map<String, dynamic> toJson() => {
        "serviceId": serviceId,
        "language": language.toJson(),
        "audioFormat": audioFormat,
        "encoding": encoding,
        "samplingRate": samplingRate,
        "postProcessors": postProcessors,
      };
}

class Language {
  String sourceLanguage;
  String sourceScriptCode;

  Language({
    required this.sourceLanguage,
    required this.sourceScriptCode,
  });

  factory Language.fromJson(Map<String, dynamic> json) => Language(
        sourceLanguage: json["sourceLanguage"],
        sourceScriptCode: json["sourceScriptCode"],
      );

  Map<String, dynamic> toJson() => {
        "sourceLanguage": sourceLanguage,
        "sourceScriptCode": sourceScriptCode,
      };
}

class Output {
  String? source;
  String? target;

  Output({
    required this.source,
    this.target,
  });

  factory Output.fromJson(Map<String, dynamic> json) => Output(
        source: json["source"],
        target: json["target"],
      );

  Map<String, dynamic> toJson() => {
        "source": source,
        "target": target,
      };
}
