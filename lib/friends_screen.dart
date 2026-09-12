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
import 'friend_challenge_screen.dart';
import 'friend_service.dart';
import 'app_bottom_nav.dart'; // 🆕 סרגל ניווט תחתון קבוע - חסר היה במסך הזה בלבד

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

  final TextEditingController _addCodeController = TextEditingController();
  bool _addingFriend = false;
  String? _addFriendError;

  @override
  void initState() {
    super.initState();
    _loadMyCode();
    _loadFriends();
    _loadMyXp();
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

  String get _inviteText =>
      "בואו לשחק איתי במשחק 🎮 \"זהה את הלוגו!\" - מי מכיר הכי הרבה לוגואים? 🔥\n\n"
      "📱 אייפון: $_iosStoreLink\n"
      "🤖 אנדרואיד/גלקסי: $_androidStoreLink";

  Future<void> _inviteToGame() async {
    HapticFeedback.lightImpact();
    try {
      await Share.share(_inviteText, subject: "זהה את הלוגו!");
    } catch (_) {
      if (!mounted) return;
      Clipboard.setData(ClipboardData(text: _inviteText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("לא נמצאה אפליקציית שיתוף - ההודעה הועתקה, אפשר להדביק ולשלוח", textDirection: TextDirection.rtl)),
      );
    }
  }

  // 🆕 שיתוף קוד החברים האישי - מודיע גם על הקוד וגם נותן קישור להורדה,
  // כדי שחבר חדש (בלי האפליקציה בכלל) יוכל גם להוריד וגם להצטרף ישר
  // כחבר ברגע שהוא פותח את האפליקציה בפעם הראשונה.
  Future<void> _shareMyCode() async {
    final code = _myCode;
    if (code == null) return;
    HapticFeedback.lightImpact();
    final text = "בוא נהיה חברים ב\"זהה את הלוגו!\" 🎮\n"
        "הקוד שלי: $code\n"
        "(פותחים את האפליקציה -> חברים -> \"יש לי קוד\" ומזינים אותו)\n\n"
        "עוד לא הורדת? 📱 אייפון: $_iosStoreLink\n🤖 אנדרואיד/גלקסי: $_androidStoreLink";
    try {
      await Share.share(text, subject: "בוא נהיה חברים!");
    } catch (_) {
      if (!mounted) return;
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("לא נמצאה אפליקציית שיתוף - ההודעה הועתקה", textDirection: TextDirection.rtl)),
      );
    }
  }

  void _copyMyCode() {
    final code = _myCode;
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("הקוד הועתק!", textDirection: TextDirection.rtl)),
    );
  }

  Future<void> _submitAddFriend() async {
    final code = _addCodeController.text.trim();
    if (code.length != FriendService.codeLength) {
      setState(() => _addFriendError = "קוד חייב להיות בן ${FriendService.codeLength} תווים");
      return;
    }
    setState(() {
      _addingFriend = true;
      _addFriendError = null;
    });
    final result = await FriendService.addFriendByCode(code, myName: widget.username);
    if (!mounted) return;
    setState(() => _addingFriend = false);
    switch (result) {
      case AddFriendResult.success:
        _addCodeController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("נוסף לרשימת החברים! 🎉", textDirection: TextDirection.rtl)),
        );
        _loadFriends();
        break;
      case AddFriendResult.alreadyFriends:
        setState(() => _addFriendError = "כבר חברים איתו");
        break;
      case AddFriendResult.ownCode:
        setState(() => _addFriendError = "זה הקוד שלך - שלח אותו לחבר, לא להזין אותו כאן");
        break;
      case AddFriendResult.notFound:
        setState(() => _addFriendError = "לא נמצא קוד כזה - ודא שהקלדת נכון");
        break;
      case AddFriendResult.invalidCode:
        setState(() => _addFriendError = "קוד לא תקין");
        break;
      case AddFriendResult.error:
        setState(() => _addFriendError = "משהו השתבש - נסה שוב");
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
                        await Future.wait([_loadMyCode(), _loadFriends(), _loadMyXp()]);
                      },
                      color: const Color(0xFFA7F3D0),
                      backgroundColor: const Color(0xFF241a4f),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            _buildHero(),
                            const SizedBox(height: 26),
                            _buildMyCodeCard(),
                            const SizedBox(height: 14),
                            _buildAddFriendCard(),
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
                            const SizedBox(height: 22),
                            _buildDivider(),
                            const SizedBox(height: 18),
                            // 🆕 "תוריד את הלמטה של אתגר חבר לדו קרב, אין
                            // צורך בזה הוא יכול ללחוץ עליו ולהזמין" - כרטיס
                            // "אתגר חבר לדו-קרב" (קוד גנרי, בלי לבחור חבר
                            // ספציפי) הוסר - ההזמנה עצמה נעשית ישירות מכפתור
                            // "הזמן למשחק" על כל חבר ברשימה למעלה.
                            _buildInviteCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const AppBottomNav(current: AppTab.friends),
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
          child: Text("או", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5, fontWeight: FontWeight.w700)),
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
          const Expanded(
            child: Text(
              "חברים",
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
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
        const Text(
          "שחק עם חברים",
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          "הוסף חברים לפי קוד, תראה מי מחובר, והזמן אותם ישר למשחק",
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
        ),
      ],
    );
  }

  // 🆕 "הקוד שלך" - המזהה האישי לשיתוף, כדי שחברים יוכלו להוסיף אותך.
  Widget _buildMyCodeCard() {
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
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.badge_rounded, color: Color(0xFF7DD3FC), size: 20),
              const SizedBox(width: 8),
              const Text("הקוד שלך", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
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
            textDirection: TextDirection.rtl,
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
                    child: const Text("שתף קוד", style: TextStyle(color: Color(0xFF0C2A3D), fontSize: 15, fontWeight: FontWeight.w900)),
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
          const Text("יש לך קוד של חבר?", textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            textDirection: TextDirection.rtl,
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
                      : const Text("הוסף", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
          if (_addFriendError != null) ...[
            const SizedBox(height: 8),
            Text(_addFriendError!, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12.5, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  // 🆕 "החברים שלי" - שם + נקודת "מחובר"/"לא מחובר" + כפתור "הזמן למשחק".
  Widget _buildFriendsListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            const Text("החברים שלי", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
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
              "עדיין אין לך חברים כאן - שתף את הקוד שלך למעלה כדי להתחיל",
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
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
    final letter = friend.name.trim().isNotEmpty ? friend.name.trim().substring(0, 1).toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withValues(alpha: 0.05)),
      child: Row(
        textDirection: TextDirection.rtl,
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
                Text(friend.name, textDirection: TextDirection.rtl, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                Text(
                  friend.online ? "מחובר" : "לא מחובר",
                  textDirection: TextDirection.rtl,
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
                  friend.online ? "הזמן למשחק" : "לא מחובר",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: friend.online ? const Color(0xFFFDA4AF) : Colors.white.withValues(alpha: 0.3), fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 "מי מוביל בין החברים שלך" - כולל אותך, ממוין לפי XP (יורד). כל
  // עוד לא נבנה עוד משהו אינטראקטיבי בין חברים, זו דרך קלה וללא סיכון
  // כלכלי לראות התקדמות יחסית לחברים - מבוסס על נתונים שכבר קיימים
  // (xp מסונכרן ל-Firestore ממילא לצורך טבלת השיאים הראשית).
  Widget _buildFriendsLeaderboard() {
    final rows = <({String name, int xp, bool isMe})>[
      (name: widget.username.isNotEmpty ? widget.username : 'אתה', xp: _myXp, isMe: true),
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
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD86B), size: 20),
              const SizedBox(width: 8),
              const Text("מי מוביל בין החברים שלך", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
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
                textDirection: TextDirection.rtl,
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
                      rows[i].isMe ? '${rows[i].name} (אתה)' : rows[i].name,
                      textDirection: TextDirection.rtl,
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
            textDirection: TextDirection.rtl,
            children: [
              const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFA7F3D0), size: 20),
              const SizedBox(width: 8),
              const Text("הזמנה למשחק", textDirection: TextDirection.rtl, style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "שלח לחברים קישור להורדת האפליקציה - וואטסאפ, מסרונים או כל אפליקציה אחרת",
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
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
                onPressed: _inviteToGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("שלח הזמנה", style: TextStyle(color: Color(0xFF0B3B2E), fontSize: 15.5, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }

}