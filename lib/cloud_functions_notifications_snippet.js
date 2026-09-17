// cloud_functions_notifications_snippet.js
//
// שתי Cloud Functions לדוגמה - הבסיס להתראות "אוטומטיות" (לא ידניות).
// דורש מעבר לתוכנית Blaze (הסברתי קודם למה זה לא באמת עולה כסף בגודל
// הנוכחי של האפליקציה - רק דורש כרטיס אשראי מקושר + Budget Alert).
//
// התקנה (בתיקיית functions/ של הפרויקט, אם עוד אין - "firebase init functions"):
//   npm install firebase-admin firebase-functions
//
// פריסה:
//   firebase deploy --only functions
//
// ⚠️ שים לב: זה קובץ JavaScript (Node.js) - רץ בענן, לא ב-Flutter/Dart.
// זה נפרד לגמרי מקוד האפליקציה, חי בתיקיית functions/ בפרויקט Firebase.

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * שולח התראת Push לשחקן ספציפי, לפי deviceId - שולף את ה-fcmToken
 * ששמרנו לו ב-Firestore (players/{deviceId}.fcmToken) ושולח דרכו.
 */
async function sendPushToPlayer(deviceId, title, body, data = {}) {
  const playerSnap = await db.collection("players").doc(deviceId).get();
  const token = playerSnap.data()?.fcmToken;
  if (!token) return; // אין טוקן שמור - השחקן אולי לא אישר הרשאת התראות

  try {
    await messaging.send({
      token,
      notification: { title, body },
      data,
    });
  } catch (e) {
    // טוקן לא תקף יותר (למשל האפליקציה הוסרה) - מוחקים אותו כדי לא
    // לנסות לשלוח אליו שוב בכל פעם ולהיכשל
    if (e.code === "messaging/registration-token-not-registered") {
      await db.collection("players").doc(deviceId).update({ fcmToken: admin.firestore.FieldValue.delete() });
    }
  }
}

// ============================================================
// דוגמה 1: "מישהו עקף אותך בטבלת הדירוג" - מופעל אוטומטית בכל פעם
// שמסמך בטבלת הדירוג (leaderboard) מתעדכן עם XP חדש. בודק אם השחקן
// שהתעדכן עכשיו עקף שחקן אחר שהיה ממש קרוב אליו (למשל בטווח 20 XP),
// ואם כן - שולח לזה שנעקף התראה שתגרום לו לחזור ולנסות להחזיר את המקום.
// ============================================================
exports.onLeaderboardOvertake = functions.firestore
  .document("leaderboard/{deviceId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return;

    const newXp = after.xp || 0;
    const oldXp = before.xp || 0;
    if (newXp <= oldXp) return; // ה-XP רק עלה מעניין אותנו (לא ירידה/איפוס)

    // מחפשים שחקן שהיה ממש קצת מעל השחקן הזה לפני העדכון, ועכשיו נעקף
    const overtakenSnap = await db
      .collection("leaderboard")
      .where("xp", ">", oldXp)
      .where("xp", "<=", newXp)
      .limit(1)
      .get();

    if (overtakenSnap.empty) return;
    const overtaken = overtakenSnap.docs[0];
    if (overtaken.id === context.params.deviceId) return; // לא לשלוח לעצמו

    await sendPushToPlayer(
      overtaken.id,
      "מישהו עקף אותך בדירוג",
      `${after.username || "שחקן"} עקף אותך בטבלת השיאים - יש לך עדיין סיכוי מצוין לחזור ולעקוף בחזרה`,
      { type: "leaderboard_overtake" }
    );
  });

