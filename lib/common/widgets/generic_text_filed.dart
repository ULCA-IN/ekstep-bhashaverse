import 'package:flutter/material.dart';

import '../../utils/constants/app_constants.dart';
import '../../utils/screen_util/screen_util.dart';
import '../../utils/theme/app_text_style.dart';
import '../../utils/theme/app_theme_provider.dart';

class GenericTextField extends StatelessWidget {
  const GenericTextField({
    super.key,
    required TextEditingController controller,
    int lines = 1,
    String hintText = '',
  })  : _controller = controller,
        _lines = lines,
        _hintText = hintText;

  final TextEditingController _controller;
  final int _lines;
  final String _hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: regular18Primary(context),
      maxLines: _lines,
      maxLength: TextField.noMaxLength,
      autocorrect: false,
      textInputAction: TextInputAction.done,
      minLines: _lines,
      decoration: InputDecoration(
        hintText: _hintText,
        hintStyle:
            regular24(context).copyWith(color: context.appTheme.hintTextColor),
        hintMaxLines: 4,
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(textFieldRadius),
            ),
            borderSide: BorderSide.none),
        counterText: '',
        contentPadding:
            AppEdgeInsets.instance.symmetric(vertical: 5, horizontal: 12),
        filled: true,
      ),
    );
  }
}
