//logo_level_screen
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sub_levels_screen.dart';
import 'leaderboard.dart';
import 'audio_manager.dart';
import 'shop_screen.dart';
import 'starter_pack_dialog.dart'; // 🆕 מציג מארז פתיחה ברגע חיכוך אם עדיין זכאי
import 'ads_manager.dart';
import 'review_manager.dart';
import 'app_background.dart';
import 'connectivity_helper.dart';
import 'device_id.dart';
import 'player_sync.dart';
import 'debug_log.dart';
import 'missions_service.dart';
import 'app_icons.dart'; // 🆕 CoinIcon - אימוג'י מטבע במקום אייקון וקטורי
import 'level_override_service.dart'; // 🆕 תיקוני שלבים מרחוק (Firestore) בלי לפרסם גרסה חדשה
import 'battle_pass_service.dart';
import 'achievements_service.dart'; // 🆕 נקודות "באטל פאס" על פתרון שלבים
import 'screenshot_guard_service.dart'; // 🆕 ענישה על צילום מסך חוזר - ראו _onRepeatedScreenshot
import 'app_notification.dart';
// 🐛 תוקן: הקובץ הזה החזיק עותק מקומי משלו של LevelData/levelsCounts/
// gameLevels - זהה ב-100% לגרסה הגלובלית ב-level_data.dart (שכבר
// חולצה משם קודם, ראו ההערה בראש level_data.dart), רק שהמעבר לא הושלם
// בפועל - הקובץ הזה (מסך המשחק האמיתי!) המשיך להשתמש בעותק המקומי
// הישן, שלא כלל רמות חדשות שנוספו רק לגרסה הגלובלית (בדיוק זו הסיבה
// ש-40 הדגלים החדשים לא הופיעו כאן). עכשיו זה משתמש בגרסה הגלובלית
// היחידה, כדי שרמה חדשה שנוספת פעם אחת ב-level_data.dart תופיע
// אוטומטית בכל מקום - לא רק בחלק מהמסכים.
import 'level_data.dart';
class LogoLevelScreen extends StatefulWidget {
  final int puzzleId;
  final bool isRandomMode; // מצב "אתגר רנדומלי"
  const LogoLevelScreen({super.key, required this.puzzleId, this.isRandomMode = false});

  @override
  State<LogoLevelScreen> createState() => _LogoLevelScreenState();
}

class _LogoLevelScreenState extends State<LogoLevelScreen> {
  late int currentPuzzleId;

  // ==== מבנה הניחוש: כל אות במילה יושבת בתא משלה ====
  // guessSlots[i] = האות שמונחת בעמדה i (null = עדיין ריק). זה מאפשר לרמז
  // לחשוף אות באמצע המילה בלי לפרק את סדר ההקלדה הרגיל.
  List<String?> guessSlots = [];
  // typedOrder: סדר העמדות שהוקלדו ידנית ע"י המשתמש (לא כולל רמזים) -
  // רק אלה ניתנות למחיקה בבק-ספייס.
  List<int> typedOrder = [];
  // hintedPositions: עמדות שנחשפו ע"י רמז - נעולות, אי אפשר למחוק אותן.
  Set<int> hintedPositions = {};
  // מיפוי בין עמדה במילה לאינדקס הכפתור במקלדת שהוקלק/הועם בגללה - כדי
  // שבק-ספייס ידע בדיוק איזה כפתור לשחרר בחזרה.
  Map<int, int> slotToKeyIndex = {};

  int coins = 15;
  int xp = 0;
  String username = "שחקן אנונימי";
  List<int> pressedKeysIndices = [];

  // מעקב אחרי רמזים בשלב הנוכחי (מתאפס בכל שלב חדש)
  int letterHintsUsed = 0;   // כל רמז אות מוריד 1 XP מהפרס
  bool usedWordHint = false; // פתרון מילה מלא = 5 XP בלבד ובלי מטבעות
  bool adHintUsedThisPuzzle = false; // רמז-פרסומת אחד בלבד לכל חידה

  // 💡 "תקוע?" - אם עברו 10 שניות בלי שהפתרון הצליח (או אחרי טעות שמאפסת
  // את החידה), מציגים בועית קטנה מעל המנורה שמזמינה לקחת רמז.
  //
  // ⚠️ מוצגת דרך Overlay אמיתי (OverlayEntry + CompositedTransformFollower)
  // ולא כ-Positioned רגיל בתוך ה-Stack המקומי של הכפתור. הגרסה הקודמת
  // (Positioned עם left/right שליליים כדי "לצאת" מגבולות ה-Stack הצר)
  // המשיכה לא לקבל לחיצות אצל המשתמש למרות כמה ניסיונות תיקון - כנראה
  // בגלל שהבועית ציירה מחוץ לגבולות ה-Row/Column שמכיל אותה, ווידג'טים
  // אחרים באותו אזור על המסך "תפסו" את מבחן-הפגיעה (Hit-Test) לפניה.
  // Overlay אמיתי (בדיוק כמו Tooltip/PopupMenu של פלאטר עצמו) מצויר תמיד
  // מעל הכל ומבטיח שהלחיצה תגיע אליו קודם, בלי תלות במבנה המסך מתחתיו.
  Timer? _stuckHintTimer;
  final LayerLink _hintButtonLink = LayerLink();
  OverlayEntry? _stuckTipOverlayEntry;

  // מה הרווחנו בשלב האחרון - לתצוגה בחלון "כל הכבוד"
  int lastEarnedXp = 0;
  int lastEarnedCoins = 0;

  // מצב רנדומלי
  bool isPickingRandom = false;
  bool? hasInternet; // null = עדיין בודקים, true/false = תוצאה
  int randomStreak = 0;      // רצף נוכחי 🔥 - נשמר בין כניסות, מתאפס רק בטעות
  int bestRandomStreak = 0;  // שיא הרצף (נשמר במכשיר)



  Color _getContrastingTextColor(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }

  // 🐛 levelsCounts/gameLevels הועברו ל-level_data.dart (import למעלה) -
  // ראו ההערה ליד ה-import.

  LevelData get currentLevelData => _applyOverride(currentPuzzleId, gameLevels[currentPuzzleId] ?? gameLevels[1]!);

  // 🆕 מפעיל תיקון אדמין (אם קיים לשלב הזה - ראו level_override_service.dart)
  // מעל הנתונים הקבועים בקוד: כל שדה שלא הוגדר בתיקון נשאר כמו במקור,
  // כך שאפשר לתקן, למשל, רק את התשובה בלי לגעת במקלדת. imageUrl (תמונת
  // רשת) מטופל בנפרד במקום שבו התמונה מוצגת בפועל, לא כאן.
  LevelData _applyOverride(int levelId, LevelData base) {
    final o = LevelOverrideService.overrideFor(levelId);
    if (o == null) return base;
    final overrideAnswer = o['answer'] as String?;
    final overrideKeyboardRaw = o['keyboard'];
    final overrideKeyboard = overrideKeyboardRaw is List ? overrideKeyboardRaw.map((e) => e.toString()).toList() : null;
    if (overrideAnswer == null && overrideKeyboard == null) return base;
    return LevelData(
      ans: overrideAnswer ?? base.answer,
      imagePath: base.imagePath,
      logoColor: base.logoColor,
      keyboard: overrideKeyboard ?? base.keyboard,
    );
  }

  // 🆕 קישור תמונת רשת חלופית לשלב הנוכחי (תיקון אדמין), אם הוגדר -
  // ראו level_override_service.dart. null אומר "אין תיקון תמונה, השתמש
  // בתמונת ה-assets המקורית".
  String? get _currentLevelImageUrlOverride {
    final o = LevelOverrideService.overrideFor(currentPuzzleId);
    final url = o?['imageUrl'] as String?;
    return (url != null && url.trim().isNotEmpty) ? url.trim() : null;
  }