// ============================================================
// דוגמה 2: תזכורת יומית לשחקנים לא פעילים - רצה כל יום בשעה קבועה
// (Cloud Scheduler, מובנה ב-Firebase, לא צריך הגדרה נפרדת). שולחת
// רק לשחקנים שלא היו פעילים (updatedAt) כבר 3 ימים ומעלה.
// ============================================================
exports.dailyInactivePlayersReminder = functions.pubsub
  .schedule("0 18 * * *") // כל יום ב-18:00 (זמן שרת = UTC - להתאים לפי הצורך)
  .timeZone("Asia/Jerusalem")
  .onRun(async () => {
    const threeDaysAgo = admin.firestore.Timestamp.fromMillis(Date.now() - 3 * 24 * 60 * 60 * 1000);

    const inactiveSnap = await db
      .collection("players")
      .where("updatedAt", "<", threeDaysAgo)
      .limit(200) // מגבלת בטיחות - לא שולחים לאלפי אנשים בבת אחת בלי לבדוק
      .get();

    const messages = ["מחכים לך - עדיין יש לך סיכוי לשבור את השיא שלך", "לוגואים חדשים מחכים - בוא תראה כמה מותגים אתה עוד זוכר", "החברים שלך כבר עקפו אותך בטבלה - הגיע הזמן לחזור ולהראות להם מי הכי טוב"];

    for (const doc of inactiveSnap.docs) {
      const randomMessage = messages[Math.floor(Math.random() * messages.length)];
      await sendPushToPlayer(doc.id, "מתגעגעים אליך", randomMessage, { type: "inactive_reminder" });
    }
  });

// ============================================================
// דוגמה 3: ניקוי מסמכי דו-קרב ישנים (duels/{matchId}) - רצה כל יום
// בשעה קבועה, בדיוק כמו dailyInactivePlayersReminder למעלה. זו הגרסה
// ה"נכונה"/היעילה של הניקוי - בניגוד לניקוי ההזדמנותי שכבר קיים בצד
// הלקוח (DuelService._maybeCleanupOldDuels ב-duel_service.dart, שרץ
// רק בסיכוי נמוך בכל חיפוש יריב ולא תלוי בפריסה שלך) - זו רצה תמיד,
// גם אם אף אחד לא מחפש דו-קרב באותו יום, ומטפלת גם במקרה קצה שהניקוי
// בצד הלקוח לא מכסה: דו-קרבים שנתקעו (status עדיין 'countdown'/'playing')
// כי שני הצדדים ניתקו בו-זמנית - ה-heartbeat timeout בצד הלקוח (ראו
// duel_room_screen.dart) לא רץ בכלל כי אין אף לקוח פעיל שיריץ אותו.
// ⚠️ דורשת אינדקס מורכב על status+createdAt (ראו הערה מקבילה בקוד
// ה-Flutter) - Firestore ייתן קישור ישיר ליצירתו בלוג השגיאה של
// הפונקציה הזו אם הוא חסר, בהרצה הראשונה.
// ============================================================
exports.cleanupOldDuels = functions.pubsub
  .schedule("0 4 * * *") // כל יום ב-4:00 לפנות בוקר (שעון שרת)
  .timeZone("Asia/Jerusalem")
  .onRun(async () => {
    const threeDaysAgo = admin.firestore.Timestamp.fromMillis(Date.now() - 3 * 24 * 60 * 60 * 1000);
    const twelveHoursAgo = admin.firestore.Timestamp.fromMillis(Date.now() - 12 * 60 * 60 * 1000);

    // דו-קרבים שהסתיימו כרגיל, ישנים משלושה ימים - אין שום צורך להחזיק אותם
    const finishedSnap = await db
      .collection("duels")
      .where("status", "==", "finished")
      .where("createdAt", "<", threeDaysAgo)
      .limit(400)
      .get();

    // 🆕 דו-קרבים "תקועים" (לא הסתיימו אף פעם, למשל שני הצדדים ניתקו
    // בו-זמנית ממש בהתחלה, לפני ש-heartbeat timeout של אחד מהם הספיק
    // לרוץ) - אם הם ישנים מ-12 שעות, בבירור אף אחד לא באמת עדיין משחק בהם.
    const stuckSnap = await db
      .collection("duels")
      .where("status", "in", ["countdown", "playing"])
      .where("createdAt", "<", twelveHoursAgo)
      .limit(200)
      .get();

    const allDocs = [...finishedSnap.docs, ...stuckSnap.docs];
    if (allDocs.length === 0) return;

    // Firestore batch מוגבל ל-500 פעולות - כאן זה תמיד פחות (400+200),
    // אבל נשארים בטוחים ומפצלים בכל מקרה ל-batches של עד 450.
    for (let i = 0; i < allDocs.length; i += 450) {
      const batch = db.batch();
      for (const doc of allDocs.slice(i, i + 450)) {
        batch.delete(doc.ref);
      }
      await batch.commit();
    }
  });