// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../models/feedback_type_model.dart';
import '../../../services/dhruva_api_client.dart';
import '../../../utils/constants/api_constants.dart';
import '../../../utils/constants/app_constants.dart';
import '../../../common/controller/language_model_controller.dart';
import '../../../utils/constants/language_map_translated.dart';
import '../../../utils/network_utils.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../i18n/strings.g.dart' as i18n;

class FeedbackController extends GetxController {
  RxDouble mainRating = 0.0.obs;
  RxList<Rx<FeedbackTypeModel>> feedbackTypeModels = RxList([]);
  RxBool isLoading = false.obs;
  String oldSourceText = '', feedbackLanguage = '';
  dynamic feedbackReqResponse;

  late DHRUVAAPIClient _dhruvaapiClient;
  late LanguageModelController _languageModelController;
  final transliterationHints = RxList([]);
  Box? _hiveDBInstance;
  Map<String, dynamic>? computePayload = {},
      computeResponse = {},
      suggestedOutput = {};

  @override
  void onInit() {
    (Get.arguments[APIConstants.kRequestPayload] as Map<String, dynamic>)
        .forEach((key, value) {
      computePayload?[key] = value;
    });

    // Fixes Dart shallow copy issue:

    Map<String, dynamic> responseCopyForSuggestedRes =
        json.decode(json.encode(Get.arguments[APIConstants.kRequestResponse]));

    (responseCopyForSuggestedRes).forEach((key, value) {
      suggestedOutput?[key] = [];
      for (Map<String, dynamic> task in value) {
        if (task[APIConstants.kTaskType] != APIConstants.kTTS) {
          suggestedOutput?[key].add(task);
        }
      }
    });

    Map<String, dynamic> responseCopyForComputeRes =
        json.decode(json.encode(Get.arguments[APIConstants.kRequestResponse]));

    (responseCopyForComputeRes).forEach((key, value) {
      computeResponse?[key] = value;
    });

    _languageModelController = Get.find();
    _dhruvaapiClient = DHRUVAAPIClient.getAPIClientInstance();
    if (_hiveDBInstance == null || !_hiveDBInstance!.isOpen) {
      _hiveDBInstance = Hive.box(hiveDBName);
    }

    super.onInit();
    feedbackLanguage = i18n.LocaleSettings.currentLocale.languageCode;
    DateTime? feedbackCacheTime =
        _hiveDBInstance?.get(feedbackCacheLastUpdatedKey);
    dynamic feedbackResponseFromCache = _hiveDBInstance?.get(feedbackCacheKey);

    if (feedbackCacheTime != null &&
        feedbackResponseFromCache != null &&
        feedbackCacheTime.isAfter(DateTime.now()) &&
        feedbackResponseFromCache[APIConstants.kFeedbackLanguage] ==
            i18n.LocaleSettings.currentLocale.languageCode) {
      // load data from cache
      feedbackReqResponse = feedbackResponseFromCache;
      getFeedbackQuestions();
    } else {
      isLoading.value = true;
      // clear cache and get new data
      _hiveDBInstance?.put(configCacheLastUpdatedKey, null);
      _hiveDBInstance?.put(feedbackCacheKey, null);
      isNetworkConnected().then((isConnected) {
        if (isConnected) {
          getFeedbackPipelines();
        } else {
          isLoading.value = false;
          showDefaultSnackbar(message: i18n.t.errorNoInternetTitle);
        }
      });
    }
  }

  @override
  void onClose() {
    feedbackTypeModels.clear();
    computePayload?.clear();
    computeResponse?.clear();
    suggestedOutput?.clear();
    transliterationHints.clear();
    super.onClose();
  }

  bool isTransliterationEnabled() {
    return _hiveDBInstance?.get(enableTransliteration, defaultValue: true);
  }

