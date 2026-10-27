/// A phone number someone can call in an emergency. Add ONLY numbers you have
/// verified with a local organisation. The app ships with none on purpose.
class EmergencyContact {
  const EmergencyContact(this.label, this.number, {this.note = ''});
  final String label;
  final String number;
  final String note;
}

class AppConfig {
  /// Supabase: Project Settings > API. Use the anon public key only,
  /// never the service_role key.
  static const supabaseUrl = 'YOUR_SUPABASE_URL';
  static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static bool get isConfigured =>
      !supabaseUrl.startsWith('YOUR_') && !supabaseAnonKey.startsWith('YOUR_');

  /// Ethiopia emergency numbers, taken from public sources (government travel
  /// advice, UNFPA and listings). Numbers can change and a few older sources
  /// disagree, so CONFIRM each one with a local organization before launch.
  static const emergencyNumbersCheckedOn = '25 Oct 2026';
  static const emergencyContacts = <EmergencyContact>[
    EmergencyContact('Police', '991', note: 'Free to call'),
    EmergencyContact('Ambulance', '907', note: 'Red Cross ambulance'),
    EmergencyContact('Fire', '939'),
    EmergencyContact('Women & GBV hotline', '7711',
        note: 'EWLA · free · Amharic, Afaan Oromo, Tigrinya'),
  ];
}
