import '../utils/constants/api_constants.dart';

class TaskSequenceResponse {
  List<Languages>? languages;
  List<PipelineResponseConfig>? pipelineResponseConfig;
  String? feedbackUrl;
  PipelineInferenceAPIEndPoint? pipelineInferenceAPIEndPoint;
  PipelineInferenceSocketAPIEndPoint? pipelineInferenceSocketAPIEndPoint;

  TaskSequenceResponse(
      {languages,
      pipelineResponseConfig,
      feedbackUrl,
      pipelineInferenceAPIEndPoint});

  TaskSequenceResponse.fromJson(Map<dynamic, dynamic> json) {
    if (json[APIConstants.kLanguages] != null) {
      languages = <Languages>[];
      json[APIConstants.kLanguages].forEach((v) {
        languages!.add(Languages.fromJson(v));
      });
    }
    if (json[APIConstants.kPipelineResponseConfig] != null) {
      pipelineResponseConfig = <PipelineResponseConfig>[];
      json[APIConstants.kPipelineResponseConfig].forEach((v) {
        pipelineResponseConfig!.add(PipelineResponseConfig.fromJson(v));
      });
    }
    feedbackUrl = json[APIConstants.kFeedbackUrl];
    pipelineInferenceAPIEndPoint =
        json[APIConstants.kPipelineInferenceAPIEndPoint] != null
            ? PipelineInferenceAPIEndPoint.fromJson(
                json[APIConstants.kPipelineInferenceAPIEndPoint])
            : null;
    pipelineInferenceSocketAPIEndPoint =
        json[APIConstants.kPipelineInferenceSocketEndPoint] != null
            ? PipelineInferenceSocketAPIEndPoint.fromJson(
                json[APIConstants.kPipelineInferenceSocketEndPoint])
            : null;
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = <dynamic, dynamic>{};
    if (languages != null) {
      data[APIConstants.kLanguages] =
          languages!.map((v) => v.toJson()).toList();
    }
    if (pipelineResponseConfig != null) {
      data[APIConstants.kPipelineResponseConfig] =
          pipelineResponseConfig!.map((v) => v.toJson()).toList();
    }
    data[APIConstants.kFeedbackUrl] = feedbackUrl;
    if (pipelineInferenceAPIEndPoint != null) {
      data[APIConstants.kPipelineInferenceAPIEndPoint] =
          pipelineInferenceAPIEndPoint!.toJson();
    }
    if (pipelineInferenceSocketAPIEndPoint != null) {
      data[APIConstants.kPipelineInferenceSocketEndPoint] =
          pipelineInferenceSocketAPIEndPoint!.toJson();
    }
    return data;
  }
}

class Languages {
  String? sourceLanguage;
  List<dynamic>? targetLanguageList;

  Languages({sourceLanguage, targetLanguageList});

  Languages.fromJson(Map<dynamic, dynamic> json) {
    sourceLanguage = json[APIConstants.kSourceLanguage];
    targetLanguageList = json[APIConstants.kTargetLanguageList];
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = <dynamic, dynamic>{};
    data[APIConstants.kSourceLanguage] = sourceLanguage;
    data[APIConstants.kTargetLanguageList] = targetLanguageList;
    return data;
  }
}

class PipelineResponseConfig {
  String? taskType;
  List<Config>? config;

  PipelineResponseConfig({taskType, config});

