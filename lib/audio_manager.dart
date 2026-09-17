import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// כל האודיו של המשחק עובר דרך שלושה נגנים קבועים שנוצרים פעם אחת בלבד.
/// אין יותר יצירה/השמדה של נגנים בכל מסך - זה מה שגרם לתקיעות (ANR).
class AudioManager {
  static final AudioPlayer _sfxPlayer = AudioPlayer();     // קליקים וצלילים קצרים
  static final AudioPlayer _successPlayer = AudioPlayer(); // צלילי ניצחון
  static final AudioPlayer _musicPlayer = AudioPlayer();   // מוזיקת רקע

  static bool _musicStarted = false;
  static bool _isDucked = false;
  static bool _sfxConfigured = false;
  static bool _globalConfigured = false;
  static bool _pausedForBackground = false;
  // 🐛 תוקן: קריסה אמיתית מהמכשיר (AndroidAudioError, "Failed to set
  // source", MEDIA_ERROR_SYSTEM) - קרתה כשהלופ הידני של המוזיקה (seek+
  // resume ב-onPlayerComplete למטה) והפעלה מחדש דרך ensureMusicPlaying
  // (נקרא בכל חזרה למסך הבית) רצו בו-זמנית על אותו _musicPlayer: שתי
  // פקודות מתחרות (play() חדש מול seek+resume קיים) על אותו MediaPlayer
  // אנדרואיד שוברות אותו. המנעול הזה מוודא שרק ניסיון הפעלה-מחדש אחד
  // רץ בכל רגע נתון.
  static bool _restartInFlight = false;

  /// 🔇 מתג חירום לבדיקות: שנה ל-false כדי לכבות את כל הסאונד במשחק.
  /// אם הקריסות נעלמות כשזה false - הבעיה באודיו של האמולטור/מכשיר.
  static bool soundEnabled = true;

