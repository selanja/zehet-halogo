// battle_pass_screen.dart
//
// 🆕 מסך "באטל פאס" מלא - מציג את כל 15 השלבים של העונה הנוכחית (שם
// העונה מ-BattlePassService.seasonDisplayName), עם שני נתיבי פרסים
// (חינמי + פרימיום) לכל שלב, מד התקדמות עליון, ובאנר שדרוג לפרימיום
// אם הוא עוד לא נרכש. נכנסים אליו מכרטיס "באטל פאס 🎫" בתפריט הראשי.
//
// ⚠️ כל הלוגיקה (נקודות/תביעת פרסים/סטטוס פרימיום) ב-BattlePassService -
// המסך הזה רק מציג ומפעיל אותה.
//
// 🩹 עוצב מחדש בדיוק לפי New_Screens.html ("10 · באטל פאס") לגבי בלוק
// דרגה+שם עונה מתחת לסרגל, כפתור מידע 'i' בסרגל העליון, ושורת כיתובש
// "עוד X לדרגה הבאה" מתחת לפס ההתקדמות - כל אלה נשארים.
//
// 🩹 בוטל מתג הטאבים "חינם"/"פרימיום": לפי בקשת המשתמש אחרי בדיקה,
// שתי עמודות הפרס (חינם+פרימיום) חוזרות להופיע יחד באותה שורת שלב,
// זו-לצד-זו, בלי צורך ללחוץ בין טאבים כדי לראות את שתיהן. בשונה
// מהגרסה הישנה-הישנה, העיצוב עכשיו "מיוחד": כותרות עמודה "חינם"/
// "פרימיום" מעל הרשימה, פס הפרדה דק בין שתי הגלולות בכל שורה, רצועת
// רקע זהובה-חמימה מתחת לעמודת הפרימיום (עם ⭐ קטן) כדי להבדיל אותה
// חזותית מהעמודה החינמית, וקו מפריד עדין בין שורות השלבים.
//
// 🩹 עוצב מחדש שוב לפי מוקאפ עדכני יותר ("10 · באטל פאס"): כרטיס
// הדרגה ופס ההתקדמות אוחדו לכרטיס-hero אחד עם מסגרת-גרדיאנט זהב→סגול
// ורקע פנימי גרדיאנט סגול כהה (ראו _buildHeroCard - במקום שני בלוקים
// נפרדים _buildRankHeader/_buildProgressHeader הישנים), ונוסף קו-מסלול
// (rail) אנכי מאחורי תגי-המספר של השלבים (ראו _buildTierRail). כותרת
// שם העונה+"עונה 1" עברה להיות מעל כרטיס ה-hero (לא בתוכו) - ראו
// _buildSeasonTitle. גם פופאפ "פרס נאסף" חדש (battle_pass_reward_popup.dart)
// מחליף את ה-SnackBar הפשוט שהיה ב-_claim.

import 'package:flutter/material.dart';
import 'battle_pass_service.dart';
import 'app_background.dart';
import 'app_icons.dart'; // CoinIcon/EnergyIcon - אייקון וקטורי אמיתי, לא אימוג'י (ראה הערה למטה)
import 'battle_pass_reward_popup.dart'; // 🆕 פופאפ "פרס נאסף!" עם אנימציית תיבה נפתחת
import 'iap_manager.dart';
import 'main_menu_screen.dart'; // 🩹 MainMenuScreen.onReturnedHome - לרענון מיידי של המטבעות/אנרגיה במסך הבית (ראו _claim/_buyPremium)

class BattlePassScreen extends StatefulWidget {
  const BattlePassScreen({super.key});

  @override
  State<BattlePassScreen> createState() => _BattlePassScreenState();
}

