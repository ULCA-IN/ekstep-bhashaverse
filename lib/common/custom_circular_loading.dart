import 'package:flutter/material.dart';

import '../utils/theme/app_colors.dart';

class CustomCircularLoading extends StatelessWidget {
  const CustomCircularLoading({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      color: balticSea,
      strokeWidth: 2,
    );
  }
}
