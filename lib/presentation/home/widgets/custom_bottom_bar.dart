import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../localization/localization_keys.dart';
import '../../../models/bottom_menu_item_model.dart';
import '../../../utils/constants/app_constants.dart';
import '../../../utils/screen_util/screen_util.dart';
import '../../../utils/theme/app_colors.dart';

class CustomBottomBar extends StatelessWidget {
  CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final Function onChanged;

  final List<BottomMenuItemModel> bottomMenuList = [
    BottomMenuItemModel(
      icon: iconTranslation,
      label: kTranslation.tr,
    ),

    // TODO: uncomment after chat feature added
    // BottomMenuItemModel(
    //   icon: iconChat,
    //   label:kChat.tr,
    // ),
    BottomMenuItemModel(
      icon: iconSettings,
      label: kSettings.tr,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppEdgeInsets.instance.only(top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.toWidth),
            topRight: Radius.circular(20.toWidth)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        selectedItemColor: balticSea,
        unselectedItemColor: balticSea,
        unselectedFontSize: 14,
        elevation: 0,
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        items: List.generate(bottomMenuList.length, (index) {
          return BottomNavigationBarItem(
            icon: Padding(
              padding:
                  AppEdgeInsets.instance.symmetric(horizontal: 20, vertical: 8),
              child: SvgPicture.asset(
                bottomMenuList[index].icon,
              ),
            ),
            label: bottomMenuList[index].label,
            activeIcon: Container(
              padding:
                  AppEdgeInsets.instance.symmetric(horizontal: 20, vertical: 8),
              decoration: const BoxDecoration(
                color: approxKarry,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: SvgPicture.asset(
                bottomMenuList[index].icon,
              ),
            ),
          );
        }),
        onTap: (index) {
          onChanged(index);
        },
      ),
    );
  }
}
