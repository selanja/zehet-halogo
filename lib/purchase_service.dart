// purchase_service.dart
//
// מערכת רכישות בתוך האפליקציה (In-App Purchase) מאפס - עוד לא היה קיים
// שום דבר, רק AdMob. משתמש בחבילה הרשמית של גוגל/פלאטר:
//   flutter pub add in_app_purchase
//
// כל רכישה שמצליחה נכתבת במלואה ל-Firestore, לאוסף "purchases" - שם
// יופיעו כל הפרטים: איזה מוצר, כמה עלה, באיזה מטבע, מאיזו פלטפורמה,
// באיזה זמן, ומזהה העסקה מהחנות עצמה.
//
// ⚠️ הערת אבטחה חשובה: הקוד הזה כותב ל-Firestore **מהלקוח** אחרי שקיבל
// אישור מקומי (PurchaseStatus.purchased) מה-SDK של in_app_purchase.
// זה מספיק ל-MVP ולמעקב פנימי, אבל טכנית שחקן עם ידע טכני יכול לזייף
// "רכישה מוצלחת" מקומית בלי לשלם בפועל, כי אין כאן אימות מול השרתים
// של גוגל/אפל (Server-Side Receipt Validation). כשיהיו רכישות אמיתיות
// בכסף, השלב הבא הוא Cloud Function שמאמתת כל receipt מול Google
// Play Developer API / App Store Server API לפני שסופית "סוגרים" את
// הרכישה (למשל: נותנים את הפריט בפועל רק אחרי שה-Function אישרה).
//
// מבנה הנתונים ב-Firestore:
//
// purchases/{purchaseId}   (purchaseId = purchaseID מה-SDK עצמו)
//   deviceId          - מזהה השחקן שקנה
//   username
//   productId          - איזה מוצר (מתוך kProductIds למטה)
//   platform           - 'android' | 'ios'
//   status             - 'purchased' | 'restored' | 'error'
//   transactionDate    - Server Timestamp
//   verificationSource - 'google_play' | 'app_store'
//   verificationToken  - ה-receipt/token הגולמי מה-SDK (לשימוש עתידי לאימות בצד שרת)
//   localVerified      - true/false - האם עבר את בדיקת ה-purchased status מקומית

import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'device_id.dart';

/// 👉 להחליף במזהי המוצרים האמיתיים שתגדיר ב-Google Play Console /
/// App Store Connect (חייבים להיות זהים מילה במילה בשני המקומות ופה)
const Set<String> kProductIds = {
  'coins_pack_small',   // חבילת מטבעות קטנה
  'coins_pack_medium',  // חבילת מטבעות בינונית
  'coins_pack_large',   // חבילת מטבעות גדולה
  'remove_ads',         // הסרת פרסומות
};

class PurchaseService {
  PurchaseService._();

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _sub;
  static List<ProductDetails> products = [];

  /// קוראים לזה פעם אחת ב-main.dart, אחרי Firebase.initializeApp()
  static Future<void> init({required void Function(String productId) onPurchaseGranted}) async {
    final available = await _iap.isAvailable();
    if (!available) {
      // אין חיבור לחנות (למשל אין אינטרנט, או שהאפליקציה רצה על מכשיר/
      // סימולטור בלי חשבון חנות מוגדר) - לא קורסים, פשוט לא זמין כרגע
      return;
    }

    final response = await _iap.queryProductDetails(kProductIds);
    products = response.productDetails;

    _sub = _iap.purchaseStream.listen(
      (purchases) => _handlePurchaseUpdates(purchases, onPurchaseGranted),
      onError: (e) {
        // שגיאת סטרים - לא קורסים, פשוט מפסיקים להאזין. אפשר להוסיף כאן
        // לוג/דיווח שגיאות בהמשך (Crashlytics וכו')
      },
    );
  }

  static void dispose() {
    _sub?.cancel();
  }

  /// מתחיל רכישה של מוצר לפי ה-productId
  static Future<void> buy(String productId) async {
    final product = products.where((p) => p.id == productId).firstOrNull;
    if (product == null) return; // המוצר לא נטען מהחנות - כנראה עוד לא הוגדר שם
    final param = PurchaseParam(productDetails: product);
    // רכישות "צרכניות" (consumable) כמו חבילות מטבעות - buyConsumable
    // רכישות חד-פעמיות קבועות (כמו הסרת פרסומות) - buyNonConsumable
    final isConsumable = productId.startsWith('coins_pack');
    if (isConsumable) {
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  static Future<void> restorePurchases() => _iap.restorePurchases();

  static Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
    void Function(String productId) onPurchaseGranted,
  ) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break; // עדיין מתבצעת - לא עושים כלום עדיין

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _recordPurchaseInFirestore(purchase);
          onPurchaseGranted(purchase.productID); // כאן נותנים בפועל את המטבעות/הפריט לשחקן
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.error:
          await _recordPurchaseInFirestore(purchase); // גם רכישות שנכשלו נרשמות - לצורך מעקב/דיבוג
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          break; // המשתמש ביטל בעצמו - אין צורך לתעד
      }
    }
  }

  static Future<void> _recordPurchaseInFirestore(PurchaseDetails purchase) async {
    final deviceId = await DeviceId.get();
    final db = FirebaseFirestore.instance;

    await db.collection('purchases').doc(purchase.purchaseID ?? db.collection('purchases').doc().id).set({
      'deviceId': deviceId,
      'productId': purchase.productID,
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'status': purchase.status.name,
      'transactionDate': FieldValue.serverTimestamp(),
      'verificationSource': Platform.isAndroid ? 'google_play' : 'app_store',
      'verificationToken': purchase.verificationData.serverVerificationData,
      'localVerified': purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored,
    }, SetOptions(merge: true));
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}