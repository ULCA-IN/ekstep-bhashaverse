import 'package:flutter/material.dart';

class RemoveScrollingGlowEffect extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
