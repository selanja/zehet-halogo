// friend_challenge_screen.dart
//
// 🆕 "אתגר חבר" - במקום לחפש יריב אקראי (DuelLobbyScreen), שחקן יכול
// ליצור קוד הזמנה בן 6 תווים לשלוח לחבר (וואטסאפ וכו'), או להקליד קוד
// שקיבל מחבר - ולהתחיל דו-קרב ישירות מולו. הלוגיקה מול Firestore נמצאת
// כולה ב-DuelService (createInvite/watchInvite/cancelInvite/getInvite/
// joinInvite) - המסך הזה רק בונה סביבה UI ומטפל בבדיקות אנרגיה/מטבעות/
// חסימה, בדיוק כמו ש-DuelLobbyScreen עושה ל-matchmaking האקראי.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, HapticFeedback;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart'; // 🆕 כפתור "שתף קוד" נפרד מהעתקה, בדיוק כמו במוקאפ
import 'duel_service.dart';
import 'duel_room_screen.dart';
import 'logo_race_service.dart'; // 🆕 "אתגר חבר" עכשיו תומך גם במרוץ, לא רק בדו-קרב - ראו isDuel
import 'logo_race_screen.dart';
import 'level_data.dart';
import 'device_id.dart';
import 'app_background.dart';
import 'energy_service.dart';
import 'app_icons.dart';
import 'audio_manager.dart';
import 'friend_service.dart'; // 🆕 הזמנה ישירה לחבר ספציפי מרשימת החברים + קפיצה אוטומטית לקוד
import 'app_notification.dart';
import 'out_of_resource.dart'; // 🆕 "נגמר משהו" - פרסומת/חנות

enum _FCState {
  checking,
  banned,
  notEnoughEnergy,
  notEnoughCoins,
  menu,
  waitingForFriend,
  enterCode,
  previewInvite,
  joining,
  expired,
  declined, // 🆕 החבר לחץ "דחה" על ההזמנה - ראו _listenToMyInvite/declineInvite
  error,
}

// 🆕 תוצאת הצטרפות מאוחדת - DuelService.joinInvite מחזיר JoinInviteStatus
// ו-LogoRaceService.joinInvite מחזיר RaceJoinInviteStatus (טיפוסים שונים,
// אותם ערכים בדיוק) - _FriendChallengeScreenState._joinInvite ממפה את
// שניהם לכאן כדי ששאר המסך יוכל להתייחס לתוצאה בלי לדעת איזה מוד רץ.
enum _JoinCode { matched, notFound, expired, ownCode, alreadyUsed, error }

class _JoinOutcome {
  final _JoinCode code;
  final String? matchId;
  const _JoinOutcome(this.code, {this.matchId});
}

// 🆕 טיפים מתחלפים למסך "ממתין לחבר" - אותו רעיון בדיוק כמו הטיפים
// במסך "מחפש יריב" של הלובי הרגיל (duel_lobby_screen.dart).
const List<String> _waitingTips = [
  "טיפ: שלח לחבר את הקוד בוואטסאפ - הוא יקליד אותו במסך \"יש לי קוד\"",
  "טיפ: הקוד בתוקף ל-15 דקות - אם הוא פג, פשוט תיצור קוד חדש",
  "טיפ: שני השחקנים מקבלים בדיוק אותם לוגואים - הראשון שמסיים מנצח",
  "טיפ: אפשר לקנות רמז זול בתוך הדו-קרב אם נתקעים על לוגו",
];

class FriendChallengeScreen extends StatefulWidget {
  final String username;
  // 🆕 כשמגיעים לכאן מרשימת "החברים שלי" (friends_screen.dart) ולוחצים
  // "הזמן למשחק" על חבר ספציפי - targetFriendId/targetFriendName מוזרמים
  // כדי שהקוד שייווצר יישלח ישירות אליו (ראה FriendService.notifyFriendOfInvite),
  // ומסך ההמתנה יציג את שמו במקום "החבר" הגנרי.
  final String? targetFriendId;
  final String? targetFriendName;
  // 🆕 כשמגיעים לכאן מקבלת הזמנה נכנסת (ראה main.dart -
  // AppLifecycleManager, כתוצאה מ-FriendService.watchIncomingInvite) -
  // הקוד מוזן ונבדק אוטומטית מיד עם הכניסה למסך, בלי שהמשתמש יצטרך
  // להקליד אותו בעצמו.
  final String? prefillJoinCode;
  // 🆕 לפי בקשה מפורשת - אתגר חבר עכשיו זמין גם לדו-קרב וגם למרוץ, לא
  // רק לדו-קרב. true (ברירת מחדל) = דו-קרב, בדיוק כמו ההתנהגות המקורית.
  final bool isDuel;
  const FriendChallengeScreen({
    super.key,
    required this.username,
    this.targetFriendId,
    this.targetFriendName,
    this.prefillJoinCode,
    this.isDuel = true,
  });

  @override
  State<FriendChallengeScreen> createState() => _FriendChallengeScreenState();
}

