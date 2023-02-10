import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../utils/screen_util/screen_util.dart';
import '../utils/theme/app_colors.dart';
import '../utils/theme/app_text_style.dart';

class LottieAnimation extends StatelessWidget {
  const LottieAnimation({
    Key? key,
    required this.context,
    required this.lottieAsset,
    required this.footerText,
  }) : super(key: key);

  final BuildContext context;
  final String lottieAsset;
  final String footerText;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.56)),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: AppEdgeInsets.instance.symmetric(horizontal: 22),
            padding: AppEdgeInsets.instance.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                LottieBuilder.asset(
                  lottieAsset,
                  width: 80.toWidth,
                  fit: BoxFit.cover,
                ),
                SizedBox(height: 14.toHeight),
                Text(
                  footerText,
                  style: AppTextStyle()
                      .regular18DolphinGrey
                      .copyWith(color: balticSea),
                ),
                SizedBox(height: 20.toHeight)
              ],
            ),
          ),
        ),
      ],
    );
  }
}
