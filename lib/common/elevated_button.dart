import '../utils/screen_util/screen_util.dart';
import 'package:flutter/material.dart';

Widget elevatedButton({
  Color? backgroundColor,
  double? borderRadius,
  VoidCallback? onButtonTap,
  required String buttonText,
  required TextStyle textStyle,
}) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(borderRadius?.toWidth ?? 16.toWidth),
      ),
    ),
    onPressed: onButtonTap,
    child: Padding(
      padding: AppEdgeInsets.instance.symmetric(vertical: 14.0),
      child: Text(
        buttonText,
        style: textStyle,
      ),
    ),
  );
}
