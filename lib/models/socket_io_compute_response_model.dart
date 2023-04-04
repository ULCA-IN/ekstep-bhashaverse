class SocketIOComputeResponseModel {
  List<Results>? results;

  SocketIOComputeResponseModel({results});

  SocketIOComputeResponseModel.fromJson(Map<String, dynamic> json) {
    if (json['results'] != null) {
      results = <Results>[];
      json['results'].forEach((v) {
        results!.add(Results.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (results != null) {
      data['results'] = results!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Results {
  Config? config;
  List<Output>? output;
  List<Audio?>? audio;

  Results({config, output, audio});

  Results.fromJson(Map<String, dynamic> json) {
    config = json['config'] != null ? Config.fromJson(json['config']) : null;
    if (json['output'] != null) {
      output = <Output>[];
      json['output'].forEach((v) {
        output!.add(Output.fromJson(v));
      });
    }
    if (json['audio'] != null) {
      audio = <Audio>[];
      json['audio'].forEach((v) {
        audio!.add(Audio.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (config != null) {
      data['config'] = config!.toJson();
    }
    if (output != null) {
      data['output'] = output!.map((v) => v.toJson()).toList();
    }
    if (audio != null) {
      data['audio'] = audio!.map((v) => v!.toJson()).toList();
    }
    return data;
  }
}

class Config {
  Language? language;
  String? audioFormat;
  String? encoding;
  int? samplingRate;
  dynamic postProcessors;

  Config({language, audioFormat, encoding, samplingRate, postProcessors});

  Config.fromJson(Map<String, dynamic> json) {
    language =
        json['language'] != null ? Language.fromJson(json['language']) : null;
    audioFormat = json['audioFormat'];
    encoding = json['encoding'];
    samplingRate = json['samplingRate'];
    postProcessors = json['postProcessors'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (language != null) {
      data['language'] = language!.toJson();
    }
    data['audioFormat'] = audioFormat;
    data['encoding'] = encoding;
    data['samplingRate'] = samplingRate;
    data['postProcessors'] = postProcessors;
    return data;
  }
}

class Language {
  String? sourceLanguage;
  String? targetLanguage;

  Language({sourceLanguage, targetLanguage});

  Language.fromJson(Map<String, dynamic> json) {
    sourceLanguage = json['sourceLanguage'];
    targetLanguage = json['targetLanguage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sourceLanguage'] = sourceLanguage;
    data['targetLanguage'] = targetLanguage;
    return data;
  }
}

class Output {
  String? source;
  String? target;

  Output({source, target});

  Output.fromJson(Map<String, dynamic> json) {
    source = json['source'];
    target = json['target'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['source'] = source;
    data['target'] = target;
    return data;
  }
}

class Audio {
  dynamic audioContent;

  Audio({audioContent});

  Audio.fromJson(Map<String, dynamic> json) {
    if (audioContent != null) audioContent = json['audioContent'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['audioContent'] = audioContent;
    return data;
  }
}
