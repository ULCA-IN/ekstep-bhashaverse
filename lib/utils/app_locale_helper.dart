import '../i18n/strings.g.dart';
import 'constants/language_map_translated.dart';

setAppLocale(String locale) {
  switch (locale) {
    case en:
      LocaleSettings.setLocale(AppLocale.en);
      break;
    case hi:
      LocaleSettings.setLocale(AppLocale.hi);
      break;
    case bho:
      LocaleSettings.setLocale(AppLocale.bho);
      break;
  }
}
