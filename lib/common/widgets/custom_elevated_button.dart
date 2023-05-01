
import '../../../utils/screen_util/screen_util.dart';
import 'package:flutter/material.dart';

class CustomElevetedButton extends StatelessWidget {
  const CustomElevetedButton({
    super.key,
    Color? backgroundColor,
    double? borderRadius,
    VoidCallback? onButtonTap,
    required String buttonText,
    required TextStyle textStyle,
  })  : _backgroundColor = backgroundColor,
        _borderRadius = borderRadius,
        _onButtonTap = onButtonTap,
        _buttonText = buttonText,
        _textStyle = textStyle;

  final Color? _backgroundColor;
  final double? _borderRadius;
  final VoidCallback? _onButtonTap;
  final String _buttonText;
  final TextStyle _textStyle;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: AppEdgeInsets.instance.symmetric(vertical: 14),
        backgroundColor: _backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(_borderRadius?.toWidth ?? 16.toWidth),
        ),
      ),
      onPressed: _onButtonTap,
      child: SizedBox(
        height: 24.toHeight,
        child: Text(
          _buttonText,
          style: _textStyle,
        ),
      ),
    );
  }
}
