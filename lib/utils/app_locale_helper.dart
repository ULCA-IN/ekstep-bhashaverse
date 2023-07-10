import '../i18n/strings.g.dart' as i18n;
import 'constants/language_map_translated.dart';

setAppLocale(String locale) {
  switch (locale) {
    case en:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.en);
      break;
    case hi:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.hi);
      break;
    case mr:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.mr);
      break;
    case bn:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.bn);
      break;
    case pa:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.pa);
      break;
    case gu:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.gu);
      break;
    case or:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.or);
      break;
    case ta:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.ta);
      break;
    case te:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.te);
      break;
    case kn:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.kn);
      break;
    case ur:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.ur);
      break;
    case doi:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.doi);
      break;
    case ne:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.ne);
      break;
    case sa:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.sa);
      break;
    case asm:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.as);
      break;
    case mai:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.mai);
      break;
    case bho:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.bho);
      break;
    case ml:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.ml);
      break;
    case mni:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.mni);
      break;
    case ks:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.ks);
      break;
    case gom:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.gom);
      break;
    case sd:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.sd);
      break;
    case sat:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.sat);
      break;
    default:
      i18n.LocaleSettings.setLocale(i18n.AppLocale.en);
      break;
  }
}
