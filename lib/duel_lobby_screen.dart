// duel_lobby_screen.dart
//
// מסך "מחפש יריב" - נכנסים אליו כשלוחצים על "דו-קרב" מהתפריט הראשי.
// קורא ל-DuelService.findMatch() ומטפל בכל התוצאות האפשריות:
//   - matched          -> עובר אוטומטית למסך חדר הדו-קרב (DuelRoomScreen)
//   - noPlayersFound    -> מציג הודעה "אין כרגע שחקנים מחוברים" + כפתור ניסיון חוזר
//   - cancelled/error   -> חוזר למסך הקודם / מציג הודעת שגיאה ידידותית

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:shared_preferences/shared_preferences.dart';
import 'duel_service.dart';
import 'duel_room_screen.dart';
import 'level_data.dart';
import 'device_id.dart';
import 'app_background.dart';
import 'energy_service.dart';
import 'ads_manager.dart';
import 'leaderboard.dart'; // 🆕 מקום/XP אמיתיים למסך "נמצא יריב"
import 'app_icons.dart'; // 🆕 CoinIcon/EnergyIcon - אימוג'י במקום אייקון וקטורי
import 'shop_screen.dart'; // 🆕 כפתור "קנה בחנות" ממסך "נגמרה האנרגיה"
import 'audio_manager.dart'; // 🆕 צליל "נמצא יריב" + הנמכת מוזיקת הרקע
import 'presence_service.dart'; // 🆕 "כמה אנשים משחקים עכשיו" - נקודה ירוקה+מספר בתפריט הראשי
import 'reward_popups.dart'; // 🆕 פופאפ "קיבלת אנרגיה" החדש (מסך מלא, לפי המוקאפ)
import 'main_menu_screen.dart'; // 🩹 MainMenuScreen.onReturnedHome - לרענון מיידי של המטבעות/אנרגיה במסך הבית
import 'debug_log.dart'; // 🩹 DebugLog.reportError - דיווח שגיאות matchmaking אמיתיות ל-Firestore לצורך אבחון

enum _LobbyState { checking, banned, notEnoughEnergy, notEnoughCoins, selectingStake, searching, found, noPlayers, error }

// 🆕 טיפים קצרים שמתחלפים בזמן החיפוש - כדי שהחיפוש ירגיש פחות "מת"
// וקצת יותר מעניין מרק ספינר סטטי.
const List<String> _searchingTips = [
  "טיפ: כל אחד עונה בקצב שלו - מי שמסיים ראשון את 10 הלוגואים מנצח",
  "טיפ: אפשר לקנות רמז זול במיוחד בתוך הדו-קרב אם נתקעים",
  "טיפ: המנצח לוקח את כל קופת המטבעות של שני השחקנים",
  "טיפ: אין אינטרנט טוב ליריב? הוא יחזור לתור אחרי שנייה",
  "טיפ: תרגלו במצב הרגיל כדי להכיר יותר לוגואים לפני דו-קרב",
];

class DuelLobbyScreen extends StatefulWidget {
  final String username;
  // 🆕 הימור שכבר נבחר מראש לפני שהגענו למסך הזה (ראה main_menu_screen.dart
  // - _showPlayVsPersonFlow, כרטיס "משחק נגד שחקן אחר" המאוחד) - אם קיים
  // ותקין (מופיע ב-DuelService.stakeOptions ויש מספיק מטבעות), מדלגים
  // ישר לחיפוש יריב בלי להציג שוב את בורר ההימור של המסך הזה. אם null
  // (או לא תקין/לא ניתן להרשות) - מתנהג בדיוק כמו קודם (מציג את הבורר).
  final int? initialStake;
  const DuelLobbyScreen({super.key, required this.username, this.initialStake});

  @override
  State<DuelLobbyScreen> createState() => _DuelLobbyScreenState();
}