class _FriendChallengeScreenState extends State<FriendChallengeScreen> with TickerProviderStateMixin {
  // 🆕 עוזרי מוד - כל מקום שהיה קורא ל-DuelService ישירות עכשיו בודק
  // את אלה. שם/אימוג'י המוד לטקסטים, שאר הפונקציות בגוף הקובץ.
  bool get _isDuel => widget.isDuel;
  String get _modeLabel => _isDuel ? 'דו-קרב' : 'מרוץ';
  List<int> get _stakeOptions => _isDuel ? DuelService.stakeOptions : LogoRaceService.stakeOptions;
  int _questionsForStake(int stake) => _isDuel ? DuelService.questionsForStake(stake) : LogoRaceService.stagesForStake(stake);
  Duration get _inviteExpiry => _isDuel ? DuelService.inviteExpiry : LogoRaceService.inviteExpiry;
  int get _inviteCodeLength => _isDuel ? DuelService.inviteCodeLength : LogoRaceService.inviteCodeLength;

  Future<String> _createInvite({required String deviceId, required String username, required int stake}) {
    return _isDuel
        ? DuelService.createInvite(deviceId: deviceId, username: username, stake: stake)
        : LogoRaceService.createInvite(deviceId: deviceId, username: username, stake: stake);
  }

  Stream<Map<String, dynamic>?> _watchInvite(String code) => _isDuel ? DuelService.watchInvite(code) : LogoRaceService.watchInvite(code);

  Future<void> _cancelInvite(String code) => _isDuel ? DuelService.cancelInvite(code) : LogoRaceService.cancelInvite(code);

  Future<Map<String, dynamic>?> _getInvite(String code) => _isDuel ? DuelService.getInvite(code) : LogoRaceService.getInvite(code);

  Future<_JoinOutcome> _joinInvite({required String code, required String deviceId, required String username, required List<int> allLevelIds}) async {
    if (_isDuel) {
      final r = await DuelService.joinInvite(code: code, deviceId: deviceId, username: username, allLevelIds: allLevelIds);
      final mapped = switch (r.status) {
        JoinInviteStatus.matched => _JoinCode.matched,
        JoinInviteStatus.notFound => _JoinCode.notFound,
        JoinInviteStatus.expired => _JoinCode.expired,
        JoinInviteStatus.ownCode => _JoinCode.ownCode,
        JoinInviteStatus.alreadyUsed => _JoinCode.alreadyUsed,
        JoinInviteStatus.error => _JoinCode.error,
      };
      return _JoinOutcome(mapped, matchId: r.matchId);
    } else {
      final r = await LogoRaceService.joinInvite(code: code, deviceId: deviceId, username: username, allLevelIds: allLevelIds);
      final mapped = switch (r.status) {
        RaceJoinInviteStatus.matched => _JoinCode.matched,
        RaceJoinInviteStatus.notFound => _JoinCode.notFound,
        RaceJoinInviteStatus.expired => _JoinCode.expired,
        RaceJoinInviteStatus.ownCode => _JoinCode.ownCode,
        RaceJoinInviteStatus.alreadyUsed => _JoinCode.alreadyUsed,
        RaceJoinInviteStatus.error => _JoinCode.error,
      };
      return _JoinOutcome(mapped, matchId: r.matchId);
    }
  }

  // 🆕 בריכת הלוגואים האפשריים להימור נבחר - בדו-קרב מוגבלת לפי עולמות
  // (DuelService.worldsForStake), במרוץ תמיד כל הלוגואים (ראה logo_race_screen.dart -
  // _startSearch, אותה בריכה בדיוק במצב החיפוש הרגיל).
  List<int> _poolForStake(int stake) {
    if (!_isDuel) return gameLevels.keys.toList();
    final worlds = DuelService.worldsForStake(stake);
    final ids = logoIdsForWorlds(worlds);
    return ids.isEmpty ? gameLevels.keys.toList() : ids;
  }

  _FCState _state = _FCState.checking;
  String? _errorText;
  String? _myDeviceId;
  int _coins = 0;
  int _energy = 0;
  DateTime? _banUntil;

  // יצירת הזמנה
  String? _myCode;
  StreamSubscription<Map<String, dynamic>?>? _inviteSub;
  Timer? _expiryTimer;
  // 🩹 שני השדות למטה מקבלים ברירת מחדל ספרותית פשוטה (לא _inviteExpiry/
  // _stakeOptions - אלה getters של המופע, ואי אפשר להשתמש בהם באתחול
  // שדה ב-Dart) - הערך האמיתי נקבע ב-_loadRequirements ברגע שידוע isDuel.
  Duration _timeLeft = const Duration(minutes: 1);
  bool _energySpentForCreate = false;
  int? _selectedStakeForCreate; // 🆕 להצגת "תנאי הדו-קרב" במסך ההמתנה
  // 🆕 עיצוב מחדש - ההימור נבחר בתפריט המאוחד עצמו (צ'יפים קומפקטיים),
  // לא במסך ניווט נפרד יותר - ראו _buildMenu/_stakeChip.
  int _selectedStake = 5;
  // 🩹 הגנה מפני לחיצה כפולה מהירה על אפשרות הימור: setState לא מרענן
  // את המסך מיידית (רק בפריים הבא), כך שלחיצה כפולה מהירה יכולה להפעיל
  // את _onCreateStakeSelected פעמיים כמעט בו-זמנית - שתי קריאות מקבילות
  // ל-runTransaction על אותו מסמך גורמות לתקלה ידועה בתוסף cloud_firestore
  // עצמו ("Bad state: Future already completed", קורסת מחוץ ל-try/catch
  // כי היא קורית בצד הפלאגין הנטיבי, לא בקוד שלנו). הדגל הזה חוסם כניסה
  // כפולה עד שהבקשה הראשונה מסתיימת (הצלחה או כישלון).
  bool _creatingInvite = false;

