import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityVm {
  final String id;
  final String title;
  final int startMinutes;
  final int targetDaysPerWeek;

  // UI metrics
  final int streak; // 🔥
  final int doneThisWeek; // 0/target

  // style
  final int color;
  final int iconCodePoint;

  ActivityVm({
    required this.id,
    required this.title,
    required this.startMinutes,
    required this.targetDaysPerWeek,
    required this.streak,
    required this.doneThisWeek,
    required this.color,
    required this.iconCodePoint,
  });

  factory ActivityVm.fromMap(
    Map<String, dynamic> map, {
    required int streak,
    required int doneThisWeek,
  }) {
    return ActivityVm(
      id: map['id'] as String,
      title: map['title'] as String,
      startMinutes: (map['start_minutes'] as num).toInt(),
      targetDaysPerWeek: (map['target_days_per_week'] as num).toInt(),
      color: (map['color'] as num?)?.toInt() ?? 0xFF2A2F3A,
      iconCodePoint: (map['icon'] as num?)?.toInt() ?? Icons.check_circle.codePoint,
      streak: streak,
      doneThisWeek: doneThisWeek,
    );
  }
}

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final _supabase = Supabase.instance.client;
  late Future<List<ActivityVm>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  String _dayKey(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  DateTime _startOfWeekMonday(DateTime now) {
    final d = DateTime(now.year, now.month, now.day);
    final diff = d.weekday - DateTime.monday; // monday=1
    return d.subtract(Duration(days: diff));
  }

  int _calcStreakFromSet(Set<String> daysSet) {
    if (daysSet.isEmpty) return 0;

    final now = DateTime.now();
    DateTime cursor = DateTime(now.year, now.month, now.day);

    int streak = 0;

    // bugün yoksa dünden başla
    final todayKey = _dayKey(cursor);
    if (!daysSet.contains(todayKey)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (true) {
      final key = _dayKey(cursor);
      if (!daysSet.contains(key)) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<List<ActivityVm>> _load() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // 1) activities
    final actsRes = await _supabase
        .from('activities')
        .select('id,title,start_minutes,target_days_per_week,color,icon,created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final acts = (actsRes as List).cast<Map<String, dynamic>>();

    if (acts.isEmpty) return [];

    // 2) checkins (tek seferde çekiyoruz)
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 140));
    final fromKey = _dayKey(from);

    final checkinsRes = await _supabase
        .from('checkins')
        .select('activity_id, checkin_date')
        .eq('user_id', user.id)
        .gte('checkin_date', fromKey);

    final rows = (checkinsRes as List).cast<Map<String, dynamic>>();

    // activityId -> set of dates
    final Map<String, Set<String>> byActivity = {};
    for (final r in rows) {
      final aid = r['activity_id'] as String;
      final day = r['checkin_date'] as String; // ✅ senin kolon
      (byActivity[aid] ??= <String>{}).add(day);
    }

    // week count
    final weekStart = _dayKey(_startOfWeekMonday(now));

    return acts.map((a) {
      final id = a['id'] as String;
      final set = byActivity[id] ?? <String>{};

      final streak = _calcStreakFromSet(set);

      final doneThisWeek = set.where((d) => d.compareTo(weekStart) >= 0).length;

      return ActivityVm.fromMap(
        a,
        streak: streak,
        doneThisWeek: doneThisWeek,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitelerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabase.auth.signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool>('/activities/new');
          if (created == true) _refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ActivityVm>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Hata: ${snap.error}'));
          }

          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Henüz aktivite yok.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final a = items[i];
                final iconData = IconData(a.iconCodePoint, fontFamily: 'MaterialIcons');
                final color = Color(a.color);

                final ratio = a.targetDaysPerWeek <= 0
                    ? 0.0
                    : (a.doneThisWeek / a.targetDaysPerWeek).clamp(0.0, 1.0);

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    // ✅ Detail’den result true gelirse anında refresh
                    final changed = await context.push<bool>('/activities/${a.id}');
                    if (changed == true) _refresh();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TOP ROW
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: color.withOpacity(0.20),
                              child: Icon(iconData, color: color),
                            ),
                            const SizedBox(width: 12),

                            // ✅ Title geri geldi
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${a.startMinutes} dk • Hedef: ${a.targetDaysPerWeek}/hafta',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),

                            // 🔥 STREAK (mini animasyon)
                            _StreakPill(value: a.streak),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // PROGRESS LABEL
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white.withOpacity(0.06)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.show_chart, size: 16, color: Colors.white.withOpacity(0.85)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'In progress',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${a.doneThisWeek}/${a.targetDaysPerWeek} this week',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.06),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
                            Text(
                              'Tap to check-in & see streak.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.65),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int value;
  const _StreakPill({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          // 🔥 küçük pulse anim
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              Icons.local_fire_department,
              key: ValueKey(value),
              size: 18,
              color: value > 0 ? const Color(0xFFFFB74D) : Colors.white.withOpacity(0.45),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Text(
              '$value',
              key: ValueKey('streak_$value'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}