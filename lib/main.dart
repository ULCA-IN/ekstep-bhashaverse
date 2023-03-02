import 'package:bhashaverse/enums/gender_enum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';

import 'localization/app_localization.dart';
import 'localization/localization_keys.dart';
import 'presentation/splash_screen/binding/splash_binding.dart';
import 'routes/app_routes.dart';
import 'utils/constants/app_constants.dart';
import 'utils/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  GestureBinding.instance.resamplingEnabled = true;

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await Hive.initFlutter();
  await Hive.openBox(hiveDBName);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Box hiveDBInstance = Hive.box(hiveDBName);

    // Localization preference
    String appLocale = hiveDBInstance.get(preferredAppLocale,
        defaultValue: Get.deviceLocale?.languageCode);
    if (appLocale.isEmpty) {
      hiveDBInstance.put(preferredAppLocale, appLocale);
    }

    // Voice assistant preference
    if (hiveDBInstance.get(preferredVoiceAssistantGender) == null) {
      hiveDBInstance.put(preferredVoiceAssistantGender, GenderEnum.female.name);
    }

    // Transliteration preference
    if (hiveDBInstance.get(enableTransliteration) == null) {
      hiveDBInstance.put(enableTransliteration, true);
    }

    // Streaming vs Batch model preference
    if (hiveDBInstance.get(isStreamingPreferred) == null) {
      hiveDBInstance.put(isStreamingPreferred, true);
    }

    return GetMaterialApp(
      title: appName.tr,
      debugShowCheckedModeBanner: false,
      translations: AppLocalization(),
      locale: Locale(appLocale),
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData(
        primaryColor: primaryColor,
        textTheme: GoogleFonts.latoTextTheme(),
        canvasColor: Colors.white,
      ),
      getPages: AppRoutes.pages,
      initialBinding: SplashBinding(),
      initialRoute: AppRoutes.splashRoute,
    );
  }
}