  Future<List<String>> getTransliterationOutput(
      String sourceText, String languageCode) async {
    if (languageCode == defaultLangCode ||
        _languageModelController.transliterationConfigResponse == null) {
      return [];
    }

    String transliterationServiceId = '';

    transliterationServiceId = APIConstants.getTaskTypeServiceID(
          _languageModelController.transliterationConfigResponse!,
          APIConstants.kTransliteration,
          defaultLangCode,
          languageCode,
        ) ??
        '';

    var transliterationPayloadToSend = APIConstants.createComputePayload(
        srcLanguage: defaultLangCode,
        targetLanguage: languageCode,
        isRecorded: false,
        inputData: sourceText,
        transliterationServiceID: transliterationServiceId,
        isTransliteration: true);

    var response = await _dhruvaapiClient.sendComputeRequest(
        baseUrl: _languageModelController.transliterationConfigResponse
            ?.pipelineInferenceAPIEndPoint?.callbackUrl,
        authorizationKey: _languageModelController.transliterationConfigResponse
            ?.pipelineInferenceAPIEndPoint?.inferenceApiKey?.name,
        authorizationValue: _languageModelController
            .transliterationConfigResponse
            ?.pipelineInferenceAPIEndPoint
            ?.inferenceApiKey
            ?.value,
        computePayload: transliterationPayloadToSend);

    response.when(
      success: (data) async {
        transliterationHints.value.clear();
        transliterationHints.value =
            data.pipelineResponse?.first.output?.first.target;
        return transliterationHints;
      },
      failure: (_) {
        return [];
      },
    );
    return [];
  }

  Future<void> getFeedbackPipelines() async {
    Map<String, dynamic> requestConfig = {
      APIConstants.kFeedbackLanguage: feedbackLanguage,
      APIConstants.kSupportedTasks: [
        APIConstants.kASR,
        APIConstants.kTranslation,
        APIConstants.kTTS
      ]
    };
    var languageRequestResponse = await _dhruvaapiClient.sendFeedbackRequest(
        requestPayload: requestConfig);
    languageRequestResponse.when(
      success: ((dynamic response) async {
        if (feedbackLanguage != en &&
            response[APIConstants.kCode] != null &&
            (response[APIConstants.kCode] >=
                    APIConstants.kApiErrorCodeRangeStarting ||
                response[APIConstants.kCode] <=
                    APIConstants.kApiErrorCodeRangeEnding)) {
          // if feedback api failed in current language, then retrieve using English language
          feedbackLanguage = en;
          getFeedbackPipelines();
          return;
        }

        await addFeedbackResponseInCache(response);
        feedbackReqResponse = response;
        getFeedbackQuestions();
        isLoading.value = false;
      }),
      failure: (error) {
        showDefaultSnackbar(message: i18n.t.somethingWentWrong);
        isLoading.value = false;
      },
    );
  }

  Future<void> submitFeedbackPayload() async {
    var feedbackSubmitResponse = await _dhruvaapiClient.submitFeedback(
      url: _languageModelController.taskSequenceResponse.feedbackUrl,
      authorizationKey: _languageModelController.taskSequenceResponse
          .pipelineInferenceAPIEndPoint?.inferenceApiKey?.name,
      authorizationValue: _languageModelController.taskSequenceResponse
          .pipelineInferenceAPIEndPoint?.inferenceApiKey?.value,
      requestPayload: createFeedbackSubmitPayload(),
    );
    feedbackSubmitResponse.when(
      success: ((dynamic response) async {
        showDefaultSnackbar(message: response[APIConstants.kMessage]);
      }),
      failure: (error) {
        showDefaultSnackbar(message: i18n.t.somethingWentWrong);
        isLoading.value = false;
      },
    );
  }

