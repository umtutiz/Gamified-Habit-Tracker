import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _supabase = Supabase.instance.client;

  final _titleCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController(text: '15');
  final _targetCtrl = TextEditingController(text: '5');

  bool _loading = false;

  // Seçilebilir ikonlar (Material)
  static const _iconOptions = <IconData>[
    Icons.book,
    Icons.fitness_center,
    Icons.code,
    Icons.brush,
    Icons.music_note,
    Icons.self_improvement,
    Icons.local_drink,
    Icons.directions_run,
    Icons.bedtime,
    Icons.restaurant,
    Icons.sports_soccer,
    Icons.language,
  ];

  // Seçilebilir renkler
  static const _colorOptions = <Color>[
    Color(0xFF2196F3), // blue
    Color(0xFF4CAF50), // green
    Color(0xFFFF9800), // orange
    Color(0xFFE91E63), // pink
    Color(0xFF9C27B0), // purple
    Color(0xFF00BCD4), // cyan
    Color(0xFFFF5722), // deep orange
    Color(0xFF607D8B), // blue grey
    Color(0xFF795548), // brown
    Color(0xFF3F51B5), // indigo
    Color(0xFF009688), // teal
    Color(0xFFF44336), // red
  ];

  int _selectedIconCodePoint = Icons.book.codePoint;
  int _selectedColorInt = 0xFF2196F3;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _minutesCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık boş olamaz')),
      );
      return;
    }

    final startMinutes = int.tryParse(_minutesCtrl.text.trim()) ?? 15;
    final target = int.tryParse(_targetCtrl.text.trim()) ?? 5;

    if (startMinutes <= 0 || startMinutes > 600) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dakika 1 ile 600 arasında olmalı')),
      );
      return;
    }
    if (target <= 0 || target > 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hedef 1 ile 7 arasında olmalı')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _supabase.from('activities').insert({
        'user_id': user.id,
        'title': title,
        'start_minutes': startMinutes,
        'target_days_per_week': target,
        'color': _selectedColorInt,
        'icon': _selectedIconCodePoint,
      });

      if (!mounted) return;
      Navigator.of(context).pop(true); // ActivitiesScreen refresh
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = Color(_selectedColorInt);
    final selectedIcon = IconData(_selectedIconCodePoint, fontFamily: 'MaterialIcons');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivite Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: selectedColor,
                child: Icon(selectedIcon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'İkon & renk seç',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Renk seçimi
          Text('Renk', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _colorOptions.map((c) {
              final isSelected = c.value == _selectedColorInt;
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() => _selectedColorInt = c.value),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // İkon seçimi
          Text('İkon', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _iconOptions.map((ic) {
              final isSelected = ic.codePoint == _selectedIconCodePoint;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedIconCodePoint = ic.codePoint),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isSelected ? selectedColor.withOpacity(0.15) : Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? selectedColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(ic, color: isSelected ? selectedColor : Colors.black54),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Başlık',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minutesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Başlangıç dk',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Hedef (1-7)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          FilledButton.icon(
            onPressed: _loading ? null : _create,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(_loading ? 'Ekleniyor...' : 'Aktivite Oluştur'),
          ),
        ],
      ),
    );
  }
}