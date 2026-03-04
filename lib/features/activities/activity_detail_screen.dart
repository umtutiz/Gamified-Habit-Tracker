import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// KENDİ KLASÖR YAPINA GÖRE STRINGS IMPORTUNU AYARLA
import '../../core/i18n/strings.dart'; 

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;
  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final _supabase = Supabase.instance.client;
  late Future<_DetailData> _future;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  String _dayKey(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  Future<_DetailData> _load() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return _DetailData.empty;

    final actRes = await _supabase
        .from('activities')
        .select('id,title,start_minutes,target_days_per_week,color,icon,created_at')
        .eq('id', widget.activityId)
        .maybeSingle();

    if (actRes == null) return _DetailData.empty;

    final activity = _ActivityVm.fromMap(actRes);

    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 120));
    final fromKey = _dayKey(from);

    final checkinsRes = await _supabase
        .from('checkins')
        .select('checkin_date, created_at')
        .eq('activity_id', widget.activityId)
        .eq('user_id', user.id)
        .gte('checkin_date', fromKey)
        .order('checkin_date', ascending: false);

    final days = (checkinsRes as List)
        .cast<Map<String, dynamic>>()
        .map((m) => m['checkin_date'] as String)
        .toList();

    final todayKey = _dayKey(DateTime(now.year, now.month, now.day));
    final checkedToday = days.contains(todayKey);

    final streak = _calcCurrentStreak(days);

    final last30 = <String>{};
    for (int i = 0; i < 30; i++) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      last30.add(_dayKey(d));
    }
    final daysSet = days.toSet();
    final heatChecked = last30.where(daysSet.contains).toSet();

    return _DetailData(
      activity: activity,
      days: days,
      checkedToday: checkedToday,
      currentStreak: streak,
      heatmapChecked: heatChecked,
    );
  }

  int _calcCurrentStreak(List<String> days) {
    if (days.isEmpty) return 0;

    final set = days.toSet();
    final now = DateTime.now();
    DateTime cursor = DateTime(now.year, now.month, now.day);

    int streak = 0;
    final todayKey = _dayKey(cursor);
    if (!set.contains(todayKey)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (true) {
      final key = _dayKey(cursor);
      if (!set.contains(key)) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> _checkInToday() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayKey = _dayKey(today);

      await _supabase.from('checkins').upsert({
        'user_id': user.id,
        'activity_id': widget.activityId,
        'checkin_date': todayKey,
      });

      _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uncheckToday() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final todayKey = _dayKey(DateTime(now.year, now.month, now.day));

      await _supabase
          .from('checkins')
          .delete()
          .eq('user_id', user.id)
          .eq('activity_id', widget.activityId)
          .eq('checkin_date', todayKey);

      _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = Theme.of(context);

    return FutureBuilder<_DetailData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('${strings.errorPrefix}${snap.error}')));
        }

        final data = snap.data ?? _DetailData.empty;
        final a = data.activity;
        if (a == null) {
          return Scaffold(body: Center(child: Text(strings.activityNotFound)));
        }

        final iconData = IconData(a.iconCodePoint, fontFamily: 'MaterialIcons');
        final accent = Color(a.color);

        final ringProgress = (data.currentStreak / 14.0).clamp(0.0, 1.0); 
        final ringLabel = data.currentStreak >= 14 ? strings.beastMode : strings.keepGoing;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                title: Text(a.title),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HERO HEADER
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: accent.withOpacity(0.26)),
                              ),
                              child: Icon(iconData, color: theme.brightness == Brightness.dark ? Colors.white : accent, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${strings.startLabel}${a.startMinutes}${strings.minLabel}${strings.targetLabel}${a.targetDaysPerWeek}${strings.perWeek}',
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.55),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // STREAK RING + BUTTON
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Row(
                                children: [
                                  _StreakRing(
                                    progress: ringProgress,
                                    accent: accent,
                                    baseColor: theme.dividerColor,
                                    valueText: '${data.currentStreak}',
                                    subText: 'streak',
                                    textColor: theme.textTheme.bodyMedium?.color,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ringLabel,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          data.checkedToday
                                              ? strings.checkedInToday
                                              : strings.checkInToKeepStreak,
                                          style: TextStyle(
                                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        SizedBox(
                                          width: double.infinity,
                                          child: FilledButton.icon(
                                            onPressed: _busy
                                                ? null
                                                : () async {
                                                    if (data.checkedToday) {
                                                      await _uncheckToday();
                                                    } else {
                                                      await _checkInToday();
                                                    }
                                                  },
                                            icon: _busy
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : Icon(data.checkedToday ? Icons.undo : Icons.check),
                                            label: Text(data.checkedToday ? strings.undoToday : strings.checkInTodayAction),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // HEATMAP
                      Text(
                        strings.last30Days,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MiniHeatmap(
                        accent: accent,
                        checkedSet: data.heatmapChecked,
                        theme: theme,
                        strings: strings,
                      ),

                      const SizedBox(height: 16),

                      // RECENT CHECK-INS
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.recentCheckins,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (data.days.isEmpty)
                              Text(
                                strings.noCheckinsYet,
                                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.55)),
                              )
                            else
                              ...data.days.take(8).map((d) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: accent),
                                      const SizedBox(width: 10),
                                      Text(
                                        d,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StreakRing extends StatelessWidget {
  final double progress;
  final Color accent;
  final Color baseColor;
  final String valueText;
  final String subText;
  final Color? textColor;

  const _StreakRing({
    required this.progress,
    required this.accent,
    required this.baseColor,
    required this.valueText,
    required this.subText,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(96, 96),
                painter: _RingPainter(
                  progress: v,
                  accent: accent,
                  baseColor: baseColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    valueText,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor),
                  ),
                  Text(
                    subText,
                    style: TextStyle(
                      color: textColor?.withOpacity(0.55),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final Color baseColor;

  _RingPainter({required this.progress, required this.accent, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;

    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final progPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);

    final startAngle = -math.pi / 2;
    final sweepAngle = (math.pi * 2) * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.accent != accent || oldDelegate.baseColor != baseColor;
  }
}

class _MiniHeatmap extends StatelessWidget {
  final Color accent;
  final Set<String> checkedSet;
  final ThemeData theme;
  final S strings;

  const _MiniHeatmap({
    required this.accent, 
    required this.checkedSet,
    required this.theme,
    required this.strings,
  });

  String _dayKey(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(30, (i) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      return d;
    }).reversed.toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                strings.consistency,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                ),
              ),
              const Spacer(),
              Text(
                '${checkedSet.length}/30',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, i) {
              final d = days[i];
              final key = _dayKey(d);
              final checked = checkedSet.contains(key);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: checked ? accent.withOpacity(0.9) : theme.dividerColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: checked ? accent.withOpacity(0.75) : theme.dividerColor.withOpacity(0.1),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.missedDaysInfo,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityVm {
  final String id;
  final String title;
  final int startMinutes;
  final int targetDaysPerWeek;
  final int color;
  final int iconCodePoint;

  _ActivityVm({
    required this.id,
    required this.title,
    required this.startMinutes,
    required this.targetDaysPerWeek,
    required this.color,
    required this.iconCodePoint,
  });

  factory _ActivityVm.fromMap(Map<String, dynamic> map) {
    return _ActivityVm(
      id: map['id'] as String,
      title: map['title'] as String,
      startMinutes: (map['start_minutes'] as num).toInt(),
      targetDaysPerWeek: (map['target_days_per_week'] as num).toInt(),
      color: (map['color'] as num?)?.toInt() ?? 0xFF9E9E9E,
      iconCodePoint: (map['icon'] as num?)?.toInt() ?? Icons.star.codePoint,
    );
  }
}

class _DetailData {
  final _ActivityVm? activity;
  final List<String> days;
  final bool checkedToday;
  final int currentStreak;
  final Set<String> heatmapChecked;

  const _DetailData({
    required this.activity,
    required this.days,
    required this.checkedToday,
    required this.currentStreak,
    required this.heatmapChecked,
  });

  static const empty = _DetailData(
    activity: null,
    days: [],
    checkedToday: false,
    currentStreak: 0,
    heatmapChecked: {},
  );
}