// app_background.dart
// 🎨 גרסה סופית ובטוחה - ראו debug_log.dart וההיסטוריה. גילינו בכמה
// סבבי בדיקה נפרדים בפועל על מכשיר אמיתי (לא אמולטור) ש-iOS קורס על:
//   1. אנימציה אינסופית + RadialGradient מונפש.
//   2. RadialGradient סטטי (בלי שום אנימציה בכלל).
//   3. ואפילו CustomPaint עם drawCircle בלולאה (רשת הנקודות).
// לעומת זאת LinearGradient בכל הצורות שלו (כולל כמה שכבות עם alpha
// חלקי) נמצא בשימוש נרחב בכל האפליקציה (כפתורים, כרטיסים) בלי אף
// דיווח קריסה - כנראה ה-shader של LinearGradient פשוט זול/יציב בהרבה
// מ-RadialGradient/CustomPaint ב-Impeller. לכן הגרסה הזו חוזרת להיראות
// עשירה וצבעונית (כמו שאהבת), אבל אך ורק באמצעות כמה שכבות של
// LinearGradient מונחות אחת על השנייה - בלי RadialGradient, בלי
// CustomPaint, בלי ImageFilter, בלי אנימציה. זו הדרך הכי בטוחה שמצאנו
// עד כה לתת עומק/צבע לרקע בלי לסכן יציבות.
import 'package:flutter/material.dart';
import 'debug_log.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    DebugLog.add("AppBackground.build START");
    final result = Container(
      color: const Color(0xFF0A0717),
      // 🐛 תיקון: בלי fit: StackFit.expand, ה-Stack מקבל את הגובה שלו
      // מהתוכן (child) שהועבר לו, ולא בהכרח ממלא את כל גובה המסך -
      // אם התוכן קצר מגובה המסך (כמו במסך "נמצא יריב" עם ה-scroll
      // הקצר יחסית), נשארת רצועה לבנה ריקה בתחתית (הרקע הלבן של
      // ה-Scaffold מתחת לרקע הסגול). expand מכריח את הרקע הסגול תמיד
      // למלא את כל השטח הזמין, לא משנה כמה גבוה התוכן בפועל.
      child: Stack(
        fit: StackFit.expand,
        children: [
          // שכבה 1: גרדיאנט בסיס - סגול-כהה "אורורה"
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A1E7B), Color(0xFF3A1B78), Color(0xFF241154), Color(0xFF0A0717)],
                  stops: [0.0, 0.3, 0.64, 1.0],
                ),
              ),
            ),
          ),
          // שכבה 2: "זוהר" כתום-חמים מהפינה הימנית-עליונה, דוהה לשקיפות
          // מלאה - נותן את אותה תחושת צבע כמו הכתם הכתום הישן, אבל
          // באמצעות LinearGradient בלבד (בטוח).
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0x33FF8E3C), Color(0x00FF8E3C)],
                  stops: [0.0, 0.55],
                ),
              ),
            ),
          ),
          // שכבה 3: "זוהר" כחול קריר מהפינה השמאלית-תחתונה
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Color(0x2938BDF8), Color(0x0038BDF8)],
                  stops: [0.0, 0.55],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
    DebugLog.add("AppBackground.build END");
    return result;
  }
}