import 'package:get/get.dart';

showDefaultSnackbar({required String message}) {
  Get.showSnackbar(GetSnackBar(
    message: message,
    isDismissible: true,
    duration: const Duration(seconds: 2),
  ));
}
