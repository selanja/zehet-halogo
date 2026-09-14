//logo_level_screen
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sub_levels_screen.dart';
import 'leaderboard.dart';
import 'audio_manager.dart';
import 'shop_screen.dart';
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
import 'battle_pass_service.dart'; // 🆕 נקודות "באטל פאס" על פתרון שלבים
import 'screenshot_guard_service.dart'; // 🆕 ענישה על צילום מסך חוזר - ראו _onRepeatedScreenshot

class LevelData {
  final String answer;
  final String imagePath;
  final Color logoColor;
  final List<String> keyboard;

  LevelData({
    required String ans,
    required this.imagePath,
    required this.logoColor,
    required this.keyboard,
  }) : answer = ans.trim();
}
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

  final Map<int, int> levelsCounts = {
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
    12: 33, // חברות חלק ב'
    13: 22, // משחקים מוכרים
    14: 23, // NBA
    15: 37, // יחידות בצה"ל וכוחות הביטחון
    16: 23, // רכבים חלק ב
  };

  final Map<int, LevelData> gameLevels = {
    1: LevelData(ans: "לגו", imagePath: 'assets/images/level1/lego.webp', logoColor: Colors.red, keyboard: ['ו', 'ר', 'ג', 'פ', 'פ', 'כ', 'ל', 'ד', 'ר', 'נ', 'ש', 'ד', 'ח', 'צ']),
    2: LevelData(ans: "אסם", imagePath: 'assets/images/level1/osem.webp', logoColor: Colors.blue, keyboard: ['ט', 'א', 'ת', 'כ', 'נ', 'ז', 'ל', 'ת', 'ם', 'י', 'ע', 'א', 'ט', 'ס']),
    3: LevelData(ans: "איקאה", imagePath: 'assets/images/level1/ikea.webp', logoColor: Colors.yellow, keyboard: ['י', 'ה', 'ל', 'ק', 'נ', 'א', 'ש', 'י', 'ל', 'א', 'א', 'ס', 'ק', 'ג']),
    4: LevelData(ans: "GUCCI", imagePath: 'assets/images/level1/gucci.webp', logoColor: Colors.amber, keyboard: ['N', 'U', 'I', 'I', 'I', 'Y', 'I', 'N', 'C', 'G', 'C', 'A', 'C', 'A']),
    5: LevelData(ans: "גט", imagePath: 'assets/images/level1/getttaxi.webp', logoColor: Colors.amber, keyboard: ['ט', 'ט', 'ט', 'א', 'ו', 'ב', 'ז', 'ו', 'ט', 'פ', 'ל', 'ג', 'ח', 'ג']),
    6: LevelData(ans: "אגד", imagePath: 'assets/images/level1/eged.webp', logoColor: Colors.green, keyboard: ['ז', 'ש', 'ב', 'ג', 'ש', 'ד', 'ו', 'ע', 'י', 'א', 'פ', 'ש', 'ג', 'ב']),
    7: LevelData(ans: "דואר ישראל", imagePath: 'assets/images/level1/doarisrael.webp', logoColor: Colors.red, keyboard: ['ו', 'ר', 'ע', 'ד', 'צ', 'א', 'א', 'י', 'ל', 'ח', 'ב', 'ר', 'ל', 'ש']),
    8: LevelData(ans: "סלקום", imagePath: 'assets/images/level1/cellcom.webp', logoColor: Colors.purple, keyboard: ['ה', 'צ', 'ק', 'כ', 'ד', 'מ', 'ו', 'ס', 'ו', 'ש', 'ם', 'ל', 'ח', 'ר']),
    9: LevelData(ans: "אפל", imagePath: 'assets/images/level1/apple.webp', logoColor: Colors.black, keyboard: ['ת', 'ש', 'צ', 'ב', 'פ', 'פ', 'ר', 'י', 'ר', 'ע', 'כ', 'א', 'ל', 'ב']),
    10: LevelData(ans: "עלית", imagePath: 'assets/images/level1/elit.webp', logoColor: Colors.black, keyboard: ['י', 'ש', 'ק', 'נ', 'ד', 'ח', 'ע', 'ם', 'מ', 'צ', 'ת', 'ל', 'ח', 'א']),
    11: LevelData(ans: "אמזון", imagePath: 'assets/images/level1/amazon.webp', logoColor: Colors.orange, keyboard: ['ד', 'א', 'ש', 'ן', 'ש', 'פ', 'א', 'י', 'מ', 'ח', 'ו', 'נ', 'ז', 'כ']),
    12: LevelData(ans: "אדידס", imagePath: 'assets/images/level1/adidas.webp', logoColor: Colors.black, keyboard: ['ס', 'ס', 'ג', 'ת', 'ד', 'ע', 'ה', 'י', 'א', 'ס', 'ג', 'ד', 'נ', 'א']),
    13: LevelData(ans: "רולקס", imagePath: 'assets/images/level1/rolex.webp', logoColor: Colors.amber, keyboard: ['ג', 'ר', 'ס', 'פ', 'ט', 'ל', 'ב', 'ו', 'כ', 'ק', 'ד', 'נ', 'ת', 'ד']),
    14: LevelData(ans: "מי עדן", imagePath: 'assets/images/level1/meeden.webp', logoColor: Colors.green, keyboard: ['ר', 'ו', 'י', 'מ', 'ר', 'א', 'ד', 'ר', 'ע', 'ל', 'ז', 'מ', 'ן', 'צ']),
    15: LevelData(ans: "פומה", imagePath: 'assets/images/level1/puma.webp', logoColor: Colors.black, keyboard: ['פ', 'ה', 'נ', 'ג', 'ס', 'ג', 'ר', 'ו', 'ה', 'פ', 'ה', 'ב', 'מ', 'ב']),
    16: LevelData(ans: "מולר", imagePath: 'assets/images/level1/nuller.webp', logoColor: Colors.blue, keyboard: ['י', 'צ', 'ר', 'פ', 'מ', 'ט', 'כ', 'י', 'ב', 'ל', 'ש', 'ס', 'ו', 'י']),
    17: LevelData(ans: "פפסי", imagePath: 'assets/images/level1/pepsi.webp', logoColor: Colors.blue, keyboard: ['ט', 'ס', 'ח', 'ס', 'ז', 'ט', 'כ', 'ז', 'פ', 'ש', 'פ', 'י', 'נ', 'ע']),
    18: LevelData(ans: "פלאפון", imagePath: 'assets/images/level1/pelephone.webp', logoColor: Colors.blue, keyboard: ['כ', 'ט', 'ל', 'ט', 'א', 'ו', 'ל', 'ג', 'ן', 'פ', 'ס', 'פ', 'צ', 'ט']),
    19: LevelData(ans: "פייפאל", imagePath: 'assets/images/level1/paypal.webp', logoColor: Colors.blue, keyboard: ['ב', 'ס', 'פ', 'פ', 'ה', 'פ', 'ב', 'י', 'ל', 'ק', 'א', 'נ', 'ע', 'י']),
    20: LevelData(ans: "אנבידיה", imagePath: 'assets/images/level1/nvidia.webp', logoColor: Colors.green, keyboard: ['ב', 'ז', 'ד', 'ד', 'נ', 'ת', 'א', 'י', 'י', 'נ', 'ה', 'ש', 'ס', 'ר']),
    21: LevelData(ans: "נייקי", imagePath: 'assets/images/level1/nike.webp', logoColor: Colors.black, keyboard: ['נ', 'ק', 'ה', 'צ', 'י', 'ב', 'נ', 'ד', 'י', 'ג', 'י', 'א', 'ג', 'י']),
    22: LevelData(ans: "מטא", imagePath: 'assets/images/level1/meta.webp', logoColor: Colors.blue, keyboard: ['א', 'מ', 'ת', 'ט', 'ש', 'ק', 'ט', 'ב', 'מ', 'ס', 'א', 'ו', 'ו', 'ס']),
    23: LevelData(ans: "מאסטרקארד", imagePath: 'assets/images/level1/mastercard.webp', logoColor: Colors.orange, keyboard: ['א', 'ד', 'א', 'כ', 'י', 'ח', 'ר', 'ס', 'ק', 'מ', 'ר', 'ה', 'ט', 'ד']),
    24: LevelData(ans: "LG", imagePath: 'assets/images/level1/lg.webp', logoColor: Colors.pink, keyboard: ['G', 'V', 'K', 'D', 'A', 'M', 'X', 'P', 'L', 'M', 'C', 'E', 'I', 'A']),
    25: LevelData(ans: "יטבתה", imagePath: 'assets/images/level1/yotveta.webp', logoColor: Colors.orange, keyboard: ['ק', 'ע', 'ס', 'ב', 'פ', 'ס', 'ת', 'ר', 'ר', 'ה', 'ט', 'ט', 'ו', 'י']),
    26: LevelData(ans: "שיאומי", imagePath: 'assets/images/level1/xiaomi.webp', logoColor: Colors.orange, keyboard: ['ת', 'א', 'א', 'ש', 'ק', 'ד', 'ת', 'י', 'ו', 'נ', 'א', 'מ', 'ס', 'י']),
    27: LevelData(ans: "אקסבוקס", imagePath: 'assets/images/level1/xbox.webp', logoColor: Colors.green, keyboard: ['ג', 'א', 'ס', 'ס', 'ל', 'ק', 'נ', 'ס', 'ו', 'ל', 'ב', 'ק', 'פ', 'ק']),
    28: LevelData(ans: "תנובה", imagePath: 'assets/images/level1/tnuva.webp', logoColor: Colors.blue, keyboard: ['ל', 'ו', 'ט', 'נ', 'ל', 'ת', 'ב', 'ב', 'ל', 'פ', 'נ', 'ה', 'ע', 'א']),
    29: LevelData(ans: "תן ביס", imagePath: 'assets/images/level1/tenbis.webp', logoColor: Colors.orange, keyboard: ['ס', 'ן', 'י', 'י', 'ת', 'ב', 'ג', 'י', 'ק', 'ת', 'ב', 'ה', 'ר', 'א']),
    30: LevelData(ans: "שטראוס", imagePath: 'assets/images/level1/shtraues.webp', logoColor: Colors.black, keyboard: ['ש', 'ק', 'ס', 'ו', 'י', 'נ', 'ט', 'א', 'מ', 'ר', 'ל', 'ח', 'ע', 'ד']),
    31: LevelData(ans: "סמסונג", imagePath: 'assets/images/level1/samsung.webp', logoColor: Colors.blue, keyboard: ['פ', 'ח', 'ו', 'מ', 'ג', 'ס', 'ח', 'ס', 'ק', 'מ', 'צ', 'ס', 'נ', 'ר']),
    32: LevelData(ans: "רד בול", imagePath: 'assets/images/level1/redbull.webp', logoColor: Colors.red, keyboard: ['ט', 'ח', 'ר', 'ו', 'ד', 'נ', 'ת', 'ל', 'ב', 'ק', 'ו', 'ש', 'י', 'מ']),
    33: LevelData(ans: "מונסטר", imagePath: 'assets/images/level1/monster.webp', logoColor: Colors.green, keyboard: ['ו', 'ד', 'ד', 'ח', 'ר', 'ס', 'ע', 'ח', 'ז', 'ט', 'מ', 'נ', 'צ', 'ק']),
    34: LevelData(ans: "פנטה", imagePath: 'assets/images/level1/fanta.webp', logoColor: Colors.orange, keyboard: ['ט', 'ט', 'פ', 'ש', 'נ', 'ח', 'ט', 'כ', 'נ', 'ב', 'נ', 'ע', 'ע', 'ה']),
    35: LevelData(ans: "נס", imagePath: 'assets/images/level1/ness.webp', logoColor: Colors.red, keyboard: ['נ', 'ל', 'י', 'ס', 'ו', 'ד', 'ו', 'נ', 'ע', 'י', 'מ', 'א', 'ט', 'ה']),
    36: LevelData(ans: "יוון", imagePath: 'assets/images/level2/greece.webp', logoColor: const Color.fromARGB(255, 184, 181, 236), keyboard: ['ו', 'א', 'א', 'ה', 'ז', 'ן', 'ר', 'י', 'ז', 'א', 'ה', 'ו', 'ס', 'ק']),
    37: LevelData(ans: "גרמניה", imagePath: 'assets/images/level2/germany.webp', logoColor: const Color.fromARGB(255, 183, 147, 232), keyboard: ['ק', 'כ', 'ל', 'ג', 'י', 'ו', 'מ', 'א', 'ה', 'ו', 'ר', 'י', 'ד', 'נ']),
    38: LevelData(ans: "צרפת", imagePath: 'assets/images/level2/franch.webp', logoColor: const Color.fromARGB(255, 120, 215, 240), keyboard: ['פ', 'ו', 'ו', 'ז', 'צ', 'ש', 'ר', 'ל', 'ת', 'ס', 'פ', 'ד', 'ד', 'פ']),
    39: LevelData(ans: "אנגליה", imagePath: 'assets/images/level2/england.webp', logoColor: const Color.fromARGB(255, 172, 202, 191), keyboard: ['ה', 'כ', 'א', 'א', 'ג', 'א', 'ל', 'ה', 'א', 'י', 'מ', 'נ', 'ד', 'ח']),
    40: LevelData(ans: "מצרים", imagePath: 'assets/images/level2/egypt.webp', logoColor: const Color.fromARGB(255, 235, 242, 181), keyboard: ['ר', 'מ', 'מ', 'ד', 'צ', 'י', 'ע', 'ם', 'מ', 'ת', 'י', 'ט', 'ש', 'כ']),
    41: LevelData(ans: "קפריסין", imagePath: 'assets/images/level2/cyprus.webp', logoColor: const Color.fromARGB(255, 168, 131, 213), keyboard: ['י', 'י', 'ד', 'פ', 'צ', 'ר', 'מ', 'ח', 'ר', 'ן', 'ו', 'ק', 'ס', 'ס']),
    42: LevelData(ans: "קרואטיה", imagePath: 'assets/images/level2/croatia.webp', logoColor: const Color.fromARGB(255, 211, 192, 126), keyboard: ['ט', 'נ', 'י', 'א', 'י', 'ר', 'א', 'ר', 'ס', 'ו', 'ה', 'ל', 'ק', 'ב']),
    43: LevelData(ans: "קנדה", imagePath: 'assets/images/level2/canda.webp', logoColor: const Color.fromARGB(255, 214, 181, 227), keyboard: ['ע', 'ג', 'נ', 'ע', 'ד', 'א', 'מ', 'ז', 'ב', 'י', 'ה', 'ק', 'ט', 'ה']),
    44: LevelData(ans: "בולגריה", imagePath: 'assets/images/level2/bulgaria.webp', logoColor: const Color.fromARGB(255, 191, 184, 253), keyboard: ['ו', 'ז', 'ת', 'ה', 'ר', 'ז', 'י', 'י', 'ק', 'ג', 'פ', 'ר', 'ל', 'ב']),
    45: LevelData(ans: "ברזיל", imagePath: 'assets/images/level2/brazil.webp', logoColor: const Color.fromARGB(255, 130, 244, 232), keyboard: ['ע', 'י', 'צ', 'ב', 'צ', 'ג', 'נ', 'ב', 'פ', 'ג', 'ל', 'ר', 'כ', 'ז']),
    46: LevelData(ans: "בלגיה", imagePath: 'assets/images/level2/belgia.webp', logoColor: const Color.fromARGB(255, 142, 224, 154), keyboard: ['ז', 'ת', 'ח', 'ד', 'ח', 'י', 'ל', 'ש', 'ק', 'ט', 'ב', 'ג', 'ג', 'ה']),
    47: LevelData(ans: "ארגנטינה", imagePath: 'assets/images/level2/argentina.webp', logoColor: const Color.fromARGB(255, 174, 251, 130), keyboard: ['י', 'ר', 'נ', 'פ', 'צ', 'ר', 'נ', 'א', 'ה', 'ה', 'ה', 'ג', 'ט', 'ט']),
    48: LevelData(ans: "רוסיה", imagePath: 'assets/images/level2/russia.webp', logoColor: const Color.fromARGB(255, 165, 212, 220), keyboard: ['כ', 'ס', 'ד', 'ח', 'ז', 'ו', 'ה', 'ת', 'ר', 'כ', 'י', 'ע', 'י', 'ח']),
    49: LevelData(ans: "רומניה", imagePath: 'assets/images/level2/romania.webp', logoColor: const Color.fromARGB(255, 144, 236, 143), keyboard: ['י', 'ט', 'נ', 'ק', 'י', 'ר', 'נ', 'ט', 'ו', 'י', 'ל', 'ר', 'מ', 'ה']),
    50: LevelData(ans: "פורטוגל", imagePath: 'assets/images/level2/portugal.webp', logoColor: const Color.fromARGB(255, 227, 176, 145), keyboard: ['ר', 'ד', 'פ', 'ג', 'ג', 'ס', 'ל', 'ו', 'ו', 'ש', 'ט', 'ט', 'ש', 'א']),
    51: LevelData(ans: "ניו זילנד", imagePath: 'assets/images/level2/newzeland.webp', logoColor: const Color.fromARGB(255, 130, 223, 165), keyboard: ['ל', 'ו', 'ט', 'נ', 'נ', 'א', 'י', 'ד', 'ז', 'ר', 'ק', 'ז', 'כ', 'י']),
    52: LevelData(ans: "מרוקו", imagePath: 'assets/images/level2/morocco.webp', logoColor: const Color.fromARGB(255, 133, 233, 129), keyboard: ['ב', 'ר', 'ז', 'צ', 'ר', 'נ', 'ח', 'ו', 'ח', 'מ', 'א', 'ו', 'ה', 'ק']),
    53: LevelData(ans: "מקסיקו", imagePath: 'assets/images/level2/mexico.webp', logoColor: const Color.fromARGB(255, 254, 161, 130), keyboard: ['ר', 'י', 'ז', 'ו', 'מ', 'ב', 'ק', 'ט', 'ק', 'ר', 'ס', 'ו', 'נ', 'י']),
    54: LevelData(ans: "לבנון", imagePath: 'assets/images/level2/lebanon.webp', logoColor: const Color.fromARGB(255, 176, 184, 164), keyboard: ['ו', 'ס', 'נ', 'נ', 'ת', 'ר', 'ח', 'ב', 'מ', 'ז', 'ו', 'צ', 'ן', 'ל']),
    55: LevelData(ans: "יפן", imagePath: 'assets/images/level2/japan.webp', logoColor: const Color.fromARGB(255, 150, 200, 190), keyboard: ['ג', 'ו', 'ן', 'ד', 'א', 'ק', 'ג', 'ג', 'י', 'מ', 'ת', 'י', 'ש', 'פ']),
    56: LevelData(ans: "איטליה", imagePath: 'assets/images/level2/italy.webp', logoColor: const Color.fromARGB(255, 167, 146, 183), keyboard: ['י', 'כ', 'ל', 'א', 'ע', 'ל', 'מ', 'ה', 'ז', 'י', 'י', 'ו', 'ט', 'ה']),
    57: LevelData(ans: "ישראל", imagePath: 'assets/images/level2/israel.webp', logoColor: const Color.fromARGB(255, 224, 143, 189), keyboard: ['ז', 'ק', 'ת', 'ג', 'ל', 'נ', 'ג', 'ש', 'א', 'י', 'ל', 'ר', 'י', 'ל']),
    58: LevelData(ans: "הודו", imagePath: 'assets/images/level2/india.webp', logoColor: const Color.fromARGB(255, 159, 142, 206), keyboard: ['ס', 'ע', 'ו', 'ש', 'ק', 'פ', 'ד', 'ה', 'ב', 'ב', 'נ', 'ו', 'א', 'ג']),
    59: LevelData(ans: "הולנד", imagePath: 'assets/images/level2/holand.webp', logoColor: const Color.fromARGB(255, 151, 159, 184), keyboard: ['ד', 'ה', 'ד', 'ב', 'ו', 'נ', 'ת', 'ל', 'ד', 'ז', 'ג', 'ג', 'ד', 'ס']),
    60: LevelData(ans: "תימן", imagePath: 'assets/images/level2/yamen.webp', logoColor: const Color.fromARGB(255, 163, 142, 183), keyboard: ['מ', 'ס', 'ו', 'י', 'א', 'ת', 'כ', 'פ', 'פ', 'ן', 'ז', 'ה', 'ד', 'א']),
    61: LevelData(ans: "ונצואלה", imagePath: 'assets/images/level2/venetz.webp', logoColor: const Color.fromARGB(255, 219, 199, 232), keyboard: ['א', 'צ', 'י', 'ו', 'ה', 'ו', 'ר', 'ש', 'י', 'ד', 'ת', 'נ', 'ג', 'ל']),
    62: LevelData(ans: "סיישל", imagePath: 'assets/images/level2/syshell.webp', logoColor: const Color.fromARGB(255, 226, 201, 137), keyboard: ['א', 'ל', 'מ', 'י', 'ל', 'ג', 'צ', 'ב', 'ה', 'ס', 'ש', 'כ', 'י', 'ח']),
    63: LevelData(ans: "ספרד", imagePath: 'assets/images/level2/spain.webp', logoColor: const Color.fromARGB(255, 234, 167, 243), keyboard: ['ס', 'ס', 'ת', 'ח', 'פ', 'פ', 'ע', 'ר', 'ה', 'מ', 'א', 'ל', 'ת', 'ד']),
    64: LevelData(ans: "שוויץ", imagePath: 'assets/images/level2/shvitzh.webp', logoColor: const Color.fromARGB(255, 225, 237, 139), keyboard: ['כ', 'ש', 'נ', 'ו', 'ל', 'ש', 'ג', 'ו', 'ץ', 'פ', 'י', 'ב', 'ז', 'ל']),
    65: LevelData(ans: "פרו", imagePath: 'assets/images/level2/peru.webp', logoColor: const Color.fromARGB(255, 215, 150, 150), keyboard: ['פ', 'ו', 'ק', 'ב', 'ט', 'פ', 'ח', 'ה', 'ו', 'ו', 'כ', 'ט', 'ב', 'ר']),
    66: LevelData(ans: "פרגוואי", imagePath: 'assets/images/level2/paragway.webp', logoColor: const Color.fromARGB(255, 180, 200, 220), keyboard: ['מ', 'ר', 'ו', 'ת', 'ג', 'א', 'פ', 'י', 'ו', 'ר', 'ב', 'ו', 'ר', 'ו']),
    67: LevelData(ans: "פנמה", imagePath: 'assets/images/level2/panama.webp', logoColor: const Color.fromARGB(255, 190, 190, 230), keyboard: ['ה', 'נ', 'צ', 'צ', 'פ', 'ס', 'פ', 'ו', 'ס', 'ג', 'ח', 'מ', 'ו', 'ס']),
    68: LevelData(ans: "ליטא", imagePath: 'assets/images/level2/lithua.webp', logoColor: const Color.fromARGB(255, 170, 210, 170), keyboard: ['א', 'ת', 'ל', 'ק', 'צ', 'ר', 'י', 'ע', 'ה', 'ל', 'ה', 'ל', 'ט', 'ש']),
    69: LevelData(ans: "מישלוחה", imagePath: 'assets/images/level3/mishlocha.webp', logoColor: Colors.amber, keyboard: ['ל', 'ח', 'ח', 'ר', 'ה', 'ו', 'מ', 'מ', 'ז', 'ש', 'ה', 'ו', 'י', 'י']),
    70: LevelData(ans: "אינסטגרם", imagePath: 'assets/images/level3/instegram.webp', logoColor: Colors.pink, keyboard: ['ט', 'נ', 'ע', 'י', 'ס', 'ג', 'ם', 'א', 'ר', 'ד', 'ב', 'נ', 'נ', 'א']),
    71: LevelData(ans: "GOOGLE MAPS", imagePath: 'assets/images/level3/googlemaps.webp', logoColor: Colors.green, keyboard: ['L', 'R', 'M', 'G', 'B', 'A', 'E', 'G', 'S', 'O', 'N', 'R', 'P', 'O']),
    72: LevelData(ans: "GMAIL", imagePath: 'assets/images/level3/gmail.webp', logoColor: Colors.red, keyboard: ['J', 'L', 'A', 'H', 'B', 'M', 'I', 'X', 'I', 'G', 'Y', 'E', 'A', 'B']),
    73: LevelData(ans: "GEMINI", imagePath: 'assets/images/level3/gemini.webp', logoColor: Colors.blue, keyboard: ['A', 'O', 'E', 'I', 'B', 'A', 'M', 'N', 'Z', 'X', 'G', 'I', 'I', 'J']),
    74: LevelData(ans: "פייסבוק", imagePath: 'assets/images/level3/facebook.webp', logoColor: Colors.blue, keyboard: ['י', 'ב', 'צ', 'י', 'ו', 'ס', 'א', 'י', 'מ', 'פ', 'ק', 'א', 'פ', 'ב']),
    75: LevelData(ans: "דיסקורד", imagePath: 'assets/images/level3/discord.webp', logoColor: Colors.indigo, keyboard: ['ש', 'ל', 'ד', 'ט', 'י', 'ו', 'ס', 'ר', 'ק', 'ת', 'ע', 'ס', 'ד', 'ו']),
    76: LevelData(ans: "כרום", imagePath: 'assets/images/level3/chrome.webp', logoColor: Colors.green, keyboard: ['ם', 'ר', 'ס', 'כ', 'ו', 'מ', 'ת', 'פ', 'ח', 'ע', 'פ', 'ר', 'ד', 'ע']),
    77: LevelData(ans: "CHATGPT", imagePath: 'assets/images/level3/chatgpt.webp', logoColor: Colors.teal, keyboard: ['R', 'G', 'C', 'A', 'C', 'T', 'E', 'T', 'C', 'T', 'H', 'F', 'P', 'X']),
    78: LevelData(ans: "TIKTOK", imagePath: 'assets/images/level3/tiktok.webp', logoColor: Colors.black, keyboard: ['T', 'T', 'Q', 'O', 'O', 'I', 'I', 'A', 'K', 'C', 'K', 'D', 'M', 'K']),
    79: LevelData(ans: "טלגרם", imagePath: 'assets/images/level3/telegram.webp', logoColor: Colors.blue, keyboard: ['ק', 'צ', 'ט', 'י', 'ר', 'ל', 'ר', 'ד', 'ר', 'כ', 'ם', 'ע', 'ג', 'ג']),
    80: LevelData(ans: "ספוטיפיי", imagePath: 'assets/images/level3/spotify.webp', logoColor: Colors.green, keyboard: ['א', 'פ', 'ט', 'פ', 'ט', 'פ', 'ח', 'י', 'ו', 'י', 'ק', 'ס', 'נ', 'י']),
    81: LevelData(ans: "SNAPCHAT", imagePath: 'assets/images/level3/snapchat.webp', logoColor: Colors.yellow, keyboard: ['A', 'S', 'T', 'F', 'Z', 'N', 'H', 'P', 'J', 'K', 'A', 'Q', 'C', 'S']),
    82: LevelData(ans: "שאזאם", imagePath: 'assets/images/level3/shazam.webp', logoColor: Colors.blue, keyboard: ['א', 'ר', 'ג', 'ק', 'א', 'א', 'ט', 'ג', 'ז', 'ה', 'ש', 'ר', 'ו', 'ם']),
    83: LevelData(ans: "ספארי", imagePath: 'assets/images/level3/safari.webp', logoColor: Colors.blue, keyboard: ['ד', 'ר', 'ר', 'פ', 'י', 'ת', 'ר', 'ס', 'י', 'י', 'פ', 'ח', 'א', 'כ']),
    84: LevelData(ans: "פייבוקס", imagePath: 'assets/images/level3/paybox.webp', logoColor: Colors.blue, keyboard: ['ב', 'פ', 'ו', 'ת', 'ק', 'ת', 'פ', 'ת', 'פ', 'ס', 'ל', 'י', 'ס', 'י']),
    85: LevelData(ans: "נטפליקס", imagePath: 'assets/images/level3/netflix.webp', logoColor: Colors.red, keyboard: ['ח', 'ט', 'ט', 'ק', 'ר', 'ה', 'פ', 'ס', 'פ', 'ג', 'כ', 'ל', 'נ', 'י']),
    86: LevelData(ans: "מוביט", imagePath: 'assets/images/level3/moovit.webp', logoColor: Colors.orange, keyboard: ['ב', 'ס', 'י', 'מ', 'י', 'מ', 'י', 'ו', 'ה', 'ב', 'א', 'ז', 'ו', 'ט']),
    87: LevelData(ans: "זום", imagePath: 'assets/images/level3/zoom.webp', logoColor: Colors.blue, keyboard: ['ק', 'ז', 'צ', 'ד', 'ם', 'ר', 'צ', 'צ', 'ז', 'ג', 'ח', 'ס', 'ס', 'ו']),
    88: LevelData(ans: "יוטיוב", imagePath: 'assets/images/level3/youtube.webp', logoColor: Colors.red, keyboard: ['נ', 'ר', 'ט', 'ט', 'ע', 'י', 'ב', 'ל', 'ו', 'ו', 'ו', 'ג', 'י', 'י']),
    89: LevelData(ans: "WHATSAPP", imagePath: 'assets/images/level3/whatsapp.webp', logoColor: Colors.green, keyboard: ['T', 'W', 'U', 'A', 'A', 'W', 'N', 'S', 'O', 'P', 'T', 'P', 'H', 'T']),
    90: LevelData(ans: "WAZE", imagePath: 'assets/images/level3/waze.webp', logoColor: Colors.lightBlue, keyboard: ['G', 'E', 'U', 'S', 'B', 'K', 'A', 'L', 'L', 'A', 'X', 'Z', 'X', 'W']),
    91: LevelData(ans: "טוויטר", imagePath: 'assets/images/level3/twitter.webp', logoColor: Colors.lightBlue, keyboard: ['ט', 'ח', 'ו', 'ה', 'ל', 'י', 'ר', 'כ', 'ו', 'כ', 'ו', 'ר', 'ע', 'ט']),
    92: LevelData(ans: "טויוטה", imagePath: 'assets/images/level4/toyota.webp', logoColor: const Color.fromARGB(255, 77, 85, 82), keyboard: ['ו', 'ו', 'ח', 'י', 'ה', 'נ', 'י', 'ט', 'ט', 'נ', 'י', 'ב', 'ב', 'ו']),
    93: LevelData(ans: "אאודי", imagePath: 'assets/images/level4/audi.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ו', 'י', 'ת', 'א', 'ת', 'פ', 'ד', 'ת', 'ל', 'ע', 'ת', 'י', 'א', 'ק']),
    94: LevelData(ans: "פיאט", imagePath: 'assets/images/level4/fiat.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['א', 'א', 'מ', 'ו', 'פ', 'ד', 'כ', 'ט', 'י', 'ס', 'ב', 'ו', 'ל', 'ט']),
    95: LevelData(ans: "יונדאי", imagePath: 'assets/images/level4/huyndai.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ג', 'א', 'ז', 'ו', 'ד', 'ט', 'ת', 'פ', 'י', 'נ', 'מ', 'ע', 'י', 'נ']),
    96: LevelData(ans: "BMW", imagePath: 'assets/images/level4/bmw.webp', logoColor: const Color.fromARGB(255, 1, 162, 255), keyboard: ['B', 'S', 'N', 'H', 'M', 'M', 'V', 'Q', 'Z', 'W', 'B', 'L', 'P', 'Y']),
    97: LevelData(ans: "הונדה", imagePath: 'assets/images/level4/honda.webp', logoColor: const Color.fromARGB(255, 250, 79, 0), keyboard: ['ש', 'ה', 'ג', 'ה', 'ר', 'ה', 'ק', 'ד', 'ד', 'ו', 'ת', 'ק', 'נ', 'י']),
    98: LevelData(ans: "פורד", imagePath: 'assets/images/level4/ford.webp', logoColor: const Color.fromARGB(255, 4, 0, 233), keyboard: ['ד', 'כ', 'פ', 'ב', 'ס', 'ר', 'ז', 'מ', 'ח', 'ג', 'ו', 'ה', 'פ', 'ר']),
    99: LevelData(ans: "טסלה", imagePath: 'assets/images/level4/tesla.webp', logoColor: const Color.fromARGB(255, 255, 0, 0), keyboard: ['ל', 'ב', 'ז', 'ה', 'ט', 'י', 'ס', 'ו', 'ס', 'כ', 'ר', 'ל', 'ט', 'ה']),
    100: LevelData(ans: "אלפא רומיאו", imagePath: 'assets/images/level4/alfa_romeo.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ר', 'פ', 'ו', 'ק', 'מ', 'פ', 'ו', 'י', 'ל', 'ל', 'ד', 'א', 'א', 'א']),
    101: LevelData(ans: "שברולט", imagePath: 'assets/images/level4/chevrolet.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ל', 'ל', 'ר', 'י', 'ח', 'ר', 'ט', 'ר', 'ת', 'פ', 'ב', 'ל', 'ש', 'ו']),
    102: LevelData(ans: "סיטרואן", imagePath: 'assets/images/level4/citroen.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ס', 'א', 'ט', 'ש', 'ש', 'ש', 'ר', 'ן', 'ר', 'ד', 'ו', 'ע', 'י', 'ח']),
    103: LevelData(ans: "פרארי", imagePath: 'assets/images/level4/ferrari.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ס', 'ס', 'ע', 'ע', 'י', 'ג', 'כ', 'ר', 'מ', 'ר', 'ע', 'ב', 'א', 'פ']),
    104: LevelData(ans: "יגואר", imagePath: 'assets/images/level4/jaguar.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ג', 'ד', 'ו', 'צ', 'ט', 'ר', 'ח', 'ו', 'ס', 'א', 'ס', 'א', 'י', 'ו']),
    105: LevelData(ans: "לקסוס", imagePath: 'assets/images/level4/lexus.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ק', 'מ', 'ט', 'ס', 'ת', 'ל', 'מ', 'ס', 'ח', 'ט', 'ו', 'ה', 'ט', 'ל']),
    106: LevelData(ans: "מאזדה", imagePath: 'assets/images/level4/mazda.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ל', 'א', 'ג', 'ג', 'כ', 'ז', 'ו', 'ד', 'כ', 'ג', 'ה', 'צ', 'מ', 'ה']),
    107: LevelData(ans: "מרצדס", imagePath: 'assets/images/level4/mercedes.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['מ', 'פ', 'ז', 'מ', 'מ', 'ע', 'ד', 'פ', 'צ', 'ו', 'מ', 'ס', 'כ', 'ר']),
    108: LevelData(ans: "מוסטנג", imagePath: 'assets/images/level4/mustang.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ב', 'ט', 'ט', 'ט', 'ט', 'ו', 'ג', 'ו', 'נ', 'י', 'מ', 'ת', 'ס', 'נ']),
    109: LevelData(ans: "ניסאן", imagePath: 'assets/images/level4/nissan.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ז', 'א', 'ז', 'ס', 'כ', 'כ', 'צ', 'כ', 'ס', 'נ', 'ן', 'ז', 'י', 'י']),
    110: LevelData(ans: "PEUGEOT", imagePath: 'assets/images/level4/peugeot.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['S', 'G', 'O', 'P', 'G', 'T', 'M', 'O', 'U', 'D', 'E', 'E', 'Q', 'A']),
    111: LevelData(ans: "סיאט", imagePath: 'assets/images/level4/seat.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ס', 'נ', 'צ', 'א', 'ל', 'ח', 'י', 'ש', 'ר', 'מ', 'ט', 'ט', 'מ', 'י']),
    112: LevelData(ans: "סקודה", imagePath: 'assets/images/level4/skoda.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['פ', 'ד', 'ק', 'ר', 'ד', 'ס', 'ר', 'ו', 'ב', 'ע', 'ה', 'פ', 'צ', 'ה']),
    113: LevelData(ans: "מיני קופר", imagePath: 'assets/images/level4/mini_cooper.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ו', 'ר', 'י', 'ש', 'מ', 'פ', 'נ', 'ט', 'צ', 'י', 'כ', 'ק', 'ק', 'ה']),
    114: LevelData(ans: "וולוו", imagePath: 'assets/images/level4/volvo.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ר', 'י', 'י', 'ו', 'ח', 'ל', 'י', 'ו', 'ע', 'ו', 'כ', 'ו', 'ב', 'ו']),
    115: LevelData(ans: "מיצובישי", imagePath: 'assets/images/level4/mitsubishi.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['ט', 'ש', 'ב', 'צ', 'ב', 'ז', 'ר', 'י', 'י', 'י', 'ו', 'ש', 'ד', 'מ']),
    116: LevelData(ans: "סובארו", imagePath: 'assets/images/level4/subaru.webp', logoColor: const Color.fromARGB(255, 255, 145, 1), keyboard: ['א', 'ס', 'א', 'ד', 'ר', 'ה', 'ה', 'ס', 'מ', 'ב', 'י', 'ו', 'ו', 'ע']),
    117: LevelData(ans: "סוזוקי", imagePath: 'assets/images/level4/suzuki.webp', logoColor: Colors.red, keyboard: ['ח', 'ו', 'ו', 'ח', 'ס', 'ס', 'ז', 'מ', 'מ', 'ק', 'ב', 'י', 'צ', 'ק']),
    118: LevelData(ans: "רנו", imagePath: 'assets/images/level4/renault.webp', logoColor: Colors.grey, keyboard: ['ה', 'ק', 'ר', 'ו', 'ו', 'ע', 'ט', 'כ', 'מ', 'ג', 'נ', 'צ', 'נ', 'ב']),
    119: LevelData(ans: "פורשה", imagePath: 'assets/images/level4/porche.webp', logoColor: Colors.black, keyboard: ['פ', 'ה', 'ד', 'ו', 'צ', 'כ', 'צ', 'ש', 'ז', 'מ', 'ר', 'ט', 'ס', 'י']),
    120: LevelData(ans: "אופל", imagePath: 'assets/images/level4/opel.webp', logoColor: Colors.grey, keyboard: ['ג', 'מ', 'ע', 'ו', 'ע', 'ט', 'א', 'א', 'נ', 'פ', 'כ', 'צ', 'ל', 'מ']),
    121: LevelData(ans: "מזראטי", imagePath: 'assets/images/level4/maserati.webp', logoColor: Colors.blue, keyboard: ['ע', 'ט', 'נ', 'ו', 'ס', 'מ', 'ש', 'ז', 'א', 'י', 'ר', 'י', 'ס', 'ש']),
    122: LevelData(ans: "למבורגיני", imagePath: 'assets/images/level4/lamb.webp', logoColor: Colors.amber, keyboard: ['ג', 'ו', 'י', 'ב', 'נ', 'ר', 'י', 'ר', 'ל', 'פ', 'י', 'ד', 'י', 'מ']),
    123: LevelData(ans: "קדילק", imagePath: 'assets/images/level4/cadillac.webp', logoColor: Colors.black, keyboard: ['ג', 'ד', 'א', 'י', 'י', 'ע', 'ק', 'ק', 'ט', 'ד', 'ל', 'נ', 'ב', 'ח']),
    124: LevelData(ans: "בנטלי", imagePath: 'assets/images/level4/bentley.webp', logoColor: Colors.black, keyboard: ['ג', 'צ', 'ה', 'ל', 'ב', 'ק', 'ז', 'נ', 'י', 'ט', 'ר', 'ס', 'י', 'צ']),
    125: LevelData(ans: "רמי לוי", imagePath: 'assets/images/level5/rami.webp', logoColor: Colors.red, keyboard: ['ו', 'ר', 'ל', 'ש', 'מ', 'ת', 'ע', 'ו', 'ג', 'י', 'ר', 'ל', 'א', 'י']),
    126: LevelData(ans: "אושר עד", imagePath: 'assets/images/level5/osher.webp', logoColor: Colors.blue, keyboard: ['ד', 'ו', 'ד', 'י', 'י', 'צ', 'ע', 'א', 'ר', 'א', 'ש', 'ש', 'ד', 'י']),
    127: LevelData(ans: "נטו חיסכון", imagePath: 'assets/images/level5/neto.webp', logoColor: Colors.indigo, keyboard: ['ו', 'ק', 'ע', 'ו', 'ו', 'נ', 'ן', 'י', 'ט', 'כ', 'ח', 'ס', 'ו', 'צ']),
    128: LevelData(ans: "מגה בעיר", imagePath: 'assets/images/level5/mega.webp', logoColor: Colors.green, keyboard: ['ע', 'ר', 'ס', 'ג', 'י', 'מ', 'ה', 'ח', 'י', 'א', 'ז', 'ב', 'ר', 'ו']),
    129: LevelData(ans: "קשת טעמים", imagePath: 'assets/images/level5/keshet.webp', logoColor: Colors.orange, keyboard: ['ח', 'ק', 'ת', 'ע', 'ם', 'ח', 'ג', 'י', 'ז', 'נ', 'מ', 'ט', 'ש', 'ע']),
    130: LevelData(ans: "חצי חינם", imagePath: 'assets/images/level5/hatzhi.webp', logoColor: Colors.blue, keyboard: ['י', 'י', 'ס', 'ח', 'ע', 'צ', 'ם', 'ח', 'ת', 'ג', 'נ', 'ב', 'א', 'צ']),
    131: LevelData(ans: "סופר דוש", imagePath: 'assets/images/level5/dosh.webp', logoColor: Colors.red, keyboard: ['ק', 'ס', 'פ', 'ד', 'י', 'ס', 'ר', 'ו', 'ז', 'ו', 'ו', 'ת', 'ט', 'ש']),
    132: LevelData(ans: "קרפור", imagePath: 'assets/images/level5/carrefour.webp', logoColor: Colors.blue, keyboard: ['ל', 'ט', 'ר', 'ד', 'י', 'ר', 'ט', 'ת', 'ע', 'א', 'פ', 'ז', 'ו', 'ק']),
    133: LevelData(ans: "ביתן מרקט", imagePath: 'assets/images/level5/bitanmarket.webp', logoColor: Colors.lightBlue, keyboard: ['ר', 'ב', 'ק', 'י', 'ר', 'א', 'מ', 'ל', 'ט', 'ב', 'ת', 'ל', 'ן', 'ל']),
    134: LevelData(ans: "יינות ביתן", imagePath: 'assets/images/level5/bitan.webp', logoColor: Colors.red, keyboard: ['ב', 'ז', 'ן', 'י', 'ו', 'י', 'ש', 'י', 'פ', 'נ', 'ת', 'ר', 'ת', 'ד']),
    135: LevelData(ans: "סופר ברקת", imagePath: 'assets/images/level5/bareket.webp', logoColor: Colors.yellow, keyboard: ['ז', 'ר', 'ו', 'ו', 'ק', 'ב', 'ת', 'פ', 'ט', 'ב', 'ק', 'ס', 'ר', 'צ']),
    136: LevelData(ans: "AMPM", imagePath: 'assets/images/level5/ampm.webp', logoColor: Colors.cyan, keyboard: ['S', 'U', 'L', 'P', 'A', 'W', 'M', 'O', 'C', 'G', 'G', 'L', 'M', 'J']),
    137: LevelData(ans: "העגלה הזולה", imagePath: 'assets/images/level5/zola.webp', logoColor: Colors.yellow, keyboard: ['ה', 'ג', 'ז', 'ל', 'ע', 'ל', 'כ', 'ה', 'ו', 'ה', 'כ', 'ה', 'ג', 'ה']),
    138: LevelData(ans: "סטופ מרקט", imagePath: 'assets/images/level5/stop.webp', logoColor: Colors.red, keyboard: ['ט', 'ט', 'ע', 'ו', 'מ', 'ק', 'פ', 'ס', 'ס', 'ר', 'ט', 'ש', 'ס', 'ש']),
    139: LevelData(ans: "מחסני השוק", imagePath: 'assets/images/level5/shuk.webp', logoColor: Colors.green, keyboard: ['ש', 'ח', 'ת', 'ק', 'מ', 'נ', 'ק', 'י', 'ו', 'ח', 'ה', 'ס', 'ע', 'ה']),
    140: LevelData(ans: "שופרסל", imagePath: 'assets/images/level5/shufersasll.webp', logoColor: Colors.green, keyboard: ['ס', 'ק', 'ל', 'א', 'פ', 'ז', 'ו', 'ט', 'ו', 'ק', 'ר', 'א', 'ח', 'ש']),
    141: LevelData(ans: "SEVEN ELEVEN", imagePath: 'assets/images/level5/seveneleven.webp', logoColor: Colors.green, keyboard: ['V', 'N', 'I', 'N', 'V', 'N', 'L', 'S', 'X', 'E', 'E', 'E', 'E', 'E']),
    142: LevelData(ans: "סופר פארם", imagePath: 'assets/images/level5/farm.webp', logoColor: Colors.pink, keyboard: ['ר', 'ר', 'ג', 'ו', 'א', 'א', 'ם', 'נ', 'ר', 'ס', 'ח', 'פ', 'פ', 'ק']),
    143: LevelData(ans: "YELLOW", imagePath: 'assets/images/level5/yellow.webp', logoColor: Colors.yellow, keyboard: ['O', 'O', 'E', 'E', 'X', 'L', 'I', 'Z', 'Y', 'W', 'E', 'M', 'X', 'L']),
    144: LevelData(ans: "KFC", imagePath: 'assets/images/level6/kfc.webp', logoColor: Colors.red, keyboard: ['F', 'Z', 'A', 'A', 'L', 'P', 'C', 'J', 'S', 'U', 'H', 'K', 'C', 'Y']),
    145: LevelData(ans: "גפניקה", imagePath: 'assets/images/level6/japnika.webp', logoColor: Colors.black, keyboard: ['נ', 'ז', 'י', 'ה', 'ל', 'א', 'ז', 'כ', 'ג', 'י', 'ס', 'ק', 'ט', 'פ']),
    146: LevelData(ans: "גולדה", imagePath: 'assets/images/level6/golda.webp', logoColor: Colors.teal, keyboard: ['נ', 'ל', 'ב', 'ו', 'א', 'ג', 'י', 'פ', 'ש', 'ד', 'ש', 'ח', 'ה', 'פ']),
    147: LevelData(ans: "פלאפל בריבוע", imagePath: 'assets/images/level6/flafel.webp', logoColor: Colors.orange, keyboard: ['פ', 'ב', 'ק', 'ל', 'ל', 'ע', 'י', 'ו', 'פ', 'ב', 'א', 'ו', 'ר', 'ל']),
    148: LevelData(ans: "דומינוס", imagePath: 'assets/images/level6/dominos.webp', logoColor: Colors.blue, keyboard: ['א', 'ס', 'ב', 'ו', 'ו', 'ח', 'ד', 'י', 'ס', 'מ', 'פ', 'ח', 'נ', 'ט']),
    149: LevelData(ans: "צוקה", imagePath: 'assets/images/level6/chooka.webp', logoColor: Colors.orange, keyboard: ['ק', 'ק', 'צ', 'ק', 'ס', 'כ', 'ע', 'ו', 'ט', 'ט', 'ח', 'י', 'ו', 'ה']),
    150: LevelData(ans: "ברגר קינג", imagePath: 'assets/images/level6/burgerking.webp', logoColor: Colors.orange, keyboard: ['נ', 'ב', 'י', 'ר', 'ר', 'ז', 'צ', 'ק', 'ע', 'מ', 'ג', 'ט', 'י', 'ג']),
    151: LevelData(ans: "בורגראנץ", imagePath: 'assets/images/level6/burgeranz.webp', logoColor: Colors.red, keyboard: ['ג', 'ץ', 'ב', 'פ', 'ר', 'ב', 'ב', 'א', 'א', 'ו', 'נ', 'מ', 'ר', 'ר']),
    152: LevelData(ans: "בלאק", imagePath: 'assets/images/level6/black.webp', logoColor: Colors.red, keyboard: ['א', 'י', 'ז', 'ס', 'ג', 'ט', 'ת', 'ק', 'כ', 'ב', 'ז', 'ט', 'ל', 'ו']),
    153: LevelData(ans: "בי פרש", imagePath: 'assets/images/level6/bfresh.webp', logoColor: Colors.lightBlue, keyboard: ['ת', 'ד', 'ב', 'ר', 'ס', 'י', 'ע', 'ש', 'ש', 'ס', 'מ', 'ב', 'פ', 'נ']),
    154: LevelData(ans: "BBB", imagePath: 'assets/images/level6/bbb.webp', logoColor: Colors.black, keyboard: ['G', 'I', 'R', 'G', 'B', 'K', 'I', 'V', 'B', 'P', 'B', 'K', 'N', 'O']),
    155: LevelData(ans: "ארומה", imagePath: 'assets/images/level6/aroma.webp', logoColor: Colors.red, keyboard: ['ו', 'ה', 'ו', 'ש', 'מ', 'ח', 'ג', 'ר', 'ה', 'ט', 'ב', 'א', 'ו', 'ת']),
    156: LevelData(ans: "רד מיט", imagePath: 'assets/images/level6/redmet.webp', logoColor: Colors.red, keyboard: ['ג', 'ד', 'י', 'ר', 'מ', 'ת', 'ט', 'ו', 'מ', 'ז', 'ר', 'ת', 'ט', 'ס']),
    157: LevelData(ans: "פיצה שמש", imagePath: 'assets/images/level6/pizzashemesh.webp', logoColor: Colors.yellow, keyboard: ['ה', 'י', 'ר', 'מ', 'ה', 'כ', 'ש', 'צ', 'ש', 'ז', 'א', 'נ', 'ג', 'פ']),
    158: LevelData(ans: "פיצה פרגו", imagePath: 'assets/images/level6/pizzapargo.webp', logoColor: Colors.red, keyboard: ['ק', 'ה', 'ג', 'י', 'ב', 'פ', 'ע', 'ו', 'צ', 'ר', 'ו', 'צ', 'צ', 'פ']),
    159: LevelData(ans: "פיצה האט", imagePath: 'assets/images/level6/pizzahat.webp', logoColor: Colors.red, keyboard: ['פ', 'ד', 'ר', 'א', 'צ', 'צ', 'ק', 'י', 'ה', 'ט', 'ו', 'ה', 'ד', 'ה']),
    160: LevelData(ans: "עובד בכפר", imagePath: 'assets/images/level6/ovadbcfar.webp', logoColor: Colors.yellow, keyboard: ['ר', 'ל', 'כ', 'ד', 'ו', 'צ', 'ב', 'ה', 'ג', 'ט', 'ע', 'א', 'ב', 'פ']),
    161: LevelData(ans: "ניו דלי", imagePath: 'assets/images/level6/newdeli.webp', logoColor: Colors.yellow, keyboard: ['מ', 'ד', 'ק', 'י', 'ר', 'כ', 'נ', 'ל', 'ו', 'צ', 'ו', 'ג', 'י', 'ד']),
    162: LevelData(ans: "מוזס", imagePath: 'assets/images/level6/moses.webp', logoColor: Colors.black, keyboard: ['ז', 'מ', 'ח', 'ו', 'ס', 'ת', 'פ', 'ה', 'ש', 'ע', 'ע', 'מ', 'נ', 'ש']),
    163: LevelData(ans: "המקסיקני", imagePath: 'assets/images/level6/mexicani.webp', logoColor: Colors.yellow, keyboard: ['ק', 'ק', 'ע', 'ה', 'ק', 'ל', 'ח', 'ס', 'ל', 'י', 'מ', 'י', 'ר', 'נ']),
    164: LevelData(ans: "מקדונלדס", imagePath: 'assets/images/level6/mcdonalds.webp', logoColor: Colors.red, keyboard: ['נ', 'ד', 'פ', 'מ', 'ל', 'ו', 'ס', 'ל', 'ס', 'ג', 'ד', 'נ', 'נ', 'ק']),
    165: LevelData(ans: "מקס ברנר", imagePath: 'assets/images/level6/maxbrener.webp', logoColor: Colors.brown, keyboard: ['ר', 'ר', 'ק', 'ב', 'ב', 'ש', 'ד', 'ר', 'מ', 'צ', 'ז', 'ס', 'נ', 'מ']),
    166: LevelData(ans: "מאפה נאמן", imagePath: 'assets/images/level6/mafenaaman.webp', logoColor: Colors.red, keyboard: ['א', 'ן', 'פ', 'נ', 'ג', 'ל', 'א', 'צ', 'ע', 'מ', 'מ', 'כ', 'ה', 'ט']),
    167: LevelData(ans: "קפה לנדוור", imagePath: 'assets/images/level6/landver.webp', logoColor: Colors.brown, keyboard: ['נ', 'ר', 'ע', 'ג', 'ל', 'ו', 'ב', 'נ', 'ה', 'ס', 'פ', 'ד', 'ק', 'ו']),
    168: LevelData(ans: "ויוינו", imagePath: 'assets/images/level6/vivinio.webp', logoColor: Colors.teal, keyboard: ['ו', 'ד', 'פ', 'ק', 'ר', 'ו', 'ט', 'ו', 'ק', 'ש', 'נ', 'מ', 'י', 'י']),
    169: LevelData(ans: "סטארבקס", imagePath: 'assets/images/level6/star.webp', logoColor: Colors.green, keyboard: ['ר', 'נ', 'ס', 'כ', 'ט', 'ג', 'ב', 'ט', 'ק', 'י', 'ס', 'א', 'ק', 'ר']),
    170: LevelData(ans: "שייק שאק", imagePath: 'assets/images/level6/shake.webp', logoColor: Colors.green, keyboard: ['ש', 'נ', 'י', 'א', 'י', 'ל', 'ר', 'ק', 'ק', 'ק', 'ו', 'ש', 'פ', 'ה']),
    171: LevelData(ans: "רולדין", imagePath: 'assets/images/level6/roladin.webp', logoColor: Colors.brown, keyboard: ['כ', 'ר', 'ן', 'ד', 'כ', 'ל', 'ת', 'ו', 'י', 'ב', 'ק', 'ג', 'ג', 'י']),
    172: LevelData(ans: "ביסלי גריל", imagePath: 'assets/images/level7/gril.webp', logoColor: Colors.orange, keyboard: ['ר', 'ל', 'ה', 'י', 'י', 'י', 'ט', 'ב', 'ל', 'ג', 'ה', 'ס', 'ש', 'ב']),
    173: LevelData(ans: "דוריטוס גריל", imagePath: 'assets/images/level7/gril (1).webp', logoColor: Colors.purple, keyboard: ['י', 'ו', 'ח', 'ח', 'נ', 'ד', 'ר', 'ל', 'ו', 'ג', 'י', 'ס', 'ר', 'ט']),
    174: LevelData(ans: "אגוזי", imagePath: 'assets/images/level7/egozi.webp', logoColor: Colors.orange, keyboard: ['כ', 'א', 'כ', 'ט', 'ז', 'ג', 'י', 'ק', 'ג', 'כ', 'כ', 'כ', 'ו', 'א']),
    175: LevelData(ans: "כיפלי גריל", imagePath: 'assets/images/level7/dsa.webp', logoColor: Colors.purple, keyboard: ['י', 'י', 'י', 'ק', 'י', 'י', 'ש', 'פ', 'ג', 'ל', 'ל', 'ז', 'ר', 'כ']),
    176: LevelData(ans: "דוריטוס", imagePath: 'assets/images/level7/doritos.webp', logoColor: Colors.orange, keyboard: ['פ', 'ס', 'ט', 'ר', 'ד', 'ה', 'ו', 'ח', 'ל', 'ז', 'ל', 'ו', 'י', 'פ']),
    177: LevelData(ans: "דובונים", imagePath: 'assets/images/level7/dobonim.webp', logoColor: Colors.blue, keyboard: ['א', 'י', 'ט', 'ו', 'ו', 'מ', 'נ', 'ם', 'ד', 'ה', 'ר', 'ב', 'ת', 'ב']),
    178: LevelData(ans: "ציטוס בוטנים", imagePath: 'assets/images/level7/botnim.webp', logoColor: Colors.orange, keyboard: ['י', 'ב', 'ט', 'כ', 'ס', 'ס', 'י', 'ו', 'ם', 'ו', 'צ', 'ט', 'ס', 'נ']),
    179: LevelData(ans: "ביסלי במבה", imagePath: 'assets/images/level7/bislibamba.webp', logoColor: Colors.blueGrey, keyboard: ['ס', 'צ', 'נ', 'י', 'ה', 'י', 'מ', 'ל', 'א', 'ב', 'ל', 'ב', 'ב', 'ד']),
    180: LevelData(ans: "ביסלי בצל", imagePath: 'assets/images/level7/bazal.webp', logoColor: Colors.yellow, keyboard: ['ל', 'ב', 'ש', 'ס', 'ט', 'ק', 'י', 'י', 'ד', 'צ', 'י', 'ש', 'ל', 'ב']),
    181: LevelData(ans: "ביסלי ברביקיו", imagePath: 'assets/images/level7/barbikio.webp', logoColor: Colors.red, keyboard: ['ל', 'ב', 'ס', 'ק', 'ר', 'י', 'י', 'י', 'י', 'ד', 'כ', 'ב', 'ב', 'ו']),
    182: LevelData(ans: "במבה", imagePath: 'assets/images/level7/bamba.webp', logoColor: Colors.yellow, keyboard: ['ל', 'ב', 'ת', 'ה', 'ק', 'ד', 'י', 'ו', 'מ', 'נ', 'ח', 'ב', 'ט', 'מ']),
    183: LevelData(ans: "אפרופו", imagePath: 'assets/images/level7/apropo.webp', logoColor: Colors.orange, keyboard: ['ל', 'ו', 'ד', 'ס', 'ח', 'ו', 'א', 'ז', 'פ', 'ז', 'י', 'פ', 'צ', 'ר']),
    184: LevelData(ans: "פופס", imagePath: 'assets/images/level7/pops.webp', logoColor: Colors.yellow, keyboard: ['ר', 'ת', 'ס', 'מ', 'ס', 'ח', 'ר', 'ג', 'כ', 'ג', 'ו', 'א', 'פ', 'פ']),
    185: LevelData(ans: "ביסלי פיצה", imagePath: 'assets/images/level7/pizza.webp', logoColor: Colors.green, keyboard: ['ל', 'ע', 'ה', 'י', 'י', 'י', 'ט', 'צ', 'ס', 'ב', 'צ', 'ס', 'פ', 'ד']),
    186: LevelData(ans: "פסק זמן", imagePath: 'assets/images/level7/pesek.webp', logoColor: Colors.brown, keyboard: ['ע', 'ס', 'ז', 'ן', 'פ', 'ר', 'ז', 'צ', 'כ', 'מ', 'ק', 'ד', 'נ', 'ש']),
    187: LevelData(ans: "אוריאו", imagePath: 'assets/images/level7/oreo.webp', logoColor: Colors.blue, keyboard: ['ע', 'ו', 'ע', 'א', 'א', 'ר', 'ה', 'י', 'פ', 'י', 'כ', 'י', 'ו', 'ז']),
    188: LevelData(ans: "במבה נוגט", imagePath: 'assets/images/level7/nogat.webp', logoColor: Colors.brown, keyboard: ['ס', 'מ', 'צ', 'ג', 'ה', 'מ', 'נ', 'ט', 'ב', 'ב', 'ב', 'ו', 'ז', 'ה']),
    189: LevelData(ans: "מקופלת", imagePath: 'assets/images/level7/mekupelet.webp', logoColor: Colors.red, keyboard: ['ו', 'ש', 'ש', 'פ', 'ש', 'ל', 'ח', 'נ', 'ט', 'מ', 'ר', 'ק', 'פ', 'ת']),
    190: LevelData(ans: "ממולדה", imagePath: 'assets/images/level7/mamolada.webp', logoColor: Colors.red, keyboard: ['מ', 'ד', 'מ', 'ל', 'ח', 'ה', 'ת', 'ש', 'מ', 'ת', 'י', 'ו', 'נ', 'ד']),
    191: LevelData(ans: "קראנץ", imagePath: 'assets/images/level7/kranch.webp', logoColor: Colors.purple, keyboard: ['ר', 'ר', 'ד', 'ל', 'נ', 'צ', 'א', 'א', 'ז', 'ד', 'מ', 'ץ', 'צ', 'ק']),
    192: LevelData(ans: "כיפלי", imagePath: 'assets/images/level7/kifli.webp', logoColor: Colors.green, keyboard: ['כ', 'פ', 'ת', 'י', 'ז', 'ר', 'י', 'ד', 'נ', 'ל', 'כ', 'פ', 'ג', 'פ']),
    193: LevelData(ans: "כיף כף", imagePath: 'assets/images/level7/kifkef.webp', logoColor: Colors.red, keyboard: ['ף', 'ז', 'מ', 'כ', 'ש', 'י', 'א', 'ר', 'ס', 'ל', 'כ', 'ג', 'ז', 'ף']),
    194: LevelData(ans: "ציטוס כאפה", imagePath: 'assets/images/level7/kafa.webp', logoColor: Colors.brown, keyboard: ['ס', 'ס', 'ז', 'ר', 'י', 'א', 'צ', 'ו', 'כ', 'י', 'ה', 'כ', 'פ', 'ט']),
    195: LevelData(ans: "חמוץ חריף", imagePath: 'assets/images/level7/hamutch.webp', logoColor: Colors.green, keyboard: ['ח', 'כ', 'ץ', 'ר', 'ו', 'ט', 'ח', 'י', 'מ', 'מ', 'צ', 'ח', 'ו', 'ף']),
    196: LevelData(ans: "טורטית", imagePath: 'assets/images/level7/tortit.webp', logoColor: Colors.green, keyboard: ['ר', 'נ', 'ד', 'ט', 'ט', 'ט', 'ש', 'ת', 'ת', 'ח', 'ל', 'ו', 'י', 'ל']),
    197: LevelData(ans: "טעמי", imagePath: 'assets/images/level7/teami.webp', logoColor: Colors.red, keyboard: ['מ', 'ח', 'ב', 'ב', 'ג', 'י', 'י', 'ע', 'ד', 'ג', 'צ', 'ל', 'ו', 'ט']),
    198: LevelData(ans: "תפוציפס", imagePath: 'assets/images/level7/tapotchips.webp', logoColor: Colors.red, keyboard: ['צ', 'ע', 'צ', 'ס', 'ת', 'ב', 'פ', 'פ', 'צ', 'ר', 'ע', 'י', 'ו', 'ש']),
    199: LevelData(ans: "שמנת בצל", imagePath: 'assets/images/level7/shamenet.webp', logoColor: Colors.orange, keyboard: ['פ', 'ל', 'ל', 'ש', 'ב', 'ש', 'ה', 'ת', 'ר', 'י', 'ע', 'מ', 'צ', 'נ']),
    200: LevelData(ans: "קיטקט", imagePath: 'assets/images/level7/kitkat.webp', logoColor: Colors.red, keyboard: ['ט', 'ט', 'צ', 'ח', 'ק', 'מ', 'כ', 'ט', 'ח', 'י', 'ו', 'י', 'ה', 'ק']),
    201: LevelData(ans: "פרינגלס", imagePath: 'assets/images/level7/pringels.webp', logoColor: Colors.red, keyboard: ['ר', 'ר', 'מ', 'צ', 'צ', 'ת', 'ג', 'פ', 'ל', 'ע', 'ס', 'נ', 'פ', 'י']),
    202: LevelData(ans: "מילקה", imagePath: 'assets/images/level7/milka.webp', logoColor: Colors.purple, keyboard: ['ל', 'ב', 'ה', 'מ', 'נ', 'ה', 'ת', 'י', 'נ', 'ג', 'ח', 'ת', 'נ', 'ק']),
    203: LevelData(ans: "צלסי", imagePath: 'assets/images/level8/chale.webp', logoColor: Colors.blue, keyboard: ['י', 'ל', 'ה', 'ז', 'י', 'ת', 'צ', 'כ', 'כ', 'צ', 'ס', 'נ', 'י', 'י']),
    204: LevelData(ans: "דורטמונד", imagePath: 'assets/images/level8/bvb.webp', logoColor: Colors.yellow, keyboard: ['ו', 'ו', 'ו', 'ס', 'ט', 'ב', 'ו', 'ז', 'ד', 'מ', 'נ', 'ת', 'ד', 'ר']),
    205: LevelData(ans: "ביתר ירושלים", imagePath: 'assets/images/level8/beitar.webp', logoColor: Colors.yellow, keyboard: ['ר', 'ט', 'י', 'י', 'י', 'ו', 'ם', 'ש', 'ע', 'ת', 'ב', 'ע', 'ל', 'ר']),
    206: LevelData(ans: "באיירן מינכן", imagePath: 'assets/images/level8/bayren.webp', logoColor: Colors.red, keyboard: ['נ', 'א', 'ש', 'ר', 'מ', 'ב', 'כ', 'י', 'ן', 'י', 'ז', 'י', 'ח', 'ן']),
    207: LevelData(ans: "ברצלונה", imagePath: 'assets/images/level8/barchelona.webp', logoColor: Colors.red, keyboard: ['ט', 'י', 'צ', 'ת', 'ה', 'ח', 'ל', 'נ', 'ב', 'א', 'נ', 'ר', 'ו', 'ו']),
    208: LevelData(ans: "אסטון וילה", imagePath: 'assets/images/level8/avf.webp', logoColor: Colors.lightBlue, keyboard: ['ן', 'א', 'ל', 'ו', 'ו', 'ל', 'ג', 'ס', 'ע', 'ה', 'ר', 'י', 'ט', 'ד']),
    209: LevelData(ans: "אתלטיקו מדריד", imagePath: 'assets/images/level8/atletico.webp', logoColor: Colors.red, keyboard: ['מ', 'ר', 'ת', 'ט', 'א', 'ל', 'ד', 'נ', 'ק', 'ט', 'ד', 'ו', 'י', 'י']),
    210: LevelData(ans: "ארסנל", imagePath: 'assets/images/level8/arsenal.webp', logoColor: Colors.red, keyboard: ['ל', 'ע', 'ר', 'נ', 'נ', 'ק', 'כ', 'ע', 'ר', 'ד', 'א', 'ס', 'ע', 'מ']),
    211: LevelData(ans: "מילאן", imagePath: 'assets/images/level8/acm.webp', logoColor: Colors.red, keyboard: ['א', 'ק', 'מ', 'ר', 'ל', 'ב', 'י', 'ח', 'ט', 'נ', 'צ', 'ן', 'ג', 'ב']),
    212: LevelData(ans: "מכבי נתניה", imagePath: 'assets/images/level8/macabin.webp', logoColor: Colors.yellow, keyboard: ['ת', 'כ', 'י', 'ט', 'נ', 'ז', 'י', 'מ', 'ב', 'ט', 'נ', 'ה', 'ת', 'ל']),
    213: LevelData(ans: "מכבי חיפה", imagePath: 'assets/images/level8/macabi.webp', logoColor: Colors.green, keyboard: ['ז', 'ח', 'ה', 'מ', 'ב', 'ז', 'י', 'ה', 'ב', 'ה', 'כ', 'י', 'ו', 'פ']),
    214: LevelData(ans: "לסטר סיטי", imagePath: 'assets/images/level8/lucifer.webp', logoColor: Colors.blue, keyboard: ['י', 'י', 'ר', 'ד', 'ס', 'ש', 'ט', 'א', 'ד', 'ס', 'ק', 'ט', 'ל', 'י']),
    215: LevelData(ans: "ליברפול", imagePath: 'assets/images/level8/liverpool.webp', logoColor: Colors.red, keyboard: ['י', 'נ', 'ו', 'נ', 'פ', 'א', 'צ', 'ה', 'ב', 'ל', 'ר', 'נ', 'ל', 'פ']),
    216: LevelData(ans: "יובנטוס", imagePath: 'assets/images/level8/juventus.webp', logoColor: Colors.black, keyboard: ['ו', 'ע', 'ב', 'ת', 'ז', 'ר', 'נ', 'ס', 'ח', 'ו', 'ת', 'ר', 'י', 'ט']),
    217: LevelData(ans: "אינטר", imagePath: 'assets/images/level8/inter.webp', logoColor: Colors.blue, keyboard: ['ד', 'ו', 'א', 'נ', 'כ', 'א', 'מ', 'ר', 'ת', 'י', 'ד', 'ז', 'ל', 'ט']),
    218: LevelData(ans: "הפועל תל אביב", imagePath: 'assets/images/level8/hapoettel.webp', logoColor: Colors.red, keyboard: ['ו', 'ב', 'ל', 'ב', 'ע', 'י', 'א', 'פ', 'ת', 'ק', 'ד', 'א', 'ה', 'ל']),
    219: LevelData(ans: "הפועל חיפה", imagePath: 'assets/images/level8/hapoelhaifa.webp', logoColor: Colors.red, keyboard: ['ע', 'ע', 'פ', 'ח', 'ו', 'ה', 'ו', 'ה', 'י', 'ג', 'ל', 'ט', 'ע', 'פ']),
    220: LevelData(ans: "פלמנגו", imagePath: 'assets/images/level8/flamengo.webp', logoColor: Colors.red, keyboard: ['מ', 'ג', 'ע', 'ח', 'ש', 'ב', 'ל', 'נ', 'ס', 'פ', 'צ', 'ע', 'ע', 'ו']),
    221: LevelData(ans: "סביליה", imagePath: 'assets/images/level8/sevilia.webp', logoColor: Colors.red, keyboard: ['כ', 'ט', 'ה', 'כ', 'ס', 'י', 'ת', 'ט', 'ב', 'ט', 'ל', 'נ', 'י', 'ז']),
    222: LevelData(ans: "ריאל מדריד", imagePath: 'assets/images/level8/real.webp', logoColor: Colors.blue, keyboard: ['ר', 'ר', 'מ', 'א', 'ד', 'ד', 'ח', 'ד', 'ז', 'י', 'י', 'ל', 'ק', 'א']),
    223: LevelData(ans: "ריינגרס", imagePath: 'assets/images/level8/rangers.webp', logoColor: Colors.blue, keyboard: ['נ', 'א', 'פ', 'ג', 'י', 'ח', 'ר', 'ר', 'ט', 'י', 'ס', 'ס', 'צ', 'ר']),
    224: LevelData(ans: "פורטו", imagePath: 'assets/images/level8/porto.webp', logoColor: Colors.blue, keyboard: ['פ', 'ר', 'פ', 'ט', 'ד', 'ו', 'ת', 'ו', 'ח', 'ה', 'ז', 'ט', 'פ', 'ר']),
    225: LevelData(ans: "פריז סן זרמן", imagePath: 'assets/images/level8/paris.webp', logoColor: Colors.blue, keyboard: ['ר', 'ן', 'נ', 'ר', 'ה', 'ז', 'ז', 'מ', 'ס', 'ר', 'ן', 'י', 'ו', 'פ']),
    226: LevelData(ans: "נאפולי", imagePath: 'assets/images/level8/na.webp', logoColor: Colors.blue, keyboard: ['פ', 'ב', 'א', 'ס', 'מ', 'ת', 'ל', 'ז', 'י', 'ב', 'נ', 'ד', 'ש', 'ו']),
    227: LevelData(ans: "מנצסטר יונייטד", imagePath: 'assets/images/level8/manchester.webp', logoColor: Colors.red, keyboard: ['מ', 'י', 'ד', 'י', 'ל', 'ו', 'ט', 'ט', 'צ', 'י', 'ס', 'ר', 'נ', 'נ']),
    228: LevelData(ans: "מנצסטר סיטי", imagePath: 'assets/images/level8/machester.webp', logoColor: Colors.lightBlue, keyboard: ['ט', 'ט', 'ט', 'צ', 'מ', 'י', 'צ', 'ר', 'י', 'ל', 'נ', 'ס', 'מ', 'ס']),
    229: LevelData(ans: "מכבי תל אביב", imagePath: 'assets/images/level8/macabitv.webp', logoColor: Colors.yellow, keyboard: ['ב', 'פ', 'ת', 'א', 'ע', 'ל', 'כ', 'י', 'ש', 'ד', 'י', 'מ', 'ב', 'ב']),
    230: LevelData(ans: "טוטנהאם", imagePath: 'assets/images/level8/totenham.webp', logoColor: Colors.indigo, keyboard: ['נ', 'א', 'ד', 'ו', 'ז', 'ם', 'ז', 'ק', 'כ', 'ו', 'ה', 'ט', 'פ', 'ט']),
    231: LevelData(ans: "סאו פאולו", imagePath: 'assets/images/level8/spfc.webp', logoColor: Colors.red, keyboard: ['ס', 'ו', 'ט', 'ל', 'א', 'ג', 'ו', 'ו', 'מ', 'ה', 'פ', 'ע', 'א', 'א']),
    232: LevelData(ans: "חדרה", imagePath: 'assets/images/level9/hedera.webp', logoColor: Colors.green, keyboard: ['ל', 'ד', 'ע', 'ג', 'ז', 'ה', 'ד', 'ו', 'ר', 'ח', 'כ', 'ו', 'ה', 'ת']),
    233: LevelData(ans: "חיפה", imagePath: 'assets/images/level9/haifa.webp', logoColor: Colors.blue, keyboard: ['א', 'י', 'ג', 'ת', 'פ', 'ק', 'ל', 'ה', 'ס', 'ח', 'פ', 'ח', 'ח', 'ס']),
    234: LevelData(ans: "גדרה", imagePath: 'assets/images/level9/gedera.webp', logoColor: Colors.green, keyboard: ['ת', 'ר', 'ח', 'ש', 'ש', 'ה', 'ג', 'נ', 'ד', 'ק', 'נ', 'ת', 'ק', 'כ']),
    235: LevelData(ans: "אילת", imagePath: 'assets/images/level9/eilat.webp', logoColor: Colors.blue, keyboard: ['נ', 'ד', 'ל', 'נ', 'א', 'ל', 'ג', 'י', 'ת', 'ז', 'ב', 'כ', 'ט', 'ט']),
    236: LevelData(ans: "דימונה", imagePath: 'assets/images/level9/dimona.webp', logoColor: Colors.blue, keyboard: ['כ', 'נ', 'מ', 'כ', 'י', 'ה', 'ו', 'ד', 'נ', 'ח', 'מ', 'כ', 'ס', 'ל']),
    237: LevelData(ans: "כרמיאל", imagePath: 'assets/images/level9/carmiel.webp', logoColor: Colors.green, keyboard: ['מ', 'ז', 'מ', 'ל', 'י', 'כ', 'ק', 'י', 'ל', 'י', 'ד', 'ר', 'א', 'ק']),
    238: LevelData(ans: "בית שמש", imagePath: 'assets/images/level9/betshemsh.webp', logoColor: Colors.yellow, keyboard: ['י', 'ש', 'ש', 'ס', 'ת', 'ב', 'ק', 'ש', 'ה', 'ל', 'ת', 'ל', 'מ', 'ה']),
    239: LevelData(ans: "בני ברק", imagePath: 'assets/images/level9/benibrak.webp', logoColor: Colors.purple, keyboard: ['ת', 'י', 'ט', 'ג', 'ב', 'ב', 'ח', 'ל', 'נ', 'ח', 'ק', 'פ', 'ר', 'ד']),
    240: LevelData(ans: "באר יעקב", imagePath: 'assets/images/level9/beeryakov.webp', logoColor: Colors.pink, keyboard: ['ע', 'ר', 'ת', 'ב', 'ס', 'כ', 'ב', 'נ', 'ק', 'צ', 'א', 'י', 'ח', 'י']),
    241: LevelData(ans: "בת ים", imagePath: 'assets/images/level9/batyam.webp', logoColor: Colors.blue, keyboard: ['צ', 'ס', 'מ', 'ת', 'ש', 'ם', 'מ', 'ד', 'ל', 'י', 'מ', 'ז', 'ב', 'ר']),
    242: LevelData(ans: "ערד", imagePath: 'assets/images/level9/arad.webp', logoColor: Colors.brown, keyboard: ['נ', 'א', 'צ', 'ד', 'ע', 'מ', 'ה', 'ר', 'נ', 'ע', 'י', 'ר', 'א', 'ל']),
    243: LevelData(ans: "עכו", imagePath: 'assets/images/level9/ako.webp', logoColor: Colors.red, keyboard: ['ע', 'ע', 'ב', 'ר', 'כ', 'ה', 'צ', 'ב', 'נ', 'ק', 'ו', 'פ', 'ג', 'ר']),
    244: LevelData(ans: "רחובות", imagePath: 'assets/images/level9/rehovot.webp', logoColor: Colors.orange, keyboard: ['ו', 'ט', 'נ', 'ד', 'ת', 'ש', 'ר', 'ב', 'י', 'ח', 'ע', 'ו', 'ס', 'ו']),
    245: LevelData(ans: "רמלה", imagePath: 'assets/images/level9/ramle.webp', logoColor: Colors.blue, keyboard: ['ש', 'ל', 'ש', 'פ', 'ס', 'ג', 'פ', 'צ', 'ש', 'ת', 'ר', 'פ', 'מ', 'ה']),
    246: LevelData(ans: "פתח תקווה", imagePath: 'assets/images/level9/petachtikva.webp', logoColor: Colors.blue, keyboard: ['ק', 'נ', 'ה', 'ת', 'ת', 'ו', 'פ', 'ב', 'ו', 'ז', 'ח', 'נ', 'ה', 'ב']),
    247: LevelData(ans: "אור יהודה", imagePath: 'assets/images/level9/oryehuda.webp', logoColor: Colors.orange, keyboard: ['ו', 'י', 'ו', 'צ', 'ע', 'א', 'א', 'ר', 'ד', 'ז', 'א', 'פ', 'ה', 'ה']),
    248: LevelData(ans: "נוף הגליל", imagePath: 'assets/images/level9/nofhagalil.webp', logoColor: Colors.green, keyboard: ['ו', 'י', 'ר', 'ס', 'ל', 'ו', 'ל', 'ף', 'ס', 'ג', 'נ', 'ה', 'ק', 'ט']),
    249: LevelData(ans: "נס ציונה", imagePath: 'assets/images/level9/nessziona.webp', logoColor: Colors.green, keyboard: ['ה', 'ד', 'נ', 'י', 'ת', 'ס', 'ו', 'ט', 'צ', 'פ', 'ס', 'ד', 'ע', 'נ']),
    250: LevelData(ans: "נצרת", imagePath: 'assets/images/level9/natzrat.webp', logoColor: Colors.blueGrey, keyboard: ['ז', 'ב', 'ר', 'נ', 'ר', 'ר', 'ר', 'ה', 'ש', 'פ', 'ת', 'צ', 'פ', 'ת']),
    251: LevelData(ans: "נתניה", imagePath: 'assets/images/level9/nataniya.webp', logoColor: Colors.blue, keyboard: ['י', 'ש', 'ש', 'ג', 'נ', 'נ', 'ז', 'ק', 'ק', 'ד', 'ת', 'ה', 'ת', 'ו']),
    252: LevelData(ans: "לוד", imagePath: 'assets/images/level9/lod.webp', logoColor: Colors.green, keyboard: ['ד', 'ט', 'ת', 'ו', 'צ', 'כ', 'כ', 'ל', 'ב', 'פ', 'נ', 'ד', 'כ', 'ט']),
    253: LevelData(ans: "קריית שמונה", imagePath: 'assets/images/level9/kiryatshmona.webp', logoColor: Colors.blue, keyboard: ['י', 'ב', 'ו', 'י', 'ס', 'ב', 'מ', 'ה', 'ק', 'ש', 'ר', 'פ', 'נ', 'ת']),
    254: LevelData(ans: "ירושלים", imagePath: 'assets/images/level9/jerusalem.webp', logoColor: Colors.blue, keyboard: ['ש', 'ר', 'צ', 'ג', 'א', 'ש', 'י', 'י', 'ט', 'צ', 'ם', 'נ', 'ו', 'ל']),
    255: LevelData(ans: "חולון", imagePath: 'assets/images/level9/holon.webp', logoColor: Colors.blue, keyboard: ['ס', 'ח', 'כ', 'ו', 'ע', 'ו', 'ט', 'ש', 'ן', 'ח', 'ל', 'ת', 'ו', 'ט']),
    256: LevelData(ans: "יבנה", imagePath: 'assets/images/level9/yavne.webp', logoColor: Colors.orange, keyboard: ['צ', 'נ', 'י', 'צ', 'ע', 'צ', 'ו', 'ז', 'י', 'פ', 'ב', 'ה', 'ק', 'ז']),
    257: LevelData(ans: "תל אביב", imagePath: 'assets/images/level9/telaviv.webp', logoColor: Colors.lightBlue, keyboard: ['צ', 'ש', 'א', 'מ', 'ס', 'י', 'ת', 'ב', 'ב', 'ו', 'א', 'ר', 'ב', 'ל']),
    258: LevelData(ans: "ראשון לציון", imagePath: 'assets/images/level9/rishonlezion.webp', logoColor: Colors.orange, keyboard: ['צ', 'ן', 'ר', 'ו', 'ע', 'א', 'ה', 'ב', 'ן', 'י', 'ל', 'ש', 'צ', 'ו']),
    259: LevelData(ans: "דנמרק", imagePath: 'assets/images/level10/denemark.webp', logoColor: const Color.fromARGB(255, 200, 100, 100), keyboard: ['ה', 'מ', 'פ', 'ר', 'ב', 'צ', 'ס', 'ד', 'מ', 'מ', 'ל', 'ד', 'ק', 'נ']),
    260: LevelData(ans: "צכיה", imagePath: 'assets/images/level10/czech.webp', logoColor: const Color.fromARGB(255, 100, 150, 200), keyboard: ['ב', 'ח', 'ה', 'כ', 'ע', 'כ', 'ק', 'ז', 'ח', 'ש', 'צ', 'ט', 'י', 'צ']),
    261: LevelData(ans: "קולומביה", imagePath: 'assets/images/level10/colombia.webp', logoColor: const Color.fromARGB(255, 230, 200, 100), keyboard: ['ב', 'פ', 'י', 'ו', 'ט', 'ע', 'ד', 'צ', 'ק', 'מ', 'ק', 'ל', 'ה', 'ו']),
    262: LevelData(ans: "צילה", imagePath: 'assets/images/level10/chile.webp', logoColor: const Color.fromARGB(255, 200, 120, 120), keyboard: ['ס', 'ד', 'ט', 'ס', 'י', 'י', 'ה', 'ו', 'א', 'צ', 'ד', 'כ', 'ל', 'ג']),
    263: LevelData(ans: "קמרון", imagePath: 'assets/images/level10/cameroon.webp', logoColor: const Color.fromARGB(255, 120, 180, 130), keyboard: ['ט', 'ק', 'ה', 'ב', 'ז', 'ר', 'כ', 'ן', 'צ', 'מ', 'ו', 'ט', 'ב', 'ו']),
    264: LevelData(ans: "בוליביה", imagePath: 'assets/images/level10/bolivia.webp', logoColor: const Color.fromARGB(255, 200, 180, 100), keyboard: ['א', 'ל', 'ה', 'ב', 'נ', 'ז', 'ב', 'כ', 'י', 'ש', 'ע', 'ו', 'ז', 'י']),
    265: LevelData(ans: "בנגלדש", imagePath: 'assets/images/level10/bangldash.webp', logoColor: const Color.fromARGB(255, 100, 160, 120), keyboard: ['ב', 'ס', 'נ', 'נ', 'ל', 'ש', 'ג', 'ד', 'פ', 'ש', 'ו', 'ל', 'ת', 'צ']),
    266: LevelData(ans: "אוסטריה", imagePath: 'assets/images/level10/austria.webp', logoColor: const Color.fromARGB(255, 220, 130, 130), keyboard: ['ר', 'ס', 'י', 'ת', 'פ', 'ד', 'מ', 'ה', 'ה', 'א', 'ט', 'ו', 'ז', 'ד']),
    267: LevelData(ans: "אלבניה", imagePath: 'assets/images/level10/albania.webp', logoColor: const Color.fromARGB(255, 210, 100, 100), keyboard: ['י', 'ב', 'י', 'ת', 'ה', 'נ', 'ל', 'ד', 'א', 'נ', 'א', 'א', 'ב', 'ד']),
    268: LevelData(ans: "מלזיה", imagePath: 'assets/images/level10/malaysia.webp', logoColor: const Color.fromARGB(255, 180, 150, 200), keyboard: ['פ', 'י', 'ת', 'ה', 'ל', 'א', 'מ', 'נ', 'ז', 'ו', 'ה', 'ג', 'ל', 'נ']),
    269: LevelData(ans: "לוקסמבורג", imagePath: 'assets/images/level10/luxemborg.webp', logoColor: const Color.fromARGB(255, 140, 190, 220), keyboard: ['ד', 'ל', 'ק', 'כ', 'ע', 'ר', 'מ', 'ל', 'ג', 'ב', 'ז', 'ו', 'ס', 'ו']),
    270: LevelData(ans: "דרום קוריאה", imagePath: 'assets/images/level10/korea.webp', logoColor: const Color.fromARGB(255, 160, 170, 210), keyboard: ['ו', 'ח', 'ם', 'פ', 'ק', 'ה', 'ר', 'מ', 'ה', 'ר', 'א', 'ד', 'ו', 'י']),
    271: LevelData(ans: "אירלנד", imagePath: 'assets/images/level10/ireland.webp', logoColor: const Color.fromARGB(255, 150, 200, 160), keyboard: ['א', 'ש', 'כ', 'ק', 'נ', 'ט', 'י', 'ל', 'מ', 'ב', 'צ', 'ר', 'ד', 'ב']),
    272: LevelData(ans: "הונגריה", imagePath: 'assets/images/level10/hungary.webp', logoColor: const Color.fromARGB(255, 170, 200, 150), keyboard: ['ר', 'ש', 'ר', 'ה', 'ג', 'י', 'ג', 'ו', 'ז', 'נ', 'ה', 'מ', 'א', 'ע']),
    273: LevelData(ans: "גאנה", imagePath: 'assets/images/level10/ghana.webp', logoColor: const Color.fromARGB(255, 210, 180, 120), keyboard: ['א', 'א', 'צ', 'ש', 'ה', 'צ', 'ז', 'נ', 'ד', 'י', 'ש', 'ו', 'ג', 'ת']),
    274: LevelData(ans: "אתיופיה", imagePath: 'assets/images/level10/ethiopia.webp', logoColor: const Color.fromARGB(255, 160, 190, 130), keyboard: ['ו', 'ר', 'י', 'ט', 'ה', 'פ', 'ת', 'ב', 'י', 'א', 'ו', 'ג', 'א', 'י']),
    275: LevelData(ans: "אנגליה", imagePath: 'assets/images/level10/england.webp', logoColor: const Color.fromARGB(255, 210, 160, 160), keyboard: ['ל', 'ה', 'ש', 'ז', 'א', 'י', 'ת', 'ה', 'נ', 'נ', 'ז', 'ג', 'ח', 'א']),
    276: LevelData(ans: "פינלנד", imagePath: 'assets/images/level10/dinland.webp', logoColor: const Color.fromARGB(255, 140, 170, 220), keyboard: ['פ', 'ו', 'י', 'מ', 'ע', 'נ', 'נ', 'ח', 'נ', 'ת', 'ט', 'ד', 'ל', 'א']),
    277: LevelData(ans: "סינגפור", imagePath: 'assets/images/level10/singapore.webp', logoColor: const Color.fromARGB(255, 210, 140, 140), keyboard: ['פ', 'ר', 'י', 'כ', 'ו', 'ת', 'ט', 'ה', 'ח', 'נ', 'ס', 'ג', 'ג', 'ה']),
    278: LevelData(ans: "סרביה", imagePath: 'assets/images/level10/serbia.webp', logoColor: const Color.fromARGB(255, 190, 140, 170), keyboard: ['ס', 'ב', 'ל', 'ל', 'ה', 'ע', 'ד', 'ר', 'א', 'י', 'ת', 'ס', 'א', 'ק']),
    279: LevelData(ans: "סקוטלנד", imagePath: 'assets/images/level10/scotland.webp', logoColor: const Color.fromARGB(255, 130, 160, 210), keyboard: ['נ', 'ו', 'כ', 'ס', 'פ', 'ק', 'א', 'ט', 'ד', 'ל', 'א', 'צ', 'ז', 'ו']),
    280: LevelData(ans: "פולין", imagePath: 'assets/images/level10/poland.webp', logoColor: const Color.fromARGB(255, 210, 150, 170), keyboard: ['י', 'פ', 'ל', 'ר', 'ן', 'ל', 'ד', 'כ', 'ו', 'י', 'כ', 'ה', 'פ', 'מ']),
    281: LevelData(ans: "פיליפינים", imagePath: 'assets/images/level10/philip.webp', logoColor: const Color.fromARGB(255, 150, 180, 210), keyboard: ['י', 'כ', 'נ', 'פ', 'ל', 'ש', 'ס', 'ם', 'פ', 'צ', 'ק', 'י', 'י', 'י']),
    282: LevelData(ans: "נורווגיה", imagePath: 'assets/images/level10/norway.webp', logoColor: const Color.fromARGB(255, 200, 130, 140), keyboard: ['ר', 'צ', 'י', 'ו', 'ד', 'ו', 'ש', 'ה', 'ג', 'נ', 'ס', 'ו', 'ק', 'ג']),
    283: LevelData(ans: "נפאל", imagePath: 'assets/images/level10/napal.webp', logoColor: const Color.fromARGB(255, 210, 140, 150), keyboard: ['מ', 'פ', 'כ', 'נ', 'ר', 'ט', 'י', 'א', 'ש', 'ל', 'ה', 'ר', 'ל', 'צ']),
    284: LevelData(ans: "מולדובה", imagePath: 'assets/images/level10/moldova.webp', logoColor: const Color.fromARGB(255, 190, 170, 130), keyboard: ['ב', 'מ', 'ל', 'ב', 'ד', 'ת', 'מ', 'ה', 'ד', 'ד', 'ג', 'ו', 'ו', 'ט']),
    285: LevelData(ans: "מלטה", imagePath: 'assets/images/level10/malta.webp', logoColor: const Color.fromARGB(255, 210, 160, 160), keyboard: ['ר', 'ט', 'ט', 'ט', 'ד', 'ה', 'ל', 'ל', 'ק', 'ח', 'מ', 'ה', 'ה', 'ה']),
    286: LevelData(ans: "וייטנאם", imagePath: 'assets/images/level10/vietnam.webp', logoColor: const Color.fromARGB(255, 210, 120, 120), keyboard: ['א', 'י', 'ז', 'ט', 'ם', 'י', 'ע', 'ו', 'פ', 'ו', 'נ', 'ז', 'מ', 'י']),
    287: LevelData(ans: "ארצות הברית", imagePath: 'assets/images/level10/untiedstates.webp', logoColor: const Color.fromARGB(255, 140, 160, 210), keyboard: ['ב', 'א', 'י', 'ו', 'ב', 'ח', 'ה', 'ר', 'ת', 'ר', 'מ', 'ת', 'ט', 'צ']),
    288: LevelData(ans: "אוקראינה", imagePath: 'assets/images/level10/ukraine.webp', logoColor: const Color.fromARGB(255, 140, 180, 210), keyboard: ['ר', 'י', 'ע', 'נ', 'ז', 'ק', 'י', 'ר', 'ו', 'ו', 'ה', 'ב', 'א', 'א']),
    289: LevelData(ans: "טורקיה", imagePath: 'assets/images/level10/turkey.webp', logoColor: const Color.fromARGB(255, 210, 130, 130), keyboard: ['ר', 'י', 'נ', 'ט', 'כ', 'ק', 'מ', 'ה', 'ק', 'כ', 'י', 'ו', 'כ', 'ע']),
    290: LevelData(ans: "תאילנד", imagePath: 'assets/images/level10/thailand.webp', logoColor: const Color.fromARGB(255, 160, 170, 210), keyboard: ['ד', 'ד', 'צ', 'י', 'ב', 'א', 'מ', 'ו', 'ב', 'נ', 'ת', 'פ', 'ל', 'ת']),
    291: LevelData(ans: "שוודיה", imagePath: 'assets/images/level10/sweeden.webp', logoColor: const Color.fromARGB(255, 130, 170, 210), keyboard: ['ש', 'ל', 'כ', 'ש', 'ס', 'מ', 'י', 'ב', 'ד', 'נ', 'ה', 'ו', 'י', 'ו']),
    292: LevelData(ans: "סרי לנקה", imagePath: 'assets/images/level10/sri lanka.webp', logoColor: const Color.fromARGB(255, 200, 170, 120), keyboard: ['צ', 'ר', 'ק', 'ס', 'ל', 'א', 'ר', 'ח', 'ה', 'נ', 'ח', 'י', 'ו', 'ו']),
    293: LevelData(ans: "סלובקיה", imagePath: 'assets/images/level10/slovakia.webp', logoColor: const Color.fromARGB(255, 160, 170, 210), keyboard: ['מ', 'ס', 'י', 'ל', 'ק', 'נ', 'ב', 'ה', 'ו', 'ז', 'ג', 'ז', 'ו', 'ע']),
    294: LevelData(ans: "בנק ירושלים", imagePath: 'assets/images/level11/jerusalem.webp', logoColor: Colors.blue, keyboard: ['ו', 'ז', 'י', 'נ', 'י', 'ב', 'ר', 'ש', 'ש', 'ז', 'ק', 'ל', 'ם', 'ל']),
    295: LevelData(ans: "ישראכרט", imagePath: 'assets/images/level11/isracard.webp', logoColor: Colors.blue, keyboard: ['מ', 'ט', 'ש', 'א', 'ה', 'ר', 'ב', 'ר', 'י', 'ט', 'ט', 'ש', 'כ', 'ת']),
    296: LevelData(ans: "הפועלים", imagePath: 'assets/images/level11/hapoalim.webp', logoColor: Colors.red, keyboard: ['ה', 'ה', 'ו', 'ה', 'ש', 'צ', 'י', 'פ', 'פ', 'פ', 'ל', 'ח', 'ם', 'ע']),
    297: LevelData(ans: "דיסקונט", imagePath: 'assets/images/level11/discont.webp', logoColor: Colors.green, keyboard: ['ס', 'כ', 'ד', 'ק', 'ה', 'נ', 'י', 'ב', 'ת', 'ו', 'צ', 'צ', 'ט', 'י']),
    298: LevelData(ans: "כלל", imagePath: 'assets/images/level11/clal.webp', logoColor: Colors.blue, keyboard: ['ס', 'ק', 'ט', 'כ', 'צ', 'ס', 'ת', 'ל', 'ד', 'ל', 'פ', 'נ', 'ז', 'י']),
    299: LevelData(ans: "כאל", imagePath: 'assets/images/level11/cal.webp', logoColor: Colors.orange, keyboard: ['ל', 'ק', 'ק', 'כ', 'מ', 'י', 'מ', 'ה', 'ב', 'ק', 'ט', 'ח', 'מ', 'א']),
    300: LevelData(ans: "ביטוח לאומי", imagePath: 'assets/images/level11/bituah.webp', logoColor: Colors.blue, keyboard: ['א', 'ב', 'מ', 'ח', 'י', 'י', 'ל', 'ו', 'י', 'ה', 'ו', 'ב', 'מ', 'ט']),
    301: LevelData(ans: "אוצר החייל", imagePath: 'assets/images/level11/bank.webp', logoColor: Colors.amber, keyboard: ['ר', 'י', 'ה', 'ל', 'א', 'ת', 'ס', 'כ', 'י', 'צ', 'ח', 'ו', 'ו', 'ת']),
    302: LevelData(ans: "AIG", imagePath: 'assets/images/level11/aig.webp', logoColor: Colors.indigo, keyboard: ['K', 'A', 'B', 'K', 'I', 'Q', 'N', 'I', 'C', 'M', 'O', 'M', 'U', 'G']),
    303: LevelData(ans: "בנק יהב", imagePath: 'assets/images/level11/yahav.webp', logoColor: Colors.blue, keyboard: ['נ', 'ה', 'ו', 'ב', 'ב', 'ע', 'פ', 'י', 'ח', 'נ', 'א', 'ב', 'ב', 'ק']),
    304: LevelData(ans: "PEPPER", imagePath: 'assets/images/level11/peper.webp', logoColor: Colors.pink, keyboard: ['P', 'G', 'P', 'A', 'E', 'S', 'G', 'R', 'P', 'X', 'M', 'E', 'H', 'U']),
    305: LevelData(ans: "הפניקס", imagePath: 'assets/images/level11/peniks.webp', logoColor: Colors.orange, keyboard: ['נ', 'ק', 'פ', 'י', 'ה', 'ק', 'ט', 'מ', 'ש', 'ו', 'ט', 'ג', 'ס', 'פ']),
    306: LevelData(ans: "ONEZERO", imagePath: 'assets/images/level11/onezero.webp', logoColor: Colors.grey, keyboard: ['L', 'R', 'N', 'V', 'E', 'O', 'Z', 'Q', 'E', 'O', 'L', 'D', 'N', 'Z']),
    307: LevelData(ans: "מזרחי", imagePath: 'assets/images/level11/mizrahi.webp', logoColor: Colors.orange, keyboard: ['א', 'ה', 'ה', 'ר', 'מ', 'צ', 'י', 'ק', 'ח', 'ס', 'ז', 'ח', 'פ', 'ו']),
    308: LevelData(ans: "מגדל", imagePath: 'assets/images/level11/migdal.webp', logoColor: Colors.indigo, keyboard: ['ר', 'מ', 'נ', 'ה', 'ד', 'ק', 'ז', 'ע', 'פ', 'ג', 'ז', 'מ', 'ל', 'ז']),
    309: LevelData(ans: "מנורה", imagePath: 'assets/images/level11/menora.webp', logoColor: Colors.orange, keyboard: ['ו', 'ו', 'מ', 'ה', 'נ', 'ל', 'ע', 'ג', 'ע', 'ר', 'ז', 'ה', 'ד', 'א']),
    310: LevelData(ans: "מיטב", imagePath: 'assets/images/level11/meitav.webp', logoColor: Colors.green, keyboard: ['נ', 'ת', 'ט', 'מ', 'ו', 'ר', 'פ', 'ב', 'ב', 'א', 'ו', 'י', 'א', 'מ']),
    311: LevelData(ans: "לאומי", imagePath: 'assets/images/level11/leumi.webp', logoColor: Colors.blue, keyboard: ['ו', 'ל', 'ס', 'פ', 'א', 'י', 'ח', 'י', 'ד', 'ל', 'י', 'ז', 'מ', 'פ']),
    312: LevelData(ans: "ביטוח ישיר", imagePath: 'assets/images/level11/yashir.webp', logoColor: Colors.red, keyboard: ['ח', 'צ', 'ר', 'ט', 'ד', 'ב', 'ת', 'י', 'י', 'ד', 'ש', 'ו', 'י', 'ס']),
    313: LevelData(ans: "ילין לפידות", imagePath: 'assets/images/level11/yalin.webp', logoColor: Colors.blue, keyboard: ['ן', 'ד', 'ל', 'ד', 'ל', 'ו', 'ט', 'י', 'י', 'י', 'א', 'פ', 'ת', 'מ']),
    314: LevelData(ans: "שירביט", imagePath: 'assets/images/level11/sirbit.webp', logoColor: Colors.red, keyboard: ['ד', 'ט', 'ר', 'ש', 'ב', 'נ', 'י', 'ק', 'פ', 'מ', 'נ', 'י', 'ץ', 'א']),
    315: LevelData(ans: "ליברה", imagePath: 'assets/images/level11/libra.webp', logoColor: Colors.black, keyboard: ['ט', 'ב', 'ט', 'ג', 'ה', 'ץ', 'י', 'ר', 'פ', 'צ', 'ל', 'פ', 'ש', 'ף']),
    316: LevelData(ans: "IBI", imagePath: 'assets/images/level11/ibi.webp', logoColor: Colors.black, keyboard: ['V', 'H', 'V', 'K', 'A', 'C', 'Z', 'V', 'I', 'B', 'R', 'D', 'J', 'I']),
    317: LevelData(ans: "הראל", imagePath: 'assets/images/level11/harel.webp', logoColor: Colors.blue, keyboard: ['ז', 'ק', 'ה', 'ו', 'ע', 'נ', 'ל', 'ץ', 'ט', 'ר', 'ך', 'ד', 'א', 'פ']),
    318: LevelData(ans: "ביט", imagePath: 'assets/images/level11/bit.webp', logoColor: Colors.teal, keyboard: ['ה', 'ק', 'ז', 'צ', 'ק', 'ב', 'ש', 'ץ', 'ף', 'ט', 'ר', 'כ', 'פ', 'י']),
    319: LevelData(ans: "אנליסט", imagePath: 'assets/images/level11/analyst.webp', logoColor: Colors.indigo, keyboard: ['א', 'ב', 'כ', 'כ', 'ד', 'נ', 'ז', 'ו', 'י', 'כ', 'ל', 'ע', 'ס', 'ט']),
    320: LevelData(ans: "אלטשולר שחם", imagePath: 'assets/images/level11/altshular.webp', logoColor: Colors.green, keyboard: ['ש', 'ר', 'ו', 'ח', 'ב', 'ם', 'מ', 'י', 'א', 'ל', 'ש', 'ט', 'ל', 'ן']),
    321: LevelData(ans: "דלק", imagePath: 'assets/images/level12/delek.webp', logoColor: Colors.blue, keyboard: ['א', 'ח', 'ק', 'ג', 'ד', 'צ', 'ד', 'ח', 'ש', 'ל', 'ת', 'ד', 'ט', 'ה']),
    322: LevelData(ans: "כללית", imagePath: 'assets/images/level12/clalit.webp', logoColor: Colors.teal, keyboard: ['כ', 'ק', 'כ', 'נ', 'ת', 'ט', 'ט', 'א', 'ס', 'ו', 'ל', 'ח', 'י', 'ל']),
    323: LevelData(ans: "סינמה סיטי", imagePath: 'assets/images/level12/cinima.webp', logoColor: Colors.indigo, keyboard: ['ט', 'י', 'ן', 'י', 'נ', 'ב', 'ס', 'ן', 'ף', 'י', 'מ', 'ה', 'ד', 'ס']),
    324: LevelData(ans: "באג", imagePath: 'assets/images/level12/bug.webp', logoColor: Colors.deepOrange, keyboard: ['ר', 'ס', 'כ', 'ב', 'ן', 'ה', 'ג', 'א', 'ך', 'ש', 'ת', 'י', 'צ', 'י']),
    325: LevelData(ans: "בזק", imagePath: 'assets/images/level12/bezep.webp', logoColor: Colors.black, keyboard: ['ב', 'ק', 'ז', 'כ', 'כ', 'ק', 'ז', 'מ', 'ח', 'ב', 'ט', 'ת', 'ב', 'ג']),
    326: LevelData(ans: "איילון", imagePath: 'assets/images/level12/ayalon.webp', logoColor: Colors.teal, keyboard: ['ן', 'ל', 'ק', 'פ', 'ל', 'ח', 'ו', 'ק', 'מ', 'י', 'ה', 'א', 'י', 'נ']),
    327: LevelData(ans: "ארקיע", imagePath: 'assets/images/level12/arkia.webp', logoColor: Colors.pink, keyboard: ['א', 'ת', 'ת', 'ט', 'צ', 'א', 'י', 'ק', 'ט', 'ע', 'ר', 'פ', 'ד', 'צ']),
    328: LevelData(ans: "אנגל", imagePath: 'assets/images/level12/angel.webp', logoColor: Colors.brown, keyboard: ['ל', 'ש', 'ש', 'נ', 'ה', 'ג', 'צ', 'ל', 'פ', 'י', 'ז', 'א', 'ר', 'ו']),
    329: LevelData(ans: "מכבי", imagePath: 'assets/images/level12/macabi.webp', logoColor: Colors.blue, keyboard: ['מ', 'ע', 'ה', 'ת', 'כ', 'ג', 'ה', 'י', 'ג', 'צ', 'ע', 'ק', 'ב', 'ג']),
    330: LevelData(ans: "לאומית", imagePath: 'assets/images/level12/leomit.webp', logoColor: Colors.green, keyboard: ['ח', 'ו', 'י', 'א', 'ס', 'ת', 'פ', 'כ', 'ח', 'ג', 'מ', 'ס', 'ד', 'ל']),
    331: LevelData(ans: "הוט", imagePath: 'assets/images/level12/hot.webp', logoColor: Colors.pink, keyboard: ['ק', 'ג', 'ז', 'ט', 'ת', 'פ', 'ה', 'ו', 'צ', 'ח', 'ה', 'כ', 'ט', 'ע']),
    332: LevelData(ans: "הום סנטר", imagePath: 'assets/images/level12/homecenter.webp', logoColor: Colors.orange, keyboard: ['ס', 'כ', 'ו', 'א', 'ת', 'ר', 'ה', 'ך', 'ז', 'נ', 'צ', 'פ', 'ט', 'ם']),
    333: LevelData(ans: "הרץ", imagePath: 'assets/images/level12/hertz.webp', logoColor: Colors.amber, keyboard: ['צ', 'ח', 'ג', 'ר', 'ה', 'ד', 'ש', 'ג', 'ב', 'צ', 'ס', 'ץ', 'ס', 'א']),
    334: LevelData(ans: "EPIC GAMES", imagePath: 'assets/images/level12/epicgames.webp', logoColor: Colors.black, keyboard: ['M', 'A', 'Z', 'O', 'E', 'P', 'I', 'C', 'I', 'E', 'S', 'Z', 'M', 'G']),
    335: LevelData(ans: "אלקטרה", imagePath: 'assets/images/level12/electra.webp', logoColor: Colors.blue, keyboard: ['ב', 'ה', 'פ', 'ב', 'ר', 'א', 'ב', 'ט', 'פ', 'ע', 'ו', 'ק', 'ל', 'ק']),
    336: LevelData(ans: "פז", imagePath: 'assets/images/level12/paz.webp', logoColor: Colors.blue, keyboard: ['ז', 'כ', 'ט', 'כ', 'פ', 'פ', 'ז', 'ת', 'ק', 'ת', 'ר', 'ק', 'נ', 'ג']),
    337: LevelData(ans: "פרטנר", imagePath: 'assets/images/level12/partner.webp', logoColor: Colors.teal, keyboard: ['צ', 'ר', 'נ', 'ה', 'ל', 'ט', 'ח', 'פ', 'ג', 'פ', 'ז', 'ט', 'ר', 'ג']),
    338: LevelData(ans: "נביעות", imagePath: 'assets/images/level12/neviot.webp', logoColor: Colors.green, keyboard: ['ד', 'ה', 'ב', 'ז', 'ר', 'נ', 'י', 'ד', 'צ', 'ו', 'ט', 'ע', 'ת', 'י']),
    339: LevelData(ans: "נתיבי ישראל", imagePath: 'assets/images/level12/netiviisrael.webp', logoColor: Colors.blue, keyboard: ['ה', 'ב', 'ש', 'י', 'ת', 'ל', 'א', 'נ', 'ש', 'א', 'ר', 'כ', 'י', 'י']),
    340: LevelData(ans: "מיקרוסופט", imagePath: 'assets/images/level12/microsoft.webp', logoColor: Colors.blue, keyboard: ['ו', 'ך', 'ר', 'ד', 'מ', 'ו', 'ט', 'ק', 'ג', 'ש', 'י', 'ח', 'ס', 'פ']),
    341: LevelData(ans: "מאוחדת", imagePath: 'assets/images/level12/meohedet.webp', logoColor: Colors.orange, keyboard: ['ח', 'א', 'ת', 'ת', 'ח', 'ו', 'כ', 'נ', 'מ', 'ו', 'א', 'נ', 'ו', 'ד']),
    342: LevelData(ans: "מקס", imagePath: 'assets/images/level12/max.webp', logoColor: Colors.red, keyboard: ['נ', 'א', 'כ', 'א', 'ז', 'ף', 'ח', 'מ', 'א', 'ץ', 'ה', 'ו', 'ס', 'ק']),
    343: LevelData(ans: "יס", imagePath: 'assets/images/level12/yes.webp', logoColor: Colors.lightBlue, keyboard: ['י', 'ש', 'ק', 'כ', 'ש', 'מ', 'ץ', 'כ', 'א', 'ס', 'ל', 'ש', 'ד', 'ו']),
    344: LevelData(ans: "טן", imagePath: 'assets/images/level12/ten.webp', logoColor: Colors.blue, keyboard: ['ה', 'ן', 'פ', 'ת', 'כ', 'ט', 'נ', 'י', 'י', 'ת', 'צ', 'מ', 'י', 'ד']),
    345: LevelData(ans: "תדיראן", imagePath: 'assets/images/level12/tadrian.webp', logoColor: Colors.black, keyboard: ['ת', 'ס', 'ק', 'ס', 'ס', 'כ', 'ת', 'ן', 'א', 'ד', 'י', 'ר', 'ש', 'ר']),
    346: LevelData(ans: "סטים", imagePath: 'assets/images/level12/steam.webp', logoColor: Colors.blueGrey, keyboard: ['ט', 'ס', 'ר', 'ב', 'י', 'ק', 'כ', 'ם', 'ץ', 'ז', 'א', 'ק', 'ש', 'ג']),
    347: LevelData(ans: "סונול", imagePath: 'assets/images/level12/sonol.webp', logoColor: Colors.red, keyboard: ['ס', 'ו', 'נ', 'ו', 'פ', 'צ', 'ל', 'ה', 'ו', 'ד', 'ב', 'ח', 'ס', 'ס']),
    348: LevelData(ans: "שלמה", imagePath: 'assets/images/level12/shlomo.webp', logoColor: Colors.green, keyboard: ['ט', 'ע', 'ח', 'ש', 'פ', 'ס', 'מ', 'ש', 'ש', 'ע', 'ל', 'ט', 'ו', 'ה']),
    349: LevelData(ans: "דורלון", imagePath: 'assets/images/level12/doralon.webp', logoColor: Colors.brown, keyboard: ['ר', 'ד', 'ו', 'ה', 'ב', 'כ', 'צ', 'ו', 'ג', 'ל', 'מ', 'ד', 'ש', 'ן']),
    350: LevelData(ans: "חברת חשמל", imagePath: 'assets/images/level12/hevrat.webp', logoColor: Colors.black, keyboard: ['ל', 'ד', 'ש', 'ר', 'ב', 'ח', 'ב', 'ת', 'ש', 'מ', 'ח', 'ש', 'ח', 'ק']),
    351: LevelData(ans: "מחסני חשמל", imagePath: 'assets/images/level12/hasmal.webp', logoColor: Colors.black, keyboard: ['י', 'ל', 'ק', 'מ', 'ש', 'י', 'מ', 'ח', 'נ', 'צ', 'ח', 'ס', 'ד', 'צ']),
    352: LevelData(ans: "מנורה מבטחים", imagePath: 'assets/images/level12/mivtach.webp', logoColor: Colors.indigo, keyboard: ['צ', 'ר', 'מ', 'ה', 'ח', 'נ', 'ו', 'ע', 'ם', 'י', 'ט', 'מ', 'ת', 'ב']),
    353: LevelData(ans: "מיקה", imagePath: 'assets/images/level12/mika.webp', logoColor: Colors.blueGrey, keyboard: ['פ', 'צ', 'ע', 'ה', 'ס', 'פ', 'מ', 'ו', 'ס', 'ס', 'י', 'ק', 'ק', 'ז']),
    354: LevelData(ans: "FLAPPY BIRD", imagePath: 'assets/images/level13/flappy.webp', logoColor: Colors.green, keyboard: ['A', 'R', 'P', 'D', 'E', 'F', 'W', 'I', 'Y', 'H', 'B', 'L', 'P', 'M']),
    355: LevelData(ans: "CS GO", imagePath: 'assets/images/level13/csgo.webp', logoColor: Colors.black, keyboard: ['S', 'M', 'C', 'Y', 'J', 'G', 'S', 'P', 'O', 'L', 'N', 'M', 'Y', 'A']),
    356: LevelData(ans: "COIN MASTER", imagePath: 'assets/images/level13/coinmaster.webp', logoColor: Colors.pink, keyboard: ['R', 'O', 'Z', 'K', 'A', 'M', 'N', 'C', 'E', 'V', 'T', 'I', 'V', 'S']),
    357: LevelData(ans: "CLASH ROYALE", imagePath: 'assets/images/level13/clashroyal.webp', logoColor: Colors.purple, keyboard: ['O', 'F', 'L', 'A', 'E', 'L', 'A', 'E', 'Y', 'S', 'R', 'O', 'H', 'C']),
    358: LevelData(ans: "CANDY CRUSH", imagePath: 'assets/images/level13/candycrush.webp', logoColor: Colors.purple, keyboard: ['A', 'N', 'Y', 'X', 'U', 'R', 'H', 'S', 'R', 'A', 'P', 'D', 'C', 'C']),
    359: LevelData(ans: "CLASH OF CLANS", imagePath: 'assets/images/level13/calshofclans.webp', logoColor: Colors.amber, keyboard: ['N', 'L', 'S', 'V', 'C', 'F', 'P', 'A', 'O', 'H', 'C', 'S', 'A', 'L']),
    360: LevelData(ans: "BRAWL STARS", imagePath: 'assets/images/level13/braw.webp', logoColor: Colors.purple, keyboard: ['A', 'R', 'A', 'B', 'L', 'A', 'S', 'S', 'S', 'R', 'W', 'J', 'T', 'S']),
    361: LevelData(ans: "ANGRY BIRDS", imagePath: 'assets/images/level13/angry.webp', logoColor: Colors.red, keyboard: ['Y', 'G', 'N', 'S', 'R', 'R', 'R', 'I', 'A', 'V', 'L', 'D', 'N', 'B']),
    362: LevelData(ans: "רובלוקס", imagePath: 'assets/images/level13/roblox.webp', logoColor: Colors.black, keyboard: ['ב', 'ל', 'ט', 'ה', 'ו', 'ס', 'ה', 'ר', 'מ', 'ק', 'ם', 'נ', 'ם', 'ו']),
    363: LevelData(ans: "פוקימון", imagePath: 'assets/images/level13/pokemon.webp', logoColor: Colors.yellow, keyboard: ['פ', 'ן', 'ב', 'ץ', 'ט', 'ע', 'ם', 'מ', 'כ', 'ק', 'ת', 'ו', 'י', 'ו']),
    364: LevelData(ans: "PAC MAN", imagePath: 'assets/images/level13/pacmen.webp', logoColor: Colors.yellow, keyboard: ['A', 'Q', 'N', 'R', 'A', 'C', 'C', 'P', 'H', 'X', 'G', 'N', 'M', 'P']),
    365: LevelData(ans: "אוברווטש", imagePath: 'assets/images/level13/overwatch.webp', logoColor: Colors.deepOrange, keyboard: ['ו', 'ב', 'פ', 'י', 'א', 'ש', 'ר', 'י', 'ו', 'י', 'ו', 'כ', 'ט', 'ל']),
    366: LevelData(ans: "מיינקראפט", imagePath: 'assets/images/level13/minecraft.webp', logoColor: Colors.green, keyboard: ['ט', 'י', 'נ', 'ז', 'י', 'א', 'ה', 'ס', 'פ', 'ס', 'ר', 'ק', 'מ', 'צ']),
    367: LevelData(ans: "מריו", imagePath: 'assets/images/level13/mario.webp', logoColor: Colors.red, keyboard: ['א', 'ח', 'ט', 'ל', 'ו', 'צ', 'ה', 'ב', 'ר', 'ו', 'י', 'י', 'י', 'מ']),
    368: LevelData(ans: "HAY DAY", imagePath: 'assets/images/level13/hayday.webp', logoColor: Colors.lightBlue, keyboard: ['P', 'Y', 'D', 'M', 'B', 'A', 'F', 'I', 'Y', 'H', 'C', 'D', 'P', 'A']),
    369: LevelData(ans: "FRUIT NINJA", imagePath: 'assets/images/level13/fruitninja.webp', logoColor: Colors.blue, keyboard: ['N', 'F', 'R', 'Y', 'T', 'U', 'R', 'N', 'I', 'J', 'I', 'T', 'N', 'A']),
    370: LevelData(ans: "פורטנייט", imagePath: 'assets/images/level13/fortnite.webp', logoColor: Colors.blue, keyboard: ['צ', 'ו', 'ט', 'פ', 'ט', 'ז', 'י', 'ן', 'נ', 'י', 'ר', 'ג', 'ץ', 'ח']),
    371: LevelData(ans: "ולוראנט", imagePath: 'assets/images/level13/valorant.webp', logoColor: Colors.red, keyboard: ['פ', 'ו', 'כ', 'ט', 'י', 'נ', 'ר', 'א', 'ל', 'ו', 'ף', 'ד', 'ס', 'ך']),
    372: LevelData(ans: "TEMPLE RUN", imagePath: 'assets/images/level13/templerun.webp', logoColor: Colors.amber, keyboard: ['E', 'U', 'U', 'R', 'R', 'H', 'P', 'N', 'L', 'E', 'T', 'E', 'M', 'I']),
    373: LevelData(ans: "SUBWAY SURFERS", imagePath: 'assets/images/level13/subway.webp', logoColor: Colors.blue, keyboard: ['F', 'W', 'S', 'E', 'A', 'B', 'Y', 'S', 'S', 'U', 'R', 'U', 'I', 'R']),
    374: LevelData(ans: "סוליטר", imagePath: 'assets/images/level13/soliter.webp', logoColor: Colors.green, keyboard: ['ר', 'כ', 'ף', 'ז', 'כ', 'פ', 'י', 'ל', 'ו', 'ס', 'ן', 'ה', 'ט', 'נ']),
    375: LevelData(ans: "JETPACK JOYRIDE", imagePath: 'assets/images/level13/123.webp', logoColor: Colors.orange, keyboard: ['C', 'T', 'K', 'J', 'I', 'A', 'R', 'P', 'E', 'D', 'E', 'O', 'J', 'Y']),
    376: LevelData(ans: "מאבריקס", imagePath: 'assets/images/level14/dallas.webp', logoColor: Colors.blue, keyboard: ['ס', 'כ', 'ץ', 'ת', 'ן', 'ק', 'מ', 'י', 'צ', 'ל', 'ב', 'ך', 'ר', 'א']),
    377: LevelData(ans: "קליפרס", imagePath: 'assets/images/level14/clippers.webp', logoColor: Colors.red, keyboard: ['ב', 'ם', 'י', 'ת', 'ר', 'ז', 'צ', 'ק', 'ל', 'ס', 'ע', 'ם', 'פ', 'ם']),
    378: LevelData(ans: "קאבלירס", imagePath: 'assets/images/level14/cleveland.webp', logoColor: Colors.brown, keyboard: ['ץ', 'ל', 'מ', 'ק', 'ר', 'י', 'ה', 'א', 'ד', 'ף', 'ב', 'ס', 'כ', 'ט']),
    379: LevelData(ans: "בולס", imagePath: 'assets/images/level14/chicago.webp', logoColor: Colors.red, keyboard: ['ו', 'ש', 'צ', 'מ', 'ל', 'י', 'ט', 'ק', 'ז', 'י', 'ב', 'ס', 'ף', 'ג']),
    380: LevelData(ans: "נטס", imagePath: 'assets/images/level14/broklyn.webp', logoColor: Colors.black, keyboard: ['ן', 'ע', 'ו', 'ר', 'נ', 'ט', 'ת', 'ו', 'ת', 'ץ', 'ם', 'ף', 'ס', 'כ']),
    381: LevelData(ans: "סלטיקס", imagePath: 'assets/images/level14/boston.webp', logoColor: Colors.green, keyboard: ['צ', 'י', 'ל', 'ט', 'ק', 'ת', 'ז', 'ס', 'צ', 'כ', 'ס', 'ז', 'פ', 'ן']),
    382: LevelData(ans: "ספרס", imagePath: 'assets/images/level14/austin.webp', logoColor: Colors.blueGrey, keyboard: ['ם', 'ס', 'ט', 'ר', 'נ', 'י', 'ף', 'פ', 'ק', 'ק', 'ס', 'א', 'י', 'צ']),
    383: LevelData(ans: "סיקסרס", imagePath: 'assets/images/level14/76.webp', logoColor: Colors.blue, keyboard: ['ה', 'ק', 'ס', 'ס', 'ט', 'נ', 'י', 'ס', 'מ', 'מ', 'ו', 'ש', 'ר', 'ו']),
    384: LevelData(ans: "באקס", imagePath: 'assets/images/level14/22.webp', logoColor: Colors.green, keyboard: ['א', 'ז', 'ד', 'י', 'י', 'ל', 'ט', 'ס', 'ב', 'ג', 'ה', 'ט', 'ר', 'ק']),
    385: LevelData(ans: "ראפטורס", imagePath: 'assets/images/level14/toronto.webp', logoColor: Colors.red, keyboard: ['ל', 'ר', 'י', 'מ', 'פ', 'ו', 'א', 'ט', 'ס', 'ם', 'ח', 'ר', 'ד', 'ן']),
    386: LevelData(ans: "סאנז", imagePath: 'assets/images/level14/sun.webp', logoColor: Colors.orange, keyboard: ['ר', 'ג', 'ת', 'ס', 'כ', 'צ', 'ו', 'נ', 'א', 'כ', 'כ', 'ת', 'ז', 'ד']),
    387: LevelData(ans: "נאגטס", imagePath: 'assets/images/level14/nuggets.webp', logoColor: Colors.indigo, keyboard: ['ט', 'ז', 'ד', 'כ', 'צ', 'ע', 'נ', 'ג', 'ף', 'ס', 'א', 'י', 'ז', 'ץ']),
    388: LevelData(ans: "היט", imagePath: 'assets/images/level14/miami.webp', logoColor: Colors.red, keyboard: ['ן', 'ת', 'א', 'ז', 'נ', 'י', 'ח', 'ס', 'ו', 'ב', 'פ', 'ק', 'ט', 'ה']),
    389: LevelData(ans: "לייקרס", imagePath: 'assets/images/level14/lakers.webp', logoColor: Colors.purple, keyboard: ['ף', 'י', 'ו', 'ר', 'י', 'א', 'ס', 'ל', 'צ', 'ד', 'ף', 'כ', 'ז', 'ק']),
    390: LevelData(ans: "ניקס", imagePath: 'assets/images/level14/knicks.webp', logoColor: Colors.blue, keyboard: ['ס', 'פ', 'ך', 'ץ', 'א', 'מ', 'ל', 'נ', 'י', 'ב', 'ג', 'פ', 'ן', 'ק']),
    391: LevelData(ans: "רוקטס", imagePath: 'assets/images/level14/houston.webp', logoColor: Colors.red, keyboard: ['ש', 'י', 'ס', 'א', 'ק', 'א', 'א', 'ר', 'י', 'ט', 'צ', 'מ', 'ו', 'א']),
    392: LevelData(ans: "הורנטס", imagePath: 'assets/images/level14/char.webp', logoColor: Colors.deepPurple, keyboard: ['נ', 'ס', 'ר', 'ט', 'ם', 'ה', 'ד', 'ה', 'ש', 'ח', 'א', 'ט', 'ו', 'ח']),
    393: LevelData(ans: "הוקס", imagePath: 'assets/images/level14/altn.webp', logoColor: Colors.red, keyboard: ['ש', 'ך', 'ס', 'ח', 'נ', 'צ', 'ו', 'ק', 'ז', 'ך', 'ק', 'ה', 'ס', 'צ']),
    394: LevelData(ans: "גריזליס", imagePath: 'assets/images/level14/memphis.webp', logoColor: Colors.indigo, keyboard: ['ב', 'ג', 'ז', 'י', 'ף', 'י', 'ל', 'ל', 'ר', 'ס', 'ר', 'ל', 'ד', 'ט']),
    395: LevelData(ans: "קינגס", imagePath: 'assets/images/level14/kings.webp', logoColor: Colors.deepPurple, keyboard: ['ן', 'ק', 'ג', 'ת', 'ג', 'י', 'ח', 'נ', 'ך', 'ב', 'ס', 'ג', 'י', 'ח']),
    396: LevelData(ans: "פיסטונס", imagePath: 'assets/images/level14/detroit.webp', logoColor: Colors.blue, keyboard: ['ו', 'ס', 'ם', 'ו', 'י', 'פ', 'ח', 'נ', 'ט', 'ש', 'צ', 'ו', 'ס', 'ר']),
    397: LevelData(ans: "ויזארדס", imagePath: 'assets/images/level14/wizards.webp', logoColor: Colors.red, keyboard: ['ו', 'ד', 'א', 'ג', 'ז', 'ך', 'י', 'ר', 'ז', 'כ', 'ז', 'ס', 'ט', 'ק']),
    398: LevelData(ans: "פייסרס", imagePath: 'assets/images/level14/parcers.webp', logoColor: Colors.amber, keyboard: ['ג', 'מ', 'ח', 'ס', 'ר', 'ל', 'ס', 'פ', 'ק', 'ה', 'י', 'י', 'פ', 'ע']),
    // 🆕 רמה 15: "יחידות בצה"ל וכוחות הביטחון" - 37 שלבים (399-435).
    // ⚠️ שמות התשובות נכתבו בלי גרשיים/מירכאות (למשל "שבס" ולא "שב"ס") כי
    // מנגנון הניחוש עובד אות-אחר-אות מול לוח מקשים, וסימני פיסוק לא היו
    // קיימים באף תשובה קודמת במשחק - בדיוק כמו שהמשתמש עצמו כתב "שבס"/"שבכ".
    399: LevelData(ans: "איסוף קרבי", imagePath: 'assets/images/level15/eisof.webp', logoColor: Colors.green.shade800, keyboard: ['ח', 'ט', 'ף', 'ש', 'ק', 'ב', 'א', 'ר', 'ד', 'י', 'י', 'א', 'ס', 'ו']),
    400: LevelData(ans: "אגוז", imagePath: 'assets/images/level15/egoz.webp', logoColor: Colors.red, keyboard: ['ח', 'ז', 'ס', 'נ', 'א', 'צ', 'ג', 'ק', 'צ', 'ז', 'ש', 'ו', 'א', 'ט']),
    401: LevelData(ans: "דובדבן", imagePath: 'assets/images/level15/dovdevan.webp', logoColor: Colors.blueGrey, keyboard: ['ב', 'ב', 'ל', 'צ', 'ד', 'ד', 'ס', 'ד', 'ן', 'ט', 'ב', 'ר', 'ו', 'ל']),
    402: LevelData(ans: "תקשוב", imagePath: 'assets/images/level15/comp.webp', logoColor: Colors.indigo, keyboard: ['ד', 'ת', 'ל', 'ט', 'ל', 'מ', 'ס', 'ו', 'ש', 'ק', 'ב', 'ש', 'ו', 'ח']),
    403: LevelData(ans: "בהד 13", imagePath: 'assets/images/level15/bhd13.webp', logoColor: Colors.brown, keyboard: ['3', 'ח', 'ב', 'ד', 'ה', 'ט', 'כ', 'כ', 'ב', 'ג', 'ת', 'מ', 'ב', '1']),
    404: LevelData(ans: "אמן", imagePath: 'assets/images/level15/aman.webp', logoColor: Colors.teal, keyboard: ['ט', 'ל', 'ק', 'פ', 'צ', 'ח', 'צ', 'ק', 'מ', 'ן', 'ה', 'א', 'מ', 'נ']),
    405: LevelData(ans: "חיל האוויר", imagePath: 'assets/images/level15/airforce.webp', logoColor: Colors.lightBlue, keyboard: ['ו', 'פ', 'ח', 'ת', 'י', 'ה', 'ל', 'א', 'ו', 'א', 'ר', 'ט', 'י', 'צ']),
    406: LevelData(ans: "חטיבה 35", imagePath: 'assets/images/level15/35.webp', logoColor: Colors.red.shade900, keyboard: ['י', 'ט', '5', 'פ', 'ש', 'ש', 'ה', 'ח', 'ד', '3', 'י', 'ב', 'פ', 'ו']),
    // ⚠️ שם הקובץ המקורי שקיבלתי לא היה קריא (הוצג כ-"__.webp") - צריך
    // לשנות את שם הקובץ אצלך ל-merkaz.webp לפני שמכניסים אותו לתיקיית
    // ה-assets, אחרת הנתיב כאן לא ימצא את הקובץ.
    407: LevelData(ans: "פיקוד מרכז", imagePath: 'assets/images/level15/merkaz.webp', logoColor: Colors.deepPurple, keyboard: ['פ', 'ח', 'ד', 'ר', 'ו', 'מ', 'י', 'ק', 'ז', 'ח', 'כ', 'ב', 'ק', 'י']),
    408: LevelData(ans: "קומנדו", imagePath: 'assets/images/level15/komando.webp', logoColor: Colors.black, keyboard: ['ש', 'ו', 'ז', 'ת', 'ד', 'ק', 'מ', 'מ', 'י', 'נ', 'ו', 'ל', 'ז', 'צ']),
    409: LevelData(ans: "צהל", imagePath: 'assets/images/level15/idf.webp', logoColor: Colors.blue.shade900, keyboard: ['ח', 'ב', 'צ', 'ב', 'ש', 'פ', 'ה', 'ג', 'ל', 'ג', 'א', 'ח', 'כ', 'ג']),
    410: LevelData(ans: "חיל החינוך", imagePath: 'assets/images/level15/hinoch.webp', logoColor: Colors.orange.shade800, keyboard: ['ה', 'נ', 'ח', 'ת', 'ך', 'ל', 'י', 'נ', 'נ', 'י', 'נ', 'ח', 'ל', 'ו']),
    411: LevelData(ans: "חטיבה 900", imagePath: 'assets/images/level15/hativa900.webp', logoColor: Colors.deepOrange, keyboard: ['ס', 'י', 'ו', '0', 'ה', 'ה', '9', 'ח', 'נ', 'צ', 'ט', 'ט', 'ב', '0']),
    412: LevelData(ans: "חיל התותחנים", imagePath: 'assets/images/level15/hataman.webp', logoColor: Colors.deepPurple.shade700, keyboard: ['נ', 'י', 'ת', 'ו', 'ח', 'ע', 'ם', 'י', 'נ', 'ע', 'ל', 'ח', 'ת', 'ה']),
    413: LevelData(ans: "חיל ההנדסה", imagePath: 'assets/images/level15/handasa.webp', logoColor: Colors.orange, keyboard: ['ה', 'ס', 'נ', 'ל', 'ד', 'ה', 'ה', 'ח', 'ל', 'ב', 'ס', 'י', 'ה', 'י']),
    414: LevelData(ans: "גולני", imagePath: 'assets/images/level15/golani.webp', logoColor: Colors.purple, keyboard: ['נ', 'ק', 'ה', 'ו', 'ז', 'י', 'ב', 'ל', 'צ', 'ז', 'י', 'ב', 'כ', 'ג']),
    415: LevelData(ans: "גבעתי", imagePath: 'assets/images/level15/givati.webp', logoColor: Colors.purple.shade800, keyboard: ['ג', 'י', 'ת', 'מ', 'ק', 'ר', 'ע', 'ת', 'ד', 'ב', 'ח', 'ח', 'ב', 'ק']),
    416: LevelData(ans: "כבאות והצלה", imagePath: 'assets/images/level15/fighters.webp', logoColor: Colors.red.shade700, keyboard: ['ו', 'ש', 'ה', 'א', 'ה', 'ה', 'ת', 'ל', 'ת', 'י', 'כ', 'ב', 'ו', 'צ']),
    417: LevelData(ans: "פיקוד דרום", imagePath: 'assets/images/level15/padam.webp', logoColor: Colors.brown.shade700, keyboard: ['ר', 'י', 'ו', 'ו', 'ק', 'ח', 'ד', 'פ', 'י', 'ג', 'ד', 'ל', 'ם', 'ו']),
    418: LevelData(ans: "עוקץ", imagePath: 'assets/images/level15/oketz.webp', logoColor: Colors.black,keyboard: ['ו', 'כ', 'צ', 'ק', 'ץ', 'ד', 'י', 'ע', 'ז', 'ה', 'ט', 'ד', 'ז', 'ר']),
    419: LevelData(ans: "נחל", imagePath: 'assets/images/level15/nhal.webp', logoColor: Colors.green, keyboard: ['ט', 'ה', 'נ', 'ו', 'צ', 'ד', 'כ', 'א', 'ש', 'נ', 'ס', 'ל', 'צ', 'ח']),
    420: LevelData(ans: "מוסד", imagePath: 'assets/images/level15/mosad.webp', logoColor: Colors.blueGrey.shade900, keyboard: ['ת', 'ח', 'ל', 'ר', 'ד', 'ז', 'ו', 'מ', 'ת', 'ל', 'נ', 'ד', 'ס', 'צ']),
    421: LevelData(ans: "משמר הגבול", imagePath: 'assets/images/level15/mishmar.webp', logoColor: Colors.green.shade700, keyboard: ['ט', 'ו', 'מ', 'מ', 'ל', 'ש', 'ב', 'ה', 'ג', 'מ', 'ד', 'ר', 'ו', 'ב']),
    422: LevelData(ans: "משטרת ישראל", imagePath: 'assets/images/level15/mis.webp', logoColor: Colors.blue.shade800, keyboard: ['ר', 'ר', 'ג', 'ש', 'ט', 'ל', 'מ', 'כ', 'ש', 'א', 'מ', 'י', 'ת', 'ט']),
    423: LevelData(ans: "מדא", imagePath: 'assets/images/level15/mda.webp', logoColor: Colors.red.shade800, keyboard: ['פ', 'ד', 'ר', 'מ', 'כ', 'ל', 'א', 'ד', 'ר', 'נ', 'מ', 'ד', 'ב', 'נ']),
    424: LevelData(ans: "מגלן", imagePath: 'assets/images/level15/maglan.webp', logoColor: Colors.teal.shade800, keyboard: ['ת', 'ד', 'ג', 'י', 'מ', 'פ', 'כ', 'ת', 'מ', 'נ', 'י', 'ן', 'ל', 'י']),
    425: LevelData(ans: "חיל הלוגיסטיקה", imagePath: 'assets/images/level15/logist.webp', logoColor: Colors.amber.shade800, keyboard: ['ל', 'ח', 'ל', 'ג', 'י', 'ק', 'ה', 'ס', 'י', 'ו', 'י', 'נ', 'ט', 'ה']),
    426: LevelData(ans: "יהלום", imagePath: 'assets/images/level15/yahalom.webp', logoColor: Colors.blueGrey.shade700, keyboard: ['ל', 'ת', 'י', 'ג', 'ת', 'י', 'ה', 'פ', 'ר', 'ם', 'ש', 'ו', 'כ', 'ג']),
    427: LevelData(ans: "חיל הים", imagePath: 'assets/images/level15/water.webp', logoColor: Colors.blue, keyboard: ['ש', 'ע', 'מ', 'נ', 'י', 'ם', 'ק', 'מ', 'ס', 'י', 'ח', 'ז', 'ל', 'ה']),
    428: LevelData(ans: "שלדג", imagePath: 'assets/images/level15/shaldag.webp', logoColor: Colors.grey.shade800, keyboard: ['ד', 'ל', 'ש', 'ס', 'צ', 'ג', 'ס', 'ד', 'ס', 'כ', 'ה', 'ת', 'ר', 'פ']),
    429: LevelData(ans: "שבס", imagePath: 'assets/images/level15/shabas.webp', logoColor: Colors.blueGrey.shade600, keyboard: ['ט', 'ג', 'ע', 'ש', 'ט', 'ח', 'כ', 'ח', 'פ', 'י', 'ס', 'ב', 'ס', 'ש']),
    // ⚠️ שם הקובץ המקורי היה "shabas (1).webp" (עם רווח וסוגריים) - צריך
    // לשנות אצלך את שם הקובץ ל-shabak.webp לפני שמכניסים אותו לתיקיית
    // ה-assets, כי רווחים/סוגריים בשמות קבצים עלולים לגרום לבעיות.
    430: LevelData(ans: "שבכ", imagePath: 'assets/images/level15/shabak.webp', logoColor: Colors.blueGrey.shade900, keyboard: ['כ', 'ק', 'כ', 'ב', 'א', 'מ', 'נ', 'ז', 'ק', 'צ', 'ס', 'ש', 'ב', 'נ']),
    431: LevelData(ans: "סיירת מטכל", imagePath: 'assets/images/level15/sayeret.webp', logoColor: Colors.black, keyboard: ['י', 'מ', 'ל', 'ר', 'ס', 'ע', 'ת', 'ט', 'כ', 'י', 'ט', 'א', 'נ', 'מ']),
    432: LevelData(ans: "חיל הרפואה", imagePath: 'assets/images/level15/refua.webp', logoColor: Colors.red.shade600, keyboard: ['ה', 'נ', 'י', 'ג', 'ה', 'ש', 'ס', 'א', 'ה', 'פ', 'ו', 'ר', 'ח', 'ל']),
    433: LevelData(ans: "פיקוד העורף", imagePath: 'assets/images/level15/pikod.webp', logoColor: Colors.orange.shade700, keyboard: ['ע', 'ק', 'ד', 'א', 'ו', 'ע', 'ף', 'ר', 'צ', 'י', 'ג', 'ו', 'ה', 'פ']),
    434: LevelData(ans: "פיקוד צפון", imagePath: 'assets/images/level15/pazan.webp', logoColor: Colors.indigo.shade700, keyboard: ['ו', 'פ', 'ן', 'ת', 'ק', 'פ', 'ז', 'ע', 'י', 'ק', 'צ', 'ד', 'ד', 'ו']),
    435: LevelData(ans: "יאמם", imagePath: 'assets/images/level15/yamam.webp', logoColor: Colors.black, keyboard: ['ם', 'ר', 'מ', 'ק', 'ד', 'מ', 'י', 'ג', 'ש', 'ז', 'י', 'ח', 'א', 'ת']),

    // ===== רמה 16: רכבים חלק ב' =====
    436: LevelData(ans: "דאציה", imagePath: 'assets/images/level16/dacia.webp', logoColor: Colors.grey.shade700, keyboard: ['ה', 'י', 'צ', 'ח', 'ש', 'ת', 'א', 'ד', 'ד', 'ד', 'ח', 'א', 'ט', 'ה']),
    437: LevelData(ans: "קרייזלר", imagePath: 'assets/images/level16/crys.webp', logoColor: Colors.grey.shade700, keyboard: ['נ', 'י', 'ח', 'צ', 'ט', 'ש', 'ר', 'ס', 'ז', 'ל', 'ר', 'י', 'ק', 'ק']),
    438: LevelData(ans: "CHERY", imagePath: 'assets/images/level16/chery.webp', logoColor: Colors.grey.shade700, keyboard: ['E', 'Z', 'T', 'X', 'O', 'C', 'B', 'R', 'L', 'Y', 'I', 'R', 'L', 'H']),
    439: LevelData(ans: "BYD", imagePath: 'assets/images/level16/byd.webp', logoColor: Colors.grey.shade700, keyboard: ['I', 'B', 'L', 'U', 'M', 'O', 'L', 'H', 'D', 'Y', 'G', 'L', 'D', 'F']),
    440: LevelData(ans: "ביואיק", imagePath: 'assets/images/level16/buick.webp', logoColor: Colors.grey.shade700, keyboard: ['י', 'ב', 'ב', 'ו', 'ט', 'כ', 'ב', 'ת', 'כ', 'מ', 'ק', 'ח', 'א', 'י']),
    441: LevelData(ans: "בוגאטי", imagePath: 'assets/images/level16/buggati.webp', logoColor: Colors.grey.shade700, keyboard: ['ט', 'ק', 'מ', 'ל', 'צ', 'י', 'נ', 'ק', 'ב', 'ו', 'צ', 'ט', 'ג', 'א']),
    442: LevelData(ans: "אסטון מרטין", imagePath: 'assets/images/level16/astonmartin.webp', logoColor: Colors.grey.shade700, keyboard: ['ו', 'ט', 'ן', 'מ', 'ט', 'מ', 'ר', 'ר', 'מ', 'ס', 'א', 'ס', 'ן', 'י']),
    443: LevelData(ans: "פולסטאר", imagePath: 'assets/images/level16/artboard.webp', logoColor: Colors.grey.shade700, keyboard: ['א', 'א', 'ר', 'פ', 'פ', 'פ', 'ו', 'ל', 'ס', 'ס', 'ו', 'ט', 'ט', 'ו']),
    444: LevelData(ans: "אקורה", imagePath: 'assets/images/level16/acura.webp', logoColor: Colors.grey.shade700, keyboard: ['א', 'ח', 'ה', 'א', 'ר', 'ע', 'י', 'ו', 'ל', 'ח', 'ד', 'ב', 'ק', 'ק']),
    445: LevelData(ans: "לנד רובר", imagePath: 'assets/images/level16/landrover.webp', logoColor: Colors.grey.shade700, keyboard: ['י', 'ו', 'ש', 'ז', 'ר', 'ד', 'ל', 'מ', 'ר', 'נ', 'ת', 'צ', 'ז', 'ב']),
    446: LevelData(ans: "קיה", imagePath: 'assets/images/level16/kia.webp', logoColor: Colors.grey.shade700, keyboard: ['ח', 'ב', 'ק', 'ב', 'ש', 'פ', 'י', 'ג', 'ה', 'ג', 'א', 'ח', 'כ', 'ג']),
    447: LevelData(ans: "JEEP", imagePath: 'assets/images/level16/jeep.webp', logoColor: Colors.grey.shade700, keyboard: ['E', 'O', 'B', 'N', 'V', 'U', 'N', 'P', 'V', 'N', 'L', 'J', 'E', 'X']),
    448: LevelData(ans: "אינפיניטי", imagePath: 'assets/images/level16/infinity.webp', logoColor: Colors.grey.shade700, keyboard: ['י', 'נ', 'י', 'פ', 'נ', 'ט', 'ג', 'ו', 'ס', 'א', 'י', 'י', 'ח', 'ט']),
    449: LevelData(ans: "GMC", imagePath: 'assets/images/level16/gmc.webp', logoColor: Colors.grey.shade700, keyboard: ['M', 'B', 'Z', 'O', 'G', 'M', 'I', 'G', 'C', 'M', 'A', 'Z', 'F', 'M']),
    450: LevelData(ans: "GENESIS", imagePath: 'assets/images/level16/genesis.webp', logoColor: Colors.grey.shade700, keyboard: ['S', 'I', 'P', 'Q', 'S', 'F', 'B', 'E', 'S', 'Q', 'N', 'E', 'B', 'G']),
    451: LevelData(ans: "DODGE", imagePath: 'assets/images/level16/doge.webp', logoColor: Colors.grey.shade700, keyboard: ['V', 'D', 'N', 'S', 'D', 'K', 'O', 'C', 'E', 'I', 'T', 'Q', 'S', 'G']),
    452: LevelData(ans: "דטסון", imagePath: 'assets/images/level16/datsun.webp', logoColor: Colors.grey.shade700, keyboard: ['ס', 'ד', 'ק', 'ז', 'ר', 'ד', 'ג', 'פ', 'צ', 'ו', 'ט', 'א', 'ס', 'ן']),
    453: LevelData(ans: "דייהו", imagePath: 'assets/images/level16/daewoo.webp', logoColor: Colors.grey.shade700, keyboard: ['ד', 'ד', 'צ', 'ד', 'ד', 'י', 'י', 'ת', 'ה', 'ה', 'ו', 'י', 'ת', 'ט']),
    454: LevelData(ans: "פולקסווגן", imagePath: 'assets/images/level16/volskswagen.webp', logoColor: Colors.grey.shade700, keyboard: ['ו', 'ן', 'ו', 'ב', 'ק', 'ט', 'ג', 'ג', 'נ', 'ס', 'ש', 'ל', 'ו', 'פ']),
    455: LevelData(ans: "סאנגיונג", imagePath: 'assets/images/level16/ssnay.webp', logoColor: Colors.grey.shade700, keyboard: ['ג', 'ק', 'צ', 'ג', 'ה', 'א', 'ל', 'ב', 'ו', 'י', 'ס', 'צ', 'נ', 'נ']),
    456: LevelData(ans: "רולס רויס", imagePath: 'assets/images/level16/rools.webp', logoColor: Colors.grey.shade700, keyboard: ['ו', 'ה', 'ס', 'ר', 'נ', 'ח', 'ו', 'ר', 'ס', 'י', 'ו', 'ו', 'ל', 'ר']),
    457: LevelData(ans: "MG", imagePath: 'assets/images/level16/mg.webp', logoColor: Colors.grey.shade700, keyboard: ['Z', 'V', 'G', 'M', 'H', 'A', 'H', 'J', 'H', 'M', 'G', 'G', 'O', 'L']),
    458: LevelData(ans: "מקלארן", imagePath: 'assets/images/level16/mclaren.webp', logoColor: Colors.grey.shade700, keyboard: ['ד', 'ל', 'מ', 'ל', 'ק', 'ר', 'א', 'ק', 'ט', 'ב', 'ו', 'ן', 'נ', 'ר']),
  };

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("אין פרסומת זמינה כרגע, נסה שוב עוד רגע 🎬", textDirection: TextDirection.rtl),
          backgroundColor: Colors.deepPurple,
        ),
      );
    }
  }

  // 💸 חלון "אין מספיק מטבעות": קפיצה מעל המשחק עם אפשרות לקנות
  // או לצפות בפרסומת תמורת רמז (החיבור ל-AdMob יתווסף בהמשך)
  void _showNotEnoughCoinsDialog(int cost) {
    // 🔴 אותו תיקון כמו בתפריט הרמזים: מבטלים את טיימר "תקוע?" (ולא רק
    // מסתירים את הבועית הנוכחית) - אחרת הוא עלול "לירות" תוך כדי שהחלון
    // הזה פתוח וליצור בועית חדשה שצפה מעליו.
    _stuckHintTimer?.cancel();
    _hideStuckTipOverlay();
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopScreen()))
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
    _clearHintState(currentPuzzleId); // החידה נפתרה - אין יותר צורך לזכור אילו רמזים שימשו בה

    if (widget.isRandomMode) {
      // במצב רנדומלי שומרים את החידה כפתורה בנפרד (לא נוגעים בהתקדמות הרגילה)
      await _markRandomSolved(currentPuzzleId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('randomStreak', randomStreak); // הרצף נשמר גם אחרי יציאה
      await prefs.setInt('bestRandomStreak', bestRandomStreak);
      if (newStreakRecord && bestRandomStreak >= 3 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🔥 שיא רצף חדש: $bestRandomStreak!", textDirection: TextDirection.rtl),
            backgroundColor: Colors.deepOrange,
            duration: const Duration(seconds: 2),
          ),
        );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "זוהה צילום מסך נוסף - עוברים לשלב הבא 🚫📸",
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
        backgroundColor: Color(0xFFB91C1C),
        duration: Duration(seconds: 4),
      ),
    );
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