import 'package:get/get.dart';

import 'as.dart';
import 'bho.dart';
import 'bn.dart';
import 'doi.dart';
import 'en.dart';
import 'gu.dart';
import 'hi.dart';
import 'kn.dart';
import 'mai.dart';
import 'ml.dart';
import 'mr.dart';
import 'ne.dart';
import 'od.dart';
import 'pa.dart';
import 'sa.dart';
import 'ta.dart';
import 'te.dart';

class AppLocalization extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': en,
        'hi': hi,
        'as': as,
        'bho': bho,
        'bn': bn,
        'doi': doi,
        'gu': gu,
        'kn': kn,
        'mai': mai,
        'ml': ml,
        'mr': mr,
        'ne': ne,
        'od': od,
        'pa': pa,
        'sa': sa,
        'ta': ta,
        'te': te,
      };
}
