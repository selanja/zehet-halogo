// debug_log_screen.dart
// 🆕 מסך אבחון זמני - מציג את השורות האחרונות שנרשמו ע"י debug_log.dart.
// נפתח בלחיצה ארוכה על מספר הגרסה בתפריט הראשי (ראה main_menu_screen.dart).
// ⚠️ להסיר את הקובץ הזה ואת הקריאה אליו אחרי שהבאג הנוכחי נמצא ותוקן.
import 'package:flutter/material.dart';
import 'debug_log.dart';
import 'presence_admin_screen.dart'; // 🆕 מעקב "כמה שחקנים מחוברים עכשיו ומה הם עושים" - ראה כפתור ה-AppBar למטה

class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  List<String> _lines = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lines = await DebugLog.readAll();
    if (mounted) setState(() => _lines = lines);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Debug Log", style: TextStyle(color: Colors.white)),
        actions: [
          // 🆕 "כמה שחקנים מחוברים עכשיו ומה הם עושים" - מסך מעקב חדש,
          // מונח כאן כי זה כבר המקום הנסתר לכלי-פיתוח בפרויקט הזה.
          IconButton(
            icon: const Icon(Icons.groups_rounded, color: Colors.white),
            tooltip: 'שחקנים אונליין',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PresenceAdminScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () async {
              await DebugLog.clear();
              _load();
            },
          ),
        ],
      ),
      body: _lines.isEmpty
          ? const Center(
              child: Text("אין רשומות עדיין", style: TextStyle(color: Colors.white54)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    for (final line in _lines)
                      TextSpan(text: "$line\n", style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace')),
                  ],
                ),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
              ),
            ),
    );
  }
}