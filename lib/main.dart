import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'enums/gender_enum.dart';
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Box hiveDBInstance = Hive.box(hiveDBName);

    // Localization preference
    String appLocale = hiveDBInstance.get(preferredAppLocale,
        defaultValue: Get.deviceLocale?.languageCode);
    if (appLocale.isEmpty) {
      hiveDBInstance.put(preferredAppLocale, appLocale);
      // handle when first time app launch
    } else {
      MyApp.setLocale(context, Locale(appLocale, 'IN'));
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
      hiveDBInstance.put(isStreamingPreferred, false);
    }

    return GetMaterialApp(
      onGenerateTitle: (context) => 'Bhashini',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