class _BattlePassScreenState extends State<BattlePassScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  int _points = 0;
  int _tier = 0;
  bool _premium = false;
  Set<int> _claimedFree = {};
  Set<int> _claimedPremium = {};
  bool _buying = false;

  VoidCallback? _prevOnPurchasesUpdated;

  // 🆕 קונטרולר לזוהר הפועם (glowPulse) מאחורי אייקון הדרגה בכרטיס
  // ה-hero - בדיוק כמו האנימציה במוקאפ (opacity 0.5↔0.92 בלולאה).
  late final AnimationController _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _prevOnPurchasesUpdated = IapManager.onPurchasesUpdated;
    IapManager.onPurchasesUpdated = _onPurchasesUpdated;
    _load();
  }

  @override
  void dispose() {
    // 🩹 משחזרים callback קודם (אם היה) במקום סתם לאפס - כדי לא "לגנוב"
    // רישום ממסך אחר שרשם את עצמו לפני שהמסך הזה נפתח.
    IapManager.onPurchasesUpdated = _prevOnPurchasesUpdated;
    _glowController.dispose();
    super.dispose();
  }

  void _onPurchasesUpdated() {
    _prevOnPurchasesUpdated?.call();
    if (mounted) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final points = await BattlePassService.getPoints();
    final premium = await BattlePassService.isPremiumUnlocked();
    final claimedFree = await BattlePassService.getClaimedFreeTiers();
    final claimedPremium = await BattlePassService.getClaimedPremiumTiers();
    if (!mounted) return;
    setState(() {
      _points = points;
      _tier = BattlePassService.currentTierFor(points);
      _premium = premium;
      _claimedFree = claimedFree;
      _claimedPremium = claimedPremium;
      _loading = false;
    });
  }

  // 🩹 במקום SnackBar פשוט - נפתח פופאפ "פרס נאסף!" מלא-מסך (עם אנימציית
  // תיבה נפתחת), ואם התביעה הזו חשפה שכבר יש דרגה נוספת שנפתחה (מספיק
  // נקודות) באותו נתיב ועדיין לא נתבעה - הפופאפ מציע להמשיך ולתבוע גם
  // אותה (שרשור: onClaimNext סוגר את הפופאפ הנוכחי וקורא שוב ל-_claim).
  Future<void> _claim(int tier, {required bool premium}) async {
    final result = await BattlePassService.claimTier(tier, premium: premium);
    if (!mounted || result == null) return;
    final coins = result['coins'] ?? 0;
    final energy = result['energy'] ?? 0;
    // 🩹 באג שתוקן: תביעת פרס עם מטבעות/אנרגיה לא עדכנה את מסך הבית -
    // היה צריך לנווט למסך אחר כדי לראות את המספר החדש. זהה לתיקון שכבר
    // קיים ב-duel_lobby_screen.dart/shop_screen.dart - MainMenuScreen
    // עצמו מאזין ל-callback הזה ומרענן את הסטטיסטיקות שלו ברגע שהוא נקרא.
    MainMenuScreen.onReturnedHome?.call();

    // מחפשים דרגה נוספת שכבר פתוחה לפי הנקודות הנוכחיות (התביעה עצמה
    // לא מוסיפה נקודות) אבל עדיין לא נתבעה באותו נתיב - כדי להציע
    // "אסוף את דרגה X" בפופאפ במקום שהשחקן יצטרך לחזור למסך ולחפש.
    final claimedSet = premium ? _claimedPremium : _claimedFree;
    BattlePassTier? nextPending;
    for (final t in BattlePassService.tiers) {
      if (t.tier <= tier) continue;
      if (t.pointsRequired > _points) break;
      final hasReward = premium ? t.hasPremiumReward : t.hasFreeReward;
      if (hasReward && !claimedSet.contains(t.tier)) {
        nextPending = t;
        break;
      }
    }

    await showBattlePassRewardPopup(
      context,
      tier: tier,
      premium: premium,
      coins: coins,
      energy: energy,
      currentPoints: _points,
      nextTier: nextPending?.tier,
      onClaimNext: nextPending == null
          ? null
          : () {
              Navigator.of(context).pop();
              _claim(nextPending!.tier, premium: premium);
            },
    );
    if (!mounted) return;
    await _load();
  }

  // 🆕 כמה פרסים פתוחים כרגע ולא נאספו (חינם + פרימיום אם הוא פעיל) -
  // חישוב מקומי מה-state שכבר נטען (זהה בלוגיקה ל-
  // BattlePassService.pendingClaimsCount, רק בלי async נוסף כי הכל כבר
  // בזיכרון).
  int _pendingClaimsCount() {
    int count = 0;
    for (final t in BattlePassService.tiers) {
      if (t.pointsRequired > _points) break;
      if (t.hasFreeReward && !_claimedFree.contains(t.tier)) count++;
      if (_premium && t.hasPremiumReward && !_claimedPremium.contains(t.tier)) count++;
    }
    return count;
  }

  Future<void> _buyPremium() async {
    if (_buying) return;
    setState(() => _buying = true);
    final ok = await IapManager.buy(IapManager.battlePassPremiumId);
    if (mounted && !ok) {
      setState(() => _buying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הרכישה לא זמינה כרגע - נסה שוב עוד רגע', textDirection: TextDirection.rtl)),
      );
    }
    // בהצלחה - _onPurchaseUpdated יטען מחדש ויכבה את _buying דרך _load אינו
    // מכבה אותו ישירות, לכן מכבים כאן גם למקרה שהמשתמש ביטל את חלון הרכישה.
    if (mounted) setState(() => _buying = false);
  }

  // 🆕 כפתור המידע 'i' בסרגל העליון (חדש - לא היה קיים קודם) פותח דיאלוג
  // קצר שמסביר מה זה באטל פאס, במקום להיות רק קישוט ריק.
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF2A1550),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('מה זה באטל פאס?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          content: const Text(
            'צובר נקודות ממשימות ומהאתגר היומי, ועולה דרגות לאורך העונה. '
            'כל דרגה פותחת פרס בנתיב החינמי, ומי שרוכש פרימיום מקבל פרס גדול '
            'יותר באותה דרגה. בתחילת כל חודש נפתחת עונה חדשה מ-0.',
            style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('הבנתי', style: TextStyle(color: Color(0xFFFFD979), fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            // 🩹 "בדיוק כמו ששלחתי" - נוסף זוהר לבנדר עדין בפינה העליונה
            // בדיוק כמו ב-Battle_Pass.html (radial-gradient סגול-בהיר),
            // מעל רקע האפליקציה המשותף (AppBackground) - בלי לשכפל/להחליף
            // אותו, כדי לא לשבור עקביות עם שאר המסכים.
            Positioned(
              top: -50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 280,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [const Color(0xFFD8B4FE).withValues(alpha: 0.24), const Color(0xFFD8B4FE).withValues(alpha: 0)]),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(child: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC))) : _buildBody()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🩹 עוצב מחדש בדיוק לפי המוקאפ: כפתור חזרה (עיגול "‹") בצד ימין,
  // כותרת "באטל פאס" במרכז בלבד (תת-הכותרת עברה לבלוק הדרגה/עונה
  // מתחת לסרגל - ראה _buildSeasonTitle/_buildHeroCard), וכפתור מידע 'i' חדש בצד שמאל
  // (לא היה קיים קודם - במוקאפ יש אייקון 'i' עגול שם, ולא תג X/Y).
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.08),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              "באטל פאס",
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          // 🆕 כפתור מידע 'i' - חדש, לא היה קיים בגרסה הקודמת.
          Material(
            color: Colors.white.withValues(alpha: 0.08),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _showInfoDialog,
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        _buildSeasonTitle(),
        const SizedBox(height: 14),
        _buildHeroCard(),
        const SizedBox(height: 18),
        _buildColumnLabels(),
        const SizedBox(height: 10),
        _buildTierListWithRail(),
        // 🆕 "שדרג לפרימיום" - כפתור סיכום גדול בתחתית (בדיוק כמו
        // ב-Battle_Pass.html), מוצג רק אם הפרימיום עוד לא נרכש.
        if (!_premium) ...[
          const SizedBox(height: 8),
          _buildUpgradeCta(),
        ],
      ],
    );
  }

  // 🩹 תוקן: "עונה 1" היה טקסט קבוע (bug) - עכשיו זה מספר העונה האמיתי
  // (BattlePassService.currentSeasonNumber, מבוסס העוגן הקבוע החדש -
  // ראו ההסבר המפורט ב-battle_pass_service.dart). 🆕 נוסף בחזרה תג
  // "⏳ נותרו X ימים" (היה קיים בעבר, נעלם בטעות בעיצוב-מחדש קודם) -
  // עכשיו במיוחד רלוונטי כי העונה הרבה יותר ארוכה (45 יום קבועים).
  Widget _buildSeasonTitle() {
    final seasonName = BattlePassService.seasonDisplayName();
    final seasonNumber = BattlePassService.currentSeasonNumber();
    final daysLeft = BattlePassService.daysLeftInSeason();
    return Column(
      children: [
        Text(
          'עונה $seasonNumber',
          textDirection: TextDirection.rtl,
          style: TextStyle(color: const Color(0xFFFFD979).withValues(alpha: 0.75), fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF6D8), Color(0xFFFFC64B), Color(0xFFC084FC)],
            stops: [0.0, 0.55, 1.0],
          ).createShader(bounds),
          child: Text(
            seasonName,
            textDirection: TextDirection.rtl,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: const Color(0xFFF43F5E).withValues(alpha: 0.18),
            border: Border.all(color: const Color(0xFFFDA4AF).withValues(alpha: 0.4)),
          ),
          child: Text(
            daysLeft <= 0 ? 'העונה מסתיימת היום' : 'נותרו $daysLeft ימים',
            textDirection: TextDirection.rtl,
            style: const TextStyle(color: Color(0xFFFDA4AF), fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  // 🆕 כרטיס "hero" מאוחד - מחליף את _buildRankHeader+_buildProgressHeader
  // הישנים בבלוק אחד עם מסגרת-גרדיאנט חיצונית (זהב→סגול) ורקע פנימי
  // גרדיאנט סגול כהה, בדיוק לפי המוקאפ: אייקון דרגה מרובע-מעוגל עם זוהר
  // פועם, פס "⭐ נקודות/סה"כ" מול "עוד X ⭐", פס התקדמות, ושתי גלולות-תג
  // ("X פרסים לאיסוף" עם ספירה אמיתית, ו"🏅 תג בסיום" עיטורי-בלבד - אין
  // דאטה אמיתית לתג עונה במודל הקיים, ראה הערה למטה).
  Widget _buildHeroCard() {
    final firstReq = BattlePassService.tiers.first.pointsRequired;
    final lastReq = BattlePassService.tiers.last.pointsRequired;
    final overallRatio = lastReq == firstReq ? 1.0 : ((_points - firstReq) / (lastReq - firstReq)).clamp(0.0, 1.0);

    BattlePassTier? nextTier;
    for (final t in BattlePassService.tiers) {
      if (t.pointsRequired > _points) {
        nextTier = t;
        break;
      }
    }
    final String nextLabel = nextTier == null ? 'הדרגה האחרונה!' : 'עוד ${nextTier.pointsRequired - _points} ⭐';
    final int pending = _pendingClaimsCount();

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [const Color(0xFFFFD979).withValues(alpha: 0.6), const Color(0xFFA855F7).withValues(alpha: 0.5)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4B238F), Color(0xFF2A1160)]),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // עיגול-זוהר דקורטיבי חצי-שקוף בפינה - בדיוק כמו במוקאפ.
              Positioned(
                top: -50,
                left: -34,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
                ),
              ),
              Column(
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // אייקון דרגה 62x62 עם זוהר פועם (glowPulse).
                      SizedBox(
                        width: 62,
                        height: 62,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _glowController,
                              builder: (ctx, _) => Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [
                                    const Color(0xFFFFB446).withValues(alpha: 0.4 * (0.5 + 0.5 * _glowController.value)),
                                    const Color(0xFFFFB446).withValues(alpha: 0),
                                  ]),
                                ),
                              ),
                            ),
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE08A), Color(0xFFF2793B)]),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10))],
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('$_tier', style: const TextStyle(color: Color(0xFF40170F), fontSize: 24, fontWeight: FontWeight.w900, height: 1.0)),
                                  Text('דרגה', textDirection: TextDirection.rtl, style: TextStyle(color: const Color(0xFF40170F).withValues(alpha: 0.6), fontSize: 8, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              textDirection: TextDirection.rtl,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('⭐ $_points / $lastReq', textDirection: TextDirection.rtl, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                                Text(nextLabel, textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFFFFD979), fontSize: 10.5, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 9),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: SizedBox(
                                height: 11,
                                child: Stack(
                                  children: [
                                    Container(color: Colors.black.withValues(alpha: 0.34)),
                                    FractionallySizedBox(
                                      widthFactor: overallRatio,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFFC084FC), Color(0xFFFFD979)]),
                                          boxShadow: [BoxShadow(color: const Color(0xFFFFD979).withValues(alpha: 0.6), blurRadius: 12)],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 9),
                            Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                _heroTagPill(pending > 0 ? '$pending פרסים לאיסוף' : 'הכל נאסף ✓'),
                                const SizedBox(width: 7),
                                // 🩹 עיטורי-בלבד: אין במודל הנתונים הקיים (BattlePassTier)
                                // "תג עונה" אמיתי - זה קישוט חזותי סטטי בלבד, בדיוק כמו
                                // שהוא רק "דוגמת עיצוב" במוקאפ (אין נתון אמיתי מאחוריו).
                                _heroTagPill('🏅 תג בסיום'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroTagPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: Colors.black.withValues(alpha: 0.3)),
      child: Text(label, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9.5, fontWeight: FontWeight.w900)),
    );
  }

  // 🩹 תוקן לפי המוקאפ המדויק: תג-מספר השלב אמור לשבת **באמצע** בין
  // עמודת "חינם" לעמודת "פרימיום" (לא בקצה הימני) - וקו-המסלול (rail)
  // עובר בדיוק מאחורי האמצע הזה, לאורך כל גובה רשימת השלבים (בדיוק
  // כמו ב-CSS: "left: 50%" במוקאפ). לכן הקו ממורכז עכשיו במרכז האופקי
  // המוחלט של האזור (Align/Center), ולא ביחס לקצה של תג-המספר.
  Widget _buildTierListWithRail() {
    const double railWidth = 4;
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Container(
              constraints: const BoxConstraints.expand(width: railWidth),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6EE7B7), Color(0xFFFFD979), Color(0x17FFFFFF), Color(0x12FFFFFF)],
                  stops: [0.0, 0.26, 0.42, 1.0],
                ),
              ),
            ),
          ),
        ),
        Column(
          children: BattlePassService.tiers
              .asMap()
              .entries
              .map((e) => _buildTierRow(e.value, isLast: e.key == BattlePassService.tiers.length - 1))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildUpgradeCta() {
    final priceLabel = IapManager.product(IapManager.battlePassPremiumId)?.price ?? '₪24.90';
    final premiumTiers = BattlePassService.tiers.where((t) => t.hasPremiumReward).toList();
    final lockedCount = premiumTiers.length;
    // 🆕 "כולל Y שכבר צברת" - סופר כמה מהשלבים עם פרס פרימיום כבר
    // הגיעו אליהם (נפתחו) לפי הנקודות הנוכחיות, כדי להראות לשחקן
    // כמה מהפרסים האלה הוא כבר יכול לתבוע ברגע שירכוש.
    final alreadyReachedCount = premiumTiers.where((t) => _points >= t.pointsRequired).length;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _buying ? null : _buyPremium,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE08A), Color(0xFFFFD979)]),
            boxShadow: [BoxShadow(color: const Color(0xFFFFD979).withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 14))],
          ),
          child: _buying
              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF40170F))))
              : Column(
                  children: [
                    Text('שדרג לפרימיום · $priceLabel', textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFF40170F), fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                      alreadyReachedCount > 0 ? 'פותח $lockedCount פרסים · כולל $alreadyReachedCount שכבר צברת' : 'פותח $lockedCount פרסים נוספים',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(color: Color(0x9E40170F), fontSize: 10.5, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // 🩹 תוקן: תג מספר-השלב עבר להיות **באמצע** בין העמודות (ראה
  // _buildTierRow/_buildTierListWithRail), אז כותרות העמודות עכשיו
  // סימטריות משני צדי מרווח אמצעי (34 - רוחב התג - ועוד שני מרווחים
  // של 7 סביבו, בדיוק כמו ברווחים ב-_buildTierRow) במקום ההזחה החד-
  // צדדית הישנה שהתאימה לתג-בקצה.
  Widget _buildColumnLabels() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Text(
            'חינם',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 7 + 34 + 7),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('⭐', style: TextStyle(fontSize: 10)),
              SizedBox(width: 3),
              Text('פרימיום', textDirection: TextDirection.rtl, style: TextStyle(color: Color(0xFFFFD979), fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }

  // 🩹 תוקן לפי המוקאפ המדויק: תג מספר-השלב (34x34) עבר מהקצה הימני
  // אל **האמצע** של השורה, בין שתי גלולות הפרס - "חינם" בצד ימין
  // ו"פרימיום" בצד שמאל (בדיוק כמו ב-CSS: pill, badge(40px), pill).
  // זה גם מה שגורם לקו-המסלול (rail) ב-_buildTierListWithRail, שעובר
  // באמצע האופקי המוחלט, לעבור בדיוק מאחורי כל תגי-המספר. כל עמודה
  // מחשבת unlocked/claimed/canClaim בנפרד לפי הנתיב שלה (חינם מול
  // פרימיום), כי הן שני מסלולי תביעה עצמאיים לגמרי בפועל.
  Widget _buildTierRow(BattlePassTier def, {required bool isLast}) {
    final bool unlocked = _points >= def.pointsRequired;

    final bool freeClaimed = _claimedFree.contains(def.tier);
    final bool freeCanClaim = unlocked && !freeClaimed && def.hasFreeReward;

    final bool premiumClaimed = _claimedPremium.contains(def.tier);
    // בנתיב פרימיום - "נעול" גם אם עוד לא נרכש הפרימיום, גם אם השלב עצמו כבר נפתח בנקודות.
    final bool premiumLocked = !_premium;
    final bool premiumCanClaim = unlocked && !premiumClaimed && !premiumLocked && def.hasPremiumReward;

    // מרחק מהשלב הנוכחי (לשלבים שעוד לא נפתחו) - קובע כמה השורה "דוהה",
    // בדיוק כמו ההדרגה ההולכת ומתעמעמת במוקאפ (0.6 / 0.45 / 0.32).
    double rowOpacity = 1.0;
    if (!unlocked) {
      final distance = def.tier - _tier;
      rowOpacity = distance <= 1 ? 0.6 : (distance == 2 ? 0.45 : 0.32);
    }

    // תג מספר-השלב מסתכל רק על מצב הנתיב החינמי (הוא זה שכל שחקן
    // מקבל בוודאות) - בדיוק כמו הלוגיקה הקודמת, רק בלי תלות בטאב.
    Color badgeGradientStart, badgeGradientEnd, badgeTextColor;
    List<BoxShadow>? badgeShadow;
    if (unlocked && freeClaimed) {
      badgeGradientStart = const Color(0xFF6EE7B7);
      badgeGradientEnd = const Color(0xFF059669);
      badgeTextColor = const Color(0xFF04291E);
    } else if (freeCanClaim || premiumCanClaim) {
      badgeGradientStart = const Color(0xFFFFE08A);
      badgeGradientEnd = const Color(0xFFF2793B);
      badgeTextColor = const Color(0xFF40170F);
      badgeShadow = [BoxShadow(color: const Color(0xFFF2793B).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))];
    } else {
      badgeGradientStart = Colors.white.withValues(alpha: 0.07);
      badgeGradientEnd = Colors.white.withValues(alpha: 0.07);
      badgeTextColor = Colors.white.withValues(alpha: 0.5);
    }

    return Opacity(
      opacity: rowOpacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
        // 🆕 קו מפריד עדין בין שורות השלבים - לא היה קיים כשהייתה שורה
        // אחת פשוטה; עכשיו כשכל שורה "עמוסה" יותר (שתי עמודות) זה עוזר
        // לעין להפריד בין שלב לשלב.
        decoration: isLast ? null : BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🩹 עמודת "חינם" - עכשיו הילד הראשון (RTL => צד ימין),
            // בדיוק כמו במוקאפ, ולא אחרי תג המספר.
            Expanded(
              child: _rewardPill(
                coins: def.freeCoins,
                energy: def.freeEnergy,
                unlocked: unlocked,
                claimed: freeClaimed,
                canClaim: freeCanClaim,
                isPremium: false,
                pointsRequired: def.pointsRequired,
                onTap: () => _claim(def.tier, premium: false),
              ),
            ),
            const SizedBox(width: 7),
            // 🩹 תג מספר-השלב - באמצע השורה (בין שתי הגלולות), בדיוק מעל
            // קו-המסלול (rail) שעובר באמצע האופקי המוחלט.
            // 🩹 תוקן שוב: ניסיון קודם הוסיף כאן מתחת לתג גם "כמה כוכבים
            // צריך" - אבל זה בדיוק האזור שהקו עובר בו, ונראה עמוס/מוזר
            // גם עם רקע אטום. המספר עבר במקום זה *לתוך* גלולת הפרס עצמה
            // (_rewardPill, מציג עכשיו X⭐ במקום מנעול כשהשלב עוד נעול) -
            // רחוק מהקו לגמרי, ובדיוק "על הפריט עצמו" כמו שביקשת.
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [badgeGradientStart, badgeGradientEnd]),
                boxShadow: badgeShadow,
                border: (!(unlocked && freeClaimed) && !freeCanClaim && !premiumCanClaim) ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
              ),
              alignment: Alignment.center,
              child: Text('${def.tier}', style: TextStyle(color: badgeTextColor, fontSize: 13, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 7),
            // עמודת "פרימיום" - עכשיו הילד האחרון (RTL => צד שמאל).
            Expanded(
              child: _rewardPill(
                coins: def.premiumCoins,
                energy: def.premiumEnergy,
                unlocked: unlocked,
                claimed: premiumClaimed,
                canClaim: premiumCanClaim,
                isPremium: true,
                pointsRequired: def.pointsRequired,
                onTap: () => _claim(def.tier, premium: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🩹 גלולת פרס - עכשיו קומפקטית יותר (כדי שתיים ייכנסו יחד בשורה
  // אחת, במקום גלולה רחבה אחת). אייקון וקטורי אמיתי (CoinIcon/EnergyIcon)
  // + כמות, וסטטוס: ✓ אם נאסף, כפתור "אסוף" זהוב אם אפשר לתבוע עכשיו,
  // או 🔒 אם עוד נעול. 🆕 isPremium נותן לעמודת הפרימיום מראה חמים-זהוב
  // מובחן (רצועת רקע + מסגרת בגוון זהב) גם במצב "נעול רגיל", כדי שהיא
  // תיראה כמו נתיב "משודרג" גם בלי שהתביעה זמינה, ולא רק כשהיא ניתנת
  // לאיסוף - זה מה שהופך את העמודות לברורות ומיוחדות זו מזו במבט חטוף.
  Widget _rewardPill({
    required int coins,
    required int energy,
    required bool unlocked,
    required bool claimed,
    required bool canClaim,
    required bool isPremium,
    required int pointsRequired,
    required VoidCallback onTap,
  }) {
    final bool hasReward = coins > 0 || energy > 0;
    if (!hasReward) {
      return Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isPremium ? const Color(0xFFFFD979).withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.03),
        ),
        child: Text('—', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12)),
      );
    }
    final bool isEnergy = energy > 0;
    // צבע רקע הגלולה לפי מצב: נאסף - ירוק-מנטה עדין; ניתן לאיסוף - זהוב
    // בולט; אחרת - תלוי אם זו עמודת פרימיום (רצועת רקע חמימה-זהובה
    // עדינה, בדיוק כמו תג ה-⭐ בכותרת העמודה) או עמודת חינם (לבן שקוף
    // עמום, ניטרלי).
    Color pillColor;
    Color borderColor;
    if (claimed) {
      pillColor = const Color(0xFF34D399).withValues(alpha: 0.16);
      borderColor = const Color(0xFF34D399).withValues(alpha: 0.35);
    } else if (canClaim) {
      pillColor = const Color(0xFFFFC64B).withValues(alpha: 0.2);
      borderColor = const Color(0xFFFFC64B).withValues(alpha: 0.5);
    } else if (isPremium) {
      pillColor = const Color(0xFFFFD979).withValues(alpha: 0.08);
      borderColor = const Color(0xFFFFD979).withValues(alpha: 0.22);
    } else {
      pillColor = Colors.white.withValues(alpha: 0.06);
      borderColor = Colors.white.withValues(alpha: 0.1);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: canClaim ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: pillColor, border: Border.all(color: borderColor)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.rtl,
                children: [
                  // 🩹 אייקון וקטורי אמיתי (CoinIcon/EnergyIcon) ולא אימוג'י -
                  // בדיוק כמו שכבר תוקן בשאר האפליקציה (אימוג'י מטבע/אנרגיה
                  // לא אמינים בין מכשירים, ראה app_icons.dart).
                  if (isEnergy) const EnergyIcon(size: 14) else const CoinIcon(size: 14),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '${isEnergy ? energy : coins}',
                      textDirection: TextDirection.rtl,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 12.5, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (claimed)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF6EE7B3), size: 15)
              else if (canClaim)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: const Color(0xFFFFD979)),
                  child: const Text('אסוף', textDirection: TextDirection.rtl, style: TextStyle(color: Color(0xFF40170F), fontSize: 9.5, fontWeight: FontWeight.w900)),
                )
              // 🆕 עוד לא הגעת לשלב הזה (לא עניין של פרימיום) - מציגים
              // כמה כוכבים חסרים במקום מנעול סתמי, ישר על הפרס עצמו
              // (לא ליד קו-המסלול בשום מקום - ראו הערה ב-_buildTierRow).
              else if (!unlocked)
                Text('$pointsRequired⭐', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 9.5, fontWeight: FontWeight.w800))
              else
                Icon(Icons.lock_rounded, color: Colors.white.withValues(alpha: 0.35), size: 13),
            ],
          ),
        ),
      ),
    );
  }
}