  PipelineResponseConfig.fromJson(Map<dynamic, dynamic> json) {
    taskType = json[APIConstants.kTaskType];
    if (json[APIConstants.kConfig] != null) {
      config = <Config>[];
      json[APIConstants.kConfig].forEach((v) {
        config!.add(Config.fromJson(v));
      });
    }
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = <dynamic, dynamic>{};
    data[APIConstants.kTaskType] = taskType;
    if (config != null) {
      data[APIConstants.kConfig] = config!.map((v) => v.toJson()).toList();
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

  Config({serviceId, modelId, language, domain, supportedVoices});

  Config.fromJson(Map<dynamic, dynamic> json) {
    serviceId = json[APIConstants.kServiceId];
    modelId = json[APIConstants.kModelId];
    language = json[APIConstants.kLanguage] != null
        ? Language.fromJson(json[APIConstants.kLanguage])
        : null;
    domain = json[APIConstants.kDomain];
    supportedVoices = json[APIConstants.kSupportedVoices];
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = <dynamic, dynamic>{};
    data[APIConstants.kServiceId] = serviceId;
    data[APIConstants.kModelId] = modelId;
    if (language != null) {
      data[APIConstants.kLanguage] = language!.toJson();
    }
    data[APIConstants.kDomain] = domain;
    data[APIConstants.kSupportedVoices] = supportedVoices;
    return data;
  }
}

class Language {
  String? sourceLanguage;
  String? targetLanguage;

  Language({sourceLanguage, targetLanguage});

  Language.fromJson(Map<dynamic, dynamic> json) {
    sourceLanguage = json[APIConstants.kSourceLanguage];
    targetLanguage = json[APIConstants.kTargetLanguage];
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = <dynamic, dynamic>{};
    data[APIConstants.kSourceLanguage] = sourceLanguage;
    data[APIConstants.kTargetLanguage] = targetLanguage;
    return data;
  }
}

class PipelineInferenceAPIEndPoint {
  String? callbackUrl;
  InferenceApiKey? inferenceApiKey;
  bool? isMultilingualEnabled;
  bool? isSyncApi;

  PipelineInferenceAPIEndPoint(
      {callbackUrl, inferenceApiKey, isMultilingualEnabled, isSyncApi});

  PipelineInferenceAPIEndPoint.fromJson(Map<dynamic, dynamic> json) {
    callbackUrl = json[APIConstants.kCallbackUrl];
    inferenceApiKey = json[APIConstants.kInferenceApiKey] != null
        ? InferenceApiKey.fromJson(json[APIConstants.kInferenceApiKey])
        : null;
    isMultilingualEnabled = json[APIConstants.kIsMultilingualEnabled];
    isSyncApi = json[APIConstants.kIsSyncApi];
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = <dynamic, dynamic>{};
    data[APIConstants.kCallbackUrl] = callbackUrl;
    if (inferenceApiKey != null) {
      data[APIConstants.kInferenceApiKey] = inferenceApiKey!.toJson();
    }
    data[APIConstants.kIsMultilingualEnabled] = isMultilingualEnabled;
    data[APIConstants.kIsSyncApi] = isSyncApi;
    return data;
  }
}

class InferenceApiKey {
  String? name;
  String? value;

  InferenceApiKey({name, value});

  InferenceApiKey.fromJson(Map<dynamic, dynamic> json) {
    name = json[APIConstants.kName];
    value = json[APIConstants.kValue];
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = <dynamic, dynamic>{};
    data[APIConstants.kName] = name;
    data[APIConstants.kValue] = value;
    return data;
  }
}

class PipelineInferenceSocketAPIEndPoint {
  String? callbackUrl;
  InferenceApiKey? inferenceApiKey;
  bool? isMultilingualEnabled;
  bool? isSyncApi;

  PipelineInferenceSocketAPIEndPoint(
      {callbackUrl, inferenceApiKey, isMultilingualEnabled, isSyncApi});

  PipelineInferenceSocketAPIEndPoint.fromJson(Map<dynamic, dynamic> json) {
    callbackUrl = json[APIConstants.kCallbackUrl];
    inferenceApiKey = json[APIConstants.kInferenceApiKey] != null
        ? InferenceApiKey.fromJson(json[APIConstants.kInferenceApiKey])
        : null;
    isMultilingualEnabled = json[APIConstants.kIsMultilingualEnabled];
    isSyncApi = json[APIConstants.kIsSyncApi];
  }

  Map<dynamic, dynamic> toJson() {
    final Map<dynamic, dynamic> data = <dynamic, dynamic>{};
    data[APIConstants.kCallbackUrl] = callbackUrl;
    if (inferenceApiKey != null) {
      data[APIConstants.kInferenceApiKey] = inferenceApiKey!.toJson();
    }
    data[APIConstants.kIsMultilingualEnabled] = isMultilingualEnabled;
    data[APIConstants.kIsSyncApi] = isSyncApi;
    return data;
  }
}
