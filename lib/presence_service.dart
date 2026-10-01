// presence_service.dart
//
// 🆕 "כמה אנשים משחקים עכשיו בכל מוד" - נקודה ירוקה + מספר על כרטיסי
// המצבים בתפריט הראשי. כדי שזה יהיה זול וזה לא יעמיס על Firebase:
//
//  - כל שחקן *פעיל* (בתור/משחק) כותב "פעימת חיים" קלה למסמך
//    presence/{deviceId} כל heartbeatIntervalSeconds שניות - בדיוק כמו
//    הפעימה הקיימת כבר בדו-קרב (ראו updateHeartbeat ב-duel_service.dart).
//    זו כתיבה בודדת קלה, לא Transaction - עלות זניחה.
//  - מסך הבית *לא* מאזין (.snapshots()) בלייב לאוסף הזה בכלל - זה היה
//    עולה קריאה על כל שינוי בכל מסמך, כל הזמן, לכל מי שנמצא במסך הבית
//    (ויכול להיות הרבה זמן - זה מסך הבית!). במקום זה countActive()
//    משתמש בשאילתת אגרגציה .count() - זו עולה קריאה בודדת (1) בלי קשר
//    לכמות המסמכים התואמים, ונקראת רק מדי פעם (לא בלייב) - ראו הקריאות
//    ב-main_menu_screen.dart (בכניסה למסך + כל 30 שניות בלבד כל עוד
//    המסך פתוח, לא יותר).
//
// ⚠️ מגבלה ידועה וכנה: duel_room_screen.dart מוגדר כקובץ "לא לגעת" בפרויקט
// הזה, אז אי אפשר להוסיף בו את קריאת הפעימה. הספירה של "דו-קרב" מגיעה
// בפועל רק מ-duel_lobby_screen.dart (מחפש יריב/נמצא/ספירה לאחור) - שחקן
// שכבר בתוך DuelRoomScreen עצמו (המשחק בפועל) לא נספר יותר, כי המסך ההוא
// (הקובץ המוגן) לא כותב פעימה. זו הערכה סבירה של "כמה פעילים עכשיו",
// לא ספירה מדויקת של כולם - אם בעתיד תרצה דיוק מלא, צריך להוסיף שורה
// אחת (PresenceService.startHeartbeat) בתוך duel_room_screen.dart בעצמך,
// או לבטל את ההגבלה על הקובץ הזה.
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'presence';

  // כל כמה שניות נשלחת פעימת חיים חדשה כל עוד השחקן פעיל במצב מסוים.
  static const int heartbeatIntervalSeconds = 20;
  // חלון "עדיין פעיל" - שחקן שלא כתב פעימה טרייה יותר מזה כבר לא נספר
  // (כנראה סגר את המסך/האפליקציה בלי שהתחדשה הפעימה הבאה).
  static const Duration activeWindow = Duration(seconds: 40);

  static Timer? _timer;
  static String? _deviceId;
  static String? _mode;

  /// מתחיל לשלוח פעימת חיים תחת מצב מסוים ('duel' | 'superdual' | 'race'). קריאה חוזרת
  /// עם אותו deviceId+mode לא עושה כלום (כבר רץ) - בטוח לקרוא כמה פעמים.
  static void startHeartbeat(String deviceId, String mode) {
    if (_timer != null && _deviceId == deviceId && _mode == mode) return;
    stopHeartbeat();
    _deviceId = deviceId;
    _mode = mode;
    _writeOnce();
    _timer = Timer.periodic(Duration(seconds: heartbeatIntervalSeconds), (_) => _writeOnce());
  }

  static Future<void> _writeOnce() async {
    final deviceId = _deviceId, mode = _mode;
    if (deviceId == null || mode == null) return;
    try {
      await _db.collection(_collection).doc(deviceId).set({
        'mode': mode,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // לא קריטי - נחמד שיהיה, לא חוסם/מפיל שום דבר במשחק עצמו.
    }
  }

  /// עוצר את הפעימה ומוחק את המסמך - כדי שהשחקן ייעלם מהספירה מיד,
  /// במקום לחכות activeWindow שלמות שהפעימה הישנה "תתיישן" מעצמה.
  static void stopHeartbeat() {
    _timer?.cancel();
    _timer = null;
    final deviceId = _deviceId;
    if (deviceId != null) {
      _db.collection(_collection).doc(deviceId).delete().catchError((_) {});
    }
    _deviceId = null;
    _mode = null;
  }

  /// כמה שחקנים "פעילים" (פעימה טרייה בתוך activeWindow) נמצאים כרגע
  /// במצב הזה.
  /// 🩹 תוקן: הגרסה הקודמת שילבה שני תנאים בשאילתה אחת (mode + updatedAt),
  /// מה שדורש אינדקס מורכב ב-Firestore שאף פעם לא נוצר בפועל בקונסולה -
  /// כל קריאה נכשלה בשקט עם FAILED_PRECONDITION (נבלע ע"י ה-catch למטה)
  /// והחזירה 0 תמיד, בדיוק התסמין שדווח ("כמות המחוברים לא עובדת"). עכשיו,
  /// בדיוק כמו listActive למטה, מסננים שרת-צד רק לפי updatedAt (שדה יחיד -
  /// לא דורש אינדקס מורכב) וסופרים לפי mode בצד הלקוח - בלי שום תלות
  /// בהגדרה ידנית בקונסולה של Firebase.
  //
  // 🩹 חיסכון בקריאות Firestore: הפונקציה הזו נקראה פעמיים (duel + race)
  // כל 30 שניות מכל משתמש שנמצא במסך הבית, ובכל קריאה שלפה את *כל* מסמכי
  // הנוכחות הפעילים (עד 500) - כלומר עשרות קריאות בכל רענון, לכל משתמש.
  // עכשיו שאילתה אחת משותפת לשני המצבים, ותוצאתה נשמרת בזיכרון _countsCacheTtl.
  static const Duration _countsCacheTtl = Duration(seconds: 60);
  static DateTime? _countsAt;
  static Map<String, int> _counts = const {};
  static Future<Map<String, int>>? _countsInFlight;

  static Future<Map<String, int>> _fetchCounts() async {
    final now = DateTime.now();
    if (_countsAt != null && now.difference(_countsAt!) < _countsCacheTtl) return _counts;
    return _countsInFlight ??= () async {
      try {
        final cutoff = Timestamp.fromDate(DateTime.now().subtract(activeWindow));
        final snap = await _db
            .collection(_collection)
            .where('updatedAt', isGreaterThan: cutoff)
            .limit(200)
            .get();
        final result = <String, int>{};
        for (final d in snap.docs) {
          final m = d.data()['mode'];
          if (m is String) result[m] = (result[m] ?? 0) + 1;
        }
        _counts = result;
        _countsAt = DateTime.now();
      } catch (_) {
        // נשארים עם הערך הקודם
      } finally {
        _countsInFlight = null;
      }
      return _counts;
    }();
  }

  // 🆕 "בוטים מחוברים" - תוספת מדומה שנוספת למספר "X משחקים עכשיו"
  // שמוצג בתפריט הראשי/מסך בחירת מוד, כדי שהאפליקציה לא תיראה ריקה
  // כשיש מעט שחקנים אמיתיים. נשלטת מרחוק דרך *אותו* מסמך meta/appConfig
  // ששולט כבר על הבוטים עצמם (ראו bot_config.dart) - שדות fakeOnlineBoostMin/
  // fakeOnlineBoostMax (מספרים שלמים, ברירת מחדל 0/0 = כבוי), כתיבה
  // ידנית בלבד דרך Firebase Console.
  // 🐛 תוקן: "מסך הבית מראה 4 מחוברים, אבל במסך בחירת המוד רואים 2+2" -
  // הגרסה הקודמת הגרילה מספר *חדש ואקראי* בכל פעם שהמטמון התרענן, וכל
  // מסך (בית/בחירת מוד) מרענן בזמנים שונים משלו - אז שני מסכים שנפתחו
  // בפערי זמן קטנים יכלו לקבל שתי הגרלות שונות, וזה נראה כאילו המספרים
  // "לא מסתדרים". עכשיו זה לא הגרלה בכלל - זו פונקציה דטרמיניסטית של
  // (מוד, "חלון הזמן" הנוכחי בן 5 דקות): אותו קלט = תמיד אותה תוצאה,
  // בכל מסך, בכל רגע נתון - אין שום דרך שהמספרים "לא יסתדרו" יותר. זה
  // עדיין "חי" (מתחלף כל 5 דקות), ועדיין שונה בין דו-קרב למירוץ.
  // ⚠️ בכוונה משפיעה *רק* על המספר המוצג כאן - לא נוגעת בשום מקום
  // בהתאמה/בתור האמיתיים, כדי שלא "לשבור" משחק אמיתי.
  static const Duration _boostCacheTtl = Duration(seconds: 60);
  static const Duration _boostChangeWindow = Duration(minutes: 5);
  static DateTime? _boostConfigAt;
  static int _boostMin = 0;
  static int _boostMax = 0;

  static Future<int> _fetchBoost(String mode) async {
    final now = DateTime.now();
    if (_boostConfigAt == null || now.difference(_boostConfigAt!) >= _boostCacheTtl) {
      try {
        final doc = await _db.collection('meta').doc('appConfig').get().timeout(const Duration(seconds: 4));
        final data = doc.data();
        final minV = data?['fakeOnlineBoostMin'];
        final maxV = data?['fakeOnlineBoostMax'];
        _boostMin = (minV is int) ? minV.clamp(0, 100000) : 0;
        _boostMax = (maxV is int) ? maxV.clamp(_boostMin, 100000) : _boostMin;
        _boostConfigAt = DateTime.now();
      } catch (_) {
        // נשארים עם הטווח הקודם (או 0/0 אם עוד לא נטען בהצלחה אף פעם)
      }
    }
    final span = _boostMax - _boostMin;
    if (span <= 0) return _boostMin.clamp(0, 100000);
    final bucket = now.millisecondsSinceEpoch ~/ _boostChangeWindow.inMilliseconds;
    final seed = Object.hash(bucket, mode);
    return _boostMin + Random(seed).nextInt(span + 1);
  }

  static Future<int> countActive(String mode) async {
    final counts = await _fetchCounts();
    final boost = await _fetchBoost(mode);
    return (counts[mode] ?? 0) + boost;
  }

  // 🆕 לצורך מסך המעקב היזמי (presence_admin_screen.dart) - "מי מחובר
  // עכשיו ומה הוא עושה". בכוונה *לא* משתמשים כאן בסינון לפי mode (כמו
  // countActive) כדי לא להזדקק לאינדקס מורכב נוסף - שולפים את כל
  // המסמכים הפעילים לפי updatedAt בלבד (שדה יחיד - לא דורש אינדקס
  // מורכב), ומקבצים לפי מוד בצד הלקוח. מוגבל ל-200 התוצאות האחרונות
  // (יותר ממספיק לכל שימוש סביר בפרויקט הזה).
  static Future<List<Map<String, dynamic>>> listActive() async {
    try {
      final cutoff = Timestamp.fromDate(DateTime.now().subtract(activeWindow));
      final snap = await _db
          .collection(_collection)
          .where('updatedAt', isGreaterThan: cutoff)
          .orderBy('updatedAt', descending: true)
          .limit(200)
          .get();
      return snap.docs
          .map((d) => {
                'deviceId': d.id,
                'mode': (d.data()['mode'] as String?) ?? '?',
                'updatedAt': (d.data()['updatedAt'] as Timestamp?)?.toDate(),
              })
          .toList();
    } catch (_) {
      return [];
    }
  }
}