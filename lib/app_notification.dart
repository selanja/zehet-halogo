// app_notification.dart
//
// 🆕 התראה עליונה מאוחדת לכל האפליקציה - מחליפה את כל ה-SnackBar's הישנים
// (שקפצו למטה, בעיצוב ה-Material הסטנדרטי האפור) לפי בקשה מפורשת: "אני
// רוצה שכל ההתראות שנמצאות באפליקציה יקפצו למעלה, בצורה הרבה יותר יפה,
// וללא אימוגים". מוצגת דרך Overlay אמיתי (לא תלויה ב-Scaffold/
// ScaffoldMessenger של המסך הנוכחי) - קופצת פנימה עם אנימציית slide+fade
// מלמעלה, ונעלמת אוטומטית אחרי `duration`. התראה חדשה מחליפה מיידית
// התראה קודמת שעוד מוצגת, כדי שלא יצטברו כמה זו מעל זו.
import 'dart:async';
import 'package:flutter/material.dart';

enum AppNotificationType { info, success, warning, error }

class AppNotification {
  AppNotification._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context,
    String message, {
    AppNotificationType type = AppNotificationType.info,
    Color? color,
    Duration duration = const Duration(seconds: 3),
    // 🆕 כשניתן - ההתראה הופכת ל"קליקבילית" (למשל ניווט למסך אחר), בלי
    // לדרוש כפתור נפרד: לחיצה סוגרת את ההתראה *וגם* מפעילה את הפעולה.
    // ראו promo_service.dart - התראה שאפשר להתעלם ממנה (נעלמת לבד) במקום
    // דיאלוג חוסם עם כפתורים, פחות "נודניקית".
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _dismiss();

    final entry = OverlayEntry(
      builder: (_) => _AppNotificationBanner(
        message: message,
        type: type,
        color: color,
        onTap: () {
          _dismiss();
          onTap?.call();
        },
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _AppNotificationBanner extends StatefulWidget {
  final String message;
  final AppNotificationType type;
  final Color? color;
  final VoidCallback onTap;
  const _AppNotificationBanner({required this.message, required this.type, required this.color, required this.onTap});

  @override
  State<_AppNotificationBanner> createState() => _AppNotificationBannerState();
}

class _AppNotificationBannerState extends State<_AppNotificationBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _slide = Tween<Offset>(begin: const Offset(0, -1.3), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Object> _style() {
    if (widget.color != null) return [widget.color!, _iconFor(widget.type)];
    switch (widget.type) {
      case AppNotificationType.success:
        return [const Color(0xFF16A46F), Icons.check_circle_rounded];
      case AppNotificationType.warning:
        return [const Color(0xFFB8600A), Icons.info_rounded];
      case AppNotificationType.error:
        return [const Color(0xFFB0225A), Icons.error_rounded];
      case AppNotificationType.info:
        return [const Color(0xFF3A2668), Icons.notifications_rounded];
    }
  }

  IconData _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.success:
        return Icons.check_circle_rounded;
      case AppNotificationType.warning:
        return Icons.info_rounded;
      case AppNotificationType.error:
        return Icons.error_rounded;
      case AppNotificationType.info:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style();
    final bg = style[0] as Color;
    final icon = style[1] as IconData;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(colors: [bg, bg.withValues(alpha: 0.82)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.55), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
