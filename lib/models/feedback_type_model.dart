import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FeedbackTypeModel {
  final String taskType;
  final String question;
  final TextEditingController textController;
  final FocusNode focusNode;
  RxDouble taskRating;
  RxBool isExpanded;
  final List<GranularFeedback> granularFeedbacks;

  FeedbackTypeModel({
    required this.taskType,
    required this.question,
    required this.textController,
    required this.focusNode,
    required this.taskRating,
    required this.isExpanded,
    required this.granularFeedbacks,
  });
}

class GranularFeedback {
  final String question;
  final List<dynamic> supportedFeedbackTypes;
  final double mainRating;
  final List<dynamic> parameters;

  GranularFeedback({
    required this.question,
    required this.supportedFeedbackTypes,
    required this.parameters,
    required this.mainRating,
  });
}

class Parameter {
  final String paramName;
  final double paramRating;

  Parameter({
    required this.paramName,
    required this.paramRating,
  });
}
