class RESTComputeResponseModel {
  final List<PipelineResponse>? pipelineResponse;

  RESTComputeResponseModel({
    this.pipelineResponse,
  });

  RESTComputeResponseModel.fromJson(Map<String, dynamic> json)
      : pipelineResponse = (json['pipelineResponse'] as List?)
            ?.map((dynamic e) =>
                PipelineResponse.fromJson(e as Map<String, dynamic>))
            .toList();

  Map<String, dynamic> toJson() =>
      {'pipelineResponse': pipelineResponse?.map((e) => e.toJson()).toList()};
}

class PipelineResponse {
  final String? taskType;
  final Config? config;
  final List<Output>? output;
  final dynamic audio;

  PipelineResponse({
    this.taskType,
    this.config,
    this.output,
    this.audio,
  });

  PipelineResponse.fromJson(Map<String, dynamic> json)
      : taskType = json['taskType'] as String?,
        config = (json['config'] as Map<String, dynamic>?) != null
            ? Config.fromJson(json['config'] as Map<String, dynamic>)
            : null,
        output = (json['output'] as List?)
            ?.map((dynamic e) => Output.fromJson(e as Map<String, dynamic>))
            .toList(),
        audio = json['audio'];

  Map<String, dynamic> toJson() => {
        'taskType': taskType,
        'config': config?.toJson(),
        'output': output?.map((e) => e.toJson()).toList(),
        'audio': audio
      };
}

class Config {
  final Language? language;
  final String? audioFormat;
  final dynamic encoding;
  final int? samplingRate;
  final dynamic postProcessors;

  Config({
    this.language,
    this.audioFormat,
    this.encoding,
    this.samplingRate,
    this.postProcessors,
  });

  Config.fromJson(Map<String, dynamic> json)
      : language = (json['language'] as Map<String, dynamic>?) != null
            ? Language.fromJson(json['language'] as Map<String, dynamic>)
            : null,
        audioFormat = json['audioFormat'] as String?,
        encoding = json['encoding'],
        samplingRate = json['samplingRate'] as int?,
        postProcessors = json['postProcessors'];

  Map<String, dynamic> toJson() => {
        'language': language?.toJson(),
        'audioFormat': audioFormat,
        'encoding': encoding,
        'samplingRate': samplingRate,
        'postProcessors': postProcessors
      };
}

class Language {
  final String? sourceLanguage;

  Language({
    this.sourceLanguage,
  });

  Language.fromJson(Map<String, dynamic> json)
      : sourceLanguage = json['sourceLanguage'] as String?;

  Map<String, dynamic> toJson() => {'sourceLanguage': sourceLanguage};
}

class Output {
  final String? source;
  final String? target;

  Output({
    this.source,
    this.target,
  });

  Output.fromJson(Map<String, dynamic> json)
      : source = json['source'] as String?,
        target = json['target'] as String?;

  Map<String, dynamic> toJson() => {'source': source};
}
