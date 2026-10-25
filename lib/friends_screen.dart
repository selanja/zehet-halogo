// friends_screen.dart
//
// 🆕 מסך "חברים" חדש - טאב "חברים" בסרגל התחתון הוביל עד עכשיו ישירות
// למסך "אתגר חבר לדו-קרב" (friend_challenge_screen.dart), שהיה ממוקד
// אך ורק בדו-קרב. לפי הבקשה המפורשת: "אין פואנטה לשים את העניין של
// החברים שמה אם זה נטו לדו קרב... אפשר לעשות שיהיה שמה חברים ואז ככה
// נניח להזמין אותם למשחק" - המסך הזה מחליף אותו כיעד הראשי של הטאב.
//
// 🆕 המשך ישיר לבקשה: "כל הקטע זה שלכל אחד יהיה מזהה משל עצמו וככה הוא
// מוסיף חברים גם לאפליקציה וגם לאזור הזה באפליקציה, ואז שהוא לוחץ על
// החבר הוא יכול להזמין אותו למשחק והוא יכול לראות אם הוא מחובר" - נוסף
// כאן קוד-חברים אישי לשיתוף (FriendService.myCode), הוספת חבר לפי קוד
// שהוא שולח לך, ורשימת חברים אמיתית עם נקודת "מחובר/לא מחובר" וכפתור
// "הזמן למשחק" לכל חבר (שולח לו הזמנת דו-קרב ישירה - ראה friend_service.dart
// ו-main.dart שמאזין להזמנות נכנסות).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, HapticFeedback;
import 'package:shared_preferences/shared_preferences.dart'; // 🆕 ה-XP של עצמי, ל"מי מוביל בין החברים שלך"
import 'package:share_plus/share_plus.dart';
import 'app_background.dart';
import 'app_notification.dart';
import 'friend_challenge_screen.dart';
import 'friend_service.dart';
import 'referral_service.dart';
import 'first_visit_explainer.dart'; // 🆕 הסבר חד-פעמי בכניסה הראשונה למסך
import 'l10n/app_localizations.dart';

class FriendsScreen extends StatefulWidget {
  final String username;
  const FriendsScreen({super.key, required this.username});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  // 🩹 אותם קישורי חנות אמיתיים המשמשים כבר את "הזמינו חברים" בהגדרות
  // (settings_screen.dart) - לא קישורים בדויים.
  static const String _iosStoreLink = "https://apps.apple.com/au/app/%D7%96%D7%94%D7%94-%D7%90%D7%AA-%D7%94%D7%9C%D7%95%D7%92%D7%95/id6797976197";
  static const String _androidStoreLink = "https://play.google.com/store/apps/details?id=com.ofeksela.zehethalogo&hl=he";

  String? _myCode;
  bool _loadingCode = true;
  List<FriendInfo> _friends = [];
  bool _loadingFriends = true;
  int _myXp = 0; // 🆕 ל"מי מוביל בין החברים שלך" - נטען פעם אחת מ-SharedPreferences

  // 🆕 בקשות חברות ממתינות (ראו friend_service.dart) - לפי בקשה מפורשת:
  // הוספת חבר לפי קוד כבר לא הופכת אתכם לחברים מיד, אלא שולחת בקשה
  // שהצד השני צריך לאשר. _respondingTo מונע לחיצה כפולה על אישור/דחייה
  // של אותה בקשה בזמן שהיא כבר בטיפול.
  List<FriendRequestInfo> _pendingRequests = [];
  bool _loadingRequests = true;
  final Set<String> _respondingTo = {};

  final TextEditingController _addCodeController = TextEditingController();
  bool _addingFriend = false;
  String? _addFriendError;

  // 🆕 הסבר חד-פעמי - ראו first_visit_explainer.dart.
  bool _showExplainer = false;

  @override
  void initState() {
    super.initState();
    _loadMyCode();
    _loadFriends();
    _loadMyXp();
    _loadPendingRequests();
    FirstVisitExplainer.shouldShow('friends').then((show) {
      if (show && mounted) setState(() => _showExplainer = true);
    });
  }

