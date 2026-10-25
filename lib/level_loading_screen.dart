// level_loading_screen.dart
// 🆕 מסך "טעינת שלב" (מכינים את השלב...) - לפי מוקאפ "All_Screens.html",
// המסך "00c". מוצג לרגע קצר (כ-1.4 שניות) בין לחיצה על שלב במסך הרמות
// לבין הופעת החידה עצמה - עם טבעת מסתובבת בגרדיאנט זהב, כותרת/תת-כותרת
// (קטגוריה · מספר שלב), וכרטיס "ידעת?" עם טיפ אקראי על המשחק.
// ⚠️ לא קיים בכלל באפליקציה לפני כן - זה מסך חדש שנוסף לפי בקשת המשתמש.
import 'dart:math';
import 'package:flutter/material.dart';
import 'logo_level_screen.dart';
import 'l10n/app_localizations.dart';

class LevelLoadingScreen extends StatefulWidget {
  final int puzzleId;
  final bool isRandomMode;
  final String categoryLabel; // למשל "חברות חלק א · שלב 7"

  const LevelLoadingScreen({
    super.key,
    required this.puzzleId,
    required this.categoryLabel,
    this.isRandomMode = false,
  });

  @override
  State<LevelLoadingScreen> createState() => _LevelLoadingScreenState();
}

class _LevelLoadingScreenState extends State<LevelLoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  late final int _tipIndex;
  // 🛠️ תוקן באג קריטי: קודם המסך הזה היה עושה pushReplacement למסך
  // החידה (LogoLevelScreen) - כלומר פותח route חדש לגמרי במקומו. זה
  // "שבר" את שרשרת ה-Future של ה-Navigator.push המקורי שממנו
  // sub_levels_screen.dart מרענן את ההתקדמות (.then(() => _loadProgress())):
  // ה-Future ההוא היה נפתר (resolve) מיד ברגע ההחלפה (אחרי כ-1.4 שניות),
  // ולא כשבאמת חוזרים מהחידה עם כפתור "חזרה" - ולכן מסך השלבים תמיד הציג
  // התקדמות ישנה עד שחוזרים אליו דרך מסך הבית. עכשיו אין שום ניווט/route
  // נוסף בכלל: מסך החידה עצמו נבנה כבר "מתחת" למסך הטעינה, ומסך הטעינה
  // הוא רק שכבת אנימציה שדוהה (fade out) מעליו. כך יש route יחיד בלבד בין
  // מסך השלבים לחידה, וה-.then() המקורי מתעורר בדיוק כשלוחצים "חזרה" מהחידה.
  bool _showOverlay = true;

  // 💡 מספר הטיפים הקצרים על מנגנוני המשחק - נבחר אחד אקראי בכל פעם שהמסך נטען
  static const int _tipCount = 6;

  List<String> _tips(AppLocalizations loc) => [
        loc.levelLoadingTip1,
        loc.levelLoadingTip2,
        loc.levelLoadingTip3,
        loc.levelLoadingTip4,
        loc.levelLoadingTip5,
        loc.levelLoadingTip6,
      ];

  @override
  void initState() {
    super.initState();
    _tipIndex = Random().nextInt(_tipCount);
    _spinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
    // ⏱️ טעינה "מדומה" קצרה - מספיקה כדי שהמעבר לא יורגש כ"קפיצה" פתאומית,
    // אבל קצרה מספיק שלא תעצבן שחקן שממהר לשחק. בזמן הזה החידה כבר נבנית
    // בפועל מתחת לשכבת הטעינה, כך שכשהיא נעלמת החידה כבר מוכנה ומחכה.
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _showOverlay = false);
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final tip = _tips(loc)[_tipIndex];
    return Stack(
      children: [
        // 🧩 מסך החידה עצמו - נבנה תמיד, גם בזמן שהטעינה עדיין מוצגת מעליו.
        // אין כאן שום Navigator.push/pushReplacement - זה אותו route בדיוק.
        LogoLevelScreen(puzzleId: widget.puzzleId, isRandomMode: widget.isRandomMode),

        // ✨ שכבת אנימציית הטעינה - דוהה (fade out) אחרי כ-1.4 שניות ואז
        // מפסיקה לקלוט מגע (IgnorePointer) כדי לא לחסום את החידה מתחתיה.
        IgnorePointer(
          ignoring: !_showOverlay,
          child: AnimatedOpacity(
            opacity: _showOverlay ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
            child: Scaffold(
              backgroundColor: const Color(0xFF120C2E),
              body: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2A1360), Color(0xFF3A1B78), Color(0xFF211055), Color(0xFF120C2E)],
                        stops: [0.0, 0.3, 0.64, 1.0],
                      ),
                    ),
                  ),
                  Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
                  SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // טבעת מסתובבת בגרדיאנט זהב סביב "?" - בדיוק כמו במוקאפ
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 132,
                                  height: 132,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(colors: [const Color(0xFFFFBE50).withValues(alpha: 0.3), const Color(0xFFFFBE50).withValues(alpha: 0.0)]),
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _spinController,
                                  builder: (context, child) => Transform.rotate(angle: _spinController.value * 2 * pi, child: child),
                                  child: Container(
                                    width: 132,
                                    height: 132,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: SweepGradient(
                                        colors: [Colors.transparent, Color(0xFFFFD86B), Color(0xFFFF8A3C), Colors.transparent],
                                        stops: [0.0, 0.3, 0.5, 0.78],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 114,
                                  height: 114,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF1C1046),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: const Center(
                                    child: Text("?", style: TextStyle(fontSize: 46, color: Color(0xFFFFD86B), fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            Text(loc.levelLoadingTitle, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 5),
                            Text(widget.categoryLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 26),
                            // כרטיס "ידעת?" עם טיפ אקראי
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.16), style: BorderStyle.solid),
                                color: Colors.white.withValues(alpha: 0.04),
                              ),
                              child: Column(
                                children: [
                                  Text(loc.levelLoadingDidYouKnow, style: const TextStyle(color: Color(0xFFFFD86B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                                  const SizedBox(height: 5),
                                  Text(tip, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.62), fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    const spacing = 26.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}