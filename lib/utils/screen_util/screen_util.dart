import 'dart:ui';

import 'package:flutter/material.dart';

int setScreenWidth = isMobile ? 414 : 1024;
int setScreenHeight = isMobile ? 896 : 1366;

class ScreenUtil {
  static ScreenUtil? _instance;
  int defaultWidth = setScreenWidth;
  int defaultHeight = setScreenHeight;

  late num uiWidthPx;
  late num uiHeightPx;

  late bool allowFontScaling;

  static late double _screenWidth;
  static late double _screenHeight;
  static late double _pixelRatio;
  static late double _statusBarHeight;
  static late double _bottomBarHeight;
  static late double _textScaleFactor;

  ScreenUtil._();

  factory ScreenUtil() {
    return _instance ?? ScreenUtil._();
  }

  void init({bool allowFontScaling = false}) {
    _instance ??= ScreenUtil._();
    _instance?.uiWidthPx = defaultWidth;
    _instance?.uiHeightPx = defaultHeight;
    _instance?.allowFontScaling = allowFontScaling;
    _pixelRatio = window.devicePixelRatio;
    _screenWidth = window.physicalSize.width;
    _screenHeight = window.physicalSize.height;
    _statusBarHeight = window.padding.top;
    _bottomBarHeight = window.padding.bottom;
    _textScaleFactor = window.textScaleFactor;
  }

  /// The number of font pixels for each logical pixel.
  static double get textScaleFactor => _textScaleFactor;

  /// The size of the media in logical pixels (e.g, the size of the screen).
  static double get pixelRatio => _pixelRatio;

  /// The horizontal extent of this size.
  static double get screenWidth => _screenWidth / _pixelRatio;

  ///The vertical extent of this size. dp
  static double get screenHeight => _screenHeight / _pixelRatio;

  /// The vertical extent of this size. px
  static double get screenWidthPx => _screenWidth;

  /// The vertical extent of this size. px
  static double get screenHeightPx => _screenHeight;

  /// The offset from the top
  static double get statusBarHeight => _statusBarHeight / _pixelRatio;

  /// The offset from the top
  static double get statusBarHeightPx => _statusBarHeight;

  /// The offset from the bottom.
  static double get bottomBarHeight => _bottomBarHeight;

  /// The offset from the bottom.
  static double get bottomBarHeightPx => _bottomBarHeight / _pixelRatio;

  /// The ratio of the actual dp to the design draft px
  double get scaleWidth => screenWidth / uiWidthPx;

  double get scaleHeight => screenHeight / uiHeightPx;

  double get scaleText => scaleWidth;

  /// Adapted to the device width of the UI Design.
  /// Height can also be adapted according to this to ensure no deformation ,
  /// if you want a square
  num setWidth(num width) => width * scaleWidth;

  /// Highly adaptable to the device according to UI Design
  /// It is recommended to use this method to achieve a high degree of adaptation
  /// when it is found that one screen in the UI design
  /// does not match the current style effect, or if there is a difference in shape.
  num setHeight(num height) => height * scaleHeight;

  ///@param [fontSize] UI设计上字体的大小,单位px.
  ///Font size adaptation method
  ///@param [fontSize] The size of the font on the UI design, in px.
  ///@param [allowFontScaling]
  num setSp(num fontSize, {bool? allowFontScalingSelf}) =>
      allowFontScalingSelf == null
          ? (allowFontScaling
              ? (fontSize * scaleText)
              : ((fontSize * scaleText) / _textScaleFactor))
          : (allowFontScalingSelf
              ? (fontSize * scaleText)
              : ((fontSize * scaleText) / _textScaleFactor));
}

extension ScreenUtilsExtension on num {
  double get toHeight => ScreenUtil().setHeight(this).toDouble();

  double get toWidth => ScreenUtil().setWidth(this).toDouble();

  double get toFont => ScreenUtil().setSp(this).toDouble();
}

class AppEdgeInsets {
  AppEdgeInsets._privateConstructor();

  static final AppEdgeInsets instance = AppEdgeInsets._privateConstructor();

  factory AppEdgeInsets() {
    return instance;
  }

  EdgeInsets all(double value) =>
      EdgeInsets.symmetric(vertical: value.toHeight, horizontal: value.toWidth);

  EdgeInsets only(
          {double left = 0.0,
          double top = 0.0,
          double right = 0.0,
          double bottom = 0.0}) =>
      EdgeInsets.only(
          top: top.toHeight,
          bottom: bottom.toHeight,
          left: left.toWidth,
          right: right.toWidth);

  EdgeInsets symmetric({
    double vertical = 0.0,
    double horizontal = 0.0,
  }) =>
      EdgeInsets.symmetric(
          vertical: vertical.toHeight, horizontal: horizontal.toWidth);

  EdgeInsets fromLTRB(double left, double top, double right, double bottom) =>
      EdgeInsets.fromLTRB(
          left.toWidth, top.toHeight, right.toWidth, bottom.toHeight);
}

var data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
bool isMobile = data.size.shortestSide < 600;

extension CustomTextFontExtension on TextStyle {
  TextStyle get convertFontSize => copyWith(fontSize: fontSize?.toFont);
}
