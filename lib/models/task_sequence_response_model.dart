class TaskSequenceResponse {
  final List<Languages>? languages;
  final List<PipelineResponseConfig>? pipelineResponseConfig;
  final PipelineInferenceAPIEndPoint? pipelineInferenceAPIEndPoint;

  TaskSequenceResponse({
    this.languages,
    this.pipelineResponseConfig,
    this.pipelineInferenceAPIEndPoint,
  });

  TaskSequenceResponse.fromJson(Map<String, dynamic> json)
      : languages = (json['languages'] as List?)
            ?.map((dynamic e) => Languages.fromJson(e as Map<String, dynamic>))
            .toList(),
        pipelineResponseConfig = (json['pipelineResponseConfig'] as List?)
            ?.map((dynamic e) =>
                PipelineResponseConfig.fromJson(e as Map<String, dynamic>))
            .toList(),
        pipelineInferenceAPIEndPoint = (json['pipelineInferenceAPIEndPoint']
                    as Map<String, dynamic>?) !=
                null
            ? PipelineInferenceAPIEndPoint.fromJson(
                json['pipelineInferenceAPIEndPoint'] as Map<String, dynamic>)
            : null;

  Map<String, dynamic> toJson() => {
        'languages': languages?.map((e) => e.toJson()).toList(),
        'pipelineResponseConfig':
            pipelineResponseConfig?.map((e) => e.toJson()).toList(),
        'pipelineInferenceAPIEndPoint': pipelineInferenceAPIEndPoint?.toJson()
      };
}

class Languages {
  final String? sourceLanguage;
  final List<String>? targetLanguageList;

  Languages({
    this.sourceLanguage,
    this.targetLanguageList,
  });

  Languages.fromJson(Map<String, dynamic> json)
      : sourceLanguage = json['sourceLanguage'] as String?,
        targetLanguageList = (json['targetLanguageList'] as List?)
            ?.map((dynamic e) => e as String)
            .toList();

  Map<String, dynamic> toJson() => {
        'sourceLanguage': sourceLanguage,
        'targetLanguageList': targetLanguageList
      };
}

class PipelineResponseConfig {
  final String? taskType;
  final List<Config>? config;

  PipelineResponseConfig({
    this.taskType,
    this.config,
  });

  PipelineResponseConfig.fromJson(Map<String, dynamic> json)
      : taskType = json['taskType'] as String?,
        config = (json['config'] as List?)
            ?.map((dynamic e) => Config.fromJson(e as Map<String, dynamic>))
            .toList();

  Map<String, dynamic> toJson() =>
      {'taskType': taskType, 'config': config?.map((e) => e.toJson()).toList()};
}

class Config {
  final String? serviceId;
  final Language? language;
  final List<String>? domain;

  Config({
    this.serviceId,
    this.language,
    this.domain,
  });

  Config.fromJson(Map<String, dynamic> json)
      : serviceId = json['serviceId'] as String?,
        language = (json['language'] as Map<String, dynamic>?) != null
            ? Language.fromJson(json['language'] as Map<String, dynamic>)
            : null,
        domain =
            (json['domain'] as List?)?.map((dynamic e) => e as String).toList();

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'language': language?.toJson(),
        'domain': domain
      };
}

class Language {
  final String? sourceLanguage;
  final String? targetLanguage;

  Language({
    this.sourceLanguage,
    this.targetLanguage,
  });

  Language.fromJson(Map<String, dynamic> json)
      : sourceLanguage = json['sourceLanguage'] as String?,
        targetLanguage = json['targetLanguage'] as String?;

  Map<String, dynamic> toJson() => {'sourceLanguage': sourceLanguage};
}

class PipelineInferenceAPIEndPoint {
  final String? callbackUrl;
  final InferenceApiKey? inferenceApiKey;
  final bool? isMultilingualEnabled;
  final bool? isSyncApi;

  PipelineInferenceAPIEndPoint({
    this.callbackUrl,
    this.inferenceApiKey,
    this.isMultilingualEnabled,
    this.isSyncApi,
  });

  PipelineInferenceAPIEndPoint.fromJson(Map<String, dynamic> json)
      : callbackUrl = json['callbackUrl'] as String?,
        inferenceApiKey =
            (json['inferenceApiKey'] as Map<String, dynamic>?) != null
                ? InferenceApiKey.fromJson(
                    json['inferenceApiKey'] as Map<String, dynamic>)
                : null,
        isMultilingualEnabled = json['isMultilingualEnabled'] as bool?,
        isSyncApi = json['isSyncApi'] as bool?;

  Map<String, dynamic> toJson() => {
        'callbackUrl': callbackUrl,
        'inferenceApiKey': inferenceApiKey?.toJson(),
        'isMultilingualEnabled': isMultilingualEnabled,
        'isSyncApi': isSyncApi
      };
}

class InferenceApiKey {
  final String? name;
  final String? value;

  InferenceApiKey({
    this.name,
    this.value,
  });

  InferenceApiKey.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String?,
        value = json['value'] as String?;

  Map<String, dynamic> toJson() => {'name': name, 'value': value};
}