  // 🆕 מציג את תמונת השלב - תמונת רשת (imageUrl) אם הוגדר תיקון אדמין
  // לשלב הזה, אחרת תמונת ה-assets המקורית כמו תמיד. אם תמונת הרשת
  // נכשלת בטעינה (קישור שבור וכו') - נופלים חזרה לתמונת ה-assets
  // המקורית במקום להציג מסך שבור, כדי שתיקון גרוע לא יגרום נזק.
  Widget _buildLevelImage() {
    final overrideUrl = _currentLevelImageUrlOverride;
    if (overrideUrl == null) {
      return Image.asset(currentLevelData.imagePath, fit: BoxFit.contain);
    }
    return Image.network(
      overrideUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) => Image.asset(currentLevelData.imagePath, fit: BoxFit.contain),
    );
  }

  /// מאתחל את כל התאים למילה החדשה - נקרא בכל פעם שמתחילים חידה חדשה
  /// (לא ב"נסה שוב" על אותה חידה, שם רק מרוקנים את התאים הקיימים)
  void _initGuessSlots() {
    int len = currentLevelData.answer.replaceAll(' ', '').length;
    guessSlots = List<String?>.filled(len, null);
    typedOrder = [];
    hintedPositions = {};
    slotToKeyIndex = {};
    adHintUsedThisPuzzle = false; // רמז-הפרסומת מתאפס עם כל חידה חדשה
    _restartStuckHintTimer();
    _restoreSavedHints(); // 🔴 אם כבר נלקחו רמזים בחידה הזו קודם ויצאנו - מחזירים אותם
  }

  /// משחזר רמזי-אות ששולמו עליהם (מטבעות/פרסומת) בחידה הזו לפני שהמשתמש
  /// יצא מהמסך וחזר. בלי זה, רמז ששולם עליו היה "נעלם" בחזרה לחידה,
  /// למרות שהמשתמש כבר שילם עליו ולא אמור לאבד אותו.
  Future<void> _restoreSavedHints() async {
    final int puzzleId = currentPuzzleId;
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('hintPositions_$puzzleId');
    if (saved == null || saved.isEmpty) return;
    if (!mounted || currentPuzzleId != puzzleId) return; // המשתמש כבר עבר הלאה לחידה אחרת

    final positions = saved.split(',').map((s) => int.tryParse(s)).whereType<int>().toSet();
    final int savedHintsUsed = prefs.getInt('hintLetterCount_$puzzleId') ?? 0;
    final bool savedWordUsed = prefs.getBool('hintWordUsed_$puzzleId') ?? false;
    // 🔴 האם רמז-הפרסומת כבר נוצל בחידה הזו - נשמר בנפרד, כדי שיציאה
    // וחזרה לאותה חידה לא "תשכח" שכבר נוצל וניתן שוב לצפות בפרסומת נוספת.
    final bool savedAdHintUsed = prefs.getBool('adHintUsed_$puzzleId') ?? false;
    // 🩹 בעבר נלקח כאן ישירות gameLevels[puzzleId] (התשובה הקבועה בקוד),
    // מה שהתעלם מתיקון אדמין פעיל לשלב הזה (ראו currentLevelData/
    // level_override_service.dart) וגרם לאותיות רמז שגויות אם התשובה
    // תוקנה מרחוק. puzzleId==currentPuzzleId תמיד כאן (נבדק למעלה), אז
    // currentLevelData (שכבר כולל את התיקון אם יש) הוא הנכון להשתמש בו.
    final String answerNoSpaces = currentLevelData.answer.replaceAll(' ', '');

    setState(() {
      for (final pos in positions) {
        if (pos < 0 || pos >= guessSlots.length) continue;
        String letter = answerNoSpaces[pos];
        guessSlots[pos] = letter;
        hintedPositions.add(pos);
        for (int i = 0; i < currentLevelData.keyboard.length; i++) {
          if (currentLevelData.keyboard[i] == letter && !pressedKeysIndices.contains(i)) {
            pressedKeysIndices.add(i);
            slotToKeyIndex[pos] = i;
            break;
          }
        }
      }
      letterHintsUsed = savedHintsUsed;
      usedWordHint = savedWordUsed;
      adHintUsedThisPuzzle = savedAdHintUsed;
    });
  }

  /// שומר את מצב הרמזים הנוכחי של החידה כדי שיחזור אם יוצאים ונכנסים שוב
  Future<void> _saveHintState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hintPositions_$currentPuzzleId', hintedPositions.join(','));
    await prefs.setInt('hintLetterCount_$currentPuzzleId', letterHintsUsed);
    await prefs.setBool('hintWordUsed_$currentPuzzleId', usedWordHint);
    await prefs.setBool('adHintUsed_$currentPuzzleId', adHintUsedThisPuzzle);
  }

  /// מנקה את מצב הרמזים השמור של חידה - נקרא אחרי שהיא נפתרה בהצלחה,
  /// כדי לא להשאיר נתונים מיותרים ב-SharedPreferences
  Future<void> _clearHintState(int puzzleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hintPositions_$puzzleId');
    await prefs.remove('hintLetterCount_$puzzleId');
    await prefs.remove('hintWordUsed_$puzzleId');
    await prefs.remove('adHintUsed_$puzzleId');
  }

  /// מפעיל מחדש את הטיימר של "תקוע?" - נקרא בתחילת כל חידה ואחרי כל טעות.
  /// אם עברו 10 שניות בלי שהחידה נפתרה - מציגים בועית מעל המנורה.
  void _restartStuckHintTimer() {
    _stuckHintTimer?.cancel();
    _hideStuckTipOverlay();
    _stuckHintTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      _showStuckTipOverlay();
    });
  }

  /// מציג את בועית "תקוע?" כ-Overlay אמיתי, "מוצמד" למיקום המדויק של
  /// כפתור המנורה (דרך _hintButtonLink) בעזרת CompositedTransformFollower -
  /// אותה טכניקה שפלאטר עצמו משתמש בה ל-Tooltip/PopupMenu, כדי להבטיח
  /// שהבועית תמיד תקבל לחיצות בלי קשר למבנה שאר המסך.
  void _showStuckTipOverlay() {
    // 🛡️ רשת ביטחון כללית: אם יש כרגע מסך/דיאלוג/bottom sheet אחר פתוח
    // מעל המשחק (route.isCurrent == false) - לא מציגים את הבועית (היא
    // הייתה צפה מעליו ונראית לא מקצועית), אלא בודקים שוב בעוד רגע. זה
    // מגן על כל מקום עתידי שפותח דיאלוג/מסך, לא רק את אלה שכבר מטפלים
    // בטיימר במפורש (תפריט רמזים / חלון "אין מספיק מטבעות").
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      _stuckHintTimer?.cancel();
      _stuckHintTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) _showStuckTipOverlay();
      });
      return;
    }
    _hideStuckTipOverlay();
    final overlay = Overlay.of(context, rootOverlay: true);
    _stuckTipOverlayEntry = OverlayEntry(
      builder: (context) {
        // חשוב: בלי Positioned.fill! Positioned.fill היה כופה אילוצים
        // "טייטים" (tight) בגודל כל המסך שזלגו דרך CompositedTransformFollower
        // ו-Material/InkWell עד ל-Container הפנימי (שאין לו width/height
        // מפורשים) - וכך הוא "נמתח" למלא את כל המסך. הפתרון: להשאיר את
        // הבועית כילד "לא ממוקם" (non-positioned) ישירות בתוך ה-Stack של
        // ה-Overlay, מה שנותן לה רק אילוצים "רופפים" (loose) - כך שהיא
        // חוזרת לגודל התוכן הטבעי שלה. UnconstrainedBox כתוספת בטיחות,
        // למקרה שהאילוצים עדיין יגיעו טייטים ממקור אחר.
        // 🎨 עיצוב זכוכיתי/גרדיאנט-זהב תואם לשאר האפליקציה (במקום קופסה
        // שטוחה בצבע אמבר/סגול בוהק) + חץ-מצביע קטן שמחבר ויזואלית לשבב
        // "רמז" שמתחתיה, וריווח גדול יותר (-14 במקום -6) כדי שהיא "תרחף"
        // מעליו בבירור במקום להידחס ממש עליו - זה מה שגרם לתחושה
        // "לא יפה ולא מקצועית" (שני עיצובים שונים ותלושים זה על זה).
        // שלושה מצבי הודעה: יש מספיק מטבעות / אין מטבעות אבל יש עדיין
        // רמז-פרסומת פנוי / אין מטבעות וגם כבר נוצל רמז-הפרסומת בחידה הזו.
        final bool hasEnoughCoins = coins >= 20;
        final bool isFreeAd = !hasEnoughCoins && !adHintUsedThisPuzzle;
        final String bubbleText = hasEnoughCoins
            ? "יש לך רמז! 💡"
            : (isFreeAd ? "פרסומת = רמז חינם 🎬" : "לחץ למנורה 💡");
        final List<Color> bubbleGradient = isFreeAd
            ? const [Color(0xFF9B5CF6), Color(0xFF7C3AED)]
            : const [Color(0xFFFFE08A), Color(0xFFFFB24D)];
        final Color bubbleTextColor = isFreeAd ? Colors.white : const Color(0xFF2A1740);
        return UnconstrainedBox(
          child: CompositedTransformFollower(
            link: _hintButtonLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: const Offset(0, -14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                // אם ההודעה מציעה פרסומת (אין מספיק מטבעות ועוד לא נוצל רמז-
                // פרסומת בחידה הזו) - לחיצה עליה קופצת ישר לפרסומת, בלי לעבור
                // דרך תפריט הרמזים. אחרת (יש מטבעות, או שכבר נוצל הרמז) -
                // פותחים את התפריט הרגיל / חושפים רמז ישירות.
                onTap: _onStuckBubbleTap,
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: bubbleGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
                        boxShadow: [
                          BoxShadow(color: bubbleGradient.last.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Text(
                        bubbleText,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(color: bubbleTextColor, fontSize: 12.5, fontWeight: FontWeight.w900),
                      ),
                    ),
                    // חץ קטן שמצביע כלפי מטה, אל שבב "רמז"
                    CustomPaint(size: const Size(14, 7), painter: _BubbleArrowPainter(color: bubbleGradient.last)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_stuckTipOverlayEntry!);
  }

  /// מסיר את בועית "תקוע?" אם היא מוצגת כרגע. בטוח לקרוא גם כשהיא לא
  /// מוצגת (no-op).
  void _hideStuckTipOverlay() {
    _stuckTipOverlayEntry?.remove();
    _stuckTipOverlayEntry = null;
  }

  // ===== זיהוי הקטגוריה של החידה הנוכחית (להצגה במצב רנדומלי) =====
  // ⚠️ המיפוי הזה חייב להישאר זהה למפה שב-levels_screen.dart וב-sub_levels_screen.dart
  static const Map<int, int> _categoryLevelsCounts = {
     1: 35,
    2: 33,
    3: 23,
    4: 33,
    5: 19,
    6: 28,
    7: 31,
    8: 29,
    9: 27,
    10: 35,
    11: 27,
    12: 33,
    13: 22,
    14: 23, // NBA
    15: 37, // יחידות בצה"ל וכוחות הביטחון
    16: 23, // רכבים חלק ב
  };

  String _categoryWorldName(int worldNum) {
    switch (worldNum) {
      case 1:
        return "חברות חלק א";
      case 2:
        return "דגלים חלק א";
      case 3:
        return "אפליקציות";
      case 4:
        return "רכבים";
      case 5:
        return "סופרים";
      case 6:
        return "רשתות מוכרות";
      case 7:
        return "חטיפים וממתקים";
      case 8:
        return "קבוצות כדורגל";
      case 9:
        return "ערים בישראל";
      case 10:
        return "דגלים חלק ב";
      case 11:
        return "בנקים וביטוח";
        case 12:
        return "חברות חלק ב";
        case 13:
        return "משחקים מוכרים";
        case 14:
        return "קבוצות NBA";
      case 15:
        return "יחידות בצה\"ל וכוחות הביטחון";
      case 16:
        return "רכבים חלק ב";
      case 17:
        return "אלקטרוניקה ומכשירי חשמל";
      case 18:
        return "תקשורת וחדשות ישראליות";
      case 19:
        return "דגלים חלק ג'";
      case 20:
        return "אלקטרוניקה ומכשירי חשמל חלק ב";
      default:
        return "כללי";
    }
  }

  /// שם הקטגוריה של puzzleId נתון (למשל: חידה 45 -> "רכבים")
  String get currentCategoryName {
    int idCounter = 0;
    for (final entry in _categoryLevelsCounts.entries) {
      idCounter += entry.value;
      if (currentPuzzleId <= idCounter) return _categoryWorldName(entry.key);
    }
    return "כללי";
  }

  int get currentMainLevel {
    int idCounter = 0;
    for (int i = 1; i <= levelsCounts.length; i++) {
      int count = levelsCounts[i] ?? 23;
      idCounter += count;
      if (currentPuzzleId <= idCounter) {
        return i;
      }
    }
    return levelsCounts.length;
  }

  int get displayPuzzleNum {
    int idCounter = 0;
    for (int i = 1; i <= levelsCounts.length; i++) {
      int count = levelsCounts[i] ?? 23;
      if (currentPuzzleId <= idCounter + count) {
        return currentPuzzleId - idCounter;
      }
      idCounter += count;
    }
    return currentPuzzleId - idCounter; 
  }

 @override
void initState() {
  super.initState();
  DebugLog.add("LogoLevelScreen.initState START (puzzleId=${widget.puzzleId}, isRandomMode=${widget.isRandomMode})");
  // 🔴 מאזינים לעדכוני מטבעות/איפוס מרחוק (ראה player_sync.dart) כדי
  // שהתצוגה על המסך תתעדכן מיד גם אם השחקן כבר באמצע שלב, ולא רק
  // בפעם הבאה שהוא פותח את האפליקציה מחדש.
  PlayerSyncService.remoteCoinsUpdate.addListener(_onRemoteCoinsUpdate);
  PlayerSyncService.remoteResetSignal.addListener(_onRemoteReset);
  // 🆕 ענישה על צילום מסך חוזר (לפי בקשה מפורשת: "בפעם הראשונה התראה,
  // בפעם השנייה מעביר שלב בלי אופציה לחזור") - ראו _onRepeatedScreenshot.
  ScreenshotGuardService.onRepeatedScreenshot = _onRepeatedScreenshot;
  AdsManager.recordGameEntered(); // 🆕 נכנסים למשחק בפועל - מאפס את מונה "גלישה בלי לשחק"
  DebugLog.add("LogoLevelScreen.initState: listeners attached, calling _checkConnectivityAndStart");
  _checkConnectivityAndStart();
  _loadLevelOverride(); // 🆕 תיקוני שלבים מרחוק - ברקע, לא חוסם את תחילת המשחק
  DebugLog.add("LogoLevelScreen.initState END");
}

  // 🆕 טוען (אם עוד לא נטען מוקדם יותר בסשן) את רשימת תיקוני השלבים
  // מ-Firestore, ומרענן את המסך אם התוצאה השתנתה - כדי שאם השלב הנוכחי
  // בדיוק קיבל תיקון, המשתמש יראה אותו מיד בלי לצאת ולהיכנס מחדש לשלב.
  Future<void> _loadLevelOverride() async {
    await LevelOverrideService.preload();
    if (mounted) setState(() {});
  }

  void _onRemoteCoinsUpdate() {
    final newCoins = PlayerSyncService.remoteCoinsUpdate.value;
    if (newCoins != null && mounted) {
      setState(() => coins = newCoins);
    }
  }

  void _onRemoteReset() {
    if (!mounted) return;
    setState(() {
      coins = 15;
      xp = 0;
    });
  }

  /// בודק חיבור אינטרנט אמיתי לפני שמאפשרים לשחק בכלל - בלי אינטרנט
  /// אין פרסומות, ובלי פרסומות אין הכנסה, אז המשחק לא נפתח.
  Future<void> _checkConnectivityAndStart() async {
    DebugLog.add("LogoLevelScreen._checkConnectivityAndStart: checking...");
    bool connected = await ConnectivityHelper.hasInternet();
    DebugLog.add("LogoLevelScreen._checkConnectivityAndStart: connected=$connected");
    if (!mounted) return;

    if (!connected) {
      setState(() => hasInternet = false);
      return;
    }

    setState(() => hasInternet = true);
    DebugLog.add("LogoLevelScreen._checkConnectivityAndStart: calling _startGame");
    _startGame();
  }

  // מסך חסימה כשאין אינטרנט - בלי חיבור אין פרסומות, ובלי פרסומות
  // אין הכנסה, אז לא מאפשרים לשחק בכלל עד שיש חיבור
  Widget _buildNoInternetScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF120C2E),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 80),
                const SizedBox(height: 24),
                const Text(
                  "אין חיבור לאינטרנט",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "כדי לשחק צריך חיבור פעיל לאינטרנט. בדקו את ה-WiFi או הסלולר ונסו שוב.",
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.white60, fontSize: 15),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.black),
                  label: const Text("נסה שוב", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() => hasInternet = null);
                    _checkConnectivityAndStart();
                  },
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("חזרה", style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startGame() {
    DebugLog.add("LogoLevelScreen._startGame START");
    currentPuzzleId = widget.puzzleId;
    _initGuessSlots();
    DebugLog.add("LogoLevelScreen._startGame: calling _loadPlayerData");
    _loadPlayerData();

    // הנמכת המוזיקה רק אחרי שהמסך כבר צויר - אף פעולת אודיו לא חוסמת את הפתיחה
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DebugLog.add("LogoLevelScreen._startGame: postFrameCallback -> AudioManager.duckMusic");
      AudioManager.duckMusic();
    });

    // במצב רנדומלי - בוחרים חידה אקראית שעוד לא נפתרה
    if (widget.isRandomMode) {
      setState(() => isPickingRandom = true);
      DebugLog.add("LogoLevelScreen._startGame: random mode -> _pickNextRandomPuzzle");
      _pickNextRandomPuzzle(isFirst: true);
    }
    DebugLog.add("LogoLevelScreen._startGame END");
  }

  // ================= מצב רנדומלי =================

  Future<List<String>> _getRandomSolvedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('randomSolvedIds') ?? [];
  }

  Future<void> _markRandomSolved(int puzzleId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> solved = prefs.getStringList('randomSolvedIds') ?? [];
    if (!solved.contains(puzzleId.toString())) {
      solved.add(puzzleId.toString());
      await prefs.setStringList('randomSolvedIds', solved);
    }
  }

  /// בוחר חידה אקראית שעוד לא נפתרה במצב הרנדומלי.
  /// [isFirst] - בחירה ראשונית בכניסה למסך.
  Future<void> _pickNextRandomPuzzle({bool isFirst = false}) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> solved = await _getRandomSolvedIds();

    // בכניסה הראשונה למסך: אם יש חידה שכבר התחלנו ולא סיימנו - ממשיכים
    // אותה במקום לבחור לוגו חדש. כך יציאה וחזרה למצב הרנדומלי לא "מחליפה"
    // את החידה שהיינו באמצע פתרונה.
    if (isFirst) {
      int? savedId = prefs.getInt('currentRandomPuzzleId');
      if (savedId != null && gameLevels.containsKey(savedId) && !solved.contains(savedId.toString())) {
        if (!mounted) return;
        setState(() {
          currentPuzzleId = savedId;
          _initGuessSlots();
          pressedKeysIndices.clear();
          letterHintsUsed = 0;
          usedWordHint = false;
          isPickingRandom = false;
        });
        return;
      }
    }

    List<int> unsolved = gameLevels.keys
        .where((id) => !solved.contains(id.toString()) && (isFirst || id != currentPuzzleId))
        .toList();

    if (!mounted) return;

    if (unsolved.isEmpty) {
      setState(() => isPickingRandom = false);
      await prefs.remove('currentRandomPuzzleId');
      _showRandomCompleteDialog();
      return;
    }

    unsolved.shuffle();
    final int nextId = unsolved.first;
    await prefs.setInt('currentRandomPuzzleId', nextId); // שומרים איזו חידה "בעבודה" כרגע

    setState(() {
      currentPuzzleId = nextId;
      _initGuessSlots();
      pressedKeysIndices.clear();
      letterHintsUsed = 0;
      usedWordHint = false;
      isPickingRandom = false;
    });
  }

  void _showRandomCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241a4f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 90),
            SizedBox(height: 15),
            Text("וואו! 🎉", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(
              "פתרת את כל הלוגואים במצב הרנדומלי!",
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(context); // סוגר את הדיאלוג
                Navigator.pop(context); // חוזר למסך הראשי
              },
              child: const Text("חזרה למסך הראשי", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  // 🆕 נקרא בלחיצה על כפתור "בית" - בפעם הראשונה בלבד (לכל מכשיר) מציג
  // קודם פופאפ סגול "נהנים מהמשחק?" עם בקשת דירוג 5 כוכבים (הלוגיקה
  // המשותפת נמצאת ב-review_manager.dart כדי שגם sub_levels_screen.dart
  // יוכל להשתמש באותה פונקציה בלי כפילות קוד), ורק אחרי שהוא נסגר (בכל
  // דרך) ממשיך לחזרה לתפריט הראשי כרגיל.
  Future<void> _onHomePressed() async {
    DebugLog.add("LogoLevelScreen._onHomePressed: calling ReviewManager.handleHomeButtonTap");
    await ReviewManager.handleHomeButtonTap(context);
    DebugLog.add("LogoLevelScreen._onHomePressed: handleHomeButtonTap returned");
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241a4f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
        title: const Text("אודות האפליקציה", style: TextStyle(color: Colors.white)),
        content: const Text(
          "כל הלוגואים המוצגים באפליקציה זו שייכים לבעליהם בהתאמה. "
          "השימוש בלוגואים למטרות זיהוי בלבד נעשה תחת עקרון 'שימוש הוגן'. "
          "אפליקציה זו אינה קשורה, ממומנת או מאושרת על ידי החברות המוצגות.",
          style: TextStyle(color: Colors.white70),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("סגור", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _loadPlayerData() async {
    DebugLog.add("LogoLevelScreen._loadPlayerData START");
    // בדיקת איפוס מרחוק (ראה player_sync.dart) - אם ביקשת לאפס את השחקן
    // הזה דרך Firestore, זה יקרה כאן לפני שנטען את הנתונים מהמכשיר.
    try {
      DebugLog.add("LogoLevelScreen._loadPlayerData: calling checkForRemoteReset");
      await PlayerSyncService.checkForRemoteReset();
      DebugLog.add("LogoLevelScreen._loadPlayerData: checkForRemoteReset returned OK");
    } catch (e) {
      // בלי אינטרנט או שגיאה כלשהי - פשוט ממשיכים לטעון את הנתונים
      // המקומיים כרגיל, בלי לתקוע את המשחק.
      DebugLog.add("LogoLevelScreen._loadPlayerData: checkForRemoteReset ERROR: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      DebugLog.add("LogoLevelScreen._loadPlayerData: not mounted after prefs, skipping setState");
      return;
    }
    setState(() {
      coins = prefs.getInt('coins') ?? 15;
      xp = prefs.getInt('xp') ?? 0;
      username = prefs.getString('username') ?? "שחקן אנונימי";
      bestRandomStreak = prefs.getInt('bestRandomStreak') ?? 0;
      randomStreak = prefs.getInt('randomStreak') ?? 0; // הרצף נשמר בין כניסות
    });
    DebugLog.add("LogoLevelScreen._loadPlayerData END");
  }

  void _savePlayerData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', coins);
    await prefs.setInt('xp', xp);
    // מסנכרן לענן (Firestore) ברקע - לא חוסם ולא מפריע אם אין אינטרנט.
    PlayerSyncService.syncCurrentProgress();
  }

  /// ה-ID הראשון של רמה ראשית נתונה, לפי levelsCounts
  int _firstPuzzleIdOfWorld(int mainLevel) {
    int startId = 1;
    for (int i = 1; i < mainLevel; i++) {
      startId += levelsCounts[i] ?? 23;
    }
    return startId;
  }

  void _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // אם החידה הנוכחית שייכת לעולם שנרכש מראש בתשלום (לפני שההתקדמות
    // הרגילה הגיעה אליו) - מתקדמים רק בסמן הפנימי של העולם הזה, ולא
    // בהתקדמות הגלובלית. אחרת, פתרון חידה בעולם 12 למשל (שה-ID שלה
    // גבוה בהרבה מ-maxLevel הנוכחי) היה מקפיץ את maxLevel קדימה, ומסמן
    // בטעות את כל העולמות שביניהם כאילו נפתרו במלואם.
    // ⚠️ אותו מנגנון קיים ב-levels_screen.dart, ב-sub_levels_screen.dart
    // וב-iap_manager.dart.
    List<String> purchasedWorlds = prefs.getStringList('purchasedWorlds') ?? [];
    int world = currentMainLevel;
    if (purchasedWorlds.contains(world.toString())) {
      String cursorKey = 'worldCursor_$world';
      int cursor = prefs.getInt(cursorKey) ?? _firstPuzzleIdOfWorld(world);
      if (currentPuzzleId >= cursor) {
        await prefs.setInt(cursorKey, currentPuzzleId + 1);
      }
    } else {
      int maxLevel = prefs.getInt('maxLevel') ?? 1;
      if (currentPuzzleId >= maxLevel) {
        await prefs.setInt('maxLevel', currentPuzzleId + 1);
      }
    }
    // מסנכרן לענן (Firestore) ברקע - לא חוסם ולא מפריע אם אין אינטרנט.
    PlayerSyncService.syncCurrentProgress();
  }

 void _onLetterPressed(int index, String letter) async {
  int emptySlot = guessSlots.indexWhere((slot) => slot == null);
  if (emptySlot == -1) return; // אין יותר עמדות פנויות

  AudioManager.playClick(); // צליל קליק על כל לחיצת אות (סאונד מערכת - תמיד עובד)

  setState(() {
    guessSlots[emptySlot] = letter;
    typedOrder.add(emptySlot);
    slotToKeyIndex[emptySlot] = index;
    pressedKeysIndices.add(index);
  });

  if (guessSlots.every((slot) => slot != null)) {
    _checkAnswer();
  }
}

  void _onBackspacePressed() async {
    // אפשר למחוק רק אותיות שהוקלדו ידנית - אות שהתקבלה מרמז נעולה לצמיתות
    if (typedOrder.isEmpty) return;

    AudioManager.playClick();

    setState(() {
      int slot = typedOrder.removeLast();
      guessSlots[slot] = null;
      int? keyIndex = slotToKeyIndex.remove(slot);
      if (keyIndex != null) pressedKeysIndices.remove(keyIndex);
    });
  }

  /// מפעיל פרסומת מתוגמלת שנותנת רמז-אות חינם (עד פעם אחת לכל חידה).
  /// משותף בין כפתור הפרסומת בחלון "אין מספיק מטבעות" ובין לחיצה ישירה
  /// על הבועית "פרסומת = רמז חינם" מעל המנורה.
  void _watchRewardedAdForHint() {
    if (AdsManager.isRewardedReady) {
      AdsManager.showRewardedAd(onReward: () {
        // המשתמש צפה עד הסוף - מקבל חשיפת אות חינם, אבל רק פעם אחת לחידה הזו
        // (נשמר מיד ב-SharedPreferences כדי שגם אם ייצא ויחזור לאותה חידה
        // בלי לפתור אותה - הרמז לא "יתאפס" ויאפשר לצפות בפרסומת שוב)
        setState(() => adHintUsedThisPuzzle = true);
        _saveHintState();
        _revealLetterHint(free: true);
      });
    } else {
      AppNotification.show(context, "אין פרסומת זמינה כרגע, נסה שוב עוד רגע", type: AppNotificationType.warning);
    }
  }

  // 💸 חלון "אין מספיק מטבעות": קפיצה מעל המשחק עם אפשרות לקנות
  // או לצפות בפרסומת תמורת רמז (החיבור ל-AdMob יתווסף בהמשך)
  void _showNotEnoughCoinsDialog(int cost) async {
    // 🔴 אותו תיקון כמו בתפריט הרמזים: מבטלים את טיימר "תקוע?" (ולא רק
    // מסתירים את הבועית הנוכחית) - אחרת הוא עלול "לירות" תוך כדי שהחלון
    // הזה פתוח וליצור בועית חדשה שצפה מעליו.
    _stuckHintTimer?.cancel();
    _hideStuckTipOverlay();
    // 🆕 אם יש עדיין הצעת "מארז פתיחה" זכאית שלא הוצגה בכלל - מציגים
    // אותה קודם (ממירה הרבה יותר טוב, ובדיוק ברגע שהמשתמש פתוח לזה).
    final prefs = await SharedPreferences.getInstance();
    final maxLevel = prefs.getInt('maxLevel') ?? 1;
    if (!mounted) return;
    final shownStarterPack = await StarterPackDialog.maybeShowAtFriction(context, maxLevel: maxLevel);
    if (shownStarterPack) {
      _restartStuckHintTimer();
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF241a4f), Color(0xFF170F38)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.22), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 20)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [const Color(0xFFFFD86B).withValues(alpha: 0.35), const Color(0xFFFFD86B).withValues(alpha: 0.0)]),
                ),
                child: const CoinIcon(size: 36),
              ),
              const SizedBox(height: 20),
              const Text("אין לך מספיק מטבעות",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text("הרמז הזה עולה $cost מטבעות ויש לך רק $coins",
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15, height: 1.4)),
              const SizedBox(height: 16),

              // 🆕 פס התקדמות "כמה חסר לך" - לפי מוקאפ מסך "אין מספיק מטבעות"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: (coins / cost).clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: Colors.black.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD86B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    // ⚠️ אייקון Material במקום אימוג'י מטבע (🪙) - לא תמיד
                    // נתמך בפונט האימוג'י המובנה של אנדרואיד (אותה בעיה
                    // שכבר תוקנה בכרטיס המטבעות במסך הבית).
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("חסרים ${(cost - coins).clamp(0, cost)}",
                            style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 11.5, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 3),
                        const CoinIcon(size: 14),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // קנייה בחנות - כפתור זהב עקבי לשאר האפליקציה
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ShopScreen(highlightNeededCoins: (cost - coins).clamp(1, cost))))
                        .then((_) => _loadPlayerData()); // מרעננים מטבעות בחזרה
                  },
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)]),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_rounded, color: Color(0xFF2A1740)),
                        SizedBox(width: 8),
                        Text("לחנות המטבעות", style: TextStyle(color: Color(0xFF2A1740), fontSize: 17, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ),

              // פרסומת תמורת רמז (Rewarded Ad) - פעם אחת בלבד לכל חידה,
              // אחרת אפשר "לצפות ברצף" ולפתור מילה שלמה בחינם
              if (!adHintUsedThisPuzzle) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text("או", style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                    label: const Text("צפה בפרסומת 🎬",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    onPressed: () {
                      Navigator.pop(context);
                      _watchRewardedAdForHint();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "חושף אות אחת בלבד - לא פותר את כל המילה",
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5),
                ),
              ] else ...[
                const SizedBox(height: 18),
                Text(
                  "כבר ניצלת רמז-פרסומת בשלב הזה 🎬",
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                ),
              ],

              const SizedBox(height: 22),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("ביטול", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (mounted) _restartStuckHintTimer();
    });
  }

  void _revealLetterHint({bool free = false}) {
    // free=true: רמז שהתקבל מצפייה בפרסומת - בלי מטבעות ובלי קנס XP
    // 🩹 מחיר הועלה מ-15 ל-20 מטבעות (תואם את המחיר בדו-קרב).
    if (!free && coins < 20) {
      _showNotEnoughCoinsDialog(20);
      return;
    }

    // 🎲 בוחרים עמדה אקראית מתוך האותיות שעדיין לא נחשפו - לא בהכרח הבאה בתור
    List<int> emptySlots = [];
    for (int i = 0; i < guessSlots.length; i++) {
      if (guessSlots[i] == null) emptySlots.add(i);
    }
    if (emptySlots.isEmpty) return; // כל האותיות כבר גלויות

    if (free || coins >= 20) {
      setState(() {
        String answerNoSpaces = currentLevelData.answer.replaceAll(' ', '');
        int randomSlot = emptySlots[Random().nextInt(emptySlots.length)];
        String revealedLetter = answerNoSpaces[randomSlot];

        guessSlots[randomSlot] = revealedLetter;
        hintedPositions.add(randomSlot); // נעול - אי אפשר למחוק בבק-ספייס

        if (!free) {
          coins -= 20;
          letterHintsUsed++; // כל רמז אות מוריד 1 XP מהפרס בסוף
          MissionsService.recordEvent(MissionEvent.hintUsed); // לא מחכים - לא חוסם את המשחק
        }

        for (int i = 0; i < currentLevelData.keyboard.length; i++) {
          if (currentLevelData.keyboard[i] == revealedLetter && !pressedKeysIndices.contains(i)) {
            pressedKeysIndices.add(i);
            slotToKeyIndex[randomSlot] = i;
            break;
          }
        }
      });
      _savePlayerData();
      _saveHintState(); // 🔴 שומר את הרמז כדי שלא "ייעלם" אם יוצאים וחוזרים לחידה
      if (guessSlots.every((slot) => slot != null)) {
        _checkAnswer();
      }
    }
  }

  void _revealWordHint() {
    if (coins < 60) {
      _showNotEnoughCoinsDialog(60);
      return;
    }
    if (coins >= 60) {
      setState(() {
        String answerNoSpaces = currentLevelData.answer.replaceAll(' ', '');
        for (int i = 0; i < answerNoSpaces.length; i++) {
          guessSlots[i] = answerNoSpaces[i];
        }
        hintedPositions = Set<int>.from(List.generate(answerNoSpaces.length, (i) => i));
        typedOrder.clear();
        coins -= 60;
        usedWordHint = true; // פתרון מלא = 5 XP בלבד ובלי מטבעות
        MissionsService.recordEvent(MissionEvent.hintUsed); // לא מחכים - לא חוסם את המשחק

        pressedKeysIndices.clear();
        slotToKeyIndex.clear();
        List<bool> usedIndices = List<bool>.filled(currentLevelData.keyboard.length, false);
        for (int c = 0; c < answerNoSpaces.length; c++) {
          String letter = answerNoSpaces[c];
          for (int i = 0; i < currentLevelData.keyboard.length; i++) {
            if (!usedIndices[i] && currentLevelData.keyboard[i] == letter) {
              usedIndices[i] = true;
              pressedKeysIndices.add(i);
              slotToKeyIndex[c] = i;
              break;
            }
          }
        }
      });
      _savePlayerData();
      _checkAnswer();
    }
  }

  // 💡 העוגן לבועית "תקוע?" (CompositedTransformTarget) עבר להיות מוצמד
  // ישירות לשבב "רמז" בשורת הפעולות התחתונה (_ActionChip עם link:), כך
  // שהבועית תמיד מופיעה בדיוק מעליו - בלי צורך בכפתור מנורה נפרד.

  /// לחיצה על בועית "תקוע?" - אם היא מציעה פרסומת, קופצים ישר לפרסומת;
  /// אחרת פותחים את תפריט הרמזים הרגיל. מופרד לפונקציה משלה (במקום closure
  /// מוטמע) כדי שתמיד תיקרא בבירור, בלי תלות בסדר ריבוי setState-ים.
  void _onStuckBubbleTap() {
    AudioManager.playClick();
    _hideStuckTipOverlay();
    // 🐛 תוקן: הושוותה ל-20 (מחיר הרמז האמיתי בכל שאר הקוד - ראה
    // hasEnoughCoins למעלה ו-_revealLetterHint למטה) - כאן נשאר בטעות
    // הסף הישן (15) מלפני שמחיר הרמז הועלה, כך ששחקן עם 15-19 מטבעות
    // ראה בבועה "פרסומת = רמז חינם" אבל בלחיצה בפועל נכנס לנתיב התשלום
    // ונחסם מיד ב"אין מספיק מטבעות" - בלי שהפרסומת שהובטחה בכלל רצה.
    if (coins < 20 && !adHintUsedThisPuzzle) {
      // אין מטבעות, ורמז-הפרסומת עוד לא נוצל בחידה הזו - קופצים ישר לפרסומת
      _watchRewardedAdForHint();
    } else if (coins >= 20) {
      // יש מטבעות - במקום לפתוח תפריט ולבקש עוד לחיצה, חושפים ישר את הרמז
      // ומראים לשחקן בדיוק איזו אות התגלתה
      _revealLetterHint();
    } else {
      // אין מטבעות וגם כבר נוצל רמז-הפרסומת לחידה הזו - מפנים לתפריט הרגיל
      _showHintMenu();
    }
  }

  void _showHintMenu() {
    AudioManager.playClick();
    // 🔴 קריטי: לא מספיק להסתיר את הבועית - חייבים גם לבטל את הטיימר של
    // 10 השניות! בלי זה, אם הטיימר ממשיך "לרוץ ברקע" בזמן שתפריט הרמזים
    // פתוח (למשל המשתמש קורא את האפשרויות זמן-מה), הוא "יורה" תוך כדי
    // והבועית נוצרת מחדש כ-Overlay חדש שצף *מעל* ה-bottom sheet עצמו -
    // בדיוק התופעה שדווחה ("אחרי 10 שניות זה מופיע לי על דף הרמזים").
    // מפעילים מחדש את הטיימר רק אחרי שהתפריט נסגר (אם החידה עוד לא נפתרה).
    _stuckHintTimer?.cancel();
    _hideStuckTipOverlay();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      // ⚠️ isScrollControlled: true + מגבלת גובה מקסימלית (85% מהמסך) +
      // SingleChildScrollView בפנים - בלי זה, כשנוספה שורת "צפה בפרסומת"
      // השלישית (+ "ביטול") לתפריט, התוכן חרג מגובה ה-sheet במסכים נמוכים
      // וגרם לגלישה (RenderFlex overflow - הפס הצהוב-שחור עם ה"!" שמוצג
      // ב-debug mode). עכשיו זה תמיד נכנס, ואם בכל זאת לא - פשוט גוללים.
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                gradient: const LinearGradient(colors: [Color(0xFF241a4f), Color(0xFF170F38)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.22)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("בחר רמז", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 18),
                _HintOptionTile(
                  icon: Icons.font_download_outlined,
                  title: "חשוף את האות הבאה",
                  subtitle: "אות אחת נוספת מתגלה מיד",
                  price: 20,
                  accent: const Color(0xFFFFB24D),
                  onTap: () {
                    AudioManager.playClick();
                    Navigator.pop(context);
                    _revealLetterHint();
                  },
                ),
                const SizedBox(height: 12),
                _HintOptionTile(
                  icon: Icons.abc_rounded,
                  title: "פתור את כל המילה",
                  subtitle: "כל האותיות מתגלות בבת אחת",
                  price: 60,
                  accent: const Color(0xFF9333EA),
                  onTap: () {
                    AudioManager.playClick();
                    Navigator.pop(context);
                    _revealWordHint();
                  },
                ),
                // 🆕 שורה שלישית - רמז-פרסומת חינמי, בדיוק כמו במוקאפ "בחר
                // רמז" - מוצגת רק אם עוד לא נוצל רמז-הפרסומת בחידה הזו.
                if (!adHintUsedThisPuzzle) ...[
                  const SizedBox(height: 12),
                  _HintOptionTile(
                    icon: Icons.ondemand_video_rounded,
                    title: "צפה בפרסומת",
                    subtitle: "קבל אות אחת בחינם",
                    accent: const Color(0xFF34D399),
                    onTap: () {
                      Navigator.pop(context);
                      _watchRewardedAdForHint();
                    },
                  ),
                ],
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("ביטול", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      // התפריט נסגר (בכל דרך - נבחרה אפשרות, או פשוט נסגר) - אם החידה
      // עדיין לא נפתרה, מפעילים מחדש את טיימר ה"תקוע?" מההתחלה.
      if (mounted) _restartStuckHintTimer();
    });
  }

  Future<void> _checkAnswer() async {
  String cleanGuess = guessSlots.map((slot) => slot ?? '').join();
  String cleanAnswer = currentLevelData.answer.replaceAll(' ', '');

  if (cleanGuess == cleanAnswer) {
    if (!mounted) return; 

    AudioManager.playSuccess('audio/win.mp3');

    // 🔴 לפני שמוסיפים מטבעות על בסיס מה שמוצג במסך - מוודאים שאין
    // עדכון/איפוס מרחוק ממתין שעדיין לא נקלט (למשל אם מישהו שינה
    // מטבעות דרך Firestore ממש עכשיו, לפני שההאזנה החיה הספיקה
    // להגיע). בלי זה, ה-+2 היה מתווסף על הערך הישן ודורס את מה
    // שנקבע מרחוק ברגע שהתוצאה נשמרת.
    await PlayerSyncService.checkForRemoteReset();
    if (!mounted) return;
    final freshPrefs = await SharedPreferences.getInstance();
    coins = freshPrefs.getInt('coins') ?? coins;

    bool newStreakRecord = false;

    setState(() {
      // 🔥 במצב רנדומלי: כל מילה שהושלמה מגדילה את הרצף.
      // הרצף יורד רק כשטועים במילה - לא ברמזים ולא ביציאה מהמשחק.
      if (widget.isRandomMode) {
        randomStreak++;
        if (randomStreak > bestRandomStreak) {
          bestRandomStreak = randomStreak;
          newStreakRecord = true;
        }
      }

      if (usedWordHint) {
        // השתמש ברמז "פתור את כל המילה" - רק 5 נקודות, בלי מטבעות
        xp += 5;
        lastEarnedXp = 5;
        lastEarnedCoins = 0;
      } else {
        // פרס בסיסי 10 XP, פחות 1 על כל רמז אות (מינימום 1)
        int gainedXp = (10 - letterHintsUsed).clamp(1, 10);

        // בונוס רצף (עד +5 XP) - רק על פתרון עצמאי
        if (widget.isRandomMode) {
          gainedXp += (randomStreak - 1).clamp(0, 5);
        }

        xp += gainedXp;
        coins += 2;
        lastEarnedXp = gainedXp;
        lastEarnedCoins = 2;
      }
    });
    _savePlayerData();
    BattlePassService.addPoints(lastEarnedXp); // 🆕 נקודות "באטל פאס" - לפי ה-XP שהתקבל בפועל
    AchievementsService.inc('logosSolved'); // 🆕 הישגים
    _clearHintState(currentPuzzleId); // החידה נפתרה - אין יותר צורך לזכור אילו רמזים שימשו בה

    if (widget.isRandomMode) {
      // במצב רנדומלי שומרים את החידה כפתורה בנפרד (לא נוגעים בהתקדמות הרגילה)
      await _markRandomSolved(currentPuzzleId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('randomStreak', randomStreak); // הרצף נשמר גם אחרי יציאה
      await prefs.setInt('bestRandomStreak', bestRandomStreak);
      if (newStreakRecord && bestRandomStreak >= 3 && mounted) {
        AppNotification.show(context, "שיא רצף חדש: $bestRandomStreak!", type: AppNotificationType.success, duration: const Duration(seconds: 2));
      }
    } else {
      _saveProgress();
    }

    // מעדכן את הטבלה הארצית ברקע - לא מעכב את המשך המשחק
    // 🛠️ תוקן באג: קודם נשלח randomStreak (הרצף הנוכחי, שמתאפס כשטועים
    // במילה) - כלומר אם שיחקן היה על רצף 14 ואז נפל, הטבלה הארצית הייתה
    // "שוכחת" את השיא הזה ומציגה 0/מספר נמוך מיד. עכשיו נשלח bestRandomStreak
    // (השיא שנשמר במכשיר) - כך שהשיא הכי גבוה אי-פעם נשאר בטבלה עד שנשבר.
    DeviceId.get().then((deviceId) {
      LeaderboardService.submitScore(username, xp, streak: bestRandomStreak, deviceId: deviceId);
    });

    // 🆕 מעדכן משימות יומיות/שבועיות בזמן אמת (לא מחכים - לא חוסם את
    // המשך המשחק).
    MissionsService.recordEvent(MissionEvent.logoSolved);

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    _showResultDialog(true);
  } else if (cleanGuess.length == cleanAnswer.length) {
    if (!mounted) return;
    // טעות במילה - הדבר היחיד שמאפס את הרצף 🔥
    if (widget.isRandomMode && randomStreak > 0) {
      setState(() => randomStreak = 0);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('randomStreak', 0);
      if (!mounted) return;
    }
    _showResultDialog(false);
  }
}

  @override
  void dispose() {
    DebugLog.add("LogoLevelScreen.dispose START");
    // מחזירים את מוזיקת הרקע לעוצמה שנבחרה כשיוצאים מהשלב
    AudioManager.restoreMusic();
    _stuckHintTimer?.cancel();
    _stuckTipOverlayEntry?.remove();
    _stuckTipOverlayEntry = null;
    PlayerSyncService.remoteCoinsUpdate.removeListener(_onRemoteCoinsUpdate);
    PlayerSyncService.remoteResetSignal.removeListener(_onRemoteReset);
    // 🆕 חשוב לנקות - אחרת מסך הזה שכבר נסגר יישאר "רשום" כמאזין הגלובלי
    // היחיד (ראו onRepeatedScreenshot ב-screenshot_guard_service.dart)
    // וצילום מסך שיילקח אחר כך במסך אחר לגמרי ינסה (בשקט, בלי לקרוס) לקרוא
    // ל-setState על מסך שכבר לא קיים.
    if (ScreenshotGuardService.onRepeatedScreenshot == _onRepeatedScreenshot) {
      ScreenshotGuardService.onRepeatedScreenshot = null;
    }
    super.dispose();
    DebugLog.add("LogoLevelScreen.dispose END");
  }

  // 🆕 צילום מסך שני (ואילך) בזמן שהשלב הזה פעיל - מעבירים בכוח לשלב
  // הבא (בדיוק כמו התקדמות רגילה - _goToNextLevel, בלי לזרוק שום פרס
  // נוסף) ומראים הודעה ברורה שזו הסיבה. אין "לחזור לשלב הקודם" כי אין
  // כאן ניווט בכלל - currentPuzzleId פשוט מתקדם באותו מסך.
  void _onRepeatedScreenshot() {
    if (!mounted) return;
    AppNotification.show(context, "זוהה צילום מסך נוסף - עוברים לשלב הבא", type: AppNotificationType.error, duration: const Duration(seconds: 4));
    _goToNextLevel();
  }

  void _goToNextLevel() {
    // במצב רנדומלי - פשוט בוחרים את החידה האקראית הבאה
    if (widget.isRandomMode) {
      _pickNextRandomPuzzle();
      return;
    }

    int totalLevelsInCurrentWorld = levelsCounts[currentMainLevel] ?? 0;

    if (totalLevelsInCurrentWorld == 0) {
      debugPrint("ERROR: Level $currentMainLevel not defined in levelsCounts!");
      return;
    }

    if (displayPuzzleNum >= totalLevelsInCurrentWorld) {
      // סיימנו את כל השלבים ברמה הראשית -> מסך "סיימת בהצלחה" מיוחד
      _showLevelCompleteDialog();
    } else if (gameLevels.containsKey(currentPuzzleId + 1)) {
      setState(() {
        currentPuzzleId++;
        _initGuessSlots();
        pressedKeysIndices.clear(); 
        letterHintsUsed = 0;
        usedWordHint = false;
      });
    }
  }

  // מסך סיום רמה: סאונד מיוחד + כפתור מעבר לרמה הבאה
  void _showLevelCompleteDialog() async {
    AudioManager.playSuccess('audio/level_complete.mp3');
    if (!mounted) return;

    int finishedLevel = currentMainLevel;
    int nextMainLevel = finishedLevel + 1;
    bool hasNextLevel = levelsCounts.containsKey(nextMainLevel);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(colors: [const Color(0xFFFFD86B).withValues(alpha: 0.85), Colors.white.withValues(alpha: 0.15)]),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(colors: [Color(0xFF241a4f), Color(0xFF170F38)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 40, offset: const Offset(0, 20))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFFFD86B).withValues(alpha: 0.42), const Color(0xFFFFD86B).withValues(alpha: 0.0)])),
                      ),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFFFFE79A), Color(0xFFFFB24D)]),
                          boxShadow: [BoxShadow(color: const Color(0xFFFFD86B).withValues(alpha: 0.45), blurRadius: 24)],
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF2A1740), size: 38),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text("כל הכבוד! 🎉", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  "סיימת בהצלחה את רמה $finishedLevel",
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 22),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(19),
                    onTap: () {
                      Navigator.pop(context); // סוגר את חלון הסיום

                      if (hasNextLevel) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => SubLevelsScreen(mainLevel: nextMainLevel)),
                        );
                      } else {
                        Navigator.pop(context); // סיימת את כל המשחק - חוזרים למסך בחירת רמות
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)]),
                      ),
                      child: Text(
                        hasNextLevel ? "לרמה $nextMainLevel ›" : "סיום",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF2A1740), fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 עוצב מחדש לפי מוקאפ "תשובה נכונה" (מסך 02 ב-All_Screens.html):
  // כרטיס זכוכית עם הילת זוהר (ירוקה=נכון / אדומה=טעות) מאחורי אייקון
  // עגול, שבבי פרס (+XP / +מטבעות / רצף), וכפתור CTA בגרדיאנט זהב.
  void _showResultDialog(bool isCorrect) {
    // 🔴 מסתירים מיד את בועית "תקוע?" / "פרסומת = רמז" (ומבטלים את
    // הטיימר שמתזמן אותה) - בלי זה היא יכולה "לקפוץ" בדיוק מעל דיאלוג
    // "כל הכבוד" אם עברו 10 שניות מאז ההקלדה האחרונה, מה שנראה כאילו
    // מציעים רמז/פרסומת על שאלה שכבר נפתרה.
    _stuckHintTimer?.cancel();
    _hideStuckTipOverlay();
    final Color glow = isCorrect ? const Color(0xFF34D399) : const Color(0xFFFB7185);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(colors: [glow.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.15)]),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(colors: [Color(0xFF241a4f), Color(0xFF170F38)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 40, offset: const Offset(0, 20))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 82,
                  height: 82,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [glow.withValues(alpha: 0.42), glow.withValues(alpha: 0.0)])),
                      ),
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: isCorrect ? const [Color(0xFF86EFAC), Color(0xFF22C79A)] : const [Color(0xFFFDA4AF), Color(0xFFE11D74)]),
                          boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.45), blurRadius: 24)],
                        ),
                        child: Icon(isCorrect ? Icons.check_rounded : Icons.close_rounded, color: const Color(0xFF10233A), size: 34),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(isCorrect ? "כל הכבוד!" : "טעות בשם", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                if (isCorrect) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _resultChip(text: "+$lastEarnedXp XP", color: const Color(0xFF93C5FD)),
                      if (lastEarnedCoins > 0) _resultChip(text: "+$lastEarnedCoins", color: const Color(0xFFFFE7A8), icon: Icons.monetization_on_rounded),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(19),
                    onTap: () {
                      AudioManager.playClick();
                      Navigator.pop(context);
                      if (isCorrect) {
                        DebugLog.add("LogoLevelScreen: calling AdsManager.onLevelSolved");
                        AdsManager.onLevelSolved(); // כל 7 שלבים - פרסומת מסך מלא
                        DebugLog.add("LogoLevelScreen: AdsManager.onLevelSolved returned, calling _goToNextLevel");
                        _goToNextLevel();
                      } else {
                        // 🔁 טעות - האותיות שהוקלדו נשארות במקום (לא מתאפסות
                        // אוטומטית). המשתמש יכול למחוק ידנית באמצעות בק-ספייס
                        // (לפי סדר ההקלדה) רק את מה שהוא רוצה לתקן.
                        setState(() {
                          _restartStuckHintTimer(); // מתחילים למנות מחדש 10 שניות מהניסיון הזה
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        gradient: isCorrect
                            ? const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)])
                            : LinearGradient(colors: [Colors.white.withValues(alpha: 0.14), Colors.white.withValues(alpha: 0.06)]),
                        border: isCorrect ? null : Border.all(color: Colors.white.withValues(alpha: 0.16)),
                      ),
                      child: Text(
                        isCorrect ? "המשך לשלב הבא ›" : "נסה שוב",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: isCorrect ? const Color(0xFF2A1740) : Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultChip({required String text, required Color color, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🆕 מטבע = אימוג'י (ראו app_icons.dart) - כל שאר האייקונים נשארים וקטוריים
          if (icon != null) ...[
            icon == Icons.monetization_on_rounded ? const CoinIcon(size: 18) : Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
          ],
          Text(text, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isEnglish) {
    List<String> words = currentLevelData.answer.split(' ');
    int totalLetters = currentLevelData.answer.replaceAll(' ', '').length;

    // 📐 גודל תא דינמי לפי רוחב המסך בפועל (לא פיקסלים קבועים) - כך
    // שמילה ארוכה על מסך צר תמיד תתכווץ ותיכנס בשורה אחת, במקום
    // "לברוח" לשתיים-שלוש שורות כמו עם רוחב קבוע.
    return LayoutBuilder(
      builder: (context, constraints) {
        const double margin = 4; // 2 מכל צד של כל תא
        const double maxTileWidth = 35;
        const double minTileWidth = 20;

        double idealWidth = totalLetters > 0
            ? (constraints.maxWidth - (totalLetters * margin)) / totalLetters
            : maxTileWidth;
        double tileWidth = idealWidth.clamp(minTileWidth, maxTileWidth);
        double tileHeight = tileWidth * (45 / 35); // אותו יחס גובה-רוחב כמו קודם
        double fontSize = (tileWidth * 0.6).clamp(13.0, 22.0);

        int globalCharIndex = 0;
        List<Widget> wordsWidgets = [];

        for (var word in words) {
          List<Widget> letters = [];
          for (int i = 0; i < word.length; i++) {
            String displayLetter = globalCharIndex < guessSlots.length ? (guessSlots[globalCharIndex] ?? "") : "";
            bool isHinted = hintedPositions.contains(globalCharIndex);
            globalCharIndex++;

            // שומרים את האינדקס הגלובלי בפנה כדי שה-closure של הלחיצה
            // ישתמש בערך הנכון (ולא תמיד ב-globalCharIndex האחרון)
            final int slotIndex = globalCharIndex - 1;
            final bool canTapRemove = displayLetter.isNotEmpty && !isHinted;

            letters.add(
              GestureDetector(
                // 👆 לחיצה על אות שהקלדת (לא רמז) מוחקת אותה מהתא - נוח
                // יותר מבק-ספייס, כי אפשר לתקן אות ספציפית באמצע המילה
                onTap: canTapRemove ? () {
                  AudioManager.playClick();
                  setState(() {
                    guessSlots[slotIndex] = null;
                    typedOrder.remove(slotIndex);
                    int? keyIndex = slotToKeyIndex.remove(slotIndex);
                    if (keyIndex != null) pressedKeysIndices.remove(keyIndex);
                  });
                } : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: tileWidth,
                  height: tileHeight,
                  decoration: BoxDecoration(
                    // תא שהתמלא ברמז מודגש בענבר קלוש - כדי שיהיה ברור שהוא נעול
                    color: isHinted ? Colors.amber.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isHinted ? Colors.amber.withValues(alpha: 0.6) : Colors.white30),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    displayLetter,
                    style: TextStyle(
                      color: isHinted ? Colors.amber : Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }
          wordsWidgets.add(Row(mainAxisSize: MainAxisSize.min, children: letters));
        }

        // ממורכז במדויק מתחת ללוגו: רוחב מלא + Center, בלי רווח עודף בסוף
        return SizedBox(
          width: double.infinity,
          child: Center(
            child: Directionality(
              textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: wordsWidgets,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DebugLog.add("LogoLevelScreen.build (hasInternet=$hasInternet)");
    // בודקים חיבור אינטרנט - בלי זה לא ניכנס לשלב בכלל
    if (hasInternet == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF120C2E),
        body: const AppBackground(
          child: Center(child: CircularProgressIndicator(color: Colors.amber)),
        ),
      );
    }
    if (hasInternet == false) {
      return _buildNoInternetScreen();
    }

    int currentMainLevelDisplay = currentMainLevel;
    int currentPuzzleNumDisplay = displayPuzzleNum;
    bool isEnglish = RegExp(r'[a-zA-Z]').hasMatch(currentLevelData.answer);

    // בזמן בחירת חידה רנדומלית - מסך טעינה קצר
    if (isPickingRandom) {
      return Scaffold(
        backgroundColor: const Color(0xFF120C2E),
        body: const AppBackground(
          child: Center(child: CircularProgressIndicator(color: Colors.amber)),
        ),
      );
    }

    DebugLog.add("LogoLevelScreen.build: constructing main widget tree");
    final mainScaffold = Scaffold(
      backgroundColor: const Color(0xFF120C2E),
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
            children: [
              // ===== כותרת: כפתורי זכוכית + כותרת ותת-כותרת + שבבי מטבעות/XP =====
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    _GlassRoundIconButton(icon: Icons.arrow_back_ios_new_rounded, color: Colors.white, onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 6),
                    _GlassRoundIconButton(icon: Icons.home_rounded, color: const Color(0xFFFFD86B), onTap: () => _onHomePressed()),
                    const SizedBox(width: 6),
                    _GlassRoundIconButton(icon: Icons.info_outline_rounded, color: Colors.white70, onTap: _showAboutDialog),
                    const SizedBox(width: 8),
                    // הכותרת מתכווצת אוטומטית אם אין מקום - בלי גלישה
                    Expanded(
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.isRandomMode
                                  ? currentCategoryName
                                  : "$currentCategoryName · שלב $currentPuzzleNumDisplay",
                              style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900),
                            ),
                          ),
                          Text(
                            widget.isRandomMode
                                ? (randomStreak > 0 ? "🔥 רצף $randomStreak" : "אתגר רנדומלי")
                                : "רמה $currentMainLevelDisplay",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _headerPill(icon: Icons.monetization_on_rounded, color: const Color(0xFFFFD86B), text: "$coins"),
                    const SizedBox(width: 6),
                    _headerPill(icon: null, color: const Color(0xFF93C5FD), text: "$xp"),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ===== כרטיס הלוגו =====
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.85), const Color(0xFFFFD86B).withValues(alpha: 0.35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 44, offset: const Offset(0, 20)),
                    BoxShadow(color: const Color(0xFFFFBE50).withValues(alpha: 0.18), blurRadius: 40),
                  ],
                ),
                child: Container(
                  height: 160,
                  width: 160,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(29)),
                  child: _buildLevelImage(),
                ),
              ),
              const SizedBox(height: 30),

              _buildInputArea(isEnglish),

              const Spacer(),

              // ===== שבבי פעולה: רמז / הסר אותיות (בלי "דלג" - לא קיים באפליקציה) =====
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ⚠️ בכוונה בלי trailingBadge ("15") - התפריט שנפתח בלחיצה
                  // מציע כמה סוגי רמזים במחירים שונים (15/60/חינם), אז מספר
                  // קבוע על הכפתור עצמו מטעה (משתמע כאילו זה המחיר היחיד).
                  _ActionChip(
                    icon: Icons.lightbulb_rounded,
                    label: "רמז",
                    color: const Color(0xFFFFD86B),
                    onTap: _showHintMenu,
                    link: _hintButtonLink,
                  ),
                  const SizedBox(width: 12),
                  _ActionChip(
                    icon: Icons.backspace_rounded,
                    label: "הסר אות",
                    color: const Color(0xFFFB7185),
                    onTap: _onBackspacePressed,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                // 📐 גודל מקש דינמי לפי רוחב המסך בפועל - מבטיח בדיוק 2
                // שורות תמיד (כמו שתוכנן), גם על מסכים צרים יותר, במקום
                // שהמקלדת "תברח" לשלוש שורות עם רוחב פיקסלים קבוע.
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const double spacing = 8;
                    const double maxKeyWidth = 45;
                    const double minKeyWidth = 30;
                    int totalKeys = currentLevelData.keyboard.length;
                    int keysPerRow = (totalKeys / 2).ceil(); // תמיד שואפים לשתי שורות בדיוק

                    double idealWidth = (constraints.maxWidth - (keysPerRow - 1) * spacing) / keysPerRow;
                    double keyWidth = idealWidth.clamp(minKeyWidth, maxKeyWidth);
                    double keyHeight = keyWidth * (50 / 45);
                    double fontSize = (keyWidth * 0.5).clamp(15.0, 22.0);

                    return Directionality(
                      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: spacing,
                        runSpacing: 10,
                        children: List.generate(totalKeys, (index) {
                          bool isPressed = pressedKeysIndices.contains(index);
                          String letter = currentLevelData.keyboard[index];
                          return GestureDetector(
                            onTap: isPressed ? null : () => _onLetterPressed(index, letter),
                            child: Container(
                              width: keyWidth,
                              height: keyHeight,
                              decoration: BoxDecoration(
                                gradient: isPressed
                                    ? null
                                    : LinearGradient(colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.05)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                color: isPressed ? Colors.white.withValues(alpha: 0.04) : null,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isPressed ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.22), width: 1),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                letter,
                                style: TextStyle(
                                  color: isPressed ? Colors.transparent : Colors.white,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
              // 🛒 כפתור צף קבוע לחנות המטבעות - נשאר צמוד לצד המסך לאורך
              // כל המשחק, בלי קשר לגלילה או למסך הנוכחי בתוך השלב. בצד ימין
              // ובעוצמה עדינה יותר כדי שלא יפריע/יבלוט מדי.
              Positioned(
                right: 4,
                top: MediaQuery.of(context).size.height * 0.32,
                child: _FloatingShopButton(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopScreen()))
                        .then((_) => _loadPlayerData());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    DebugLog.add("LogoLevelScreen.build: widget tree constructed, returning");
    return mainScaffold;
  }

  Widget _headerPill({required IconData? icon, required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        color: color.withValues(alpha: 0.13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🆕 מטבע = אימוג'י (ראו app_icons.dart) - כל שאר האייקונים נשארים וקטוריים
          if (icon != null) ...[
            icon == Icons.monetization_on_rounded ? const CoinIcon(size: 14) : Icon(icon, color: color, size: 14),
            const SizedBox(width: 3),
          ],
          Text(text, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

/// חץ-מצביע קטן (משולש) מתחת לבועית "תקוע?" - מחבר אותה ויזואלית לשבב
/// "רמז" שמתחתיה במקום שהיא תרחף כמלבן מנותק.
class _BubbleArrowPainter extends CustomPainter {
  final Color color;
  const _BubbleArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleArrowPainter oldDelegate) => oldDelegate.color != color;
}

/// שבב פעולה תחתון (רמז / הסר אות) - עיצוב זכוכיתי עקבי לשאר האפליקציה,
/// עם תג-מחיר אופציונלי. אם מועבר link - הוא מתפקד גם כ"עוגן" למיקום
/// בועית "תקוע?" (CompositedTransformTarget), בדיוק כמו כפתור הרמז הישן.
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? trailingBadge;
  final VoidCallback onTap;
  final LayerLink? link;
  const _ActionChip({required this.icon, required this.label, required this.color, required this.onTap, this.trailingBadge, this.link});

  @override
  Widget build(BuildContext context) {
    final chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.45)),
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)]),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 7),
              Text(label, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w800)),
              if (trailingBadge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: color.withValues(alpha: 0.9)),
                  child: Text(trailingBadge!, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (link == null) return chip;
    return CompositedTransformTarget(link: link!, child: chip);
  }
}

/// כפתור עגול קטן זכוכיתי לכותרת מסך המשחק.
class _GlassRoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _GlassRoundIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      shape: CircleBorder(side: BorderSide(color: color.withValues(alpha: 0.32))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }
}

/// שורת אפשרות רמז בתפריט התחתון - כרטיס מרווח עם אייקון, כותרת, הסבר
/// קצר ותג מחיר, במקום ListTile דחוס.
class _HintOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int? price; // null = אופציה חינמית (רמז-פרסומת)
  final VoidCallback onTap;
  // 🎨 צבע-נושא לכל שורה (זהה בגרדיאנט של כפתור בחירת רמז) - זהב לרמז-אות,
  // סגול לרמז-מילה, ירוק לרמז-פרסומת - בדיוק כמו במוקאפ "בחר רמז".
  final Color accent;

  const _HintOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accent,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFree = price == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent.withValues(alpha: 0.16), accent.withValues(alpha: 0.03)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent.withValues(alpha: 0.9), accent.withValues(alpha: 0.55)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isFree ? Colors.white : const Color(0xFF2A1740), size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isFree ? const Color(0xFF34D399).withValues(alpha: 0.16) : const Color(0xFFFFD86B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: isFree ? Border.all(color: const Color(0xFF6EE7B7).withValues(alpha: 0.5)) : null,
              ),
              child: isFree
                  ? const Text("חינם", style: TextStyle(color: Color(0xFFA7F3D0), fontWeight: FontWeight.w900, fontSize: 13))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("$price", style: const TextStyle(color: Color(0xFF2A1740), fontWeight: FontWeight.w900, fontSize: 15)),
                        const SizedBox(width: 3),
                        const CoinIcon(size: 15),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


/// כפתור צף קטן וקבוע בצד המסך שמוביל ישר לחנות המטבעות - נגיש תמיד
/// באמצע המשחק בלי לצאת לתפריט.
class _FloatingShopButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingShopButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFFFE79A), Color(0xFFFFB24D)]),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.3),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFFB24D).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF2A1740), size: 18),
        ),
      ),
    );
  }
}