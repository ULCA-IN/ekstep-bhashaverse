import 'package:flutter/material.dart';

import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/theme/app_text_style.dart';

class TransliterationHints extends StatelessWidget {
  const TransliterationHints(
      {super.key,
      required ScrollController scrollController,
      required List<dynamic> transliterationHints,
      required bool isScrollArrowVisible,
      required Function onSelected})
      : _scrollController = scrollController,
        _transliterationHints = transliterationHints,
        _isScrollArrowVisible = isScrollArrowVisible,
        _onHintTap = onSelected;

  final ScrollController _scrollController;
  final List<dynamic> _transliterationHints;
  final bool _isScrollArrowVisible;

  final Function _onHintTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 85.toHeight,
      child: Column(
        children: [
          SizedBox(height: 6.toHeight),
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
                          color: lilyWhite,
                        ),
                        margin: AppEdgeInsets.instance.all(4),
                        padding: AppEdgeInsets.instance
                            .symmetric(vertical: 6, horizontal: 6),
                        alignment: Alignment.center,
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth: (ScreenUtil.screenWidth / 7.5).toWidth,
                          ),
                          child: Text(
                            hintText,
                            style: AppTextStyle().regular16DolphinGrey.copyWith(
                                  color: Colors.black,
                                ),
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
