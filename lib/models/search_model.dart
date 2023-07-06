import '../utils/constants/api_constants.dart';

class SearchModel {
  late String message;
  late List<SearchModelData> data;
  late int count;

  SearchModel({
    required this.message,
    required this.data,
    required this.count,
  });

  SearchModel.fromJson(Map<String, dynamic> json) {
    message = json[APIConstants.kMessage];
    if (json[APIConstants.kData] != null) {
      data = <SearchModelData>[];
      json[APIConstants.kData].forEach((v) {
        data.add(SearchModelData.fromJson(v));
      });
    }
    count = json[APIConstants.kCount];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data[APIConstants.kMessage] = message;
    data[APIConstants.kData] = this.data.map((v) => v.toJson()).toList();
    data[APIConstants.kCount] = count;
    return data;
  }
}

class SearchModelData {
  SearchModelData({
    required this.name,
    required this.description,
    required this.refUrl,
    required this.task,
    required this.languages,
    required this.submitter,
    required this.inferenceEndPoint,
    required this.modelId,
    required this.userId,
  });
  late final String name;

  late final String description;
  late final String refUrl;
  late final Task task;
  late final List<Languages> languages;

  late final Submitter submitter;
  late final InferenceEndPoint inferenceEndPoint;

  late final String modelId;
  late final String userId;

  SearchModelData.fromJson(Map<String, dynamic> json) {
    name = json[APIConstants.kName];

    description = json[APIConstants.kDescription];
    refUrl = json[APIConstants.kRefUrl];
    task = Task.fromJson(json[APIConstants.kTask]);
    languages = List.from(json[APIConstants.kLanguages])
        .map((e) => Languages.fromJson(e))
        .toList();

    submitter = Submitter.fromJson(json[APIConstants.kSubmitters]);
    inferenceEndPoint =
        InferenceEndPoint.fromJson(json[APIConstants.kInferenceEndPoint]);

    modelId = json[APIConstants.kModelId];
    userId = json[APIConstants.kUserId];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[APIConstants.kName] = name;

    data[APIConstants.kDescription] = description;
    data[APIConstants.kRefUrl] = refUrl;
    data[APIConstants.kTask] = task.toJson();
    data[APIConstants.kLanguages] = languages.map((e) => e.toJson()).toList();

    data[APIConstants.kSubmitters] = submitter.toJson();
    data[APIConstants.kInferenceEndPoint] = inferenceEndPoint.toJson();

    data[APIConstants.kModelId] = modelId;
    data[APIConstants.kUserId] = userId;

    return data;
  }
}

class Task {
  Task({
    required this.type,
  });
  late final String type;

  Task.fromJson(Map<String, dynamic> json) {
    type = json[APIConstants.kType];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[APIConstants.kType] = type;
    return data;
  }
}

class Languages {
  Languages({
    this.sourceLanguageName,
    required this.sourceLanguage,
    this.targetLanguageName,
    this.targetLanguage,
  });
  late final String? sourceLanguageName;
  late final String sourceLanguage;
  late final String? targetLanguageName;
  late final String? targetLanguage;

  Languages.fromJson(Map<String, dynamic> json) {
    sourceLanguageName = json[APIConstants.kSourceLanguageName];
    sourceLanguage = json[APIConstants.kSourceLanguage];
    targetLanguageName = json[APIConstants.kTargetLanguageName];
    targetLanguage = json[APIConstants.kTargetLanguage];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[APIConstants.kSourceLanguageName] = sourceLanguageName;
    data[APIConstants.kSourceLanguage] = sourceLanguage;
    data[APIConstants.kTargetLanguageName] = targetLanguageName;
    data[APIConstants.kTargetLanguage] = targetLanguage;
    return data;
  }
}

class Submitter {
  Submitter({
    required this.name,
    this.aboutMe,
  });
  late final String name;
  late final String? aboutMe;

  Submitter.fromJson(Map<String, dynamic> json) {
    name = json[APIConstants.kName];
    aboutMe = null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[APIConstants.kName] = name;
    data[APIConstants.kAboutMe] = aboutMe;
    return data;
  }
}

class InferenceEndPoint {
  InferenceEndPoint({
    required this.callbackUrl,
    required this.modelProcessingType,
  });
  late final String? callbackUrl;
  late final String? modelProcessingType;

  InferenceEndPoint.fromJson(Map<String, dynamic> json) {
    callbackUrl = json[APIConstants.kCallbackUrl];
    if (json[APIConstants.kSchema][APIConstants.kModelProcessingType] != null) {
      modelProcessingType = json[APIConstants.kSchema]
          [APIConstants.kModelProcessingType][APIConstants.kType];
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[APIConstants.kCallbackUrl] = callbackUrl;
    data[APIConstants.kSchema][APIConstants.kType] = modelProcessingType;

    return data;
  }
}
