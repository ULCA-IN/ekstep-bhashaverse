import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../localization/localization_keys.dart';
import '../models/search_model.dart';
import '../utils/constants/api_constants.dart';
import 'data_source_manager/exception/app_exceptions.dart';
import 'data_source_manager/models/api_result.dart';
import 'network_error.dart';

class TranslationAppAPIClient {
  late Dio _dio;

  static TranslationAppAPIClient? translationAppAPIClient;

  TranslationAppAPIClient(dio) {
    _dio = dio;
  }

  CancelToken transliterationAPIcancelToken = CancelToken();

  static TranslationAppAPIClient getAPIClientInstance() {
    var options = BaseOptions(
      baseUrl: APIConstants.STS_BASE_URL,
      connectTimeout: 80000,
      receiveTimeout: 50000,
    );

    translationAppAPIClient = translationAppAPIClient ??
        TranslationAppAPIClient(Dio(options)
          ..interceptors.addAll(
            [
              if (kDebugMode)
                LogInterceptor(
                  responseBody: true,
                  requestBody: true,
                ),
            ],
          ));
    return translationAppAPIClient!;
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
    } on Exception catch (error) {
      if (kDebugMode) {
        print('Other Exception::: ${error.toString()}');
      }
      return Result.failure(AppException(somethingWentWrong.tr));
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
    } on Exception catch (error) {
      if (kDebugMode) {
        print('Other Exception::: ${error.toString()}');
      }
      return Result.failure(AppException(somethingWentWrong.tr));
    }
  }
}
