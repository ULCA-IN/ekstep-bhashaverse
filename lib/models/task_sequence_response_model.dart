class TaskSequenceResponse {
  List<Languages>? languages;
  List<PipelineResponseConfig>? pipelineResponseConfig;
  PipelineInferenceAPIEndPoint? pipelineInferenceAPIEndPoint;

  TaskSequenceResponse(
      {this.languages,
      this.pipelineResponseConfig,
      this.pipelineInferenceAPIEndPoint});

  TaskSequenceResponse.fromJson(Map<dynamic, dynamic> json) {
    if (json['languages'] != null) {
      languages = <Languages>[];
      json['languages'].forEach((v) {
        languages!.add(new Languages.fromJson(v));
      });
    }
    if (json['pipelineResponseConfig'] != null) {
      pipelineResponseConfig = <PipelineResponseConfig>[];
      json['pipelineResponseConfig'].forEach((v) {
        pipelineResponseConfig!.add(new PipelineResponseConfig.fromJson(v));
      });
    }
    pipelineInferenceAPIEndPoint = json['pipelineInferenceAPIEndPoint'] != null
        ? new PipelineInferenceAPIEndPoint.fromJson(
            json['pipelineInferenceAPIEndPoint'])
        : null;
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = new Map<dynamic, dynamic>();
    if (this.languages != null) {
      data['languages'] = this.languages!.map((v) => v.toJson()).toList();
    }
    if (this.pipelineResponseConfig != null) {
      data['pipelineResponseConfig'] =
          this.pipelineResponseConfig!.map((v) => v.toJson()).toList();
    }
    if (this.pipelineInferenceAPIEndPoint != null) {
      data['pipelineInferenceAPIEndPoint'] =
          this.pipelineInferenceAPIEndPoint!.toJson();
    }
    return data;
  }
}

class Languages {
  String? sourceLanguage;
  List<dynamic>? targetLanguageList;

  Languages({this.sourceLanguage, this.targetLanguageList});

  Languages.fromJson(Map<dynamic, dynamic> json) {
    sourceLanguage = json['sourceLanguage'];
    targetLanguageList = json['targetLanguageList'];
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = new Map<dynamic, dynamic>();
    data['sourceLanguage'] = this.sourceLanguage;
    data['targetLanguageList'] = this.targetLanguageList;
    return data;
  }
}

class PipelineResponseConfig {
  String? taskType;
  List<Config>? config;

  PipelineResponseConfig({this.taskType, this.config});

  PipelineResponseConfig.fromJson(Map<dynamic, dynamic> json) {
    taskType = json['taskType'];
    if (json['config'] != null) {
      config = <Config>[];
      json['config'].forEach((v) {
        config!.add(new Config.fromJson(v));
      });
    }
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = new Map<dynamic, dynamic>();
    data['taskType'] = this.taskType;
    if (this.config != null) {
      data['config'] = this.config!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Config {
  String? serviceId;
  String? modelId;
  Language? language;
  List<dynamic>? domain;
  List<dynamic>? supportedVoices;

  Config(
      {this.serviceId,
      this.modelId,
      this.language,
      this.domain,
      this.supportedVoices});

  Config.fromJson(Map<dynamic, dynamic> json) {
    serviceId = json['serviceId'];
    modelId = json['modelId'];
    language =
        json['language'] != null ? Language.fromJson(json['language']) : null;
    domain = json['domain'];
    supportedVoices = json['supportedVoices'];
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = new Map<dynamic, dynamic>();
    data['serviceId'] = this.serviceId;
    data['modelId'] = this.modelId;
    if (this.language != null) {
      data['language'] = this.language!.toJson();
    }
    data['domain'] = this.domain;
    data['supportedVoices'] = this.supportedVoices;
    return data;
  }
}

class Language {
  String? sourceLanguage;
  String? targetLanguage;

  Language({this.sourceLanguage, this.targetLanguage});

  Language.fromJson(Map<dynamic, dynamic> json) {
    sourceLanguage = json['sourceLanguage'];
    targetLanguage = json['targetLanguage'];
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = new Map<dynamic, dynamic>();
    data['sourceLanguage'] = this.sourceLanguage;
    data['targetLanguage'] = this.targetLanguage;
    return data;
  }
}

class PipelineInferenceAPIEndPoint {
  String? callbackUrl;
  InferenceApiKey? inferenceApiKey;
  bool? isMultilingualEnabled;
  bool? isSyncApi;

  PipelineInferenceAPIEndPoint(
      {this.callbackUrl,
      this.inferenceApiKey,
      this.isMultilingualEnabled,
      this.isSyncApi});

  PipelineInferenceAPIEndPoint.fromJson(Map<dynamic, dynamic> json) {
    callbackUrl = json['callbackUrl'];
    inferenceApiKey = json['inferenceApiKey'] != null
        ? new InferenceApiKey.fromJson(json['inferenceApiKey'])
        : null;
    isMultilingualEnabled = json['isMultilingualEnabled'];
    isSyncApi = json['isSyncApi'];
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = new Map<dynamic, dynamic>();
    data['callbackUrl'] = this.callbackUrl;
    if (this.inferenceApiKey != null) {
      data['inferenceApiKey'] = this.inferenceApiKey!.toJson();
    }
    data['isMultilingualEnabled'] = this.isMultilingualEnabled;
    data['isSyncApi'] = this.isSyncApi;
    return data;
  }
}

class InferenceApiKey {
  String? name;
  String? value;

  InferenceApiKey({this.name, this.value});

  InferenceApiKey.fromJson(Map<dynamic, dynamic> json) {
    name = json['name'];
    value = json['value'];
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = new Map<dynamic, dynamic>();
    data['name'] = this.name;
    data['value'] = this.value;
    return data;
  }
}
