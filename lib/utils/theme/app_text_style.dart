import 'package:flutter/material.dart';

import '../screen_util/screen_util.dart';
import '../../utils/theme/app_theme_provider.dart';

TextStyle regular12(BuildContext context) => TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 12.toFont,
      color: context.appTheme.highlightedTextColor,
    );

TextStyle regular14(BuildContext context) => TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 14.toFont,
      color: context.appTheme.highlightedTextColor,
    );

TextStyle regular14Title(BuildContext context) => TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 14.toFont,
      color: context.appTheme.titleTextColor,
    );

TextStyle light16(BuildContext context) => TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 16.toFont,
      color: context.appTheme.primaryTextColor,
    );

TextStyle regular16(BuildContext context) => TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 16.toFont,
      color: context.appTheme.secondaryTextColor,
    );

TextStyle regular18Primary(BuildContext context) => TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 18.toFont,
      color: context.appTheme.primaryTextColor,
    );

TextStyle regular18Secondary(BuildContext context) => TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 18.toFont,
      color: context.appTheme.secondaryTextColor,
    );

TextStyle semibold18(BuildContext context) => TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 18.toFont,
      color: context.appTheme.primaryTextColor,
    );

TextStyle semibold22(BuildContext context) => TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 22.toFont,
      color: context.appTheme.primaryTextColor,
    );

TextStyle regular24(BuildContext context) => TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 24.toFont,
      color: context.appTheme.primaryTextColor,
    );

TextStyle semibold24(BuildContext context) => TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 24.toFont,
      color: context.appTheme.primaryTextColor,
    );

TextStyle bold24(BuildContext context) => TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 24.toFont,
      color: context.appTheme.primaryTextColor,
    );

TextStyle regular28(BuildContext context) => TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 28.toFont,
      color: context.appTheme.primaryTextColor,
    );