  void getFeedbackQuestions() {
    if (feedbackReqResponse[APIConstants.kTaskFeedback] != null &&
        feedbackReqResponse[APIConstants.kTaskFeedback] is List) {
      for (var taskFeedback
          in feedbackReqResponse[APIConstants.kTaskFeedback]) {
        List<GranularFeedback> granularFeedbacks = [];
        if (taskFeedback[APIConstants.kGranularFeedback] != null &&
            taskFeedback[APIConstants.kGranularFeedback].isNotEmpty) {
          for (var granularFeedback
              in taskFeedback[APIConstants.kGranularFeedback]) {
            granularFeedbacks.add(GranularFeedback(
              question: granularFeedback[APIConstants.kQuestion],
              mainRating: null,
              supportedFeedbackTypes:
                  granularFeedback[APIConstants.kSupportedFeedbackTypes],
              parameters: granularFeedback[APIConstants.kParameters] != null
                  ? granularFeedback[APIConstants.kParameters]
                      .map((parameter) =>
                          Parameter(paramName: parameter, paramRating: null))
                      .toList()
                  : [],
            ));
          }
        }

        Map<String, dynamic>? task =
            (suggestedOutput?[APIConstants.kPipelineResponse] as List<dynamic>)
                .firstWhereOrNull((e) =>
                    e[APIConstants.kTaskType] ==
                    taskFeedback[APIConstants.kTaskType]);
        String pipelineTaskValue = '';
        String? suggestedOutputTitle;
        switch (task?[APIConstants.kTaskType]) {
          case APIConstants.kASR:
            pipelineTaskValue =
                task?[APIConstants.kOutput][0][APIConstants.kSource];
            suggestedOutputTitle = i18n.t.suggestedOutputTextASR;
            break;
          case APIConstants.kTranslation:
            pipelineTaskValue =
                task?[APIConstants.kOutput][0][APIConstants.kTarget];
            suggestedOutputTitle = i18n.t.suggestedOutputTextTranslate;
            break;
        }
        TextEditingController feedbackTextController =
            TextEditingController(text: pipelineTaskValue);
        FocusNode feedbackFocusNode = FocusNode();
        feedbackFocusNode.addListener(() {
          oldSourceText = feedbackTextController.text;
        });
        feedbackTypeModels.add(FeedbackTypeModel(
                taskType: taskFeedback[APIConstants.kTaskType],
                question: taskFeedback[APIConstants.kCommonFeedback].length > 0
                    ? taskFeedback[APIConstants.kCommonFeedback][0]
                        [APIConstants.kQuestion]
                    : '',
                suggestedOutputTitle: suggestedOutputTitle,
                textController: feedbackTextController,
                focusNode: feedbackFocusNode,
                taskRating: Rxn<double>(),
                isExpanded: false.obs,
                granularFeedbacks: granularFeedbacks)
            .obs);
      }
    }
  }

  Future<void> addFeedbackResponseInCache(responseData) async {
    await _hiveDBInstance?.put(feedbackCacheKey, responseData);
    await _hiveDBInstance?.put(
      feedbackCacheLastUpdatedKey,
      DateTime.now().add(
        const Duration(days: 1),
      ),
    );
  }

