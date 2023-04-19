import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../common/widgets/elevated_button.dart';
import '../../common/widgets/language_selection_widget.dart';
import '../../enums/language_enum.dart';
import '../../localization/localization_keys.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants/api_constants.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/remove_glow_effect.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/theme/app_text_style.dart';
import 'controller/app_language_controller.dart';

class AppLanguageScreen extends StatefulWidget {
  const AppLanguageScreen({super.key});

  @override
  State<AppLanguageScreen> createState() => _AppLanguageScreenState();
}

class _AppLanguageScreenState extends State<AppLanguageScreen> {
  late AppLanguageController _appLanguageController;
  late TextEditingController _languageSearchController;
  final FocusNode _focusNodeLanguageSearch = FocusNode();
  late final Box _hiveDBInstance;

  @override
  void initState() {
    _appLanguageController = Get.find();
    _languageSearchController = TextEditingController();
    _hiveDBInstance = Hive.box(hiveDBName);
    if (Get.arguments != null && Get.arguments[selectedLanguage] != null) {
      setSelectedLanguageFromArg(Get.arguments[selectedLanguage]);
    }
    ScreenUtil().init();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    if (_focusNodeLanguageSearch.hasFocus) {
      _focusNodeLanguageSearch.unfocus();
    }
    _focusNodeLanguageSearch.dispose();
    _appLanguageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: AppEdgeInsets.instance.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 16.toHeight),
                Text(
                  selectAppLanguage.tr,
                  style: AppTextStyle().semibold24BalticSea,
                ),
                SizedBox(height: 8.toHeight),
                Text(
                  youCanAlwaysChange.tr,
                  style: AppTextStyle()
                      .light16BalticSea
                      .copyWith(color: dolphinGray),
                ),
                SizedBox(height: 24.toHeight),
                _textFormFieldContainer(),
                SizedBox(height: 24.toHeight),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: RemoveScrollingGlowEffect(),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        mainAxisSpacing: 8.toHeight,
                        crossAxisCount: 2,
                        childAspectRatio: 2,
                      ),
                      itemCount:
                          _appLanguageController.getAppLanguageList().length,
                      itemBuilder: (context, index) {
                        return Obx(
                          () {
                            return LanguageSelectionWidget(
                              title: getLangNameInAppLanguage(
                                  _appLanguageController
                                          .getAppLanguageList()[index]
                                      [APIConstants.kLanguageCode],
                                  _appLanguageController
                                      .getSelectedLanguageCode()),
                              subTitle: _appLanguageController
                                      .getAppLanguageList()[index]
                                  [APIConstants.kNativeName],
                              onItemTap: () {
                                _appLanguageController
                                    .setSelectedLanguageIndex(index);
                              },
                              index: index,
                              selectedIndex: _appLanguageController
                                  .getSelectedLanguageIndex(),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16.toHeight),
                CustomElevetedButton(
                  buttonText: continueText.tr,
                  textStyle: AppTextStyle()
                      .semibold24BalticSea
                      .copyWith(fontSize: 18.toFont),
                  backgroundColor: primaryColor,
                  borderRadius: 16,
                  onButtonTap: () {
                    if (_appLanguageController
                            .getAppLanguageList()
                            .isNotEmpty &&
                        _appLanguageController.getSelectedLanguageIndex() !=
                            null &&
                        _appLanguageController.getSelectedLanguageIndex()! <
                            _appLanguageController
                                .getAppLanguageList()
                                .length) {
                      _languageSearchController.clear();
                      _appLanguageController.saveSelectedLocaleInDB();
                      Get.updateLocale(Locale(
                          _appLanguageController.getSelectedLanguageCode()));
                      if (_hiveDBInstance.get(introShownAlreadyKey,
                          defaultValue: false)) {
                        Get.back();
                      } else {
                        Get.toNamed(AppRoutes.onboardingRoute);
                      }
                    } else {
                      showDefaultSnackbar(
                          message: errorPleaseSelectLanguage.tr);
                    }
                  },
                ),
                SizedBox(height: 16.toHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textFormFieldContainer() {
    return Container(
      margin: AppEdgeInsets.instance.symmetric(horizontal: 8),
      padding: AppEdgeInsets.instance.only(left: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: goastWhite,
      ),
      child: TextFormField(
        cursorColor: dolphinGray,
        decoration: InputDecoration(
          contentPadding: AppEdgeInsets.instance.all(0),
          border: InputBorder.none,
          icon: const Icon(
            Icons.search,
            color: dolphinGray,
          ),
          hintText: searchLanguage.tr,
          hintStyle: AppTextStyle()
              .light16BalticSea
              .copyWith(fontSize: 18.toFont, color: manateeGray),
        ),
        onChanged: ((value) => performLanguageSearch(value)),
        controller: _languageSearchController,
        focusNode: _focusNodeLanguageSearch,
      ),
    );
  }

  void performLanguageSearch(String searchString) {
    if (_appLanguageController.getAppLanguageList().isEmpty) {
      _appLanguageController.setAllLanguageList();
    }

    List<Map<String, dynamic>> tempList =
        _appLanguageController.getAppLanguageList();
    if (searchString.isNotEmpty) {
      List<Map<String, dynamic>> searchedLanguageList = tempList.where(
        (language) {
          return language[APIConstants.kEnglishName]
                  .toLowerCase()
                  .contains(searchString.toLowerCase()) ||
              language[APIConstants.kNativeName]
                  .toLowerCase()
                  .contains(searchString.toLowerCase()) ||
              getLangNameInAppLanguage(language[APIConstants.kLanguageCode],
                      _appLanguageController.getSelectedLanguageCode())
                  .contains(searchString);
        },
      ).toList();
      _appLanguageController.setCustomLanguageList(searchedLanguageList);
      _appLanguageController.setSelectedLanguageIndex(null);
      for (var i = 0; i < searchedLanguageList.length; i++) {
        if (searchedLanguageList[i][APIConstants.kLanguageCode] ==
            Get.locale?.languageCode) {
          _appLanguageController.setSelectedLanguageIndex(i);
        }
      }
    } else {
      _appLanguageController.setAllLanguageList();
    }
  }

  String getLangNameInAppLanguage(
      String languageCode, String selectedLangCode) {
    return APIConstants.getLanguageCodeOrName(
        value: languageCode,
        returnWhat: LanguageMap.languageNameInAppLanguage,
        lang_code_map: APIConstants.LANGUAGE_CODE_MAP,
        langCode: selectedLangCode);
  }

  void setSelectedLanguageFromArg(String name) {
    _appLanguageController.setSelectedLanguageIndex(_appLanguageController
        .getAppLanguageList()
        .indexWhere((element) => element[APIConstants.kNativeName] == name));
  }

  Future<bool> _onWillPop() async {
    if (_focusNodeLanguageSearch.hasFocus) {
      _focusNodeLanguageSearch.unfocus();
      _languageSearchController.clear();
      _appLanguageController.setAllLanguageList();
    } else {
      Get.updateLocale(
        Locale(_hiveDBInstance.get(preferredAppLocale)),
      );
      Get.back();
    }
    return Future.value(false);
  }
}