  /// הגדרה גלובלית חד-פעמית: מכבה את ניהול "פוקוס האודיו" של audioplayers
  /// (מנגנון שידוע כגורם לתקיעות כשיש כמה נגנים במקביל).
  ///
  /// 🔊 iOS: קטגוריית ambient מאפשרת לאודיו של המשחק להתנגן יחד עם
  /// מוזיקה מאפליקציות אחרות (Spotify, Apple Music וכו') - בלי להשתיק אותן.
  /// היא גם מכבדת את מתג השקט של האייפון.
  // 🐛 תוקן: קטגוריית ambient כבר "מערבבת" אודיו עם אפליקציות אחרות
  // מעצם הגדרתה ב-iOS (בניגוד ל-playback/playAndRecord/multiRoute, שם
  // צריך לבקש את זה במפורש) - האופציה mixWithOthers שהייתה כאן בנוסף
  // בכלל לא חוקית יחד עם ambient, וחבילת ה-audioplayers עצמה דוחה את
  // הצירוף הזה עם Failed assertion בכל הפעלה (נראה בלוג אפילו באנדרואיד,
  // כי הבדיקה רצה בצד ה-Dart המשותף לפני שמגיעים לקוד הפלטפורמה). בפועל
  // זה היה נתפס ב-catch למטה ומדלג בשקט על כל ההגדרה הגלובלית הזו - כך
  // שב-iOS ההתנהגות המבוקשת (מתנגן יחד עם Spotify, מכבד מתג שקט) כנראה
  // מעולם לא הופעלה בפועל. הוסרה האופציה המיותרת/הלא-חוקית.
  static Future<void> _ensureGlobalConfig() async {
    if (_globalConfigured) return;
    _globalConfigured = true;
    try {
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
        ),
      ));
    } catch (e) {
      debugPrint('שגיאת הגדרה גלובלית של אודיו: $e');
    }
  }

  // עוצמות נשלטות ע"י המשתמש (0.0 - 1.0), נשמרות במכשיר
  static double musicVolume = 0.6;
  static double sfxVolume = 1.0;

  // 🆕 מתג "רטט" במסך ההגדרות (לפי המוקאפ, מסך 11) - שולט על הרטט
  // העדין שמלווה קליקים במקלדת/כפתורים (playClick למטה). לא נוגע ברטט
  // של המערכת עצמה (למשל התראות) - רק הרטט שהמשחק יוזם בעצמו.
  static bool hapticsEnabled = true;

  /// הגדרה חד-פעמית של נגני האפקטים (רצה בפעם הראשונה שמנגנים צליל)
  static Future<void> _ensureSfxConfigured() async {
    if (_sfxConfigured) return;
    _sfxConfigured = true;
    await _ensureGlobalConfig();
    try {
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _successPlayer.setReleaseMode(ReleaseMode.stop);
      // ⚠️ ניסינו lowLatency (SoundPool) לקליק כדי לקצר את ההשהיה - אבל
      // בסביבת הבדיקה הזו הוא פשוט לא מנגן כלום (יש כמה תקלות ידועות
      // של lowLatency בחבילת audioplayers). MediaPlayer רגיל אמין הרבה
      // יותר, ולמרות שיש לו השהיית הכנה קטנה, עדיף צליל מושהה מעט על
      // פני שקט מוחלט.
      await _sfxPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _successPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    } catch (e) {
      debugPrint('שגיאת הגדרת אודיו: $e');
    }
  }

  /// טוען את ההגדרות השמורות
  static Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      musicVolume = prefs.getDouble('musicVolume') ?? 0.6;
      sfxVolume = prefs.getDouble('sfxVolume') ?? 1.0;
      hapticsEnabled = prefs.getBool('hapticsEnabled') ?? true;
    } catch (_) {}
  }

  /// הפעלה/כיבוי של הרטט (מהתפריט הגדרות) + שמירה
  static Future<void> setHapticsEnabled(bool value) async {
    hapticsEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hapticsEnabled', value);
    } catch (_) {}
  }

  /// שינוי עוצמת המוזיקה (מהתפריט הגדרות) + שמירה
  static Future<void> setMusicVolume(double value) async {
    musicVolume = value;
    try {
      await _musicPlayer.setVolume(_isDucked ? value * 0.2 : value);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('musicVolume', value);
    } catch (_) {}
  }

  /// שינוי עוצמת האפקטים (מהתפריט הגדרות) + שמירה
  static Future<void> setSfxVolume(double value) async {
    sfxVolume = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('sfxVolume', value);
    } catch (_) {}
  }

  // ⚡ הקליק נוצר בזיכרון בזמן ריצה (טון קצרצר, 60 מילישניות) - לא קובץ
  // חיצוני. זה פותר לצמיתות שתי בעיות ביחד: (1) קבצי שמע שהתגלו כפגומים
  // או שלא הגיעו לפרויקט, (2) השהיה של כמעט שנייה שנגרמה מ-MediaPlayer
  // שצריך "להתכונן" לכל ניגון - SoundPool (lowLatency) כמעט מיידי.
  static Uint8List? _clickWavBytes;

  static Uint8List _generateClickWav() {
    const int sampleRate = 44100;
    const double durationSec = 0.06;
    final int numSamples = (sampleRate * durationSec).round();
    final int dataSize = numSamples * 2; // 16-bit mono
    final int totalSize = 44 + dataSize;

    final Uint8List bytes = Uint8List(totalSize);
    final ByteData bd = ByteData.sublistView(bytes);

    void writeAscii(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        bytes[offset + i] = s.codeUnitAt(i);
      }
    }

    writeAscii(0, 'RIFF');
    bd.setUint32(4, totalSize - 8, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    bd.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double env = math.exp(-t * 70);
      final double v = 0.7 * math.sin(2 * math.pi * 1000 * t) + 0.3 * math.sin(2 * math.pi * 2000 * t);
      int sample = (v * env * 32767 * 0.8).round().clamp(-32768, 32767);
      bd.setInt16(44 + i * 2, sample, Endian.little);
    }
    return bytes;
  }

  /// 🔘 קליק על מקלדת/כפתורים - צליל שנוצר בזיכרון + רטט עדין. אין קובץ
  /// חיצוני שיכול להיות חסר/פגום, ואין השהיה של MediaPlayer.
  static void playClick() {
    if (!soundEnabled) return;
    if (hapticsEnabled) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }
    _ensureSfxConfigured().then((_) async {
      _clickWavBytes ??= _generateClickWav();
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(sfxVolume);
      return _sfxPlayer.play(BytesSource(_clickWavBytes!));
    }).catchError((e) {
      debugPrint('שגיאת קליק: $e');
    });
  }

  /// "מחמם" את נגן הקליק מראש (עוצמה 0, בלתי נשמע) - כדי שגם הלחיצה
  /// הראשונה ממש בתחילת המשחק תהיה מיידית ולא רק הלחיצות הבאות.
  static Future<void> warmUpClick() async {
    try {
      await _ensureSfxConfigured();
      _clickWavBytes ??= _generateClickWav();
      await _sfxPlayer.setVolume(0);
      await _sfxPlayer.play(BytesSource(_clickWavBytes!));
      await Future.delayed(const Duration(milliseconds: 120));
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(sfxVolume);
    } catch (_) {}
  }

  /// צליל קצר מקובץ אודיו (וכו') - לא חוסם את הממשק לעולם
  static void playSound(String assetPath) {
    if (!soundEnabled) return;
    _ensureSfxConfigured().then((_) async {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(sfxVolume);
      return _sfxPlayer.play(AssetSource(assetPath));
    }).catchError((e) {
      debugPrint('שגיאת סאונד: $e');
    });
  }

  /// צליל ניצחון/סיום - נגן נפרד כדי שלא ייחתך ע"י קליקים
  static void playSuccess(String assetPath) {
    if (!soundEnabled) return;
    _ensureSfxConfigured().then((_) async {
      await _successPlayer.stop();
      await _successPlayer.setVolume(sfxVolume);
      return _successPlayer.play(AssetSource(assetPath));
    }).catchError((e) {
      debugPrint('שגיאת סאונד: $e');
    });
  }

  // 🆕 צליל "הפסד" - בדיוק כמו playClick, נוצר בזיכרון בזמן ריצה (טון
  // קצר יורד, ~0.55 שניות) ולא קובץ אודיו חיצוני. הסיבה: בעבר תוצאת
  // הפסד בדו-קרב ניגנה בטעות את אותו קובץ 'audio/win.mp3' שמנוגן
  // בניצחון (רק שם הקובץ קצת מטעה - זה לא היה קשור לניצחון האמיתי, אבל
  // עדיין נשמע כמו צליל "טוב" גם כשמפסידים, מה שהרגיש לא הגיוני). טון
  // יורד (מ-320Hz ל-140Hz בערך) נותן תחושת "כישלון" ברורה, ההפך
  // מהתחושה העולה של צליל ניצחון - וכמו ב-playClick, אין תלות בקובץ
  // חיצוני שיכול להיות חסר/פגום.
  static Uint8List? _loseWavBytes;

  static Uint8List _generateLoseWav() {
    const int sampleRate = 44100;
    const double durationSec = 0.55;
    final int numSamples = (sampleRate * durationSec).round();
    final int dataSize = numSamples * 2; // 16-bit mono
    final int totalSize = 44 + dataSize;

    final Uint8List bytes = Uint8List(totalSize);
    final ByteData bd = ByteData.sublistView(bytes);

    void writeAscii(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        bytes[offset + i] = s.codeUnitAt(i);
      }
    }

    writeAscii(0, 'RIFF');
    bd.setUint32(4, totalSize - 8, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    bd.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double freq = 320 - (180 * (t / durationSec)); // תדר יורד
      final double env = math.exp(-t * 5);
      final double v = 0.6 * math.sin(2 * math.pi * freq * t) + 0.25 * math.sin(2 * math.pi * (freq * 0.5) * t);
      int sample = (v * env * 32767 * 0.8).round().clamp(-32768, 32767);
      bd.setInt16(44 + i * 2, sample, Endian.little);
    }
    return bytes;
  }

  /// צליל "הפסד" - להשתמש בו בכל מקום שבו שחקן מפסיד (כרגע: תוצאת דו-קרב).
  static void playLose() {
    if (!soundEnabled) return;
    _ensureSfxConfigured().then((_) async {
      _loseWavBytes ??= _generateLoseWav();
      await _successPlayer.stop();
      await _successPlayer.setVolume(sfxVolume);
      return _successPlayer.play(BytesSource(_loseWavBytes!));
    }).catchError((e) {
      debugPrint('שגיאת סאונד הפסד: $e');
    });
  }

  // 🆕 צליל "נמצא יריב" - נוצר בזיכרון בזמן ריצה (כמו playClick/playLose,
  // בלי תלות בקובץ חיצוני), שני "פעמונים" עולים קצרים (D5 -> A5 בערך)
  // שנותנים תחושת "משהו טוב קרה!" - מנוגן ברגע ש-DuelLobbyScreen עובר
  // ל-_LobbyState.found (ראה duel_lobby_screen.dart), יחד עם
  // AudioManager.duckMusic() כדי שהצליל יישמע ברור מעל המוזיקה.
  static Uint8List? _opponentFoundWavBytes;

  static Uint8List _generateOpponentFoundWav() {
    const int sampleRate = 44100;
    const double durationSec = 0.5;
    final int numSamples = (sampleRate * durationSec).round();
    final int dataSize = numSamples * 2; // 16-bit mono
    final int totalSize = 44 + dataSize;

    final Uint8List bytes = Uint8List(totalSize);
    final ByteData bd = ByteData.sublistView(bytes);

    void writeAscii(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        bytes[offset + i] = s.codeUnitAt(i);
      }
    }

    writeAscii(0, 'RIFF');
    bd.setUint32(4, totalSize - 8, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    bd.setUint32(40, dataSize, Endian.little);

    // שתי "פעימות" עולות - הראשונה בערך ב-0 שניות (587Hz~D5), השנייה
    // חופפת חלקית ב-0.12 שניות (880Hz~A5) - יוצר תחושת "דינג-דינג" עולה.
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double v = 0;
      // פעימה 1
      final double t1 = t;
      final double env1 = t1 >= 0 ? math.exp(-t1 * 9) : 0;
      v += 0.5 * math.sin(2 * math.pi * 587 * t1) * env1;
      // פעימה 2 (מתחילה קצת אחרי הראשונה)
      final double t2 = t - 0.12;
      if (t2 >= 0) {
        final double env2 = math.exp(-t2 * 7);
        v += 0.55 * math.sin(2 * math.pi * 880 * t2) * env2;
      }
      int sample = (v * 32767 * 0.8).round().clamp(-32768, 32767);
      bd.setInt16(44 + i * 2, sample, Endian.little);
    }
    return bytes;
  }

  /// 🆕 צליל "נמצא יריב!" בדו-קרב - קורא גם ל-duckMusic() כדי שהצליל
  /// יישמע ברור. חשוב לזכור לקרוא ל-restoreMusic() בהמשך (המסך שקורא
  /// לפונקציה הזו אחראי לכך - ראה duel_lobby_screen.dart).
  static void playOpponentFound() {
    if (!soundEnabled) return;
    duckMusic();
    _ensureSfxConfigured().then((_) async {
      _opponentFoundWavBytes ??= _generateOpponentFoundWav();
      await _successPlayer.stop();
      await _successPlayer.setVolume(sfxVolume);
      return _successPlayer.play(BytesSource(_opponentFoundWavBytes!));
    }).catchError((e) {
      debugPrint('שגיאת סאונד נמצא יריב: $e');
    });
  }

  // 🆕 באג אמיתי שהתגלה מלוג המכשיר בפועל: עם ReleaseMode.loop (לופ טבעי
  // ברמת ה-MediaPlayer של אנדרואיד) המוזיקה הייתה "נתקעת" בערך ב-10
  // שניות (getCurrentPosition חוזר שוב ושוב על אותו ערך בלי להתקדם) -
  // כלומר מפסיקה לנגן בפועל, למרות שהפלייר "חושב" שהוא עדיין פעיל. זו
  // תקלה ידועה של MediaPlayer עם לופ טבעי על קבצי OGG בחלק מהמכשירים.
  // הפתרון: לופ "ידני" - במקום לסמוך על setLooping, מאזינים ל-
  // onPlayerComplete ומפעילים מחדש בעצמנו (seek לתחילה + play מחדש) -
  // זה עוקף לגמרי את הבאג כי זה לא תלוי במנגנון הלופ הפנימי הבעייתי.
  static StreamSubscription<void>? _musicCompleteSub;

  /// מתחיל מוזיקת רקע בלופ (נקרא במסך הפתיחה).
  /// ⚠️ צריך להוסיף קובץ: assets/audio/bg_music.mp3 (ולרשום בפאבספק)
  static Future<void> startBackgroundMusic() async {
    if (!soundEnabled) return;
    if (_musicStarted) return;
    _musicStarted = true;
    try {
      await loadSettings();
      await _ensureGlobalConfig();
      // 🩹 תוקן: ReleaseMode.stop (לא loop!) + לופ ידני דרך onPlayerComplete
      // למטה - ראו ההסבר המלא מעל למה זה הכרחי (תקלת "קפיאה" ב-~10 שניות).
      await _musicPlayer.setReleaseMode(ReleaseMode.stop);
      await _musicPlayer.setVolume(musicVolume);
      _musicCompleteSub?.cancel();
      _musicCompleteSub = _musicPlayer.onPlayerComplete.listen((_) async {
        if (!_musicStarted || !soundEnabled) return;
        // 🩹 תוקן: אם האפליקציה ברקע כרגע (המשתמש נעל את המסך/יצא
        // מהאפליקציה) - לא מפעילים מחדש! בלי הבדיקה הזו, אם השיר בדיוק
        // הגיע לסופו בזמן שהאפליקציה ברקע, הלופ הידני היה "מחייה" את
        // המוזיקה מחדש (seek+resume) גם אחרי ש-pauseMusic() כבר עצר
        // אותה - זו הסיבה שהמוזיקה המשיכה להישמע אחרי כיבוי המסך.
        if (_pausedForBackground) return;
        if (_restartInFlight) return; // ראו הסבר ליד _restartInFlight
        _restartInFlight = true;
        try {
          await _musicPlayer.seek(Duration.zero);
          await _musicPlayer.resume();
        } catch (_) {
        } finally {
          _restartInFlight = false;
        }
      });
      await _musicPlayer.play(AssetSource('audio/bg_music.ogg'));
    } catch (e) {
      _musicStarted = false;
      debugPrint('שגיאת מוזיקת רקע: $e');
    }
  }

  /// עוצר את המוזיקה כשהאפליקציה עוברת לרקע (מוזערת/מוחלפת) - אחרת
  /// היא ממשיכה לנגן גם כשלא רואים את המשחק בכלל, וזה לא רצוי.
  static void pauseMusic() {
    if (!_musicStarted) return;
    _musicPlayer.pause().catchError((_) {});
    _pausedForBackground = true;
  }

  /// ממשיך את המוזיקה כשהאפליקציה חוזרת לחזית - רק אם היא הופסקה
  /// בגלל המעבר לרקע (ולא מסיבה אחרת)
  static void resumeMusicFromBackground() {
    if (!_musicStarted || !_pausedForBackground) return;
    _pausedForBackground = false;
    _musicPlayer.resume().catchError((_) {});
  }

  /// מנמיך את המוזיקה (כשנכנסים לשלב) - בלי לחסום. 🆕 בכוונה *לא* עוצר
  /// אותה - לפי בקשה מפורשת: המוזיקה צריכה להישאר תמיד ברקע, גם במהלך
  /// המשחק, רק בעוצמה נמוכה יותר - לא להיעלם.
  static void duckMusic() {
    _isDucked = true;
    _musicPlayer.setVolume(musicVolume * 0.2).catchError((_) {});
  }

  /// מחזיר את המוזיקה לעוצמה שהמשתמש בחר (כשחוזרים מהשלב) - בלי לחסום
  static void restoreMusic() {
    _isDucked = false;
    _musicPlayer.setVolume(musicVolume).catchError((_) {});
  }

  /// 🆕 "רשת ביטחון" - קוראים לזה בכל פעם שחוזרים למסך הבית (ראו
  /// main_menu_screen.dart). בודק את מצב הנגן בפועל ומתקן אם צריך: אם
  /// המוזיקה נעצרה/הושלמה/במצב שגוי מסיבה כלשהי (כמו הבאג שתואר למעלה,
  /// או כל תקלה אחרת שלא צפינו) - מפעיל אותה מחדש מאפס, במקום לסמוך על
  /// כך ש"היא כבר התחילה פעם אחת אז היא בטח עדיין מתנגנת".
  static Future<void> ensureMusicPlaying() async {
    if (!soundEnabled) return;
    try {
      final state = _musicPlayer.state;
      if (state == PlayerState.playing) {
        // כבר מתנגנת בפועל - רק לוודא שהעוצמה תקינה (בלי דאק ישן שנתקע)
        if (!_isDucked) await _musicPlayer.setVolume(musicVolume);
        return;
      }
      if (state == PlayerState.paused && !_pausedForBackground) {
        // מושהית אבל לא בגלל שהאפליקציה ברקע - כנראה נעצרה בטעות בדרך
        await _musicPlayer.resume();
        await _musicPlayer.setVolume(_isDucked ? musicVolume * 0.2 : musicVolume);
        return;
      }
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        // ראו הסבר ליד _restartInFlight - אם הלופ הידני של onPlayerComplete
        // כבר באמצע הפעלה-מחדש (מצב "completed" הרגעי הזה בדיוק הוא מה
        // שהוא נועד לתפוס) - לא מפעילים כאן ניסיון שני עליו במקביל.
        if (_restartInFlight) return;
        // המוזיקה נעצרה/הסתיימה לגמרי - מתחילים מחדש מאפס
        debugPrint('AudioManager.ensureMusicPlaying: music was ${state.name}, restarting');
        _restartInFlight = true;
        try {
          _musicStarted = false;
          await startBackgroundMusic();
        } finally {
          _restartInFlight = false;
        }
      }
    } catch (e) {
      debugPrint('שגיאת ensureMusicPlaying: $e');
    }
  }
}