  Map<String, dynamic> createFeedbackSubmitPayload() {
    Map<String, dynamic> submissionPayload = {};
    submissionPayload[APIConstants.kFeedbackTimeStamp] =
        DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
    submissionPayload[APIConstants.kFeedbackLanguage] =
        i18n.LocaleSettings.currentLocale.languageCode;
    submissionPayload[APIConstants.kPipelineInput] = computePayload;
    submissionPayload[APIConstants.kPipelineOutput] = computeResponse;

    // Suggested Output

    bool isUserSuggestedOutput = false;

    for (Map<String, dynamic> task
        in suggestedOutput?[APIConstants.kPipelineResponse]) {
      if (task[APIConstants.kTaskType] == APIConstants.kASR) {
        String? outputTextSource =
            (computeResponse?[APIConstants.kPipelineResponse] as List<dynamic>)
                    .firstWhere((e) =>
                        e[APIConstants.kTaskType] ==
                        task[APIConstants.kTaskType])[APIConstants.kOutput][0]
                [APIConstants.kSource];
        String? userSuggestedOutputText =
            task[APIConstants.kOutput][0][APIConstants.kSource];
        isUserSuggestedOutput = outputTextSource != userSuggestedOutputText;

        // update in translation as well
        if (isUserSuggestedOutput) {
          (suggestedOutput?[APIConstants.kPipelineResponse] as List<dynamic>)
                  .firstWhere((task) =>
                      task[APIConstants.kTaskType] ==
                      APIConstants.kTranslation)[APIConstants.kOutput][0]
              [APIConstants.kSource] = userSuggestedOutputText;
        }
      }
      if (!isUserSuggestedOutput &&
          task[APIConstants.kTaskType] == APIConstants.kTranslation) {
        String outputTextSource =
            (computeResponse?[APIConstants.kPipelineResponse] as List<dynamic>)
                    .firstWhere((e) =>
                        e[APIConstants.kTaskType] ==
                        task[APIConstants.kTaskType])[APIConstants.kOutput][0]
                [APIConstants.kTarget];
        String userSuggestedOutputText =
            task[APIConstants.kOutput][0][APIConstants.kTarget];
        isUserSuggestedOutput = outputTextSource != userSuggestedOutputText;
      }
    }
    if (isUserSuggestedOutput) {
      submissionPayload[APIConstants.kSuggestedPipelineOutput] =
          suggestedOutput;
    }

    // Pipeline Feedback

    submissionPayload[APIConstants.kPipelineFeedback] = {
      APIConstants.kCommonFeedback: [
        {
          APIConstants.kQuestion:
              feedbackReqResponse[APIConstants.kPipelineFeedback]
                  [APIConstants.kCommonFeedback][0][APIConstants.kQuestion],
          APIConstants.kFeedbackType: APIConstants.kRating,
          APIConstants.kRating: mainRating.value
        }
      ]
    };

    // Task Feedback

    List<Map<String, dynamic>> taskFeedback = [];

    for (var task in feedbackTypeModels.value) {
      if (task.value.taskRating.value != null) {
        // Granular Feedback

        List<Map<String, dynamic>> granularFeedback = [];
        if (task.value.taskRating.value! < 4) {
          for (var feedback in task.value.granularFeedbacks) {
            bool isRating =
                feedback.supportedFeedbackTypes.contains(APIConstants.kRating);

            // Granular Feedback Rating questions

            Map<String, dynamic> question = {
              APIConstants.kQuestion: feedback.question,
              APIConstants.kFeedbackType:
                  isRating ? APIConstants.kRating : APIConstants.kRatingList,
            };

            if (isRating && feedback.mainRating != null) {
              question[APIConstants.kRating] = feedback.mainRating;
            } else {
              // Granular Feedback questions parameter

              List<Map<String, dynamic>> parameters = [];

              for (var parameter in feedback.parameters) {
                if (parameter.paramRating != null) {
                  Map<String, dynamic> singleParameter = {
                    APIConstants.kParameterName: parameter.paramName,
                    APIConstants.kRating: parameter.paramRating,
                  };
                  parameters.add(singleParameter);
                }
              }

              if (parameters.isNotEmpty) {
                question[APIConstants.kRatingList] = parameters;
              }
            }
            if (question[APIConstants.kRating] != null ||
                question[APIConstants.kRatingList] != null) {
              granularFeedback.add(question);
            }
          }
        }

        taskFeedback.add({
          APIConstants.kTaskType: task.value.taskType,
          APIConstants.kCommonFeedback: [
            {
              APIConstants.kQuestion: task.value.question,
              APIConstants.kFeedbackType: APIConstants.kRating,
              APIConstants.kRating: task.value.taskRating.value,
            }
          ],
          if (granularFeedback.isNotEmpty)
            APIConstants.kGranularFeedback: granularFeedback,
        });
      }
    }

    if (taskFeedback.isNotEmpty) {
      submissionPayload[APIConstants.kTaskFeedback] = taskFeedback;
    }
    return submissionPayload;
  }
}