class _DuelLobbyScreenState extends State<DuelLobbyScreen> with TickerProviderStateMixin {
  final DuelService _duelService = DuelService();
  _LobbyState _state = _LobbyState.checking;
  String? _errorText;
  String? _myDeviceId;
  String? _foundMatchId;
  // 🩹 ראו הערה מפורטת ב-_enterRoom - מונע מ-dispose() לעצור את
  // PresenceService בטעות ברגע שנכנסים בפועל לחדר הדו-קרב.
  bool _enteringRoom = false;
  String? _opponentName;
  String? _opponentId;
  int _coins = 0;
  int _energy = 0;
  int? _selectedStake;
  // 🆕 בורר ההימור עבר להיות bottom sheet אמיתי (showModalBottomSheet)
  // במקום החלפת state מלאה בתוך אותו Scaffold - ראו _openStakeSheet.
  // הדגל הזה מסמן שבפועל נבחרה רמת הימור בתוך הגליון (ולא רק שהגליון
  // נסגר מעצמו בגרירה/הקשה על הרקע), כדי לדעת אם לפרש סגירה של הגליון
  // כ"ביטול" (בדיוק כמו שכפתור "ביטול" הישן עשה) או לא.
  bool _stakeChosen = false;
  // 🩹 קריסה אדומה ("Failed assertion... check that it really is our
  // descendant... is not true") שקרתה "בכניסה למשחק" - שורש הבעיה:
  // onTap בתוך הגליון קרא ל-Navigator.pop(sheetContext) ומיד אחר כך,
  // באותה נשימה, ל-_onStakeSelected(stake) שעושה setState על מסך
  // הלובי (עובר ל-_LobbyState.searching, בונה תת-עץ שונה לגמרי) -
  // בזמן שהגליון עדיין באמצע אנימציית הסגירה שלו (טרם הושלמה בפועל).
  // לבנות מחדש את העץ שמתחת לגליון תוך כדי שהגליון (שתלוי באלמנטים
  // באותו עץ) עדיין באמצע מעבר - זה בדיוק התרחיש שגורם ל-Flutter
  // לאבד את שרשרת ה-ancestor ולהיכשל ב-assertion הזה. התיקון: לא
  // קוראים ל-_onStakeSelected ישירות מתוך ה-onTap בגליון - רק שומרים
  // את הבחירה (_pendingStake) וסוגרים את הגליון, ורק אחרי שה-await של
  // showModalBottomSheet ב-_openStakeSheet מחזיר בפועל (סימן שהגליון
  // באמת נסגר לגמרי, לא רק שהתחיל להיסגר) - רק אז קוראים בפועל
  // ל-_onStakeSelected. ראו _openStakeSheet/_stakeOption למטה.
  int? _pendingStake;
  // 🆕 סטטיסטיקות אמיתיות למסך "נמצא יריב" (מוקאפ Opponent Found) -
  // נטענות ברקע אחרי שנמצא יריב ולא חוסמות את הצגת המסך עצמו.
  int? _myRank;
  int? _myXp;
  int? _oppRank;
  int? _oppXp;
  int _myWins = 0;
  int _oppWins = 0;
  int _h2hMine = 0;
  int _h2hTheirs = 0;
  // 🆕 ספירה לאחור אמיתית (לא רק עיכוב קבוע) לפני שנכנסים בפועל לחדר -
  // בדיוק כמו "הדו־קרב מתחיל בעוד" במוקאפ.
  int _readyCountdown = 3;
  Timer? _readyTimer;
  StreamSubscription<DuelMatch>? _foundMatchSub;
  // 🆕 חסימה זמנית עקב יציאה חוזרת באמצע דו-קרב - ראו applyForfeitPenalty
  DateTime? _banUntil;
  late final AnimationController _pulseController;
  // 🆕 סיבוב "מכ״ם" רציף מאחורי העיגול המרכזי - יוצר תחושה של "מחפש"
  // אמיתית, לא רק פעימה סטטית.
  late final AnimationController _radarController;
  Timer? _tipTimer;
  int _tipIndex = 0;
  // 🆕 שניות שחלפו מתחילת החיפוש - לתצוגת "מחפש יריב… 0:07" חיה,
  // בדיוק כמו בעיצוב שסופק.
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    // 🆕 לובי הדו-קרב (עוד לא נכנסים בפועל למשחק) נחשב "גלישה" - הכניסה
    // האמיתית ל"שיחק" קורית ב-DuelRoomScreen.initState (AdsManager.recordGameEntered).
    AdsManager.recordBrowseNavigation();
    _loadRequirementsThenPickStake();
  }

  // 🆕 טוענים אנרגיה+מטבעות ומחליטים מה להציג: אם אין בכלל אנרגיה -
  // אין טעם אפילו להראות את בחירת ההימור. אם יש אנרגיה אבל אין מספיק
  // מטבעות אפילו לרמה הזולה ביותר - גם כן חוסמים לפני הבחירה. אחרת -
  // מציגים את מסך בחירת ההימור (עם רמות שלא ניתן להרשות מסומנות ככה).
  Future<void> _loadRequirementsThenPickStake() async {
    setState(() => _state = _LobbyState.checking);

    // 🆕 קודם כל בודקים אם השחקן חסום זמנית (עזב באמצע דו-קרב יותר
    // מפעם אחת) - אם כן, אין טעם אפילו לבדוק אנרגיה/מטבעות.
    final deviceId = await DeviceId.get();
    _myDeviceId = deviceId;
    if (!mounted) return;
    // 🆕 "כמה אנשים משחקים עכשיו בדו-קרב" - ראו presence_service.dart.
    // ⚠️ מגבלה ידועה: duel_room_screen.dart הוא קובץ "לא לגעת" בפרויקט
    // הזה, אז הפעימה רצה רק כל עוד המסך הזה (הלובי) פתוח - בחירת הימור/
    // חיפוש/נמצא/ספירה לאחור. ברגע שנכנסים בפועל ל-DuelRoomScreen (שם
    // המשחק עצמו קורה) המסך הזה נסגר, ה-dispose שלו עוצר את הפעימה, וזה
    // "מפספס" שחקנים שכבר באמצע דו-קרב פעיל. זו הערכה סבירה, לא ספירה
    // מדויקת - ראו ההערה המלאה ב-presence_service.dart.
    PresenceService.startHeartbeat(deviceId, 'duel');
    final forfeitStatus = await DuelService.getForfeitStatus(deviceId);
    if (!mounted) return;
    if (DuelService.isBanned(forfeitStatus)) {
      setState(() {
        _banUntil = DateTime.fromMillisecondsSinceEpoch(forfeitStatus['banUntilMs'] as int);
        _state = _LobbyState.banned;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt('coins') ?? 15;
    final energy = await EnergyService.getCurrentEnergy();
    if (!mounted) return;

    setState(() {
      _coins = coins;
      _energy = energy;
    });

    if (energy < EnergyService.duelCost) {
      setState(() => _state = _LobbyState.notEnoughEnergy);
      return;
    }
    if (coins < DuelService.stakeOptions.first) {
      setState(() => _state = _LobbyState.notEnoughCoins);
      return;
    }

    // 🆕 אם הגענו לפה עם הימור שכבר נבחר מראש (מהזרימה המאוחדת "משחק
    // נגד שחקן אחר" במסך הבית) - מדלגים ישר לחיפוש בלי להציג שוב את
    // בורר ההימור. בודקים תקינות (קיים ברשימת ההימורים של דו-קרב, ויש
    // מספיק מטבעות) לפני שסומכים עליו - אחרת נופלים חזרה לבורר הרגיל.
    final preselected = widget.initialStake;
    if (preselected != null && DuelService.stakeOptions.contains(preselected) && coins >= preselected) {
      await _onStakeSelected(preselected);
      return;
    }

    setState(() => _state = _LobbyState.selectingStake);
    // 🆕 בורר ההימור עולה כגליון תחתון (bottom sheet אמיתי) שנפתח מעל
    // המסך הנוכחי, ולא כהחלפת state מלאה בתוך אותו Scaffold - כדי שזה
    // יראה ויתנהג כמו bottom sheet אמיתי (רקע מטושטש/מוכהה של המסך
    // הקודם מאחור, החלקה מלמטה כלפי מעלה) - בדיוק כמו שהתבקש.
    _openStakeSheet();
  }

  // 🆕 פותח את בורר ההימור כ-bottom sheet אמיתי (showModalBottomSheet)
  // במקום להציג אותו inline בתוך גוף המסך - כך יש רקע כהה מטושטש עם
  // המסך הקודם מוצג (ומוכהה) מאחורי הגליון, והגליון עצמו מחליק פנימה
  // מלמטה עם אנימציה סטנדרטית, בדיוק כמו bottom sheet אמיתי. אם הגליון
  // נסגר בלי שנבחרה בפועל רמת הימור (גרירה למטה/הקשה על הרקע הכהה) -
  // מתפרש בדיוק כמו שכפתור "ביטול" הישן התנהג: חוזרים אחורה מהלובי.
  Future<void> _openStakeSheet() async {
    _stakeChosen = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (sheetContext) => _buildStakeSheet(sheetContext),
    );
    if (!mounted) return;
    if (_stakeChosen && _pendingStake != null) {
      // 🩹 רק עכשיו, אחרי שהגליון נסגר לגמרי בפועל (ה-await הזה חוזר
      // רק כשה-route של הגליון סיים להיעלם), מפעילים את לוגיקת הבחירה
      // בפועל - ראו הערה מפורטת ליד _pendingStake למעלה.
      await _onStakeSelected(_pendingStake!);
    } else if (!_stakeChosen) {
      Navigator.pop(context);
    }
  }

  // נבחרה רמת הימור - האנרגיה נצרכת כאן (בתחילת החיפוש בפועל), דמי
  // הכניסה עצמם רק כש-*באמת* נמצא יריב (ב-DuelRoomScreen).
  Future<void> _onStakeSelected(int stake) async {
    if (_coins < stake) return;
    _selectedStake = stake;
    await EnergyService.spendForDuel();
    await _startSearch();
  }

  Future<void> _watchAdForEnergy() async {
    // 🆕 קירור אמיתי בין פרסומות-לאנרגיה (פעם ב-2 דקות, ראו
    // EnergyService.timeUntilNextAdEnergy) - אותו תיקון בדיוק כמו
    // main_menu_screen._watchAdForEnergyFromHome, כי זו נקודת כניסה שנייה
    // לאותה מנגנון (אותה אנרגיה, אותה פרסומת).
    final adCooldown = await EnergyService.timeUntilNextAdEnergy();
    if (adCooldown != null) {
      if (!mounted) return;
      final m = adCooldown.inMinutes;
      final s = adCooldown.inSeconds % 60;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("אפשר לצפות בפרסומת נוספת בעוד $m:${s.toString().padLeft(2, '0')} ⏳", textDirection: TextDirection.rtl)),
      );
      return;
    }
    if (!AdsManager.isRewardedReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("אין פרסומת זמינה כרגע, נסה שוב עוד רגע 🎬", textDirection: TextDirection.rtl)),
      );
      return;
    }
    AdsManager.showRewardedAd(onReward: () async {
      await EnergyService.addFromAd();
      final energyNow = await EnergyService.getCurrentEnergy(); // 🆕 ערך מדויק לאחר הזיכוי, לתצוגה בפופאפ
      // 🩹 "האנרגיה/מטבעות לא מתעדכנים במסך הראשי מיד" - מסך הבית עדיין
      // חי מתחת ללובי הזה במחסנית הניווט (לא נסגר), אבל היה מתעדכן רק
      // כשחוזרים אליו בפועל (pop). הקריאה הזו ל-hook הסטטי הקיים
      // (MainMenuScreen.onReturnedHome, כבר מוגדר ב-main_menu_screen.dart
      // אך אף אחד לא קרא לו בפועל עד עכשיו) מרעננת את מסך הבית מיידית.
      MainMenuScreen.onReturnedHome?.call();
      if (!mounted) return;
      // 🩹 הוחלף מדיאלוג הטקסט הישן (_showRewardDialog, עם ⚡ גולמי)
      // בפופאפ המסך-מלא החדש (reward_popups.dart). כפתור ה-CTA ("יאללה,
      // לדו-קרב") הוא זה שממשיך לבחירת ההימור עכשיו (במקום שזה יקרה
      // אוטומטית ברקע מתחת לדיאלוג הישן, בלי תלות בפעולת המשתמש).
      showEnergyRewardPopup(
        context,
        rewardAmount: EnergyService.adRewardAmount,
        currentEnergy: energyNow,
        maxEnergy: EnergyService.maxEnergy,
        onDuelTap: _loadRequirementsThenPickStake,
      );
    });
  }

  void _startTipRotation() {
    _tipTimer?.cancel();
    _tipTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _tipIndex = (_tipIndex + 1) % _searchingTips.length);
    });
  }

  Future<void> _startSearch() async {
    setState(() {
      _state = _LobbyState.searching;
      _elapsedSeconds = 0;
    });
    _startTipRotation();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });

    final deviceId = await DeviceId.get();
    _myDeviceId = deviceId;
    if (!mounted) return;

    final stakeForSearch = _selectedStake ?? DuelService.stakeOptions.first;
    // 🆕 מאגר הלוגואים נבחר לפי רמת ההימור (ראו DuelService.stakeWorlds) -
    // אם משום מה הרשימה יוצאת ריקה (למשל הגדרה שגויה של מספרי רמה),
    // logoIdsForWorlds/logoPoolForStake כבר נופלים חזרה לכל הלוגואים
    // כדי שלעולם לא ייתקע חיפוש על מאגר ריק.
    final worldsForStake = DuelService.stakeWorlds[stakeForSearch];
    final poolIds = worldsForStake != null ? logoIdsForWorlds(worldsForStake) : gameLevels.keys.toList();
    final result = await _duelService.findMatch(
      deviceId: deviceId,
      username: widget.username,
      allLevelIds: poolIds.isEmpty ? gameLevels.keys.toList() : poolIds,
      stake: stakeForSearch,
    );

    if (!mounted) return;
    _tipTimer?.cancel();
    _elapsedTimer?.cancel();

    switch (result.status) {
      case DuelSearchStatus.matched:
        await _showFoundThenEnter(result.matchId!, deviceId);
        break;
      case DuelSearchStatus.noPlayersFound:
        await EnergyService.refundSearchEnergy();
        if (!mounted) return;
        setState(() => _state = _LobbyState.noPlayers);
        break;
      case DuelSearchStatus.cancelled:
        await EnergyService.refundSearchEnergy();
        if (mounted) Navigator.pop(context);
        break;
      case DuelSearchStatus.error:
        await EnergyService.refundSearchEnergy();
        DebugLog.reportError('Duel.findMatch', result.errorMessage ?? '(ללא הודעה)');
        if (!mounted) return;
        setState(() {
          _state = _LobbyState.error;
          _errorText = result.errorMessage;
        });
        break;
    }
  }

  // 🆕 לפני שקופצים ישר לחדר המשחק - מציגים רגע "נמצא יריב!" עם השם שלי
  // ושל היריב זה מול זה, כדי שהמסך *ירגיש* אונליין אמיתי (לא סתם מעבר
  // מסך פתאומי). שולפים פעם אחת את פרטי ה-match כדי לדעת את שם היריב.
  Future<void> _showFoundThenEnter(String matchId, String deviceId) async {
    try {
      final match = await DuelService.watchMatch(matchId).first;
      if (!mounted) return;
      final oppId = match.opponentIdFor(deviceId);
      final oppName = oppId == match.player1Id ? match.player1Name : match.player2Name;
      // 🆕 רטט ברגע שנמצא יריב - כדי שהרגע ירגיש מוחשי גם אם לא מסתכלים
      // ישר על המסך (למשל הטלפון בכיס בזמן שממתינים).
      HapticFeedback.heavyImpact();
      // 🆕 צליל "נמצא יריב!" + הנמכת מוזיקת הרקע - כדי שהצליל יישמע ברור
      // מעל המוזיקה. AudioManager.restoreMusic() נקרא ב-_enterRoom (כשעוזבים
      // את מסך "נמצא!" ונכנסים בפועל לחדר הדו-קרב).
      AudioManager.playOpponentFound();
      setState(() {
        _state = _LobbyState.found;
        _foundMatchId = matchId;
        _opponentName = oppName;
        _opponentId = oppId;
        _readyCountdown = 3;
      });
      _loadFoundStats(deviceId, oppId); // ברקע - לא חוסם את הכניסה לדו-קרב
      _startReadyCountdown(matchId, deviceId);
    } catch (e) {
      // אם משום מה לא הצלחנו לשלוף את פרטי המשחק - לא נתקעים, פשוט
      // ממשיכים ישר לחדר בלי מסך "נמצא!" (עדיף מלהישאר תקוע).
      DebugLog.reportError('Duel.showFoundThenEnter', e.toString());
      _foundMatchId = matchId;
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted || _foundMatchId == null) return;
      _enterRoom(deviceId);
    }
  }

  void _enterRoom(String deviceId) {
    if (_foundMatchId == null) return;
    // 🩹 "שחקן שכבר בתוך דו-קרב בפועל (DuelRoomScreen) לא נספר במחוברים"
    // - הבעיה: dispose() למטה תמיד קרא ל-PresenceService.stopHeartbeat(),
    // וה-pushReplacement הזה בדיוק לחדר הדו-קרב האמיתי גורם ל-dispose()
    // לרוץ מיד - כך שברגע שהמשחק בפועל מתחיל, ה-heartbeat כבר נעצר,
    // והשחקן פשוט "נעלם" מה-presence כל עוד הוא בדו-קרב עצמו. הפתרון:
    // מסמנים שאנחנו נכנסים לחדר (ולא באמת עוזבים/מבטלים), כדי ש-dispose()
    // ידע לא לעצור את ה-heartbeat הפעם - הוא ימשיך לרוץ ברקע דרך כל
    // הדו-קרב (DuelRoomScreen עצמו לא נוגע ב-PresenceService כלל, ואסור
    // לי לערוך אותו - קובץ מוגן). ה-heartbeat ייעצר בסוף בפועל כשהשחקן
    // חוזר למסך הבית (ראו PresenceService.stopHeartbeat() ב-initState של
    // main_menu_screen.dart - רשת ביטחון שרצה בכל כניסה/חזרה לבית).
    _enteringRoom = true;
    // 🆕 מחזיר את מוזיקת הרקע לעוצמה הרגילה - ה-duck שקרה ברגע "נמצא
    // יריב!" (AudioManager.playOpponentFound) לא אמור להישאר לכל הדו-קרב.
    AudioManager.restoreMusic();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DuelRoomScreen(
          matchId: _foundMatchId!,
          myDeviceId: deviceId,
          myUsername: widget.username,
        ),
      ),
    );
  }

  // 🆕 טוען ברקע מקום/XP (מתוך טבלת השיאים הקיימת) ואת ניצחונות/מאזן
  // ראש-בראש (סטטיסטיקות דו-קרב ייעודיות חדשות - ראו duel_service.dart)
  // עבור שני השחקנים. לא חוסם כלום - פשוט ממלא את הכרטיסים ברגע שמגיע.
  Future<void> _loadFoundStats(String myId, String oppId) async {
    try {
      final results = await Future.wait([
        LeaderboardService.fetchLeaderboard(),
        DuelService.getWins(myId),
        DuelService.getWins(oppId),
        DuelService.getHeadToHead(myId, oppId),
      ]);
      if (!mounted) return;
      final board = results[0] as List<Map<String, dynamic>>;
      final myWins = results[1] as int;
      final oppWins = results[2] as int;
      final h2h = results[3] as Map<String, int>;
      final myIdx = board.indexWhere((e) => e['deviceId'] == myId);
      final oppIdx = board.indexWhere((e) => e['deviceId'] == oppId);
      setState(() {
        _myRank = myIdx >= 0 ? myIdx + 1 : null;
        _myXp = myIdx >= 0 ? (board[myIdx]['xp'] as int) : null;
        _oppRank = oppIdx >= 0 ? oppIdx + 1 : null;
        _oppXp = oppIdx >= 0 ? (board[oppIdx]['xp'] as int) : null;
        _myWins = myWins;
        _oppWins = oppWins;
        _h2hMine = h2h['mine'] ?? 0;
        _h2hTheirs = h2h['theirs'] ?? 0;
      });
    } catch (_) {
      // סטטיסטיקה "נחמד שיהיה" - כשל בטעינה לא אמור להפריע להתחלת הדו-קרב
    }
  }

  // 🆕 ספירה לאחור אמיתית של 3 שניות ("הדו־קרב מתחיל בעוד") לפני
  // שנכנסים בפועל לחדר - ומקשיבים במקביל למשחק, כדי שאם היריב לוחץ
  // "ביטול" מהצד שלו (cancelBeforeStart) לא נישאר תקועים מחכים לו.
  void _startReadyCountdown(String matchId, String deviceId) {
    _readyTimer?.cancel();
    _foundMatchSub?.cancel();
    _foundMatchSub = DuelService.watchMatch(matchId).listen((m) {
      if (!mounted || _state != _LobbyState.found) return;
      if (m.status == 'finished' && m.winnerId == null) {
        // 🆕 היריב ביטל את הדו-קרב לפני שהתחיל - לא נכנסים לחדר, פשוט
        // מציגים הודעה ידידותית באותו מסך (בלי לאבד קופה - היא עוד לא
        // נגבתה) עם אפשרות לחזור/לנסות שוב, במקום לקפוץ החוצה בשקט.
        _readyTimer?.cancel();
        _foundMatchSub?.cancel();
        setState(() {
          _state = _LobbyState.error;
          _errorText = "היריב ביטל את הדו-קרב לפני שהתחיל";
        });
      }
    }, onError: (_) {});

    _readyTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_readyCountdown <= 1) {
        t.cancel();
        await DuelService.startMatchIfNeeded(matchId);
        _foundMatchSub?.cancel();
        if (!mounted) return;
        _enterRoom(deviceId);
      } else {
        setState(() => _readyCountdown--);
      }
    });
  }

  // 🆕 "ביטול הדו-קרב" מתוך מסך "נמצא יריב" - מבטל לפני שהתחיל בפועל
  // (אף אחד עוד לא ענה על אף שאלה, דמי הכניסה עוד לא נגבו), אז אין כאן
  // "הפסד" אמיתי - פשוט חוזרים אחורה. היריב מקבל הודעה מקבילה משלו.
  Future<void> _cancelFoundDuel() async {
    _readyTimer?.cancel();
    _foundMatchSub?.cancel();
    final matchId = _foundMatchId;
    if (matchId != null) {
      await DuelService.cancelBeforeStart(matchId);
    }
    if (mounted) Navigator.pop(context);
  }

  // "נסה שוב" אחרי כישלון חיפוש - ממשיך על אותה רמת הימור שכבר נבחרה
  // (בלי להכריח לבחור מחדש), אחרי בדיקה טרייה שעדיין יש מספיק אנרגיה/מטבעות.
  Future<void> _retrySameStake() async {
    final stake = _selectedStake;
    if (stake == null) {
      await _loadRequirementsThenPickStake();
      return;
    }
    setState(() => _state = _LobbyState.checking);
    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt('coins') ?? 15;
    final energy = await EnergyService.getCurrentEnergy();
    if (!mounted) return;
    setState(() {
      _coins = coins;
      _energy = energy;
    });
    if (energy < EnergyService.duelCost) {
      setState(() => _state = _LobbyState.notEnoughEnergy);
      return;
    }
    if (coins < stake) {
      setState(() => _state = _LobbyState.notEnoughCoins);
      return;
    }
    await _onStakeSelected(stake);
  }

  Future<void> _cancelAndExit() async {
    final deviceId = await DeviceId.get();
    await _duelService.cancelSearch(deviceId);
    await EnergyService.refundSearchEnergy(); // בוטל ידנית - מזכים את האנרגיה בחזרה
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    // 🆕 רשת ביטחון: אם המסך נסגר תוך כדי שהמוזיקה עדיין מונמכת (למשל
    // יצאו מהמסך ממש ברגע "נמצא יריב!" לפני שהגענו ל-_enterRoom) - לא
    // רוצים שהמוזיקה תישאר מונמכת לצמיתות במסכים הבאים.
    AudioManager.restoreMusic();
    // 🩹 לא עוצרים את ה-heartbeat אם נכנסים בפועל לחדר הדו-קרב (ראו
    // הערה מפורטת ב-_enterRoom) - רק אם באמת יצאנו/ביטלנו.
    if (!_enteringRoom) PresenceService.stopHeartbeat();
    _pulseController.dispose();
    _radarController.dispose();
    _tipTimer?.cancel();
    _elapsedTimer?.cancel();
    _readyTimer?.cancel();
    _foundMatchSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 מסך "נמצא יריב!" בנוי בדיוק לפי מוקאפ העיצוב שסופק - מסך מלא
    // משלו עם הבאדג' והפריסה שלו, בלי סרגל העליון הכללי ובלי המרכוז/
    // הריפוד הגנרי של שאר המצבים (בדיוק כמו שאר מסכי הדו-קרב שכבר בנויים
    // ככה, כדי שלא יהיה מסך-בתוך-מסך).
    if (_state == _LobbyState.found) {
      return Scaffold(
        body: AppBackground(child: SafeArea(child: _buildFound())),
      );
    }
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 🆕 סרגל עליון קבוע - כותרת/תת-כותרת משתנה לפי מצב + תג
              // אנרגיה/מטבעות, כדי שתמיד יהיה ברור כמה אנרגיה נשארה
              // (לא רק במסך השגיאה הייעודי), בדיוק כמו בעיצוב שסופק.
              if (_state != _LobbyState.checking) _buildTopBar(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: switch (_state) {
                      _LobbyState.checking => const CircularProgressIndicator(color: Color(0xFFFFD86B)),
                      _LobbyState.banned => _buildBanned(),
                      _LobbyState.notEnoughEnergy => _buildNotEnoughEnergy(),
                      _LobbyState.notEnoughCoins => _buildNotEnoughCoins(),
                      // 🆕 בורר ההימור עצמו כבר לא מוצג כאן inline - הוא נפתח
                      // כ-bottom sheet מעל המסך (ראו _openStakeSheet). מה
                      // שנשאר גלוי כאן ברקע (מטושטש/מוכהה על ידי ה-barrier
                      // של הגליון) הוא רק המרווח הריק, בדיוק כמו שרואים מאחורי
                      // כל bottom sheet אמיתי.
                      _LobbyState.selectingStake => const SizedBox.shrink(),
                      _LobbyState.searching => _buildSearching(),
                      _LobbyState.found => _buildFound(),
                      _LobbyState.noPlayers => _buildNoPlayers(),
                      _LobbyState.error => _buildError(),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 כותרת+תת-כותרת של הסרגל העליון, לפי המצב הנוכחי - תואם לעיצוב
  // שסופק ("דו־קרב 1 על 1" / "בחר על מה משחקים" בבחירת הימור, "מחפש
  // יריב" / "דו־קרב על X 🪙 · Y לוגואים" בזמן חיפוש).
  (String, String) get _topBarTexts {
    switch (_state) {
      case _LobbyState.searching:
        final stake = _selectedStake;
        final sub = stake == null ? '' : 'דו־קרב על $stake מטבעות · ${DuelService.questionsForStake(stake)} לוגואים';
        return ('מחפש יריב', sub);
      case _LobbyState.selectingStake:
        return ('דו־קרב 1 על 1', 'בחר על מה משחקים');
      default:
        return ('דו־קרב 1 על 1', '');
    }
  }

  Widget _buildTopBar() {
    final (title, subtitle) = _topBarTexts;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      // 🆕 עיצוב מחדש - סדר הפוך (מסך 04 · לובי דו-קרב): פיל
      // האנרגיה/מטבעות בצד שמאל, כפתור החזרה העגול בצד ימין.
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.4)),
              color: const Color(0xFFFFD86B).withValues(alpha: 0.13),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EnergyIcon(size: 15),
                const SizedBox(width: 3),
                Text('$_energy', style: const TextStyle(color: Color(0xFFFB7185), fontSize: 12.5, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                const CoinIcon(size: 14),
                const SizedBox(width: 3),
                Text('$_coins', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 12.5, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(title, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
          _GlassRoundIconButton(icon: Icons.arrow_forward_rounded, color: Colors.white, onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  // 🆕 מסך חסימה זמנית - מוצג כשהשחקן עזב דו-קרב באמצע יותר מפעם אחת
  // (ראו applyForfeitPenalty ב-duel_service.dart).
  Widget _buildBanned() {
    final until = _banUntil;
    final remaining = until != null ? until.difference(DateTime.now()) : Duration.zero;
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final remainingText = remaining.isNegative ? "כמה רגעים" : (h > 0 ? "$h שעות ו-$m דקות" : "$m דקות");
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.block_rounded, color: Color(0xFFFF6B6B), size: 60),
        const SizedBox(height: 18),
        const Text("חסום זמנית מדו-קרב", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          "עזבת דו-קרב באמצע המשחק יותר מפעם אחת - זו לא הוגן כלפי היריבים שממתינים לתשובה. תוכל לשחק דו-קרב שוב בעוד $remainingText.",
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13.5),
        ),
        const SizedBox(height: 26),
        _buildTextButton("חזרה", onTap: () => Navigator.pop(context)),
        const SizedBox(height: 10),
        // 🆕 כפתור דיבאג קטן - מנקה את החסימה של המכשיר הזה בלבד, בלי
        // צורך לחפש/למחוק ידנית ב-Firebase Console. נראה עמום בכוונה
        // כדי שלא יבלוט לשחקנים רגילים.
        TextButton(
          onPressed: () async {
            final deviceId = _myDeviceId;
            if (deviceId == null) return;
            await DuelService.clearMyForfeitPenalty(deviceId);
            if (!mounted) return;
            _loadRequirementsThenPickStake();
          },
          child: Text(
            "נקה חסימה (דיבאג)",
            textDirection: TextDirection.rtl,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // 🆕 בחירת רמת הימור - 3 אפשרויות (15/50/200), כל אחת מציגה גם את
  // הזכייה הפוטנציאלית (פי 2). רמה שאין מספיק מטבעות בשבילה - מוצגת
  // עמומה וחסומה, לא נעלמת (כדי שיהיה ברור שיש עוד אפשרויות "לשאוף אליהן").
  // 🆕 עוצב מחדש במדויק לפי המוקאפ שסופק (מסך "05 · גודל ההימור") - כרטיס
  // תחתון קומפקטי במקום המסך המלא הישן: כותרת "על מה משחקים?" + תת-כותרת,
  // כרטיסי ההימור (נשארו בעיצוב הצבעוני הקיים - ירוק/זהב-פופולרי/סגול),
  // שורת מידע על עלות האנרגיה, וקישור "ביטול". שורת "אתה מול יריב"
  // ותפריטי "טבלת העונה"/"קרא לחבר" עברו למסך הרכזת החדש
  // (play_vs_person_mode_screen.dart) - עדיין נגישים משם לפני שבוחרים
  // מוד, כדי לא לאבד את הפיצ'רים, רק לא כפולים כאן. ⚠️ בכוונה מציגים רק
  // 3 רמות הימור (15/50/200) בדיוק כמו במוקאפ - רמת "בזק" (5) נשארת
  // נתמכת בשרת (DuelService.stakeOptions) אך לא מוצגת יותר בבורר הזה.
  // 🆕 תוכן הגליון עצמו (bottom sheet) - אותו תוכן/עיצוב בדיוק כמו
  // שהיה קודם ב-_buildStakePicker (המסך המלא הישן), רק עטוף עכשיו
  // בכרטיס עם פינות עליונות מעוגלות + ידית גרירה, בדיוק כמו bottom
  // sheet אמיתי (ראו _openStakeSheet). הכפתור "ביטול" וכל הקשה מחוץ
  // לגליון/גרירה למטה סוגרים את הגליון עם sheetContext (לא את המסך
  // כולו) - ה"ביטול" בפועל של הלובי קורה ב-_openStakeSheet אחרי שהגליון
  // נסגר, אם לא נבחרה רמת הימור.
  Widget _buildStakeSheet(BuildContext sheetContext) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1548),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // 🆕 ידית גרירה - הרמז החזותי הסטנדרטי לכך שאפשר לגרור את
              // הגליון למטה כדי לסגור אותו.
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "על מה משחקים?",
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                "ההימור נלקח משני השחקנים",
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 22),
              ...[15, 50, 200].map((stake) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _stakeOption(stake, sheetContext),
                  )),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    const EnergyIcon(size: 15),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "כל דו-קרב עולה אנרגיה אחת · יש לך $_energy",
                        textDirection: TextDirection.rtl,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text("ביטול", style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 אווטאר עגול עם האות הראשונה של השם, בתוך טבעת גרדיאנט זהב -
  // בדיוק כמו כרטיסי השחקנים בעיצוב שסופק. משמש גם בבחירת הימור וגם
  // במסך "מחפש יריב".
  Widget _avatarCircle(
    String name, {
    double size = 54,
    bool ring = true,
    List<Color> innerColors = const [Color(0xFFFFE79A), Color(0xFFFFB24D)],
    List<Color> ringColors = const [Color(0xFFFFD86B), Color(0xFFFF9A3C)],
    Color glowColor = const Color(0xFFFFB43C),
    Color letterColor = const Color(0xFF2A1740),
    double borderAlpha = 0.75,
  }) {
    final trimmed = name.trim();
    final letter = trimmed.isNotEmpty ? trimmed.substring(0, 1) : '?';
    final inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: innerColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: Colors.white.withValues(alpha: borderAlpha), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(letter, style: TextStyle(color: letterColor, fontSize: size * 0.38, fontWeight: FontWeight.w900)),
    );
    if (!ring) return inner;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: ringColors),
        boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.45), blurRadius: 18)],
      ),
      child: inner,
    );
  }

  // 🆕 כל רמת הימור מקבלת "אישיות" ויזואלית משלה, בדיוק כמו בעיצוב
  // שסופק: 15 = ירוק/"חימום" (משחק קצר, 5 לוגואים), 50 = כרטיס זהב
  // בולט עם ברק ותג "הכי פופולרי" (7 לוגואים), 200 = סגול/"אלופים"
  // (המשחק המלא, 10 לוגואים).
  Widget _stakeOption(int stake, BuildContext sheetContext) {
    final canAfford = _coins >= stake;
    final questions = DuelService.questionsForStake(stake);
    final prize = stake * 2;
    final subtitle = '$questions לוגואים · המנצח לוקח $prize';

    void onTap() {
      if (canAfford) {
        // 🩹 תוקן (ראו הערה מפורטת ליד _pendingStake למעלה - זה בדיוק
        // מה שגרם לקריסה האדומה "בכניסה למשחק"): רק שומרים את הבחירה
        // וסוגרים את הגליון - *לא* קוראים ל-_onStakeSelected כאן. זה
        // יקרה רק אחרי שהגליון נסגר לגמרי בפועל, ב-_openStakeSheet.
        _stakeChosen = true;
        _pendingStake = stake;
        Navigator.pop(sheetContext);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("חסרים לך מטבעות לרמה הזו (יש לך $_coins)", textDirection: TextDirection.rtl)),
        );
      }
    }

    if (stake == 50) {
      // כרטיס "הכי פופולרי" - גרדיאנט זהב בולט עם ברק ותג צף, בדיוק
      // כמו כרטיס הפתיחה של דו-קרב בתפריט הראשי.
      return Opacity(
        opacity: canAfford ? 1 : 0.45,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.8), const Color(0xFFFF9A3C).withValues(alpha: 0.35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: const Color(0xFFFFAA3C).withValues(alpha: 0.25), blurRadius: 30, spreadRadius: 2)],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB24D), Color(0xFFFF8A3C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
                          alignment: Alignment.center,
                          child: const CoinIcon(size: 22),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            textDirection: TextDirection.rtl,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$stake מטבעות', textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 19, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(subtitle, textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 11.5, fontWeight: FontWeight.w700).copyWith(color: const Color(0xFF2A1740).withValues(alpha: 0.68))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: const Color(0xFF2A1740), borderRadius: BorderRadius.circular(15)),
                          child: const Text('שחק', style: TextStyle(color: Color(0xFFFFD86B), fontSize: 13.5, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -10,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(colors: [Color(0xFFFB7185), Color(0xFFE11D74)]),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: const Text('הכי פופולרי', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      );
    }

    // כרטיסי 5 (ציאן, "בזק" - חדש), 15 (ירוק, "חימום") ו-200 (סגול,
    // "אלופים") - עיצוב זהה עם צבע/אייקון/תג שונים לכל רמה.
    final bool isBlitz = stake == 5;
    final bool isCheap = stake == 15;
    final bool needsDarkText = isBlitz || isCheap; // רקעים בהירים (ציאן/ירוק) לעומת סגול כהה ל-200
    final Color accent = isBlitz ? const Color(0xFF38BDF8) : (isCheap ? const Color(0xFF34D399) : const Color(0xFFC084FC));
    final Color accentDark = isBlitz ? const Color(0xFF0284C7) : (isCheap ? const Color(0xFF16A46F) : const Color(0xFF7C3AED));
    final IconData stakeIcon = isBlitz ? Icons.bolt_rounded : (isCheap ? Icons.monetization_on_rounded : Icons.diamond_rounded);
    final String badgeText = isBlitz ? 'בזק ⚡' : (isCheap ? 'חימום' : 'אלופים');
    final Color? badgeColor = needsDarkText ? accent : null;
    final Gradient? badgeGradient = needsDarkText ? null : const LinearGradient(colors: [Color(0xFFC084FC), Color(0xFF7DD3FC)]);
    final Color badgeTextColor = needsDarkText ? const Color(0xFF08281C) : const Color(0xFF2A1740);

    return Opacity(
      opacity: canAfford ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
              gradient: LinearGradient(colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.03)], begin: Alignment.centerLeft, end: Alignment.centerRight),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [accent, accentDark]), borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: isCheap ? const CoinIcon(size: 20) : Icon(stakeIcon, color: needsDarkText ? const Color(0xFF08281C) : Colors.white, size: 22),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🩹 תוקן: היה Row עם Flexible+ellipsis על "$stake מטבעות" -
                      // כשהתג הצמוד ("חימום"/"אלופים") היה רחב מדי, הטקסט של הסכום
                      // עצמו נחתך/הוסתר לגמרי במקום רק לקבל "...". Wrap לא חותך
                      // כלום - אם אין מספיק רוחב לשניהם באותה שורה, התג פשוט יורד
                      // לשורה הבאה, אבל סכום המטבעות תמיד מוצג במלואו.
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 7,
                        runSpacing: 4,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text('$stake מטבעות', textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                            decoration: BoxDecoration(color: badgeColor, gradient: badgeGradient, borderRadius: BorderRadius.circular(8)),
                            child: Text(badgeText, style: TextStyle(color: badgeTextColor, fontSize: 9.5, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(subtitle, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [accent, accentDark]), borderRadius: BorderRadius.circular(14)),
                  child: Text('שחק', style: TextStyle(color: needsDarkText ? const Color(0xFF08281C) : Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🆕 טבעת "מחפש…" מסתובבת (conic gradient) - בדיוק כמו כרטיס היריב
  // הריק בעיצוב שסופק, סביב "?" מרכזי.
  Widget _spinningOpponentAvatar({double size = 66}) {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Opacity(
                opacity: 0.35 + _pulseController.value * 0.35,
                child: Container(
                  width: size + 16,
                  height: size + 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [const Color(0xFFFB7185).withValues(alpha: 0.4), const Color(0xFFFB7185).withValues(alpha: 0)]),
                  ),
                ),
              ),
            ),
            Transform.rotate(
              angle: _radarController.value * 2 * 3.14159,
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [Color(0x00FDA4AF), Color(0xFFFDA4AF), Color(0xFFE11D74), Color(0x00FDA4AF)]),
                ),
              ),
            ),
            Container(
              width: size - 10,
              height: size - 10,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF22103F)),
              alignment: Alignment.center,
              child: Text('?', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontFamily: null, fontSize: size * 0.34, fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearching() {
    final stake = _selectedStake;
    final elapsedText = '0:${_elapsedSeconds.toString().padLeft(2, '0')}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🆕 שני כרטיסים זה מול זה - אני ("מוכן ✓") מול היריב (עדיין
        // "מחפש…" עם טבעת מסתובבת), VS ביניהם - בדיוק כמו בעיצוב.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.45)),
                    gradient: LinearGradient(colors: [const Color(0xFFFFD86B).withValues(alpha: 0.18), const Color(0xFFFFD86B).withValues(alpha: 0.03)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  ),
                  child: Column(
                    children: [
                      _avatarCircle(widget.username, size: 66),
                      const SizedBox(height: 10),
                      Text(widget.username, textDirection: TextDirection.rtl, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 15, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFF34D399).withValues(alpha: 0.18), border: Border.all(color: const Color(0xFF6EE7B7).withValues(alpha: 0.45))),
                        child: const Text('מוכן ✓', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 10.5, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.15)),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.18)), color: const Color(0xFF140D34).withValues(alpha: 0.9)),
                    alignment: Alignment.center,
                    child: Text('VS', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, fontWeight: FontWeight.w900)),
                  ),
                  Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.15)),
                ],
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFDA4AF).withValues(alpha: 0.4)),
                    gradient: LinearGradient(colors: [const Color(0xFFFB7185).withValues(alpha: 0.13), const Color(0xFFFB7185).withValues(alpha: 0.02)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  ),
                  child: Column(
                    children: [
                      _spinningOpponentAvatar(),
                      const SizedBox(height: 10),
                      Text('מחפש…', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.white.withValues(alpha: 0.07), border: Border.all(color: Colors.white.withValues(alpha: 0.14))),
                        child: Text('מתחבר…', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 🆕 פס טעינה זוחל + "מחפש יריב… 0:07" חי - במקום הטבעות המרכזיות
        // הישנות, בדיוק כמו בעיצוב שסופק.
        SizedBox(
          width: 200,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(color: Colors.white.withValues(alpha: 0.1)),
                AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    final t = _radarController.value;
                    return Align(
                      alignment: Alignment(-1 + t * 2.4, 0),
                      child: FractionallySizedBox(
                        widthFactor: 0.45,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: const LinearGradient(colors: [Color(0xFFFDA4AF), Color(0xFFE11D74)]),
                            boxShadow: [BoxShadow(color: const Color(0xFFF43F5E).withValues(alpha: 0.6), blurRadius: 10)],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text('מחפש יריב… $elapsedText', textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        // 🆕 טיפ מתחלף - שובר את המונוטוניות של מסך "מחפש..." ריק
        SizedBox(
          height: 34,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Padding(
              key: ValueKey(_tipIndex),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _searchingTips[_tipIndex],
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 🆕 תזכורת "תנאי הדו-קרב" - כדי שיהיה ברור על מה בדיוק מחכים,
        // בדיוק כמו בעיצוב שסופק (הימור / לוגואים / זכייה למנצח).
        if (stake != null) _buildDuelConditionsGrid(stake),
        const SizedBox(height: 22),
        _buildCancelButton(),
      ],
    );
  }

  Widget _buildDuelConditionsGrid(int stake) {
    final questions = DuelService.questionsForStake(stake);
    final prize = stake * 2;
    Widget stat(String value, String label, Color color, Color bg) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: bg.withValues(alpha: 0.14), border: Border.all(color: bg.withValues(alpha: 0.35))),
            child: Column(
              children: [
                Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(label, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.07), Colors.white.withValues(alpha: 0.02)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: const [
              Text('⚔️', style: TextStyle(fontSize: 13)),
              SizedBox(width: 8),
              Text('תנאי הדו־קרב', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              stat('$stake', 'הימור', const Color(0xFFFFE7A8), const Color(0xFFFFD86B)),
              const SizedBox(width: 9),
              stat('$questions', 'לוגואים', const Color(0xFFBFDBFE), const Color(0xFF60A5FA)),
              const SizedBox(width: 9),
              stat('$prize', 'למנצח', const Color(0xFFA7F3D0), const Color(0xFF34D399)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotEnoughEnergy() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const EnergyIcon(size: 52),
        const SizedBox(height: 18),
        const Text("נגמרה האנרגיה ⚡", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          "כל דו-קרב עולה ${EnergyService.duelCost} אנרגיות מתוך ${EnergyService.maxEnergy}. אנרגיה מתמלאת אוטומטית כל ${EnergyService.regenMinutes} דקות.",
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13.5),
        ),
        const SizedBox(height: 26),
        _buildPrimaryButton("צפה בפרסומת (+${EnergyService.adRewardAmount} אנרגיה) 🎬", onTap: _watchAdForEnergy),
        const SizedBox(height: 12),
        // 🆕 מי שלא רוצה לחכות/לצפות בפרסומת - אפשרות לקנות אנרגיה
        // ישירות מהחנות. לוחצים וזה גולל אוטומטית לקטע "חנות האנרגיה".
        _buildTextButton("קנה בחנות ⚡", onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopScreen(scrollToEnergy: true)));
        }),
        const SizedBox(height: 8),
        _buildTextButton("חזרה", onTap: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildNotEnoughCoins() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CoinIcon(size: 52),
        const SizedBox(height: 18),
        const Text("אין מספיק מטבעות", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          "דמי כניסה לדו-קרב: החל מ-${DuelService.stakeOptions.first} מטבעות (יש לך $_coins). המנצח לוקח את כל הקופה!",
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13.5),
        ),
        const SizedBox(height: 26),
        _buildTextButton("חזרה", onTap: () => Navigator.pop(context)),
      ],
    );
  }

  // 🆕 מסך "נמצא יריב!" - בנוי פיקסל-לפיקסל לפי מוקאפ העיצוב "Opponent
  // Found" שסופק: באדג' ירוק למעלה, שני כרטיסי שחקן (אני מול היריב) עם
  // אווטאר+מקום+XP+ניצחונות, מפריד VS, כרטיס "מאזן ראש בראש", כרטיס
  // "תנאי הדו-קרב", וספירה לאחור אמיתית של 3 שניות + כפתור ביטול.
  // עטוף ב-SingleChildScrollView כדי שלעולם לא יגלוש במסכים נמוכים.
  // 🆕 עטיפה מגנה: אם משהו בבניית המסך המפורט נכשל (מסיבה כלשהי שלא
  // ניתן היה לזהות בלי להריץ את הפרויקט בפועל), עדיף להציג מסך גיבוי
  // פשוט אבל תפקודי (עם הספירה לאחור עדיין רצה) - מלהראות מסך ריק.
  Widget _buildFound() {
    try {
      return _buildFoundContent();
    } catch (e) {
      return _buildFoundFallback(e);
    }
  }

  Widget _buildFoundFallback(Object error) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 26),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 56),
          const SizedBox(height: 14),
          const Text("נמצא יריב! ⚔️", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(_opponentName ?? "יריב", textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 30),
          Text("$_readyCountdown", style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 40, fontWeight: FontWeight.w900)),
          const SizedBox(height: 30),
          // 🆕 טקסט השגיאה עצמו מוצג (בדיוק כמו ErrorWidget.builder הקיים
          // באפליקציה) - כדי שאם זה קורה שוב, אפשר יהיה לצלם ולשלוח לי
          // בדיוק מה נשבר, במקום שהמסך פשוט ייראה "ריק" בלי שום רמז.
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
            child: Text(error.toString(), style: TextStyle(color: Colors.red.shade200, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundContent() {
    final gold = const Color(0xFFFFD86B);
    final pink = const Color(0xFFFDA4AF);
    final showH2H = (_h2hMine + _h2hTheirs) > 0;
    final stake = _selectedStake ?? DuelService.stakeOptions.first;
    final logos = DuelService.questionsForStake(stake);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        children: [
          // באדג' "נמצא יריב!"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF6EE7B7).withValues(alpha: 0.5)),
              color: const Color(0xFF34D399).withValues(alpha: 0.16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                const Icon(Icons.check_rounded, color: Color(0xFF6EE7B7), size: 14),
                const SizedBox(width: 7),
                const Text("נמצא יריב!", textDirection: TextDirection.rtl, style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 12.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // שני כרטיסי השחקנים + VS באמצע
          // 🩹 זה בדיוק היה מקור הבאג "מסך ריק" - Row עם
          // crossAxisAlignment.stretch (שדורש גובה סופי) בתוך
          // SingleChildScrollView (שנותן גובה אינסופי) גרם ל-
          // "BoxConstraints forces an infinite height" וקריסה שקטה של
          // כל התוכן. IntrinsicHeight נותן ל-Row גובה סופי אמיתי לפני
          // שה-stretch מנסה לפעול, ופותר את זה.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _foundPlayerCard(
                    name: widget.username,
                  label: "אתה",
                  borderColor: gold,
                  nameColor: gold,
                  innerColors: const [Color(0xFFFFD86B), Color(0xFFFFA94D)],
                  ringColors: const [Color(0xFFFFE79A), Color(0xFFFF9A3C)],
                  glowColor: gold,
                  rank: _myRank,
                  xp: _myXp,
                  wins: _myWins,
                ),
              ),
              _foundVsDivider(),
              Expanded(
                child: _foundPlayerCard(
                  name: _opponentName ?? "יריב",
                  label: "היריב",
                  borderColor: pink,
                  nameColor: pink,
                  innerColors: const [Color(0xFFFDA4AF), Color(0xFFF43F5E)],
                  ringColors: const [Color(0xFFFDA4AF), Color(0xFFE11D74)],
                  glowColor: const Color(0xFFFB7185),
                  rank: _oppRank,
                  xp: _oppXp,
                  wins: _oppWins,
                ),
              ),
            ],
            ),
          ),
          if (showH2H) ...[
            const SizedBox(height: 18),
            _headToHeadCard(),
          ],
          const SizedBox(height: 14),
          _duelTermsCard(stake: stake, logos: logos, winnerReward: stake * 2),
          const SizedBox(height: 28),
          Text("הדו־קרב מתחיל בעוד", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _readyCountdownRing(),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(19),
              onTap: _cancelFoundDuel,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: Text("ביטול הדו־קרב", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14.5, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _foundPlayerCard({
    required String name,
    required String label,
    required Color borderColor,
    required Color nameColor,
    required List<Color> innerColors,
    required List<Color> ringColors,
    required Color glowColor,
    required int? rank,
    required int? xp,
    required int wins,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
        gradient: LinearGradient(colors: [borderColor.withValues(alpha: 0.2), borderColor.withValues(alpha: 0.03)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Column(
        children: [
          _avatarCircle(name, size: 74, innerColors: innerColors, ringColors: ringColors, glowColor: glowColor),
          const SizedBox(height: 11),
          Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: nameColor, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
          const SizedBox(height: 12),
          Column(
            children: [
              _foundStatRow("מקום", rank != null ? "#$rank" : "—", Colors.white),
              const SizedBox(height: 6),
              _foundStatRow("XP", xp != null ? _formatXp(xp) : "—", const Color(0xFF93C5FD)),
              const SizedBox(height: 6),
              _foundStatRow("ניצחונות", "$wins", const Color(0xFFA7F3D0)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatXp(int xp) {
    final s = xp.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _foundStatRow(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: Colors.white.withValues(alpha: 0.06)),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w700)),
          Text(value, style: TextStyle(color: valueColor, fontSize: 12.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _foundVsDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.18)),
          const SizedBox(height: 6),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.6), width: 1.5),
              color: const Color(0xFF2A1740).withValues(alpha: 0.95),
            ),
            alignment: Alignment.center,
            child: const Text("VS", style: TextStyle(color: Color(0xFFFFD86B), fontSize: 15, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 6),
          Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.18)),
        ],
      ),
    );
  }

  // 🆕 "מאזן ראש בראש" - כמה פעמים ניצחתי/הפסדתי ליריב הספציפי הזה בעבר,
  // מוצג רק אם באמת יש היסטוריה ביניכם (אחרת "0 — 0" לא אומר כלום).
  Widget _headToHeadCard() {
    final mineFlex = _h2hMine == 0 ? 1 : _h2hMine;
    final theirsFlex = _h2hTheirs == 0 ? 1 : _h2hTheirs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.07), Colors.white.withValues(alpha: 0.02)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("מאזן ראש בראש", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5, fontWeight: FontWeight.w700)),
              Text("$_h2hMine — $_h2hTheirs", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    flex: mineFlex,
                    child: Container(color: const Color(0xFFFFD86B)),
                  ),
                  Expanded(
                    flex: theirsFlex,
                    child: Container(color: const Color(0xFFE11D74)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("אתה $_h2hMine ניצחונות", style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 10.5, fontWeight: FontWeight.w700)),
              Text("${_opponentName ?? 'היריב'} $_h2hTheirs", style: const TextStyle(color: Color(0xFFFDA4AF), fontSize: 10.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  // 🆕 "תנאי הדו-קרב" - הימור/מספר לוגואים/פרס למנצח, לפי הרמה שבאמת
  // נבחרה בלובי (לא מספרים בדויים).
  Widget _duelTermsCard({required int stake, required int logos, required int winnerReward}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.4)),
        gradient: LinearGradient(colors: [const Color(0xFFFFD86B).withValues(alpha: 0.15), const Color(0xFFFFD86B).withValues(alpha: 0.03)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const Text("⚔", style: TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              const Text("תנאי הדו־קרב", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 🩹 הוסר אימוג'י המטבע (🪙) מהתוויות - לא נתמך בפונט של חלק
              // מהמכשירים ומוצג כריבוע ריק במקום סמל.
              Expanded(child: _termBox(value: "$stake", label: "הימור", bg: const Color(0xFFFFD86B), valueColor: const Color(0xFFFFE7A8))),
              const SizedBox(width: 9),
              Expanded(child: _termBox(value: "$logos", label: "לוגואים", bg: const Color(0xFF60A5FA), valueColor: const Color(0xFFBFDBFE))),
              const SizedBox(width: 9),
              Expanded(child: _termBox(value: "$winnerReward", label: "למנצח", bg: const Color(0xFF34D399), valueColor: const Color(0xFFA7F3D0))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _termBox({required String value, required String label, required Color bg, required Color valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bg.withValues(alpha: 0.14),
        border: Border.all(color: bg.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // 🆕 טבעת ספירה-לאחור - CircularProgressIndicator רגיל (בדיוק אותו
  // widget שכבר היה במסך "נמצא!" המקורי, לפני שהרחבתי אותו) עם המספר
  // באמצע - פשוט ויציב, בלי אנימציות/גרדיאנטים מותאמים-אישית.
  Widget _readyCountdownRing() {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(strokeWidth: 4, color: Color(0xFFFFD86B), backgroundColor: Color(0x22FFFFFF)),
          ),
          Text("$_readyCountdown", style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 32, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildNoPlayers() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_off_rounded, color: Colors.white.withValues(alpha: 0.5), size: 64),
        const SizedBox(height: 20),
        const Text(
          "אין כרגע שחקנים מחוברים 🙁",
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          "נסה שוב בעוד כמה דקות, או שתף חברים כדי לשחק ביחד",
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14.5),
        ),
        const SizedBox(height: 30),
        _buildPrimaryButton("נסה שוב", onTap: _retrySameStake),
        const SizedBox(height: 12),
        _buildTextButton("חזרה", onTap: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wifi_off_rounded, color: Colors.redAccent.withValues(alpha: 0.8), size: 64),
        const SizedBox(height: 20),
        const Text(
          "משהו השתבש",
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorText!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
        ],
        const SizedBox(height: 30),
        _buildPrimaryButton("נסה שוב", onTap: _retrySameStake),
        const SizedBox(height: 12),
        _buildTextButton("חזרה", onTap: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildCancelButton() => _buildTextButton("ביטול", onTap: _cancelAndExit);

  Widget _buildPrimaryButton(String label, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [Color(0xFFFFE79A), Color(0xFFFFB24D)]),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF2A1740), fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(String label, {required VoidCallback onTap}) {
    return TextButton(
      onPressed: onTap,
      child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15)),
    );
  }
}

// כפתור זכוכית עגול קטן (חזרה) - זהה בסגנון לכפתור המקביל במסך הדו-קרב עצמו.
class _GlassRoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _GlassRoundIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: color, size: 19),
        ),
      ),
    );
  }
}