  // הצטרפות עם קוד
  final TextEditingController _codeController = TextEditingController();
  String? _joinCodeError;
  Map<String, dynamic>? _previewInvite;
  bool _joiningInvite = false; // 🩹 אותה הגנה מפני לחיצה כפולה כמו _creatingInvite
  String? _previewCode;
  bool _energySpentForJoin = false;

  // 🆕 אנימציות "ממתין לחבר" - בדיוק כמו במסך "מחפש יריב" של הלובי הרגיל
  // (פעימה סביב אווטאר החבר + טבעת מסתובבת), כדי שהמסך ירגיש עקבי.
  late final AnimationController _pulseController;
  late final AnimationController _radarController;
  Timer? _tipTimer;
  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _loadRequirements().then((_) {
      // 🆕 הגענו מקבלת הזמנה נכנסת (prefillJoinCode) - ממלאים ובודקים את
      // הקוד אוטומטית, בלי שהמשתמש יצטרך להקליד אותו בעצמו. רק אם הבדיקות
      // (אנרגיה/מטבעות/חסימה) עברו בהצלחה והמסך הגיע למצב "menu". ואז,
      // מכיוון שהמשתמש כבר אישר את ההזמנה בדיאלוג הקופץ (ראו main.dart -
      // _showIncomingInviteDialog, כפתור "הצטרף") - אין צורך במסך אישור
      // נוסף: מצטרפים ישר לדו-קרב ברגע שהקוד אומת בהצלחה.
      final code = widget.prefillJoinCode;
      if (code != null && code.isNotEmpty && mounted && _state == _FCState.menu) {
        _codeController.text = code;
        _checkCode().then((_) {
          if (mounted && _state == _FCState.previewInvite) {
            _confirmJoin();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _inviteSub?.cancel();
    _expiryTimer?.cancel();
    _tipTimer?.cancel();
    _pulseController.dispose();
    _radarController.dispose();
    _codeController.dispose();
    // 🆕 אם עוזבים את המסך באמצע המתנה ליריב/עם אנרגיה שכבר נגבתה בלי
    // שהמשחק בפועל התחיל - מזכים בחזרה, בדיוק כמו ביטול חיפוש בלובי הרגיל.
    if (_energySpentForCreate) {
      _energySpentForCreate = false;
      EnergyService.refundSearchEnergy();
      final code = _myCode;
      if (code != null) _cancelInvite(code);
    }
    if (_energySpentForJoin) {
      _energySpentForJoin = false;
      EnergyService.refundSearchEnergy();
    }
    super.dispose();
  }

  Future<void> _loadRequirements() async {
    setState(() => _state = _FCState.checking);
    final deviceId = await DeviceId.get();
    _myDeviceId = deviceId;
    _selectedStake = _stakeOptions.first; // 🆕 עכשיו שידוע isDuel - ראו הערה ליד _selectedStake
    if (!mounted) return;
    // 🆕 חסימה על עזיבה-באמצע קיימת רק בדו-קרב (DuelService.applyForfeitPenalty) -
    // במרוץ אין מנגנון קנס/חסימה כזה בכלל (forfeitRace לא קורא לשום
    // penalty), אז אין טעם לבדוק או לחסום לפיו.
    if (_isDuel) {
      final forfeitStatus = await DuelService.getForfeitStatus(deviceId);
      if (!mounted) return;
      if (DuelService.isBanned(forfeitStatus)) {
        setState(() {
          _banUntil = DateTime.fromMillisecondsSinceEpoch(forfeitStatus['banUntilMs'] as int);
          _state = _FCState.banned;
        });
        return;
      }
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
      setState(() => _state = _FCState.notEnoughEnergy);
      return;
    }
    if (coins < _stakeOptions.first) {
      setState(() => _state = _FCState.notEnoughCoins);
      return;
    }
    setState(() => _state = _FCState.menu);
  }

  // ================================================================
  // יצירת הזמנה
  // ================================================================
  Future<void> _onCreateStakeSelected(int stake) async {
    if (_creatingInvite) return; // 🩹 חוסם לחיצה כפולה - ראו הסבר ליד השדה
    if (_coins < stake) return;
    final deviceId = _myDeviceId;
    if (deviceId == null) return;
    _creatingInvite = true;
    _selectedStakeForCreate = stake;
    setState(() => _state = _FCState.waitingForFriend);
    _startTipRotation();
    try {
      await EnergyService.spendForDuel();
      _energySpentForCreate = true;
      final code = await _createInvite(deviceId: deviceId, username: widget.username, stake: stake);
      if (!mounted) return;
      _myCode = code;
      _timeLeft = _inviteExpiry;
      _startExpiryCountdown();
      _listenToMyInvite(code, deviceId);
      // 🆕 אם הגענו מרשימת "החברים שלי" (הוזמן חבר ספציפי) - שולחים לו
      // הודעה ישירה על הקוד, כדי שאם האפליקציה שלו פתוחה הוא יראה באנר
      // הזמנה מיידי (ראה FriendService.notifyFriendOfInvite + main.dart).
      // לא חוסם ולא מציג שגיאה אם נכשל (למשל אין אינטרנט) - זו רק תוספת
      // נוחות, קוד ה-6-תווים עדיין תקף לשיתוף ידני בכל מקרה.
      final friendId = widget.targetFriendId;
      if (friendId != null) {
        FriendService.myId().then((myId) {
          FriendService.notifyFriendOfInvite(
            friendId: friendId,
            fromId: myId,
            fromName: widget.username,
            code: code,
            stake: stake,
            isDuel: _isDuel,
          );
        });
      }
    } catch (e) {
      _energySpentForCreate = false;
      await EnergyService.refundSearchEnergy();
      if (!mounted) return;
      setState(() {
        _state = _FCState.error;
        _errorText = "לא הצלחנו ליצור קוד הזמנה - נסה שוב";
      });
    } finally {
      _creatingInvite = false;
    }
  }

  void _startTipRotation() {
    _tipTimer?.cancel();
    _tipTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _tipIndex = (_tipIndex + 1) % _waitingTips.length);
    });
  }

  void _startExpiryCountdown() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _timeLeft -= const Duration(seconds: 1));
      if (_timeLeft.inSeconds <= 0) {
        t.cancel();
        _onInviteExpired();
      }
    });
  }

  void _onInviteExpired() {
    if (_state != _FCState.waitingForFriend) return;
    _tipTimer?.cancel();
    _inviteSub?.cancel();
    final code = _myCode;
    if (code != null) _cancelInvite(code);
    _energySpentForCreate = false;
    EnergyService.refundSearchEnergy();
    if (!mounted) return;
    setState(() => _state = _FCState.expired);
  }

  void _listenToMyInvite(String code, String deviceId) {
    _inviteSub?.cancel();
    _inviteSub = _watchInvite(code).listen((data) {
      if (!mounted || _state != _FCState.waitingForFriend) return;
      if (data == null) return; // בוטל
      if (data['status'] == 'matched' && data['matchId'] != null) {
        _expiryTimer?.cancel();
        _tipTimer?.cancel();
        _inviteSub?.cancel();
        _energySpentForCreate = false; // נגבה בפועל - לא מזכים יותר
        HapticFeedback.heavyImpact();
        AudioManager.playOpponentFound();
        _enterRoom(data['matchId'] as String, deviceId);
        return;
      }
      // 🆕 החבר לחץ "דחה" בדיאלוג הקופץ אצלו (ראו main.dart -
      // _showIncomingInviteDialog + DuelService.declineInvite) - מזכים
      // אנרגיה, מנקים את המסמך ומציגים מסך "החבר דחה את ההזמנה".
      if (data['status'] == 'declined') {
        _expiryTimer?.cancel();
        _tipTimer?.cancel();
        _inviteSub?.cancel();
        _energySpentForCreate = false;
        EnergyService.refundSearchEnergy();
        _cancelInvite(code);
        setState(() => _state = _FCState.declined);
      }
    }, onError: (_) {});
  }

  // 🩹 תוקן: בעבר "ביטול" רק חזר לתפריט הפנימי של המסך הזה (עדיין בתוך
  // FriendChallengeScreen) - כך שהיה צריך ללחוץ "חזרה"/יציאה פעם נוספת
  // כדי לצאת בפועל חזרה ללובי. עכשיו זה יוצא ישירות מהמסך, בדיוק כמו
  // כפתור "ביטול" במסך "מחפש יריב" של הלובי הרגיל (_cancelAndExit).
  Future<void> _cancelMyInvite() async {
    _expiryTimer?.cancel();
    _tipTimer?.cancel();
    _inviteSub?.cancel();
    final code = _myCode;
    if (code != null) await _cancelInvite(code);
    _energySpentForCreate = false;
    await EnergyService.refundSearchEnergy();
    _myCode = null;
    if (mounted) Navigator.pop(context);
  }

  void _copyCode() {
    final code = _myCode;
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    AppNotification.show(context, "הקוד הועתק! שלח אותו לחבר", type: AppNotificationType.success);
  }

  // 🆕 "שתף קוד" - פותח את תפריט השיתוף של המכשיר (וואטסאפ וכו'), בדיוק
  // כמו כפתור "שתף קוד" במוקאפ (מסך 06 · קריאה לחבר) - בנוסף לכפתור
  // ההעתקה הקיים, לא במקומו.
  Future<void> _shareCode() async {
    final code = _myCode;
    if (code == null) return;
    HapticFeedback.lightImpact();
    final text = "בוא נשחק $_modeLabel ב\"זהה את הלוגו!\" 🔗 הקוד שלי: $code";
    try {
      // 🐛 תוקן: "באייפון שיתוף כותב שאי אפשר לשתף" - חסר sharePositionOrigin
      // (ראו share_helper.dart להסבר המלא). גם הוספה הודעת גיבוי - קודם
      // כשל נכשל בשקט לגמרי, בלי שום משוב למשתמש.
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(text, subject: "אתגר $_modeLabel", sharePositionOrigin: box != null ? (box.localToGlobal(Offset.zero) & box.size) : null);
    } catch (_) {
      if (mounted) AppNotification.show(context, "לא נמצאה אפליקציית שיתוף. אפשר להעתיק ולשלוח ידנית:\n$text", duration: const Duration(seconds: 5));
    }
  }

  // ================================================================
  // הצטרפות עם קוד
  // ================================================================
  Future<void> _checkCode() async {
    final code = _codeController.text.trim().toUpperCase();
    setState(() => _joinCodeError = null);
    if (code.length != _inviteCodeLength) {
      setState(() => _joinCodeError = "קוד חייב להיות בן $_inviteCodeLength תווים");
      return;
    }
    final myId = _myDeviceId;
    if (myId == null) return;
    setState(() => _state = _FCState.joining);
    final invite = await _getInvite(code);
    if (!mounted) return;
    if (invite == null) {
      setState(() {
        _state = _FCState.enterCode;
        _joinCodeError = "לא נמצא קוד כזה - ודא שהקלדת נכון";
      });
      return;
    }
    if (invite['creatorId'] == myId) {
      setState(() {
        _state = _FCState.enterCode;
        _joinCodeError = "זה הקוד שלך - שלח אותו לחבר, לא להזין אותו כאן";
      });
      return;
    }
    if (invite['status'] != 'waiting') {
      setState(() {
        _state = _FCState.enterCode;
        _joinCodeError = "מישהו כבר הצטרף לקוד הזה";
      });
      return;
    }
    final createdAt = (invite['createdAt'] as dynamic);
    DateTime? createdDate;
    try {
      createdDate = createdAt?.toDate();
    } catch (_) {}
    if (createdDate != null && DateTime.now().difference(createdDate) > _inviteExpiry) {
      setState(() {
        _state = _FCState.enterCode;
        _joinCodeError = "הקוד הזה כבר פג תוקף";
      });
      return;
    }
    final stake = (invite['stake'] ?? _stakeOptions.first) as int;
    if (_coins < stake) {
      setState(() {
        _state = _FCState.enterCode;
        // 🩹 הוסרה האמוג'י 🪙 - בחלק מהמכשירים/פונטים היא מוצגת כריבוע ריק
        _joinCodeError = "אין לך מספיק מטבעות להימור הזה ($stake)";
      });
      return;
    }
    setState(() {
      _previewInvite = invite;
      _previewCode = code;
      _state = _FCState.previewInvite;
    });
  }

  Future<void> _confirmJoin() async {
    if (_joiningInvite) return; // 🩹 חוסם לחיצה כפולה - ראו הסבר ליד _creatingInvite
    final code = _previewCode;
    final invite = _previewInvite;
    final myId = _myDeviceId;
    if (code == null || invite == null || myId == null) return;
    final stake = (invite['stake'] ?? _stakeOptions.first) as int;
    _joiningInvite = true;
    setState(() => _state = _FCState.joining);
    try {
      await EnergyService.spendForDuel();
      _energySpentForJoin = true;
      final result = await _joinInvite(
        code: code,
        deviceId: myId,
        username: widget.username,
        allLevelIds: _poolForStake(stake),
      );
      if (!mounted) return;
      if (result.code == _JoinCode.matched && result.matchId != null) {
        _energySpentForJoin = false;
        HapticFeedback.heavyImpact();
        AudioManager.playOpponentFound();
        _enterRoom(result.matchId!, myId);
        return;
      }
      _energySpentForJoin = false;
      await EnergyService.refundSearchEnergy();
      if (!mounted) return;
      _finishJoinWithError(result.code);
    } finally {
      _joiningInvite = false;
    }
  }

  void _finishJoinWithError(_JoinCode status) {
    setState(() {
      _state = _FCState.enterCode;
      _previewInvite = null;
      _previewCode = null;
      switch (status) {
        case _JoinCode.notFound:
          _joinCodeError = "לא נמצא קוד כזה";
          break;
        case _JoinCode.expired:
          _joinCodeError = "הקוד הזה כבר פג תוקף";
          break;
        case _JoinCode.ownCode:
          _joinCodeError = "זה הקוד שלך";
          break;
        case _JoinCode.alreadyUsed:
          _joinCodeError = "מישהו כבר הצטרף לקוד הזה";
          break;
        default:
          _joinCodeError = "משהו השתבש - נסה שוב";
      }
    });
  }

  void _enterRoom(String matchId, String deviceId) {
    AudioManager.restoreMusic();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _isDuel
            ? DuelRoomScreen(
                matchId: matchId,
                myDeviceId: deviceId,
                myUsername: widget.username,
              )
            : LogoRaceScreen(
                username: widget.username,
                initialRaceId: matchId,
              ),
      ),
    );
  }

  // ================================================================
  // UI
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (_state != _FCState.checking) _buildTopBar(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: switch (_state) {
                      _FCState.checking => const CircularProgressIndicator(color: Color(0xFFFFD86B)),
                      _FCState.banned => _buildBanned(),
                      _FCState.notEnoughEnergy => _buildNotEnoughEnergy(),
                      _FCState.notEnoughCoins => _buildNotEnoughCoins(),
                      // 🆕 עיצוב מחדש - "menu" ו-"enterCode" חולקים כעת אותו מסך מאוחד
                      // (יצירת קוד + הזנת קוד באותו מקום), בלי שלב ניווט נפרד לבחירת
                      // הימור - ראו _buildMenu().
                      _FCState.menu => _buildMenu(),
                      _FCState.waitingForFriend => _buildWaiting(),
                      _FCState.enterCode => _buildMenu(),
                      _FCState.previewInvite => _buildPreview(),
                      _FCState.joining => const CircularProgressIndicator(color: Color(0xFFFFD86B)),
                      _FCState.expired => _buildExpired(),
                      _FCState.declined => _buildDeclined(),
                      _FCState.error => _buildError(),
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

  String get _topBarTitle {
    switch (_state) {
      case _FCState.waitingForFriend:
        return 'ממתין לחבר';
      case _FCState.previewInvite:
      case _FCState.joining:
        return 'הצטרפות עם קוד';
      default:
        return 'אתגר חבר';
    }
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          _GlassBackButton(onTap: () => Navigator.pop(context)),
          Expanded(
            child: Text(
              _topBarTitle,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
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
        ],
      ),
    );
  }

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
          "עזבת דו-קרב באמצע המשחק יותר מפעם אחת. תוכל לשחק דו-קרב שוב בעוד $remainingText.",
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13.5),
        ),
        const SizedBox(height: 26),
        _textButton("חזרה", onTap: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildNotEnoughEnergy() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const EnergyIcon(size: 56),
        const SizedBox(height: 18),
        const Text("אין מספיק אנרגיה", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          "כל $_modeLabel עולה ${EnergyService.duelCost} אנרגיות. אנרגיה מתמלאת אוטומטית כל ${EnergyService.regenMinutes} דקות.",
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13.5),
        ),
        const SizedBox(height: 26),
        ...OutOfResource.offerButtons(context, coins: false, onGranted: _loadRequirements),
        const SizedBox(height: 12),
        _textButton("חזרה", onTap: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildNotEnoughCoins() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CoinIcon(size: 56),
        const SizedBox(height: 18),
        const Text("אין מספיק מטבעות", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          "צריך לפחות ${_stakeOptions.first} מטבעות כדי להתחיל $_modeLabel.",
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13.5),
        ),
        const SizedBox(height: 26),
        ...OutOfResource.offerButtons(context, coins: true, onGranted: _loadRequirements),
        const SizedBox(height: 12),
        _textButton("חזרה", onTap: () => Navigator.pop(context)),
      ],
    );
  }

  // 🆕 עיצוב מחדש - מסך מאוחד אחד (במקום תפריט → בחירת הימור במסך נפרד →
  // הזנת קוד במסך נפרד), בדיוק כמו במוקאפ (מסך 10 · קריאה לחבר) שם הכול
  // מופיע יחד בלי ניווט ביניים. בחירת ההימור עצמה נשארת (היא קובעת כמה
  // מטבעות מסתכנים וכמה שאלות יהיו בדו-קרב) - רק הפכה לצ'יפים קומפקטיים
  // בתוך אותו מסך, עם ברירת מחדל נבחרת מראש (_selectedStake).
  Widget _buildMenu() {
    final stakeOptions = _stakeOptions;
    if (!stakeOptions.contains(_selectedStake)) _selectedStake = stakeOptions.first;
    final canAffordSelected = _coins >= _selectedStake;
    // 🆕 כשמגיעים לכאן מלחיצה על "הזמן למשחק" על חבר ספציפי מתוך רשימת
    // "החברים שלי" (targetFriendId != null) - כבר ידוע בדיוק את מי
    // מזמינים, אז אין שום סיבה להציג גם את קטע "יש לך קוד מחבר?" (זה
    // רק בלבל, כמו שתיארת). במקרה הזה מציגים רק את בחירת ההימור וכפתור
    // שליחת ההזמנה, עם הפניה ישירה לשם החבר.
    final friendName = widget.targetFriendName;
    final isDirectInvite = widget.targetFriendId != null;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔗', style: TextStyle(fontSize: 46)),
          const SizedBox(height: 14),
          Text(
            isDirectInvite ? "הזמנת ${friendName ?? 'חבר'} ל$_modeLabel" : "אתגר חבר ל$_modeLabel",
            textDirection: TextDirection.rtl,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            isDirectInvite
                ? "בחר על מה משחקים - ${friendName ?? 'החבר'} יקבל הזמנה מיידית."
                : "בחר על מה משחקים, ואז צור קוד לשלוח לחבר - או הזן קוד שכבר קיבלת.",
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: stakeOptions.map((stake) => _stakeChip(stake)).toList(),
          ),
          const SizedBox(height: 16),
          _bigActionButton(
            isDirectInvite ? "שלח הזמנה 🎟️" : "צור קוד לחבר 🎟️",
            onTap: canAffordSelected ? () => _onCreateStakeSelected(_selectedStake) : null,
          ),
          if (!isDirectInvite) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.12))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text("או", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
                Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.12))),
              ],
            ),
            const SizedBox(height: 16),
            Text("יש לך קוד מחבר?", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                maxLength: _inviteCodeLength,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 5),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  hintText: '------',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), letterSpacing: 5),
                ),
                onSubmitted: (_) => _checkCode(),
              ),
            ),
            if (_joinCodeError != null) ...[
              const SizedBox(height: 10),
              Text(_joinCodeError!, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 12),
            _bigActionButton("הצטרף עם קוד ⌨️", filled: false, onTap: _checkCode),
          ],
          const SizedBox(height: 14),
          _textButton("חזרה", onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  // צ'יפ הימור קומפקטי - תחליף למסך "על מה משחקים?" הנפרד שהיה קודם.
  Widget _stakeChip(int stake) {
    final selected = _selectedStake == stake;
    final canAfford = _coins >= stake;
    final bool isBlitz = _isDuel && stake == 5; // 🆕 רמת ההימור הזולה/מהירה ביותר - ראו DuelService.stakeLogoTimeoutSeconds
    final Color accent = isBlitz ? const Color(0xFF38BDF8) : const Color(0xFFFFD86B);
    return Opacity(
      opacity: canAfford ? 1 : 0.4,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: canAfford ? () => setState(() => _selectedStake = stake) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? LinearGradient(colors: [accent.withValues(alpha: 0.9), accent.withValues(alpha: 0.55)])
                : const LinearGradient(colors: [Color(0xFF3A2A6B), Color(0xFF2A1D50)]),
            border: Border.all(color: selected ? accent : accent.withValues(alpha: 0.3), width: selected ? 1.6 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              const CoinIcon(size: 15),
              const SizedBox(width: 5),
              Text('$stake', style: TextStyle(color: selected ? const Color(0xFF2A1740) : Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900)),
              if (isBlitz) ...[
                const SizedBox(width: 4),
                Text('⚡', style: TextStyle(fontSize: 11, color: selected ? const Color(0xFF2A1740) : null)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 עוצב מחדש כדי להרגיש כמו מסך "מחפש יריב" בלובי הרגיל - שני
  // כרטיסים (אני מול "?" של החבר) עם VS, טבעת מסתובבת, טיפים מתחלפים
  // ותזכורת תנאי הדו-קרב - רק שבמקום פס טעינה זוחל, הקוד עצמו במרכז.
  Widget _buildWaiting() {
    final code = _myCode;
    if (code == null) {
      return const CircularProgressIndicator(color: Color(0xFFFFD86B));
    }
    final min = _timeLeft.inMinutes.clamp(0, 99);
    final sec = _timeLeft.inSeconds % 60;
    final stake = _selectedStakeForCreate;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _sideCard(name: widget.username, ready: true)),
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
                Expanded(child: _sideCard(name: null, ready: false)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // 🆕 עיצוב מחדש - כרטיס "הקוד שלך" + כפתור "שתף קוד" נפרד לצד
          // כפתור העתקה קטן, בדיוק כמו במוקאפ (מסך 06 · קריאה לחבר) -
          // במקום קופסה יחידה שגם מציגה וגם מעתיקה בלחיצה עליה.
          Text("הקוד שלך", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(code, style: const TextStyle(color: Color(0xFF7DD3FC), fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 8)),
          const SizedBox(height: 14),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _copyCode,
                  child: const Padding(
                    padding: EdgeInsets.all(13),
                    child: Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _shareCode,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)]),
                    ),
                    child: const Text("שתף קוד", style: TextStyle(color: Color(0xFF0C2A3D), fontSize: 15, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            // 🆕 אם ידוע שם החבר שהוזמן ישירות (targetFriendName) - מציגים
            // אותו במקום "החבר" הגנרי.
            "ממתין ש${widget.targetFriendName ?? 'החבר'} יזין את הקוד… ${min.toString().padLeft(1, '0')}:${sec.toString().padLeft(2, '0')}",
            textDirection: TextDirection.rtl,
            style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 34,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Padding(
                key: ValueKey(_tipIndex),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _waitingTips[_tipIndex],
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (stake != null) _duelConditionsGrid(stake),
          const SizedBox(height: 22),
          _textButton("ביטול", onTap: _cancelMyInvite),
        ],
      ),
    );
  }

  // כרטיס צד (אני / החבר) - זהה בסגנון לכרטיסי "אני מול יריב" בלובי הרגיל.
  Widget _sideCard({required String? name, required bool ready}) {
    if (ready && name != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.45)),
          gradient: LinearGradient(colors: [const Color(0xFFFFD86B).withValues(alpha: 0.18), const Color(0xFFFFD86B).withValues(alpha: 0.03)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Column(
          children: [
            _letterAvatar(name, size: 66, gold: true),
            const SizedBox(height: 10),
            Text(name, textDirection: TextDirection.rtl, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFF34D399).withValues(alpha: 0.18), border: Border.all(color: const Color(0xFF6EE7B7).withValues(alpha: 0.45))),
              child: const Text('מוכן ✓', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 10.5, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDA4AF).withValues(alpha: 0.4)),
        gradient: LinearGradient(colors: [const Color(0xFFFB7185).withValues(alpha: 0.13), const Color(0xFFFB7185).withValues(alpha: 0.02)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Column(
        children: [
          _spinningFriendAvatar(),
          const SizedBox(height: 10),
          Text(
            widget.targetFriendName ?? 'החבר',
            textDirection: TextDirection.rtl,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.white.withValues(alpha: 0.07), border: Border.all(color: Colors.white.withValues(alpha: 0.14))),
            child: Text('ממתין…', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _letterAvatar(String name, {double size = 54, bool gold = true}) {
    final letter = name.trim().isNotEmpty ? name.trim().substring(0, 1) : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: gold ? [const Color(0xFFFFE79A), const Color(0xFFFFB24D)] : [Colors.white24, Colors.white10]),
      ),
      alignment: Alignment.center,
      child: Text(letter, style: TextStyle(color: const Color(0xFF2A1740), fontSize: size * 0.4, fontWeight: FontWeight.w900)),
    );
  }

  // אווטאר "?" עם טבעת מסתובבת + פעימה - זהה בעיקרון ל-_spinningOpponentAvatar
  // בלובי הרגיל (duel_lobby_screen.dart), משוכפל כאן כי הוא פרטי לשם.
  Widget _spinningFriendAvatar({double size = 66}) {
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
              child: Text('?', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: size * 0.34, fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
  }

  // תזכורת "תנאי הדו-קרב" - זהה בעיקרון ל-_buildDuelConditionsGrid בלובי
  // הרגיל, משוכפלת כאן כי היא פרטית לשם.
  Widget _duelConditionsGrid(int stake) {
    final questions = _questionsForStake(stake);
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
            children: [
              Text(_isDuel ? '⚔️' : '🏁', style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              Text('תנאי ה$_modeLabel', textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900)),
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

  Widget _buildPreview() {
    final invite = _previewInvite;
    if (invite == null) return const SizedBox.shrink();
    final stake = (invite['stake'] ?? _stakeOptions.first) as int;
    final creatorName = (invite['creatorName'] ?? '?') as String;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_isDuel ? '⚔️' : '🏁', style: const TextStyle(fontSize: 44)),
        const SizedBox(height: 12),
        Text("אתגר מ-$creatorName", textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              const CoinIcon(size: 20),
              const SizedBox(width: 6),
              Text('$stake מטבעות', style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(width: 14),
              Text('${_questionsForStake(stake)} לוגואים', textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _bigActionButton("הצטרף ל$_modeLabel ${_isDuel ? "⚔️" : "🏁"}", onTap: _confirmJoin),
        const SizedBox(height: 12),
        _textButton("ביטול", onTap: () => setState(() {
              _state = _FCState.enterCode;
              _previewInvite = null;
              _previewCode = null;
            })),
      ],
    );
  }

  // 🆕 החבר לחץ "דחה" על ההזמנה - ראו _listenToMyInvite.
  Widget _buildDeclined() {
    final name = widget.targetFriendName ?? 'החבר';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.close_rounded, color: Color(0xFFFF6B6B), size: 54),
        const SizedBox(height: 16),
        Text("$name דחה את ההזמנה", textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          "אפשר לנסות שוב מאוחר יותר, או להזמין חבר אחר.",
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
        ),
        const SizedBox(height: 22),
        _bigActionButton("חזרה", onTap: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildExpired() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.hourglass_bottom_rounded, color: Color(0xFFFFD86B), size: 54),
        const SizedBox(height: 16),
        const Text("הקוד פג תוקף", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          "החבר לא הספיק להצטרף בזמן. אפשר ליצור קוד חדש.",
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
        ),
        const SizedBox(height: 22),
        _bigActionButton("צור קוד חדש", onTap: () {
          _myCode = null;
          setState(() => _state = _FCState.menu);
        }),
        const SizedBox(height: 12),
        _textButton("חזרה", onTap: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B), size: 54),
        const SizedBox(height: 16),
        Text(_errorText ?? "משהו השתבש", textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 22),
        _bigActionButton("נסה שוב", onTap: _loadRequirements),
        const SizedBox(height: 12),
        _textButton("חזרה", onTap: () => Navigator.pop(context)),
      ],
    );
  }

  // 🆕 onTap כעת nullable - כפתור "צור קוד" צריך להיות מנוטרל (לא רק
  // מוסתר) כשאין מספיק מטבעות להימור הנבחר בתפריט המאוחד.
  Widget _bigActionButton(String label, {bool filled = true, required VoidCallback? onTap}) {
    return SizedBox(
      width: 240,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? const Color(0xFFFFD86B) : Colors.white.withValues(alpha: 0.08),
          foregroundColor: filled ? const Color(0xFF2A1740) : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: filled ? BorderSide.none : BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _textButton(String label, {required VoidCallback onTap}) {
    return TextButton(
      onPressed: onTap,
      child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15)),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(9),
          child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}