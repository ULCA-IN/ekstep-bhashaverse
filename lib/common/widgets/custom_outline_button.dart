import '../../utils/screen_util/screen_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../utils/theme/app_colors.dart';
import '../../utils/theme/app_text_style.dart';

class CustomOutlineButton extends StatelessWidget {
  const CustomOutlineButton({
    Key? key,
    this.title,
    this.icon,
    this.isHighlighted = false,
    required this.onTap,
  }) : super(key: key);

  final String? title;
  final String? icon;
  final Function onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: ButtonStyle(
        overlayColor: MaterialStateProperty.all(
          japaneseLaurel.withOpacity(0.2),
        ),
        backgroundColor: MaterialStateProperty.all(
          Colors.white,
        ),
        side: MaterialStateProperty.resolveWith((state) {
          return BorderSide(
            color: isHighlighted ? japaneseLaurel : neonGreen,
          );
        }),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        )),
      ),
      onPressed: () => onTap(),
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
                style: AppTextStyle().regular14Arsenic.copyWith(
                    color: isHighlighted ? japaneseLaurel : Colors.black87)),
        ],
      ),
    );
  }
}
