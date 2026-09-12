// coupon_service.dart
// 🆕 מערכת קופונים למימוש בחנות. Firestore הוא מקור האמת היחיד ל"כמה
// שחקנים כבר השתמשו בקוד" - בכוונה לא Google Sheets ישירות, כי:
// 1. Firestore תומך ב-transaction אטומי (2 שחקנים לא יכולים "לגנוב" את
//    השימוש האחרון בקופון בו-זמנית ולגרום למונה לחרוג מהמגבלה).
// 2. באפליקציה הזו כבר הוחלט בעבר להחליף את ה-leaderboard מ-Google
//    Sheets+Apps Script ל-Firestore בדיוק בגלל "cold start" איטי של
//    הסקריפט - נמנע מלחזור לאותה בעיה כאן, במסך שגם הוא רגיש לזמן תגובה.
//
// איך מוסיפים/עורכים קופונים (ה"אקסל" בפועל):
// הכי נוח לנהל את זה ישירות מ-Firebase Console -> Firestore Database ->
// אוסף "coupons" - זו טבלה חיה שנראית ומתנהגת כמו גיליון (שורות ועמודות),
// בלי צורך בקוד. לכל קופון: מסמך חדש שה-ID שלו הוא קוד הקופון באותיות
// גדולות (למשל "WELCOME15"), עם השדות:
//   coins      (מספר)  - כמה מטבעות מקבלים
//   maxUses    (מספר)  - כמה שחקנים יכולים להשתמש בקוד בסה"כ
//   usedCount  (מספר)  - מתחיל מ-0, מתעדכן אוטומטית לבד - אל תיגע בזה
//   active     (בוליאני) - true/false, לכיבוי קוד בלי למחוק אותו
//
// 🔁 סנכרון מ-Google Sheets: אם נוח לך לתחזק את רשימת הקופונים בגיליון
// אקסל/Sheets ולדחוף אותה ל-Firestore בלחיצה, יש סקריפט Python נפרד
// (sync_coupons_from_sheet.py) שמצורף בנפרד - מריצים אותו כל פעם שרוצים
// שהשינויים בגיליון "יעלו" לאפליקציה. זה לא סנכרון אוטומטי חי (זה ידרוש
// הקמת שרת/Cloud Function בצד גוגל), אבל זו הדרך הכי אמינה בלי לחזור
// לבעיות הביצועים שכבר היו עם Sheets בעבר.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum CouponResult {
  success,
  notFound,
  inactive,
  usedUp,
  alreadyUsedByThisDevice,
  error,
}

class CouponRedeemOutcome {
  final CouponResult result;
  final int coins; // רלוונטי רק אם result == success
  // 🩺 זמני, לצורך אבחון: כשיש שגיאה, השדה הזה מכיל את הודעת השגיאה
  // האמיתית מ-Firestore (למשל "permission-denied") - ה-UI מציג אותה
  // כדי שאפשר יהיה לצלם מסך ולזהות בדיוק מה השתבש, במקום הודעה גנרית.
  final String? debugMessage;
  const CouponRedeemOutcome(this.result, {this.coins = 0, this.debugMessage});
}

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

class CouponService {
  static final CollectionReference<Map<String, dynamic>> _coupons =
      FirebaseFirestore.instance.collection('coupons');
  // 🛡️ מונע מאותו מכשיר לממש את אותו קוד פעמיים - מסמך אחד לכל
  // צירוף (קוד, מכשיר), עם ה-ID "CODE_deviceId" כך שניסיון שני נכשל
  // מיידית על "כבר קיים" בלי לגעת בכלל במונה של הקופון.
  static final CollectionReference<Map<String, dynamic>> _redemptions =
      FirebaseFirestore.instance.collection('couponRedemptions');

  /// מנסה לממש קוד קופון עבור המכשיר הנתון. אטומי לגמרי (transaction) -
  /// גם אם 1000 שחקנים ילחצו על אותו קוד באותה השנייה בדיוק, אף אחד לא
  /// "יעקוף" את מגבלת maxUses.
  static Future<CouponRedeemOutcome> redeem(String rawCode, String deviceId) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return const CouponRedeemOutcome(CouponResult.notFound);

    final redemptionDocId = "${code}_$deviceId";
    final redemptionRef = _redemptions.doc(redemptionDocId);
    final couponRef = _coupons.doc(code);

    try {
      return await FirebaseFirestore.instance.runTransaction<CouponRedeemOutcome>((tx) async {
        // 🥇 קודם בודקים אם המכשיר הזה כבר מימש את הקוד הזה בעבר
        final existingRedemption = await tx.get(redemptionRef);
        if (existingRedemption.exists) {
          return const CouponRedeemOutcome(CouponResult.alreadyUsedByThisDevice);
        }

        final couponSnap = await tx.get(couponRef);
        if (!couponSnap.exists) {
          return const CouponRedeemOutcome(CouponResult.notFound);
        }
        final data = couponSnap.data()!;
        final bool active = data['active'] ?? true;
        // 🐛 באג שתוקן: הגרסה הקודמת בדקה "(v ?? 0) is int" אבל אז החזירה
        // בפועל את v המקורי (לא את ה-0!) - כך שאם השדה היה null בפיירסטור
        // (חסר/ריק), עדיין הוחזר null במקום 0, וזה גרם ל-
        // "'type 'Null' is not a subtype of type 'int'" בדיוק כמו שקרה כאן.
        final int coins = _parseInt(data['coins']);
        final int maxUses = _parseInt(data['maxUses']);
        final int usedCount = _parseInt(data['usedCount']);

        if (!active) return const CouponRedeemOutcome(CouponResult.inactive);
        if (maxUses > 0 && usedCount >= maxUses) return const CouponRedeemOutcome(CouponResult.usedUp);

        // ✅ הכל תקין - רושמים את המימוש ומעלים את המונה, שניהם באותה
        // עסקה אטומית כדי שלא יהיה מצב של "מונה עלה אבל לא נרשם מימוש"
        tx.set(redemptionRef, {
          "code": code,
          "deviceId": deviceId,
          "redeemedAt": FieldValue.serverTimestamp(),
          "coins": coins,
        });
        tx.update(couponRef, {"usedCount": FieldValue.increment(1)});

        return CouponRedeemOutcome(CouponResult.success, coins: coins);
      });
    } catch (e) {
      debugPrint("COUPON REDEEM ERROR: $e");
      return CouponRedeemOutcome(CouponResult.error, debugMessage: e.toString());
    }
  }
}