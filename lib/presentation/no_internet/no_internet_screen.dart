import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../common/widgets/common_app_bar.dart';
import '../../localization/localization_keys.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/theme/app_text_style.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: honeydew,
      body: WillPopScope(
        onWillPop: () => Future.value(false),
        child: SafeArea(
            child: Padding(
          padding: AppEdgeInsets.instance.all(16),
          child: Column(
            children: [
              SizedBox(height: 20.toHeight),
              CommonAppBar(title: bhashiniTitle.tr, showBackButton: false),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(imgNoInternet),
                    SizedBox(height: 16.toHeight),
                    Text(
                      'No Internet connected',
                      style: AppTextStyle().bold24BalticSea,
                    ),
                    SizedBox(height: 12.toHeight),
                    Text(
                      'Please check your internet connection and try again.',
                      style: AppTextStyle().regular18balticSea,
                    ),
                  ],
                ),
              )
            ],
          ),
        )),
      ),
    );
  }
}
