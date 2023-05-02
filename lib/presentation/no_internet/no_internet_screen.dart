import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../common/widgets/common_app_bar.dart';
import '../../localization/localization_keys.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_theme_provider.dart';
import '../../utils/theme/app_text_style.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appTheme.backgroundColor,
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
                      errorNoInternetTitle.tr,
                      style: bold24(context),
                    ),
                    SizedBox(height: 12.toHeight),
                    Text(
                      errorNoInternetSubTitle.tr,
                      style: regular16(context)
                          .copyWith(color: context.appTheme.disabledTextColor),
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
