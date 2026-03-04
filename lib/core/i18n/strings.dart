import 'package:flutter/widgets.dart';

class S {
  final Locale locale;
  S(this.locale);

  static S of(BuildContext context) => S(Localizations.localeOf(context));

  bool get isTr => locale.languageCode.toLowerCase() == 'tr';

  String get settings => isTr ? 'Ayarlar' : 'Settings';
  String get language => isTr ? 'Dil' : 'Language';
  String get theme => isTr ? 'Tema' : 'Theme';
  String get accent => isTr ? 'Vurgu rengi' : 'Accent';
  String get background => isTr ? 'Arkaplan' : 'Background';
  String get system => isTr ? 'Sistem' : 'System';
  String get light => isTr ? 'Açık' : 'Light';
  String get dark => isTr ? 'Koyu' : 'Dark';

  // --- Activity Detail Sayfası İçin Eklenenler ---
  String get last30Days => isTr ? 'Son 30 gün' : 'Last 30 days';
  String get consistency => isTr ? 'Tutarlılık' : 'Consistency';
  String get missedDaysInfo => isTr ? 'Gün kaçırmak normaldir. Zinciri iki kez kırma.' : 'Missed days are normal. Don’t break the chain twice.';
  String get recentCheckins => isTr ? 'Son check-in’ler' : 'Recent check-ins';
  String get noCheckinsYet => isTr ? 'Henüz check-in yok.' : 'No check-ins yet.';
  String get startLabel => isTr ? 'Başlangıç: ' : 'Start: ';
  String get minLabel => isTr ? ' dk' : ' min';
  String get targetLabel => isTr ? ' • Hedef: ' : ' • Target: ';
  String get perWeek => isTr ? '/hafta' : '/week';
  String get beastMode => isTr ? '🔥 Canavar modu' : '🔥 Beast mode';
  String get keepGoing => isTr ? 'Aynen devam' : 'Keep going';
  String get checkedInToday => isTr ? 'Bugün check-in yapıldı.' : 'Checked in today.';
  String get checkInToKeepStreak => isTr ? 'Bugün check-in yap, streak’i koru.' : 'Check in today to keep the streak.';
  String get undoToday => isTr ? 'Bugünü geri al' : 'Undo today';
  String get checkInTodayAction => isTr ? 'Bugün check-in' : 'Check-in today';
  String get activityNotFound => isTr ? 'Aktivite bulunamadı.' : 'Activity not found.';
  String get errorPrefix => isTr ? 'Hata: ' : 'Error: ';

  String presetLabel(String key) {
    if (isTr) {
      return switch (key) {
        'graphite' => 'Gri (Graphite)',
        'midnight' => 'Gece (Midnight)',
        'emerald' => 'Zümrüt (Emerald)',
        _ => key,
      };
    } else {
      return switch (key) {
        'graphite' => 'Graphite',
        'midnight' => 'Midnight',
        'emerald' => 'Emerald',
        _ => key,
      };
    }
  }
}