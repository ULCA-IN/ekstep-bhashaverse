import 'package:dio/dio.dart';

import '../models/search_model.dart';
import '../utils/constants/api_constants.dart';
import 'data_source_manager/exception/app_exceptions.dart';
import 'data_source_manager/models/api_result.dart';
import 'network_error.dart';
import '../i18n/strings.g.dart' as i18n;

class TransliterationAppAPIClient {
  late Dio _dio;

  static TransliterationAppAPIClient? transliterationAppAPIClient;

  TransliterationAppAPIClient(dio) {
    _dio = dio;
  }

  CancelToken transliterationAPIcancelToken = CancelToken();

  static TransliterationAppAPIClient getAPIClientInstance() {
    var options = BaseOptions(
      baseUrl: APIConstants.TRANSLITERATION_BASE_URL,
      connectTimeout: 80000,
      receiveTimeout: 50000,
    );

    transliterationAppAPIClient = transliterationAppAPIClient ??
        TransliterationAppAPIClient(Dio(options));
    return transliterationAppAPIClient!;
  }

  Future<Result<AppException, dynamic>> getTransliterationModels(
      {required Map<String, dynamic> taskPayloads}) async {
    try {
      final response =
          await _dio.post(APIConstants.SEARCH_REQ_URL, data: taskPayloads);

      return Result.success(SearchModel.fromJson(response.data));
    } on DioError catch (error) {
      return Result.failure(
          AppException(NetworkError(error).getErrorModel().errorMessage));
    } on Exception catch (_) {
      return Result.failure(AppException(i18n.t.somethingWentWrong));
    }
  }

  Future<Result<AppException, dynamic>?> sendTransliterationRequest(
      {required transliterationPayload}) async {
    try {
      var response = await _dio.post(
        APIConstants.TRANSLITERATION_REQ_URL,
        data: transliterationPayload,
        options: Options(
            headers: {'Content-Type': 'application/json', 'Accept': '*/*'}),
      );
      return Result.success(response.data);
    } on DioError catch (error) {
      if (error.type != DioErrorType.cancel) {
        return Result.failure(
            AppException(NetworkError(error).getErrorModel().errorMessage));
      } else {
        return null;
      }
    } on Exception catch (_) {
      return Result.failure(AppException(i18n.t.somethingWentWrong));
    }
  }
}
