import 'package:flutter/material.dart';

import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_theme_provider.dart';
import '../../utils/theme/app_text_style.dart';

class TransliterationHints extends StatelessWidget {
  const TransliterationHints(
      {super.key,
      required ScrollController scrollController,
      required List<dynamic> transliterationHints,
      required bool showScrollIcon,
      isScrollArrowVisible,
      required Function onSelected})
      : _scrollController = scrollController,
        _transliterationHints = transliterationHints,
        _showScrollIcon = showScrollIcon,
        _isScrollArrowVisible = isScrollArrowVisible,
        _onHintTap = onSelected;

  final ScrollController _scrollController;
  final List<dynamic> _transliterationHints;
  final bool _showScrollIcon, _isScrollArrowVisible;

  final Function _onHintTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _showScrollIcon ? 85.toHeight : 50.toHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: _showScrollIcon ? 6.toHeight : null),
          if (_showScrollIcon)
            _isScrollArrowVisible
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_forward_outlined,
                      color: Colors.grey.shade400,
                      size: 22.toHeight,
                    ),
                  )
                : SizedBox(height: 22.toHeight),
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ..._transliterationHints.map((hintText) => GestureDetector(
                      onTap: () => _onHintTap(hintText),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: context.appTheme.lightBGColor,
                        ),
                        margin: AppEdgeInsets.instance.all(4),
                        padding: AppEdgeInsets.instance
                            .symmetric(vertical: 4, horizontal: 6),
                        alignment: Alignment.center,
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth: (ScreenUtil.screenWidth / 7).toWidth,
                          ),
                          child: Text(
                            hintText,
                            style: regular16(context).copyWith(
                                color: context.appTheme.primaryTextColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
