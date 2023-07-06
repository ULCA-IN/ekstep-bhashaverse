import '../utils/constants/api_constants.dart';

class ASRResponseModel {
  late int count;
  late Data data;
  late String message;

  ASRResponseModel(
      {required this.count, required this.data, required this.message});

  ASRResponseModel.fromJson(Map<String, dynamic> json) {
    count = json[APIConstants.kCount] ?? 0;
    data =
        Data.fromJson(json[APIConstants.kData] ?? {APIConstants.kSource: ''});
    message = json[APIConstants.kMessage] ?? 'No Message received';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data[APIConstants.kCount] = count;
    data[APIConstants.kData] = this.data.toJson();
    data[APIConstants.kMessage] = message;
    return data;
  }
}

class Data {
  late String source;

  Data({required this.source});

  Data.fromJson(Map<String, dynamic> json) {
    source = json[APIConstants.kSource];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data[APIConstants.kSource] = source;
    return data;
  }
}
