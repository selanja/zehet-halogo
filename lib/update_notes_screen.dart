// update_notes_screen.dart
//
// 🆕 מסך "מה חדש במשחק" - לפי בקשה מפורשת: "אני רוצה שיהיה בתוך המשחק
// מקום בו יהיה רשום את כל התיקונים של המשחק... שיהיה מקושר ל-Firestore".
// קורא מאוסף updateNotes/{id} - כל מסמך הוא הערת עדכון אחת: {title,
// body, publishedAt}. נטען פעם אחת בפתיחת המסך (לא live - אין סיבה
// שהמסך יתעדכן תוך כדי שהוא פתוח, וחוסך פתיחת חיבור מיותר).
//
// ⚠️ ניהול התוכן: מוסיפים/עורכים מסמכים ידנית דרך Firebase Console
// (Firestore Database -> updateNotes) - לא צריך גרסה חדשה של האפליקציה
// כדי לפרסם הערת עדכון. שדה publishedAt (Timestamp) קובע את סדר התצוגה
// (החדש ביותר למעלה) - בלי צורך למספר את המסמכים בעצמך.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_background.dart';
import 'l10n/app_localizations.dart';

class UpdateNotesScreen extends StatefulWidget {
  const UpdateNotesScreen({super.key});

  @override
  State<UpdateNotesScreen> createState() => _UpdateNotesScreenState();
}

class _UpdateNotesScreenState extends State<UpdateNotesScreen> {
  bool _loading = true;
  String? _error;
  List<_UpdateNote> _notes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('updateNotes').orderBy('publishedAt', descending: true).limit(50).get();
      final notes = snap.docs.map((d) {
        final data = d.data();
        final ts = data['publishedAt'];
        return _UpdateNote(
          title: (data['title'] as String?) ?? '',
          body: (data['body'] as String?) ?? '',
          publishedAt: ts is Timestamp ? ts.toDate() : null,
        );
      }).toList();
      if (mounted) setState(() { _notes = notes; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = AppLocalizations.of(context)!.updateNotesLoadError; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120C2E),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.08),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: const Padding(padding: EdgeInsets.all(9), child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20)),
            ),
          ),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.updateNotesTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
      );
    }
    if (_notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            AppLocalizations.of(context)!.updateNotesEmptyMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      itemCount: _notes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _noteCard(_notes[i]),
    );
  }

  Widget _noteCard(_UpdateNote note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(note.title, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900)),
              ),
              if (note.publishedAt != null)
                Text(_formatDate(note.publishedAt!), style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11.5, fontWeight: FontWeight.w700)),
            ],
          ),
          if (note.body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(note.body, style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 13.5, height: 1.5)),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
}

class _UpdateNote {
  final String title;
  final String body;
  final DateTime? publishedAt;
  const _UpdateNote({required this.title, required this.body, required this.publishedAt});
}
