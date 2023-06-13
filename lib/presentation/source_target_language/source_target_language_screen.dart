import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../common/widgets/language_selection_widget.dart';
import '../../enums/language_enum.dart';
import '../../localization/localization_keys.dart';
import '../../utils/constants/api_constants.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/remove_glow_effect.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

    super.initState();
    setLanguageListFromArgument();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appTheme.listingScreenBGColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.w),
              _headerWidget(),
              SizedBox(height: 24.w),
              _textFormFieldContainer(),
              SizedBox(height: 24.w),
              Expanded(
                child: ScrollConfiguration(
                  behavior: RemoveScrollingGlowEffect(),
                  child: Obx(
                    () => GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        mainAxisSpacing: 8.w,
                        crossAxisCount:
                            MediaQuery.of(context).size.shortestSide > 600
                                ? 3
                                : 2,
                        childAspectRatio: 2,
                      ),
                      itemCount:
                          _languageSelectionController.getLanguageList().length,
                      itemBuilder: (context, index) {
                        return Obx(
                          () {
                            return LanguageSelectionWidget(
                              title: APIConstants.getLanNameInAppLang(
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
              SizedBox(height: 16.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textFormFieldContainer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      padding: EdgeInsets.only(left: 16.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: context.appTheme.containerColor,
      ),
      child: TextFormField(
        cursorColor: context.appTheme.secondaryTextColor,
        style: regular18Primary(context),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(0),
          border: InputBorder.none,
          icon: Icon(
            Icons.search,
            color: context.appTheme.secondaryTextColor,
          ),
          hintText: searchLanguage.tr,
          hintStyle: light16(context)
              .copyWith(fontSize: 18, color: context.appTheme.titleTextColor),
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
            padding: const EdgeInsets.all(8).w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  width: 1.w, color: context.appTheme.containerColor),
            ),
            child: SvgPicture.asset(
              iconPrevious,
            ),
          ),
        ),
        SizedBox(width: 24.w),
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
              APIConstants.getLanNameInAppLang(languageCode)
                  .contains(searchString);
        },
      ).toList();
      _languageSelectionController.setLanguageList(searchedLanguageList);
      _languageSelectionController.setSelectedLanguageIndex(null);
      for (var i = 0; i < searchedLanguageList.length; i++) {
        if (searchedLanguageList[i] == Get.arguments[selectedLanguage]) {
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

  String getNativeNameOfLanguage(String languageCode) {
    return APIConstants.getLanguageCodeOrName(
        value: languageCode,
        returnWhat: LanguageMap.nativeName,
        lang_code_map: APIConstants.LANGUAGE_CODE_MAP);
  }
}
