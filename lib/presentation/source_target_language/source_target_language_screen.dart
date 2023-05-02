import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../common/widgets/language_selection_widget.dart';
import '../../enums/language_enum.dart';
import '../../localization/localization_keys.dart';
import '../../utils/constants/api_constants.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/remove_glow_effect.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_theme_provider.dart';
import '../../utils/theme/app_text_style.dart';
import 'controller/source_target_language_controller.dart';

class SourceTargetLanguageScreen extends StatefulWidget {
  const SourceTargetLanguageScreen({super.key});

  @override
  State<SourceTargetLanguageScreen> createState() =>
      _SourceTargetLanguageScreenState();
}

class _SourceTargetLanguageScreenState
    extends State<SourceTargetLanguageScreen> {
  late SourceTargetLanguageController _languageSelectionController;
  late TextEditingController _languageSearchController;
  final FocusNode _focusNodeLanguageSearch = FocusNode();
  bool isUserSelectedFromSearchResult = false;

  @override
  void initState() {
    _languageSelectionController = Get.find();
    _languageSearchController = TextEditingController();
    ScreenUtil().init();
    super.initState();
    setLanguageListFromArgument();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appTheme.listingScreenBGColor,
      body: SafeArea(
        child: Padding(
          padding: AppEdgeInsets.instance.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.toHeight),
              _headerWidget(),
              SizedBox(height: 24.toHeight),
              _textFormFieldContainer(),
              SizedBox(height: 24.toHeight),
              Expanded(
                child: ScrollConfiguration(
                  behavior: RemoveScrollingGlowEffect(),
                  child: Obx(
                    () => GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        mainAxisSpacing: 8.toHeight,
                        crossAxisCount: 2,
                        childAspectRatio: 2,
                      ),
                      itemCount:
                          _languageSelectionController.getLanguageList().length,
                      itemBuilder: (context, index) {
                        return Obx(
                          () {
                            return LanguageSelectionWidget(
                              title: getLangNameInAppLanguage(
                                  _languageSelectionController
                                      .getLanguageList()[index]),
                              subTitle: getNativeNameOfLanguage(
                                  _languageSelectionController
                                      .getLanguageList()[index]),
                              onItemTap: () => Get.back(
                                  result: _languageSelectionController
                                      .getLanguageList()[index]),
                              index: index,
                              selectedIndex: _languageSelectionController
                                  .getSelectedLanguageIndex(),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.toHeight),
            ],
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
        color: context.appTheme.containerColor,
      ),
      child: TextFormField(
        cursorColor: context.appTheme.secondaryTextColor,
        style: regular18Primary(context),
        decoration: InputDecoration(
          contentPadding: AppEdgeInsets.instance.all(0),
          border: InputBorder.none,
          icon: Icon(
            Icons.search,
            color: context.appTheme.secondaryTextColor,
          ),
          hintText: searchLanguage.tr,
          hintStyle: light16(context).copyWith(
              fontSize: 18.toFont, color: context.appTheme.titleTextColor),
        ),
        onChanged: (value) {
          performLanguageSearch(value);
        },
        controller: _languageSearchController,
        focusNode: _focusNodeLanguageSearch,
      ),
    );
  }

  Widget _headerWidget() {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Get.back(),
          child: Container(
            padding: AppEdgeInsets.instance.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  width: 1.toWidth, color: context.appTheme.containerColor),
            ),
            child: SvgPicture.asset(
              iconPrevious,
            ),
          ),
        ),
        SizedBox(width: 24.toWidth),
        Text(
          Get.arguments[kIsSourceLanguage]
              ? kTranslateSourceTitle.tr
              : kTranslateTargetTitle.tr,
          style: semibold24(context),
        ),
      ],
    );
  }

  void performLanguageSearch(String searchString) {
    if (_languageSelectionController.getLanguageList().isEmpty) {
      _languageSelectionController
          .setLanguageList(Get.arguments[kLanguageList]);
    }
    if (searchString.isNotEmpty) {
      isUserSelectedFromSearchResult = true;
      List<dynamic> tempList = _languageSelectionController.getLanguageList();
      List<dynamic> searchedLanguageList = tempList.where(
        (languageCode) {
          String languageNameInEnglish = APIConstants.getLanguageCodeOrName(
              value: languageCode,
              returnWhat: LanguageMap.englishName,
              lang_code_map: APIConstants.LANGUAGE_CODE_MAP);

          return languageNameInEnglish
                  .toLowerCase()
                  .contains(searchString.toLowerCase()) ||
              getNativeNameOfLanguage(languageCode)
                  .toLowerCase()
                  .contains(searchString.toLowerCase()) ||
              getLangNameInAppLanguage(languageCode).contains(searchString);
        },
      ).toList();
      _languageSelectionController.setLanguageList(searchedLanguageList);
      _languageSelectionController.setSelectedLanguageIndex(null);
      for (var i = 0; i < searchedLanguageList.length; i++) {
        if (searchedLanguageList[i][APIConstants.kLanguageCode] ==
            Get.locale?.languageCode) {
          _languageSelectionController.setSelectedLanguageIndex(i);
        }
      }
    } else {
      setLanguageListFromArgument();
      isUserSelectedFromSearchResult = false;
    }
  }

  void setLanguageListFromArgument() {
    var langListArgument = Get.arguments[kLanguageList];
    if (langListArgument != null && langListArgument.isNotEmpty) {
      _languageSelectionController.setLanguageList(langListArgument);
      _languageSelectionController.setSelectedLanguageIndex(
          _languageSelectionController.getLanguageList().indexWhere(
              (element) => element == Get.arguments[selectedLanguage]));
    }
  }

  String getLangNameInAppLanguage(String languageCode) {
    return APIConstants.getLanguageCodeOrName(
        value: languageCode,
        returnWhat: LanguageMap.languageNameInAppLanguage,
        lang_code_map: APIConstants.LANGUAGE_CODE_MAP);
  }

  String getNativeNameOfLanguage(String languageCode) {
    return APIConstants.getLanguageCodeOrName(
        value: languageCode,
        returnWhat: LanguageMap.nativeName,
        lang_code_map: APIConstants.LANGUAGE_CODE_MAP);
  }
}
