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
    case mr:
      LocaleSettings.setLocale(AppLocale.mr);
      break;
    case bn:
      LocaleSettings.setLocale(AppLocale.bn);
      break;
    case pa:
      LocaleSettings.setLocale(AppLocale.pa);
      break;
    case gu:
      LocaleSettings.setLocale(AppLocale.gu);
      break;
    case or:
      LocaleSettings.setLocale(AppLocale.or);
      break;
    case ta:
      LocaleSettings.setLocale(AppLocale.ta);
      break;
    case te:
      LocaleSettings.setLocale(AppLocale.te);
      break;
    case kn:
      LocaleSettings.setLocale(AppLocale.kn);
      break;
    case ur:
      LocaleSettings.setLocale(AppLocale.ur);
      break;
    case doi:
      LocaleSettings.setLocale(AppLocale.doi);
      break;
    case ne:
      LocaleSettings.setLocale(AppLocale.ne);
      break;
    case sa:
      LocaleSettings.setLocale(AppLocale.sa);
      break;
    case as:
      LocaleSettings.setLocale(AppLocale.as);
      break;
    case mai:
      LocaleSettings.setLocale(AppLocale.mai);
      break;
    case bho:
      LocaleSettings.setLocale(AppLocale.bho);
      break;
    case ml:
      LocaleSettings.setLocale(AppLocale.ml);
      break;
    case mni:
      LocaleSettings.setLocale(AppLocale.mni);
      break;
    case ks:
      LocaleSettings.setLocale(AppLocale.ks);
      break;
    case gom:
      LocaleSettings.setLocale(AppLocale.gom);
      break;
    case sd:
      LocaleSettings.setLocale(AppLocale.sd);
      break;
    case sat:
      LocaleSettings.setLocale(AppLocale.sat);
      break;
    default:
      LocaleSettings.setLocale(AppLocale.en);
      break;
  }
}
