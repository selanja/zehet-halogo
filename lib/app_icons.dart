// app_icons.dart
//
// 🆕 אייקוני "מטבע" ו"אנרגיה" גלובליים לכל האפליקציה - עכשיו כתמונת
// PNG קבועה (Image.asset), לא אימוג'י ולא אייקון Material וקטורי.
//
// ⚠️ הערה חשובה על ההיסטוריה כאן - זו הפעם השלישית שמנסים לפתור את זה:
//  1. במקור: אימוג'י מטבע (🪙) ישירות בקוד - נשבר (ריבוע ריק/"תופו")
//     במכשירי גלקסי מסוימים בגלל חוסר תמיכה בפונט האימוג'י של אנדרואיד.
//  2. הוחלף לאייקון Material וקטורי (Icons.monetization_on_rounded) -
//     אבל זה בתורו לא הוצג בכלל אצלך (כנראה שהפונט MaterialIcons לא
//     נטען כמו שצריך במכשיר/בבילד שלך).
//  3. חזרנו לאימוג'י (CoinIcon/EnergyIcon כ-Text) - ואז זה *שוב* לא
//     הוצג אצלך (בדיוק כמו הבעיה המקורית - כנראה שוב חוסר תמיכה בפונט
//     האימוג'י במכשיר הספציפי שלך).
// המסקנה: שני הפתרונות תלויי-פונט (אימוג'י/Material) לא אמינים אצלך
// באופן עקבי. הפתרון היחיד שבאמת לא תלוי בשום פונט של המכשיר הוא תמונה
// קבועה (PNG) שמצוירת מראש ונטענת כ-asset - בדיוק כמו שכל שאר התמונות
// באפליקציה (לוגואים וכו') כבר עובדות אצלך בלי בעיה. זה הפתרון שמומש כאן.
//
// ⚠️ קבצי ה-PNG (assets/icon/coin.png, assets/icon/energy.png) צוירו
// כאן פשוטים וגנריים (מטבע זהב עגול / ברק כחול) - אם יש לך עיצוב/מוקאפ
// מדויק יותר בשבילם, אפשר להחליף את הקבצים בעצמך (אותו שם קובץ, אותה
// תיקייה) בלי לגעת בקוד בכלל.
import 'package:flutter/material.dart';

/// אייקון מטבע - תמונת PNG קבועה (assets/icon/coin.png), לא אימוג'י
/// ולא אייקון וקטורי - להצבה בכל מקום שהיה בו Icon(Icons.monetization_on_rounded).
class CoinIcon extends StatelessWidget {
  final double size;
  const CoinIcon({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/icon/coin.png', width: size, height: size, fit: BoxFit.contain);
  }
}

/// אייקון אנרגיה/ברק - תמונת PNG קבועה (assets/icon/energy.png), לא
/// אימוג'י ולא אייקון וקטורי - להצבה בכל מקום שהיה בו Icon(Icons.bolt_rounded)
/// שמייצג אנרגיה (לא XP - שם נשאר האייקון הוקטורי כרגיל).
class EnergyIcon extends StatelessWidget {
  final double size;
  const EnergyIcon({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/icon/energy.png', width: size, height: size, fit: BoxFit.contain);
  }
}

/// 🆕 אייקון מתנה - תמונת PNG קבועה (assets/icon/gift.png), לא אייקון
/// וקטורי (Icons.card_giftcard_rounded) - לפי אותה היסטוריה בדיוק
/// שמתועדת למעלה (אימוג'י/Material icons לא תמיד נטענים אצל המשתמש הזה
/// במכשיר הספציפי שלו) - להצבה בכל מקום שהיה בו Icon(Icons.card_giftcard_rounded).
class GiftIcon extends StatelessWidget {
  final double size;
  const GiftIcon({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/icon/gift.png', width: size, height: size, fit: BoxFit.contain);
  }
}