  Future<void> _loadMyXp() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _myXp = prefs.getInt('xp') ?? 0);
  }

  @override
  void dispose() {
    _addCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadMyCode() async {
    try {
      final code = await FriendService.myCode();
      if (!mounted) return;
      setState(() {
        _myCode = code;
        _loadingCode = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCode = false);
    }
  }

  Future<void> _loadFriends() async {
    setState(() => _loadingFriends = true);
    final friends = await FriendService.fetchFriends();
    if (!mounted) return;
    setState(() {
      _friends = friends;
      _loadingFriends = false;
    });
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _loadingRequests = true);
    final requests = await FriendService.fetchPendingRequests();
    if (!mounted) return;
    setState(() {
      _pendingRequests = requests;
      _loadingRequests = false;
    });
  }

  Future<void> _respondToRequest(FriendRequestInfo request, {required bool accept}) async {
    setState(() => _respondingTo.add(request.id));
    final ok = accept
        ? await FriendService.acceptFriendRequest(request.id, requesterName: request.name, myName: widget.username)
        : await FriendService.declineFriendRequest(request.id);
    if (!mounted) return;
    setState(() {
      _respondingTo.remove(request.id);
      if (ok) _pendingRequests.removeWhere((r) => r.id == request.id);
    });
    if (ok && accept) {
      AppNotification.show(context, AppLocalizations.of(context)!.friendsNowFriendsMessage, type: AppNotificationType.success);
      _loadFriends();
    } else if (!ok) {
      AppNotification.show(context, AppLocalizations.of(context)!.friendChallengeGenericError, type: AppNotificationType.error);
    }
  }

  // 🩹 תוקן: זה כפתור ה-CTA הראשי "הזמנה למשחק" - עד עכשיו שלח רק קישור
  // רגיל לחנות, בלי שום זיהוי של מי הזמין את מי. עכשיו שולח קישור אחד
  // לדף נחיתה (ReferralService.shareLink) שכבר יודע לבד להפנות לחנות
  // הנכונה (אנדרואיד/אייפון) *עם הקוד האישי מוטמע בתוכו* - כשהחבר
  // מתקין ופותח את האפליקציה, שניכם מקבלים מטבעות אוטומטית, בלי להזין
  // שום קוד ידנית ובלי קשר בכלל למערכת החברים בתוך האפליקציה (ראו
  // referral_service.dart).
  String get _inviteText {
    final code = _myCode;
    final link = code != null ? ReferralService.shareLink(code) : _androidStoreLink;
    return AppLocalizations.of(context)!.friendsInviteText(link, ReferralService.bonusCoins);
  }

  Future<void> _inviteToGame() async {
    HapticFeedback.lightImpact();
    final loc = AppLocalizations.of(context)!;
    final inviteText = _inviteText;
    try {
      // 🐛 תוקן: "באייפון שיתוף כותב שאי אפשר לשתף" - חסר sharePositionOrigin
      // (נקודת העיגון של ה-popover ב-iOS, ראו share_helper.dart להסבר המלא).
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(inviteText, subject: loc.appLoadingTitle, sharePositionOrigin: box != null ? (box.localToGlobal(Offset.zero) & box.size) : null);
    } catch (_) {
      if (!mounted) return;
      Clipboard.setData(ClipboardData(text: inviteText));
      AppNotification.show(context, loc.friendsShareFallbackCopiedWithPaste);
    }
  }

  // 🆕 שיתוף קוד החברים האישי - מודיע גם על הקוד וגם נותן קישור להורדה,
  // כדי שחבר חדש (בלי האפליקציה בכלל) יוכל גם להוריד וגם להצטרף ישר
  // כחבר ברגע שהוא פותח את האפליקציה בפעם הראשונה.
  Future<void> _shareMyCode() async {
    final code = _myCode;
    if (code == null) return;
    HapticFeedback.lightImpact();
    final loc = AppLocalizations.of(context)!;
    final text = loc.friendsShareCodeText(code, _iosStoreLink, _androidStoreLink);
    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(text, subject: loc.friendsShareCodeSubject, sharePositionOrigin: box != null ? (box.localToGlobal(Offset.zero) & box.size) : null);
    } catch (_) {
      if (!mounted) return;
      Clipboard.setData(ClipboardData(text: text));
      AppNotification.show(context, loc.friendsShareFallbackCopied);
    }
  }

  void _copyMyCode() {
    final code = _myCode;
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    AppNotification.show(context, AppLocalizations.of(context)!.friendsCodeCopiedMessage, type: AppNotificationType.success);
  }

  Future<void> _submitAddFriend() async {
    final loc = AppLocalizations.of(context)!;
    final code = _addCodeController.text.trim();
    if (code.length != FriendService.codeLength) {
      setState(() => _addFriendError = loc.friendsCodeLengthError(FriendService.codeLength));
      return;
    }
    setState(() {
      _addingFriend = true;
      _addFriendError = null;
    });
    final result = await FriendService.sendFriendRequest(code, myName: widget.username);
    if (!mounted) return;
    setState(() => _addingFriend = false);
    switch (result) {
      case AddFriendResult.requestSent:
      case AddFriendResult.success: // תאימות היסטורית - לא אמור להיזרק בפועל יותר
        _addCodeController.clear();
        AppNotification.show(context, loc.friendsRequestSentMessage, type: AppNotificationType.success);
        break;
      case AddFriendResult.alreadyRequested:
        setState(() => _addFriendError = loc.friendsAlreadyRequestedError);
        break;
      case AddFriendResult.alreadyFriends:
        setState(() => _addFriendError = loc.friendsAlreadyFriendsError);
        break;
      case AddFriendResult.ownCode:
        setState(() => _addFriendError = loc.friendsOwnCodeError);
        break;
      case AddFriendResult.notFound:
        setState(() => _addFriendError = loc.friendsCodeNotFoundError);
        break;
      case AddFriendResult.invalidCode:
        setState(() => _addFriendError = loc.friendsInvalidCodeError);
        break;
      case AddFriendResult.error:
        setState(() => _addFriendError = loc.friendsGenericErrorLater);
        break;
    }
  }

  void _inviteFriend(FriendInfo friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FriendChallengeScreen(
          username: widget.username,
          targetFriendId: friend.id,
          targetFriendName: friend.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    // 🆕 "בכל המסכים צריך להיות למטה את המניו, גם במסך של החברים" - המסך
    // הזה היה היחיד שנבנה בלי AppBottomNav (Scaffold+SafeArea רגיל, לא
    // Stack). עוטפים עכשיו בדיוק כמו shop_screen.dart/missions_screen.dart:
    // Scaffold -> body: Stack -> [AppBackground(...תוכן...), AppBottomNav].
    return Scaffold(
      body: Stack(
        children: [
          AppBackground(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await Future.wait([_loadMyCode(), _loadFriends(), _loadMyXp(), _loadPendingRequests()]);
                      },
                      color: const Color(0xFFA7F3D0),
                      backgroundColor: const Color(0xFF241a4f),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            _buildHero(),
                            const SizedBox(height: 22),
                            // 🩹 תוקן לפי בקשה מפורשת: "תעלה את העניין של
                            // הפרס למעלה במקום שיהיה למטה" - כרטיס "הזמן
                            // למשחק" (ReferralService, זה שבאמת נותן מטבעות
                            // על התקנה חדשה) עבר להיות ראשון בעמוד - הוא
                            // הפעולה הכי משתלמת/חשובה כאן, לא "הקוד שלך"
                            // שרק מחבר כחברים בלי פרס (ראו ההערה שם).
                            _buildInviteCard(),
                            const SizedBox(height: 22),
                            _buildDivider(),
                            const SizedBox(height: 18),
                            _buildMyCodeCard(),
                            const SizedBox(height: 14),
                            _buildAddFriendCard(),
                            // 🆕 בקשות חברות ממתינות - מוצג רק אם יש כאלה
                            // (ראה _pendingRequests/_loadPendingRequests).
                            if (!_loadingRequests && _pendingRequests.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _buildPendingRequestsSection(),
                            ],
                            const SizedBox(height: 22),
                            _buildFriendsListSection(),
                            // 🆕 "תוסיף איזה משהו מעניין שיהיה אפשר לעשות
                            // עוד משהו בין חברים" - מיני-טבלת שיאים בין
                            // החברים שלך (כולל אתה) לפי XP, כדי לראות מי
                            // מוביל - בלי כלכלה חדשה/סיכון ניצול, קריאה
                            // בלבד מנתונים שכבר קיימים (אותו xp שמוצג
                            // בטבלת השיאים הראשית).
                            if (_friends.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _buildFriendsLeaderboard(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showExplainer)
            buildFirstVisitOverlay(
              context: context,
              title: loc.friendsExplainerTitle,
              points: [
                ExplainerPoint('🔑', loc.friendsExplainerCodeTitle, loc.friendsExplainerCodeBody),
                ExplainerPoint('🟢', loc.friendsExplainerOnlineTitle, loc.friendsExplainerOnlineBody),
                ExplainerPoint('⚔️', loc.friendsExplainerInviteTitle, loc.friendsExplainerInviteBody),
              ],
              onDismiss: () {
                FirstVisitExplainer.markSeen('friends');
                setState(() => _showExplainer = false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.12))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(AppLocalizations.of(context)!.logoLevelOrDivider, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.12))),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
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
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.friendsTopBarTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(colors: [Color(0xFFA7F3D0), Color(0xFF34D399)]),
            boxShadow: [BoxShadow(color: const Color(0xFF34D399).withValues(alpha: 0.35), blurRadius: 22)],
          ),
          child: const Icon(Icons.groups_rounded, color: Color(0xFF0B3B2E), size: 38),
        ),
        const SizedBox(height: 14),
        Text(
          AppLocalizations.of(context)!.friendsHeroTitle,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context)!.friendsHeroSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
        ),
      ],
    );
  }

  // 🆕 "הקוד שלך" - המזהה האישי לשיתוף, כדי שחברים יוכלו להוסיף אותך.
  Widget _buildMyCodeCard() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF7DD3FC).withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF38BDF8).withValues(alpha: 0.16), const Color(0xFF38BDF8).withValues(alpha: 0.03)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.badge_rounded, color: Color(0xFF7DD3FC), size: 20),
              const SizedBox(width: 8),
              Text(loc.friendsMyCodeTitle, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          // 🩹 תוקן לפי דיווח מפורש: "שתף קוד משתף אבל בלי לקבל פרס" - זה
          // בכוונה (הקוד מחבר כחברים מישהו שכבר מותקן אצלו המשחק, לא מביא
          // משתמש חדש - לכן אין כאן פרס, בשונה מ"הזמן למשחק" למטה שכן נותן
          // מטבעות כי הוא מביא התקנה חדשה). עכשיו מבהירים את זה בממשק במקום
          // להשאיר את זה עמום.
          Text(loc.friendsMyCodeHint, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (_loadingCode)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF7DD3FC))),
            )
          else
            Text(
              _myCode ?? "----",
              style: const TextStyle(color: Color(0xFF7DD3FC), fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 6),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _myCode == null ? null : _copyMyCode,
                  child: const Padding(
                    padding: EdgeInsets.all(13),
                    child: Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _myCode == null ? null : _shareMyCode,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)]),
                    ),
                    child: Text(loc.friendsShareCodeButton, style: const TextStyle(color: Color(0xFF0C2A3D), fontSize: 15, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🆕 הוספת חבר לפי קוד שקיבלת ממנו.
  Widget _buildAddFriendCard() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(loc.friendsAddFriendPrompt, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addCodeController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: FriendService.codeLength,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    hintText: '------',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), letterSpacing: 3),
                  ),
                  onSubmitted: (_) => _submitAddFriend(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _addingFriend ? null : _submitAddFriend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA7F3D0),
                    foregroundColor: const Color(0xFF0B3B2E),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _addingFriend
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF0B3B2E)))
                      : Text(loc.friendsAddButton, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
          if (_addFriendError != null) ...[
            const SizedBox(height: 8),
            Text(_addFriendError!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12.5, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  // 🆕 בקשות חברות ממתינות - לפי בקשה מפורשת: הוספת חבר לפי קוד לא
  // הופכת אתכם לחברים מיד, הצד השני צריך לאשר קודם. כל שורה מציגה את
  // שם השולח + כפתורי אישור (✓ ירוק, יוצר חברות הדדית) ודחייה (✕ אדום,
  // רק מוחק את הבקשה).
  Widget _buildPendingRequestsSection() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(loc.friendsPendingRequestsTitle, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0xFFFB7185).withValues(alpha: 0.25)),
              child: Text("${_pendingRequests.length}", style: const TextStyle(color: Color(0xFFFDA4AF), fontSize: 12, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._pendingRequests.map((request) {
          final busy = _respondingTo.contains(request.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              color: Colors.white.withValues(alpha: 0.05),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFA7F3D0).withValues(alpha: 0.25),
                  child: Text(
                    request.name.isNotEmpty ? request.name.substring(0, 1).toUpperCase() : "?",
                    style: const TextStyle(color: Color(0xFFA7F3D0), fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    request.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white54)),
                  )
                else ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _respondToRequest(request, accept: true),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF34D399).withValues(alpha: 0.22)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check_rounded, color: Color(0xFF6EE7B7), size: 19),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _respondToRequest(request, accept: false),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFB7185).withValues(alpha: 0.18)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close_rounded, color: Color(0xFFFDA4AF), size: 19),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // 🆕 "החברים שלי" - שם + נקודת "מחובר"/"לא מחובר" + כפתור "הזמן למשחק".
  Widget _buildFriendsListSection() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(loc.friendsMyFriendsTitle, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
            if (_friends.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text("(${_friends.length})", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (_loadingFriends)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFA7F3D0))),
          )
        else if (_friends.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Colors.white.withValues(alpha: 0.04)),
            child: Text(
              loc.friendsEmptyListMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12.5),
            ),
          )
        else
          Column(
            children: [
              for (final friend in _friends) ...[
                _friendRow(friend),
                const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }

  Widget _friendRow(FriendInfo friend) {
    final loc = AppLocalizations.of(context)!;
    final letter = friend.name.trim().isNotEmpty ? friend.name.trim().substring(0, 1).toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withValues(alpha: 0.05)),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFE79A), Color(0xFFFFB24D)])),
                alignment: Alignment.center,
                child: Text(letter, style: const TextStyle(color: Color(0xFF2A1740), fontSize: 15, fontWeight: FontWeight.w900)),
              ),
              Positioned(
                bottom: -1,
                left: -1,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: friend.online ? const Color(0xFF34D399) : Colors.white24,
                    border: Border.all(color: const Color(0xFF1D0E3C), width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(friend.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                Text(
                  friend.online ? loc.friendsOnlineStatus : loc.friendsOfflineStatus,
                  style: TextStyle(color: friend.online ? const Color(0xFF6EE7B7) : Colors.white.withValues(alpha: 0.4), fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 🆕 "כשהמשתמש לא מחובר שלא תהיה אפשרות להזמין אותו" - כפתור
          // "הזמן למשחק" מנוטרל (onTap: null) וכהה יותר כשהחבר לא מחובר,
          // עם טקסט שמסביר למה. מוזמן רק חבר שבאמת יכול לקבל את ההזמנה
          // בזמן אמת (ראה main.dart - watchIncomingInvite).
          Material(
            color: friend.online ? const Color(0xFFFB7185).withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: friend.online ? () => _inviteFriend(friend) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Text(
                  friend.online ? loc.friendsInviteButtonLabel : loc.friendsOfflineStatus,
                  style: TextStyle(color: friend.online ? const Color(0xFFFDA4AF) : Colors.white.withValues(alpha: 0.3), fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          // 🆕 הסרת חברות - לפי בקשה מפורשת. עם דיאלוג אישור (לא מחיקה
          // מיידית בלחיצה אחת) כי זו פעולה הדדית שלא ניתן לבטל בקלות.
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => _confirmRemoveFriend(friend),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.person_remove_rounded, color: Colors.white.withValues(alpha: 0.35), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveFriend(FriendInfo friend) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241a4f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.friendsRemoveConfirmTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text(
          loc.friendsRemoveConfirmBody(friend.name),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13.5),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.duelLobbyCancelButton, style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.friendsRemoveButton, style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await FriendService.removeFriend(friend.id);
    if (!mounted) return;
    if (ok) {
      setState(() => _friends.removeWhere((f) => f.id == friend.id));
      AppNotification.show(context, loc.friendsRemovedMessage(friend.name));
    } else {
      AppNotification.show(context, loc.friendChallengeGenericError, type: AppNotificationType.error);
    }
  }

  // 🆕 "מי מוביל בין החברים שלך" - כולל אותך, ממוין לפי XP (יורד). כל
  // עוד לא נבנה עוד משהו אינטראקטיבי בין חברים, זו דרך קלה וללא סיכון
  // כלכלי לראות התקדמות יחסית לחברים - מבוסס על נתונים שכבר קיימים
  // (xp מסונכרן ל-Firestore ממילא לצורך טבלת השיאים הראשית).
  Widget _buildFriendsLeaderboard() {
    final loc = AppLocalizations.of(context)!;
    final rows = <({String name, int xp, bool isMe})>[
      (name: widget.username.isNotEmpty ? widget.username : loc.duelLobbyYouLabel, xp: _myXp, isMe: true),
      for (final f in _friends) (name: f.name, xp: f.xp, isMe: false),
    ]..sort((a, b) => b.xp.compareTo(a.xp));

    const medalColors = [Color(0xFFFFD86B), Color(0xFFD1D5DB), Color(0xFFCD7F32)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD86B).withValues(alpha: 0.28)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFFFD86B).withValues(alpha: 0.1), const Color(0xFFFFD86B).withValues(alpha: 0.02)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD86B), size: 20),
              const SizedBox(width: 8),
              Text(loc.friendsLeaderboardTitle, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: rows[i].isMe ? const Color(0xFFFFD86B).withValues(alpha: 0.12) : Colors.transparent,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: i < 3 ? medalColors[i] : Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rows[i].isMe ? loc.friendsLeaderboardYouRow(rows[i].name) : rows[i].name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: rows[i].isMe ? FontWeight.w900 : FontWeight.w700),
                    ),
                  ),
                  Text('${rows[i].xp} XP', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInviteCard() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF34D399).withValues(alpha: 0.16), const Color(0xFF34D399).withValues(alpha: 0.03)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFA7F3D0), size: 20),
              const SizedBox(width: 8),
              Text(loc.friendsInviteCardTitle, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.friendsInviteCardBody(ReferralService.bonusCoins),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFA7F3D0), Color(0xFF34D399)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                // 🩹 עכשיו שההזמנה כוללת את הקוד האישי - ממתינים שהוא
                // ייטען (ראו _load) לפני שמאפשרים לשתף, כדי שלא תישלח
                // הודעה עם "----" במקום קוד אמיתי.
                onPressed: _myCode == null ? null : _inviteToGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(loc.friendsSendInviteButton, style: const TextStyle(color: Color(0xFF0B3B2E), fontSize: 15.5, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }

}