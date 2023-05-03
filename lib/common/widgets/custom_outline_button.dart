import '../../utils/screen_util/screen_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/theme/app_theme_provider.dart';
import '../../utils/theme/app_text_style.dart';

class CustomOutlineButton extends StatelessWidget {
  const CustomOutlineButton({
    Key? key,
    this.title,
    this.icon,
    this.isDisabled = false,
    required this.onTap,
  }) : super(key: key);

  final String? title;
  final String? icon;
  final Function onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        elevation: MaterialStateProperty.all(0),
        overlayColor: MaterialStateProperty.all(
          isDisabled
              ? Colors.transparent
              : context.appTheme.highlightedBGColor.withOpacity(0.2),
        ),
        backgroundColor:
            MaterialStateProperty.all(context.appTheme.normalTextFeildColor),
        side: MaterialStateProperty.resolveWith((state) {
          return BorderSide(
            color: isDisabled
                ? context.appTheme.titleTextColor
                : context.appTheme.highlightedBGColor,
          );
        }),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        )),
      ),
      onPressed: isDisabled ? null : () => onTap(),
      child: Row(
        children: [
          if (icon != null && icon!.isNotEmpty)
            SvgPicture.asset(
              icon!,
              height: 20.toWidth,
              width: 20.toWidth,
            ),
          if (icon != null && icon!.isNotEmpty)
            SizedBox(
              width: 8.toWidth,
            ),
          if (title != null && title!.isNotEmpty)
            Text(title!,
                style: regular14(context).copyWith(
                    color: isDisabled
                        ? context.appTheme.titleTextColor
                        : context.appTheme.highlightedBGColor)),
        ],
      ),
    );
  }
}
