import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

/// Current UI language. Every Tx and LabeledField widget listens to this,
/// so changing the language updates the whole app instantly without a restart.
final languageNotifier = ValueNotifier<String>('English');

const supportedLanguages = ['English', 'አማርኛ', 'Afaan Oromo'];

/// Initialize saved language on app startup.
Future<void> initLanguage() async {
  try {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString('language');
    if (saved != null && supportedLanguages.contains(saved)) {
      languageNotifier.value = saved;
    }
  } catch (_) {
    // Falls back to English if preferences are unavailable.
  }
}

/// Set active language and persist to preferences.
Future<void> setAppLanguage(String lang) async {
  if (!supportedLanguages.contains(lang)) return;
  languageNotifier.value = lang;
  try {
    final p = await SharedPreferences.getInstance();
    await p.setString('language', lang);
  } catch (_) {}
}

/// Show modal language picker bottom sheet anywhere in the app.
void showLanguagePicker(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: ValueListenableBuilder<String>(
        valueListenable: languageNotifier,
        builder: (_, currentLang, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.language, color: C.primary),
                  const SizedBox(width: 10),
                  Text(
                    trFor(currentLang, 'Language'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            for (final l in supportedLanguages)
              ListTile(
                title: Text(
                  l,
                  style: TextStyle(
                    fontWeight: currentLang == l
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: currentLang == l ? C.primary : null,
                  ),
                ),
                subtitle: Text(
                  trFor(l, 'Your voice belongs here.'),
                  style: const TextStyle(fontSize: 12, color: C.muted),
                ),
                trailing: currentLang == l
                    ? const Icon(Icons.check, color: C.primary)
                    : null,
                onTap: () {
                  setAppLanguage(l);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

/// Format localized current date for top banner on Home (with weekday).
String formatLocalizedDateWithDay(DateTime dt, String lang) {
  const daysAm = ['', 'ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'አርብ', 'ቅዳሜ', 'እሁድ'];
  const monthsAm = [
    '',
    'ጥር',
    'የካቲት',
    'መጋቢት',
    'ሚያዚያ',
    'ግንቦት',
    'ሰኔ',
    'ሐምሌ',
    'ነሐሴ',
    'መስከረም',
    'ጥቅምት',
    'ህዳር',
    'ታህሳስ',
  ];

  const daysOm = [
    '',
    'Wiixata',
    'Kibxata',
    'Roobii',
    'Kamisa',
    'Jimaata',
    'Sanbata',
    'Dilbata',
  ];
  const monthsOm = [
    '',
    'Amajjii',
    'Guraandhala',
    'Bitooteessa',
    'Ebla',
    'Caamsaa',
    'Waxabajjii',
    'Adooleessa',
    'Hagayya',
    'Fuulbana',
    'Onkololeessa',
    'Sadaasa',
    'Muddee',
  ];

  if (lang == 'አማርኛ') {
    return '${daysAm[dt.weekday]}፣ ${dt.day} ${monthsAm[dt.month]} ${dt.year}';
  } else if (lang == 'Afaan Oromo') {
    return '${daysOm[dt.weekday]}, ${dt.day} ${monthsOm[dt.month]} ${dt.year}';
  }
  return DateFormat('EEEE, d MMMM').format(dt).toUpperCase();
}

/// Format localized short date (e.g. "30 ጥቅምት 2026").
String formatLocalizedDate(DateTime dt, String lang) {
  const monthsAm = [
    '',
    'ጥር',
    'የካቲት',
    'መጋቢት',
    'ሚያዚያ',
    'ግንቦት',
    'ሰኔ',
    'ሐምሌ',
    'ነሐሴ',
    'መስከረም',
    'ጥቅምት',
    'ህዳር',
    'ታህሳስ',
  ];
  const monthsOm = [
    '',
    'Amajjii',
    'Guraandhala',
    'Bitooteessa',
    'Ebla',
    'Caamsaa',
    'Waxabajjii',
    'Adooleessa',
    'Hagayya',
    'Fuulbana',
    'Onkololeessa',
    'Sadaasa',
    'Muddee',
  ];

  if (lang == 'አማርኛ') {
    return '${dt.day} ${monthsAm[dt.month]} ${dt.year}';
  } else if (lang == 'Afaan Oromo') {
    return '${dt.day} ${monthsOm[dt.month]} ${dt.year}';
  }
  return DateFormat('d MMM yyyy').format(dt);
}

/// Format localized date and time (e.g. "30 ጥቅምት 2026፣ 14:30").
String formatLocalizedDateTime(DateTime dt, String lang) {
  final d = formatLocalizedDate(dt, lang);
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  if (lang == 'አማርኛ') {
    return '$d፣ $h:$m';
  } else if (lang == 'Afaan Oromo') {
    return '$d, $h:$m';
  }
  return DateFormat('d MMM yyyy, HH:mm').format(dt);
}

/// Format localized month and year.
String formatLocalizedMonthYear(DateTime dt, String lang) {
  const monthsAm = [
    '',
    'ጥር',
    'የካቲት',
    'መጋቢት',
    'ሚያዚያ',
    'ግንቦት',
    'ሰኔ',
    'ሐምሌ',
    'ነሐሴ',
    'መስከረም',
    'ጥቅምት',
    'ህዳር',
    'ታህሳስ',
  ];
  const monthsOm = [
    '',
    'Amajjii',
    'Guraandhala',
    'Bitooteessa',
    'Ebla',
    'Caamsaa',
    'Waxabajjii',
    'Adooleessa',
    'Hagayya',
    'Fuulbana',
    'Onkololeessa',
    'Sadaasa',
    'Muddee',
  ];

  if (lang == 'አማርኛ') {
    return '${monthsAm[dt.month]} ${dt.year}';
  } else if (lang == 'Afaan Oromo') {
    return '${monthsOm[dt.month]} ${dt.year}';
  }
  return DateFormat('MMMM yyyy').format(dt);
}

String trFor(String lang, String s) {
  if (lang == 'English') return s;
  final e = _t[s];
  if (e != null) return lang == 'አማርኛ' ? e.$1 : e.$2;

  // Dynamic prefix translations with recursive translation of the inner value
  final dynamicLabels = <String, (String, String)>{
    'Category: ': ('የክስተት ዓይነት፦ ', 'Gosa dhimmaa: '),
    'Broad location: ': ('ሰፋ ያለ አካባቢ፦ ', 'Iddoo bal\'aa: '),
    'Approximate date: ': ('ግምታዊ ቀን፦ ', 'Guyyaa tilmaamaa: '),
    'Contact • ': ('እውቂያ • ', 'Quunnamtii • '),
    'Masked contact • ': ('የተደበቀ እውቂያ • ', 'Quunnamtii dhokataa • '),
    'Evidence: ': ('ማስረጃ፦ ', 'Ragaa: '),
    'Stop recording · ': ('ቀረጻውን አቁሚ · ', 'Waraabuu dhaabi · '),
    'Last update: ': ('የመጨረሻ ዝመና፦ ', 'Haaromsa dhumaa: '),
    'Last checked ': ('ለመጨረሻ ጊዜ የተረጋገጠው ', 'Yeroo dhumaaf kan mirkanaa\'e '),
    'Hello, ': ('ሰላም፣ ', 'Akkam, '),
    'Sample listing · ': ('ናሙና ዝርዝር · ', 'Tarreeffama fakkeenyaa · '),
    'Received: ': ('የደረሰበት ጊዜ፦ ', 'Kan dhufe: '),
    'Incident (approx.): ': ('የክስተት ወቅት (ግምታዊ)፦ ', 'Yeroo mudannoo (tilmaamaan): '),
    'Institution: ': ('ተቋም፦ ', 'Dhaabbata: '),
    'Approx. coordinates: ': ('ግምታዊ መጋጠሚያዎች፦ ', 'Qubannoo tilmaamaa: '),
    'File: ': ('ፋይል፦ ', 'Faayilii: '),
  };

  for (final entry in dynamicLabels.entries) {
    if (s.startsWith(entry.key)) {
      final label = lang == 'አማርኛ' ? entry.value.$1 : entry.value.$2;
      final rest = s.substring(entry.key.length);
      final translatedRest = trFor(lang, rest);
      return '$label$translatedRest';
    }
  }

  // Posted relative dates
  if (s == 'Posted today') {
    return lang == 'አማርኛ' ? 'ዛሬ ተለጠፈ' : 'Har\'a maxxanfame';
  }
  if (s == 'Posted 1 day ago') {
    return lang == 'አማርኛ' ? 'ከ1 ቀን በፊት ተለጠፈ' : 'Guyyaa 1 dura maxxanfame';
  }
  if (s.startsWith('Posted ') && s.endsWith(' days ago')) {
    final days = s.substring(7, s.length - 9);
    return lang == 'አማርኛ' ? 'ከ$days ቀናት በፊት ተለጠፈ' : 'Guyyoota $days dura maxxanfame';
  }

  // Last checked date handling
  if (s.startsWith('Last checked ') && s.endsWith(' from public sources.')) {
    return lang == 'አማርኛ'
        ? 'ከሕዝብ መረጃዎች የተረጋገጠው ጥቅምት 25/2026 ነው።'
        : 'Maddoota uummataa irraa yeroo dhumaaf kan mirkanaa\'e Onkololeessa 25, 2026.';
  }

  // Dynamic step label handling
  if (s.contains(' / SAFETY')) {
    final prefix = s.split(' / ')[0];
    return '$prefix / ${lang == 'አማርኛ' ? 'ደህንነት' : 'NAGEENYA'}';
  }
  if (s.contains(' / SAFEVOICE')) {
    final prefix = s.split(' / ')[0];
    return '$prefix / ${lang == 'አማርኛ' ? 'ሰይፍቮይስ' : 'SAGALEE NAGAA'}';
  }

  // Evidence count handling (e.g. "2 attached")
  if (s.endsWith(' attached')) {
    final count = s.split(' ')[0];
    return lang == 'አማርኛ' ? '$count ተያይዟል' : '$count maxxanfameera';
  }

  // Character counter helper
  if (s.endsWith(' / 3,000 characters')) {
    final count = s.split(' ')[0];
    return lang == 'አማርኛ' ? '$count / 3,000 ፊደላት' : '$count / 3,000 qubeewwan';
  }

  // Lowercase / code key mappings to title case labels
  const codeMap = <String, String>{
    'harassment': 'Harassment',
    'bullying': 'Bullying',
    'discrimination': 'Discrimination',
    'abuse': 'Abuse',
    'disrespect': 'Disrespect',
    'workplace_inequality': 'Unequal opportunity',
    'other': 'Other',
    'counseling': 'Counseling',
    'legal_aid': 'Legal aid',
    'gbv_support': 'GBV support',
    'shelter': 'Shelter',
    'health': 'Health',
    'scholarship': 'Scholarship',
    'internship': 'Internship',
    'job': 'Job',
    'training': 'Training',
    'mentorship': 'Mentorship',
    'received': 'Received',
    'under_review': 'Under review',
    'referred': 'Referred',
    'resolved': 'Resolved',
    'closed': 'Closed',
    'university': 'University',
    'school': 'School',
    'workplace': 'Workplace',
    'ngo': 'NGO',
    'government': 'Government office',
    'community': 'Community',
    'reviewer': 'Reviewer',
    'manager': 'Manager',
  };
  if (codeMap.containsKey(s)) {
    return trFor(lang, codeMap[s]!);
  }

  return s; // falls back to English if not found
}

String tr(String s) => trFor(languageNotifier.value, s);

// English : (Amharic, Afaan Oromo)
const _t = <String, (String, String)>{
  // ----- navigation & common actions
  'Home': ('ቤት', 'Mana'),
  'Explore': ('ያስሱ', 'Qorannoo'),
  'Report': ('ሪፖርት', 'Gabaasa'),
  'Support': ('ድጋፍ', 'Deeggarsa'),
  'Profile': ('መገለጫ', 'Piroofayilii'),
  'Back': ('ተመለስ', 'Duubatti'),
  'Next': ('ቀጥል', 'Itti aanu'),
  'Cancel': ('ሰርዝ', 'Haqi'),
  'Save': ('አስቀምጥ', "Olkaa'i"),
  'Delete': ('ሰርዝ', 'Haqi'),
  'Remove': ('አስወግድ', 'Balleessi'),
  'Edit': ('አርም', 'Gulaali'),
  'Manage': ('አስተዳድር', 'Bulchi'),
  'Try again': ('እንደገና ሞክር', "Irra deebi'ii yaali"),
  'Quick exit': ('ፈጣን መውጫ', "Battalumatti ba'i"),
  'Language': ('ቋንቋ', 'Afaan'),
  'Name': ('ስም', 'Maqaa'),
  'All': ('ሁሉም', 'Hunda'),
  'Call': ('ደውይ', 'Bilbili'),
  'Email': ('ኢሜይል', 'Imeelii'),
  'Verified': ('የተረጋገጠ', "Mirkanaa'e"),
  'Sample listing': ('ናሙና ዝርዝር', 'Tarreeffama fakkeenyaa'),
  'Hello': ('ሰላም', 'Akkam'),
  'Not given': ('አልተሰጠም', 'Hin kennamne'),
  'None attached': ('ምንም አልተያያዘም', 'Wanti maxxanfame hin jiru'),
  'attached': ('ተያይዟል', 'maxxanfameera'),
  'characters': ('ፊደላት', 'qubeewwan'),

  // ----- languages
  'English': ('እንግሊዝኛ', 'Ingiliffa'),
  'አማርኛ': ('አማርኛ', 'Amaariffa'),
  'Afaan Oromo': ('አፋን ኦሮሞ', 'Afaan Oromoo'),

  // ----- welcome & onboarding
  'Skip introduction': ('መግቢያውን ዝለል', 'Seensa irra utaali'),
  'Your voice belongs here.': (
    'ድምፅሽ እዚህ ቦታ አለው።',
    'Sagaleen kee asitti kan keeti.',
  ),
  'Support, on your terms.': ('ድጋፍ፣ በራስሽ መንገድ።', 'Deeggarsa, akka feetetti.'),
  'Your next chapter starts with you.': (
    'ቀጣዩ ምዕራፍሽ ከአንቺ ይጀምራል።',
    'Boqonnaan kee itti aanu si irraa jalqaba.',
  ),
  'A space for you': ('ለአንቺ የሚሆን ቦታ', 'Iddoo siif ta\'e'),
  'You are not alone': ('ብቻሽን አይደለሽም', 'Kophaa kee miti'),
  'Make room for your future': ('ለመጻኢ ጊዜሽ ቦታ ስጪ', 'Egeree keetiif iddoo kenni'),
  'A private place to speak up, find trusted support and learn about your rights, at your own pace.':
      (
        'በራስሽ ፍጥነት ድምፅሽን የምታሰሚበት፣ የታመነ ድጋፍ የምታገኚበት እና ስለ መብቶችሽ የምትማሪበት የግል ቦታ።',
        'Saffisa keetiin sagalee kee kan dhageessiftu, deeggarsa amanamaa kan argattu fi mirga kee kan barattu iddoo dhuunfaa.',
      ),
  'Find verified counseling, legal-aid and support services. You decide what to share and with whom.':
      (
        'የተረጋገጡ የምክር፣ የሕግ ድጋፍ እና የእርዳታ አገልግሎቶችን አግኚ። ምን እንደምታጋሪ እና ለማን እንደምታጋሪ የምትወስኚው አንቺ ነሽ።',
        'Tajaajiloota gorsaa, deeggarsa seeraa fi gargaarsaa mirkanaa\'an argadhu. Maal akka qooddattu fi eenyuuf akka qooddu kan murteessitu si\'i.',
      ),
  'Discover scholarships, training, mentorship and jobs with clear and fair eligibility.':
      (
        'ግልጽ እና ፍትሃዊ የብቁነት መስፈርት ያላቸውን ስኮላርሺፖች፣ ስልጠናዎች፣ የአማካሪነት ፕሮግራሞች እና ስራዎችን አግኚ።',
        'Isgoolarshippii, leenjii, mentorship fi hojiiwwan ulaagaa ifaa fi haqa qabeessa qaban argadhu.',
      ),
  'Your choice is saved.': ('ምርጫሽ ተቀምጧል።', 'Filannoon kee olkaa\'ameera.'),
  'Create private access': ('የግል መግቢያ ፍጠሪ', 'Seensa dhuunfaa uumi'),
  'Sign in': ('ግቢ', 'Seeni'),
  'Continue without an account': ('ያለ መለያ ቀጥዪ', 'Akkaawuntii malee itti fufi'),
  'Your safety. Your voice. Your future.': (
    'ደህንነትሽ። ድምፅሽ። መጻኢ ጊዜሽ።',
    'Nageenya kee. Sagalee kee. Egeree kee.',
  ),
  'Designed with care, for women and girls.': (
    'ለሴቶችና ለልጃገረዶች በጥንቃቄ የተሰራ።',
    'Dubartootaa fi durboota irratti of-eeggannoodhaan kan hojjetame.',
  ),

  // ----- auth & account
  'Welcome back.': ('እንኳን ደህና መጣሽ።', 'Baga nagaan deebitee dhuftee.'),
  'Sign in for private case access, saved opportunities and your trusted contact.':
      (
        'ለግል የጉዳይ ክትትል፣ ለተቀመጡ እድሎች እና ለታመነ ሰውሽ መረጃ ለመግባት ግቢ።',
        'Gabaasa dhuunfaa hordofuu, carraawwan kuufamanii fi nama amanamoo argachuuf seeni.',
      ),
  'Email address': ('የኢሜይል አድራሻ', 'Teessoo imeelii'),
  'Password': ('የይለፍ ቃል', 'Jecha darbii'),
  'Show password': ('የይለፍ ቃል አሳይ', 'Jecha darbii agarsiisi'),
  'Hide password': ('የይለፍ ቃል ደብቅ', 'Jecha darbii dhoksi'),
  'Forgot access?': ('መግቢያሽን ረሳሽው?', 'Seensa irraanfatte?'),
  'Signing in…': ('በመግባት ላይ…', 'Seenaa jira…'),
  'A little space for you.': ('ለአንቺ ትንሽ ቦታ።', 'Iddoo xiqqoo siif.'),
  'Create private access. We only ask for what is needed to manage your account.':
      (
        'የግል መግቢያ ፍጠሪ። መለያሽን ለማስተዳደር የሚያስፈልገውን ብቻ ነው የምንጠይቀው።',
        'Seensa dhuunfaa uumi. Akkaawuntii kee bulchuuf wanta barbaachisu qofa gaafanna.',
      ),
  'Name or nickname (optional)': (
    'ስም ወይም ቅጽል ስም (አማራጭ)',
    'Maqaa ykn moggaasa (filannoo)',
  ),
  'What should we call you?': ('ምን ብለን እንጥራሽ?', 'Maal jennee si waamnu?'),
  'Use an email only you can access.': (
    'አንቺ ብቻ ልትደርሺበት የምትችዪውን ኢሜይል ተጠቀሚ።',
    'Imeelii ati qofti banuu dandeessu fayyadami.',
  ),
  'At least 8 characters.': ('ቢያንስ 8 ፊደላት።', 'Yoo xiqqaate qubee 8.'),
  'I understand how my information is used and who can see it.': (
    'መረጃዬ እንዴት ጥቅም ላይ እንደሚውል እና ማን ሊያየው እንደሚችል ተረድቻለሁ።',
    'Odeeffannoon koo akkamitti akka fayyadamu fi eenyu akka argu nan hubadha.',
  ),
  'Creating…': ('በመፍጠር ላይ…', 'Uumaa jira…'),
  'Create account': ('መለያ ፍጠሪ', 'Akkaawuntii uumi'),
  'You do not need an account to use SheRise': (
    'SheRise ለመጠቀም የግድ መለያ አያስፈልግሽም',
    'SheRise fayyadamuuf akkaawuntiin si hin barbaachisu',
  ),
  'You can read resources and submit an anonymous report without one.': (
    'ያለ መለያ መረጃዎችን ማንበብ እና ስም-አልባ ሪፖርት ማስገባት ትችያለሽ።',
    'Akkaawuntii malee odeeffannoo dubbisuu fi gabaasa maqaa malee erguu dandeessa.',
  ),
  'Recover your access': ('መግቢያሽን መልሺ', 'Seensa kee deebisi'),
  'Enter your email and we will send a link to reset your password.': (
    'ኢሜይልሽን አስገቢና የይለፍ ቃልሽን ዳግም የምታስጀምሪበትን ሊንክ እንልካለን።',
    'Imeelii kee galchi, jecha darbii haaromsuuf liinkii siif ergina.',
  ),
  'Sending…': ('በመላክ ላይ…', 'Ergaa jira…'),
  'Send reset link': ('የዳግም ማስጀመሪያ ሊንክ ላክ', 'Liinkii deebisanii kaa\'uu ergi'),
  'Check your email': ('ኢሜይልሽን ተመልከቺ', 'Imeelii kee ilaali'),
  'If an account exists for that address, a reset link is on its way.': (
    'በዚያ አድራሻ መለያ ካለ የይለፍ ቃል ማስጀመሪያ ሊንክ እየተላከ ነው።',
    'Teessoo sanaan akkaawuntiin yoo jiraate, liinkiin haaromsaa karaa irra jira.',
  ),
  'Lost a report access code?': (
    'የሪፖርት መግቢያ ኮድሽን አጣሽው?',
    'Koodii seensa gabaasaa dhabdee?',
  ),
  'Report codes cannot be recovered. They are never stored in readable form. If you lost one, you can submit a new report.':
      (
        'የሪፖርት ኮዶች ሊመለሱ አይችሉም። በሚነበብ መልኩ በጭራሽ አይቀመጡም። ካጣሽው አዲስ ሪፖርት ማስገባት ትችያለሽ።',
        'Koodiin gabaasaa deebifamuu hin danda’u. Gonkumaa bifa dubbifamuun hin kuufamu. Yoo dhabde, gabaasa haaraa dhiyeessuu dandeessa.',
      ),
  'Back to sign in': ('ወደ መግቢያ ተመለሺ', 'Gara seensaatti deebi\'i'),
  'Demo mode': ('የሙከራ ሁነታ', 'Haala qorannoo'),
  'No account is needed yet. Tap Sign in to continue.': (
    'እስካሁን ምንም መለያ አያስፈልግም። ለመቀጠል ግቢ የሚለውን ይጫኑ።',
    'Ammaaf akkaawuntiin hin barbaachisu. Itti fufuuf Seeni kan jedhu tuqi.',
  ),
  'No account is created in this version.': (
    'በዚህ ስሪት ውስጥ ምንም መለያ አይፈጠርም።',
    'Gosa kana keessatti akkaawuntiin hin uumamu.',
  ),

  // ----- home screen
  'Here, you come first': ('እዚህ አንቺ ትቀድሚያለሽ', 'Asitti, ati dursa argatta'),
  'A safer today.\nA stronger tomorrow.': (
    'ዛሬ ይበልጥ ደህንነት።\nነገ ይበልጥ ጥንካሬ።',
    'Har\'a nageenya caalu.\nBori cimina caalu.',
  ),
  'SOS / Safety Center': ('SOS / የደህንነት ማዕከል', 'SOS / Giddugala Nageenyaa'),
  'Emergency information & trusted contacts': (
    'የአደጋ ጊዜ መረጃ እና የታመኑ ሰዎች',
    'Odeeffannoo yeroo ariifachiisaa fi namoota amanamoo',
  ),
  'How can we help?': (
    'እንዴት ልንረዳሽ እንችላለን?',
    'Akkamittiin si gargaaruu dandeenya?',
  ),
  'Speak up, your way': ('በራስሽ መንገድ ተናገሪ', 'Akka feetetti dubbadhu'),
  'Find someone to help': ('የሚረዳሽ ሰው አግኚ', 'Nama si gargaaru barbaadi'),
  'Build your next chapter': (
    'ቀጣዩን ምዕራፍሽን ገንቢ',
    'Boqonnaa kee itti aanu ijaari',
  ),
  'View private updates': ('የግል ዝመናዎችን ተመልከቺ', 'Odeeffannoo dhuunfaa ilaali'),
  'A step toward your future': (
    'ወደ መጻኢ ጊዜሽ የሚወስድ እርምጃ',
    'Tarkaanfii gara egeree keetti',
  ),
  'Explore all': ('ሁሉንም ያስሱ', 'Hunda ilaali'),
  'A small safety habit': ('ትንሽ የደህንነት ልማድ', 'Amala nageenyaa xiqqaa'),
  'On a shared device, lock SheRise before you step away. Keep private access codes somewhere only you can reach.':
      (
        'በጋራ መሣሪያ ላይ ከSheRise ከመራቅሽ በፊት ቆልፊው። የግል መግቢያ ኮዶችን አንቺ ብቻ በምትደርሺበት ቦታ አስቀምጪ።',
        'Meeshaa waliinii irratti, osoo hin fagaatin dura SheRise cufi. Koodii seensaa dhuunfaa iddoo ati qofti argachuu dandeessu olkaa\'i.',
      ),
  'No new notifications': ('አዲስ ማስታወቂያ የለም', 'Beeksiisni haaraan hin jiru'),
  'Private notifications never show report details on your lock screen.': (
    'የግል ማስታወቂያዎች በመቆለፊያ ማያ ገጽሽ ላይ የሪፖርት ዝርዝሮችን በጭራሽ አያሳዩም።',
    'Beeksisni dhuunfaa bilbila kee cufaa irratti bal’ina gabaasaa gonkumaa hin agarsiisu.',
  ),

  // ----- SafeVoice reporting
  'Your voice matters.': ('ድምፅሽ አስፈላጊ ነው።', 'Sagaleen kee ni barbaachisa.'),
  'Tell us what happened, in your own words. You are in control of how much you share.':
      (
        'ምን እንደተፈጠረ በራስሽ ቃላት ንገሪን። ምን ያህል እንደምታጋሪ የምትቆጣጠሪው አንቺ ነሽ።',
        'Wanta ta’e jecha keetiin nutti himi. Hanga fedhii keetiin wanta qooddattu to’atta.',
      ),
  'Not an emergency service': (
    'የአደጋ ጊዜ አገልግሎት አይደለም',
    'Tajaajila yeroo ariifachiisaa miti',
  ),
  'If you may be in danger now, open the Safety Center. Reporting here does not call emergency services.':
      (
        'አሁን አደጋ ላይ ከሆንሽ የደህንነት ማዕከሉን ክፈቺ። እዚህ ሪፖርት ማድረግ ለአደጋ ጊዜ አገልግሎቶች አይደውልም።',
        'Amma balaa keessa jiraachuu dandeessa yoo ta’e, Giddugala Nageenyaa bani. Asitti gabaasuun tajaajila yeroo ariifachiisaaf hin bilbilu.',
      ),
  'Choose how to speak up': (
    'እንዴት መናገር እንደምትፈልጊ ምረጪ',
    'Akkamitti dubbachuu akka feetu filadhu',
  ),
  'Anonymous': ('ማንነት የማይታወቅ', 'Maqaa malee'),
  'No name, email, phone or account is needed. Evidence and technical information may still reveal identity; anonymity cannot be guaranteed.':
      (
        'ምንም ስም፣ ኢሜይል፣ ስልክ ወይም መለያ አያስፈልግም። ማስረጃዎች እና የቴክኒክ መረጃዎች ማንነትን ሊያሳዩ ስለሚችሉ ማንነት ፈጽሞ እንደማይታወቅ ዋስትና ሊሰጥ አይችልም።',
        'Maqaan, imeeliin, bilbilli ykn akkaawuntiin hin barbaachisu. Ragaa fi odeeffannoon teeknikaa eenyummaa mul’isuu danda’a; guutummaatti maqaa malee ta’uun hin mirkanaa’u.',
      ),
  'Confidential': ('ሚስጥራዊ', 'Icciitii'),
  'Your report is linked to your account so authorized support staff can follow up, within the stated limits.':
      (
        'የተፈቀደላቸው የድጋፍ ሰራተኞች በተገለጹት ገደቦች ውስጥ ክትትል እንዲያደርጉ ሪፖርትሽ ከመለያሽ ጋር ይገናኛል።',
        'Hojjattoonni deeggarsaa hayyama qaban daangaa ibsame keessatti hordoffii akka taasisaniif gabaasni kee akkaawuntii kee waliin walqabata.',
      ),
  'How reporting works': ('ሪፖርት ማድረግ እንዴት ይሰራል', 'Gabaasni akkamitti hojjata'),
  'Choose an incident category': ('የክስተቱን ዓይነት ምረጪ', 'Gosa dhimmichaa filadhu'),
  'Use a broad location, if you wish.': (
    'ከፈለግሽ ሰፋ ያለ አካባቢ ተጠቀሚ።',
    'Yoo feete iddoo bal’aa fayyadami.',
  ),
  'Share details at your own pace': (
    'ዝርዝሩን በራስሽ ፍጥነት አጋሪ',
    'Bal\'ina saffisa kee irratti qooddadhu',
  ),
  'Evidence is always optional.': (
    'ማስረጃ ማያያዝ ሁልጊዜም አማራጭ ነው።',
    'Ragaa dhiyeessuun yeroo hunda filannoo dha.',
  ),
  'Review privacy, then submit': (
    'ግላዊነትን ገምግሚ፣ ከዚያ አስገቢ',
    'Iccitii gamaaggami, booda ergi',
  ),
  'Keep your private case access code.': (
    'የግል የጉዳይ መግቢያ ኮድሽን ጠብቂ።',
    'Koodii seensa dhimma dhuunfaa kee qabadhu.',
  ),
  'Start a report': ('ሪፖርት ጀምሪ', 'Gabaasa jalqabi'),
  'Resume private draft': ('የግል ረቂቅ ቀጥዪ', 'Dalagaa dhuunfaa itti fufi'),
  'Drafts are kept only while the app stays open, because they can contain sensitive details.':
      (
        'ረቂቆች ሊስጢራዊ መረጃ ሊይዙ ስለሚችሉ መተግበሪያው ክፍት እስካለ ድረስ ብቻ ይቀመጣሉ።',
        'Qabiyyeen iccitii qabaachuu waan danda’uuf, wixineen appiin banaa yeroo jiru qofa kuufama.',
      ),
  'What would you like to report?': (
    'ምን ሪፖርት ማድረግ ትፈልጊያለሽ?',
    'Maal gabaasuu barbaaddu?',
  ),
  'Choose the closest category. You do not need to have every detail or be sure how to describe it.':
      (
        'በጣም የሚቀርበውን ምድብ ምረጪ። ሁሉንም ዝርዝር ማወቅ ወይም በትክክል መግለጽ አያስፈልግሽም።',
        'Gosa siitti dhiyaatu filadhu. Bal’ina hunda beekuun ykn sirriitti ibsuun si hin barbaachisu.',
      ),
  'Incident category · Required': (
    'የክስተት ዓይነት · ያስፈልጋል',
    'Gosa dhimmaa · Barbaachisaa',
  ),
  'Harassment': ('ትንኮሳ', 'Rakkisuu'),
  'Discrimination': ('መድልዎ', 'Garaagarummaa'),
  'Bullying': ('ጉልበተኝነት', 'Cunqursuu'),
  'Abuse': ('ጥቃት', 'Miidhaa'),
  'Disrespect': ('ክብር ማጉደል', 'Kabaja dhabuu'),
  'Unequal opportunity': ('እኩል ያልሆነ እድል', 'Carraa wal-qixa hin taane'),
  'Approximate date (optional)': (
    'ግምታዊ ቀን (አማራጭ)',
    'Guyyaa tilmaamaa (filannoo)',
  ),
  'Choose a month': ('ወር ምረጪ', 'Ji\'a filadhu'),
  'An approximate month is enough. You can leave this blank.': (
    'ግምታዊ ወር በቂ ነው። ባዶ መተው ትችያለሽ።',
    'Ji’a tilmaamaa qofti ni ga’a. Duwwaa dhiisuu dandeessa.',
  ),
  'Broad location (optional)': (
    'ሰፋ ያለ አካባቢ (አማራጭ)',
    'Iddoo bal\'aa (filannoo)',
  ),
  'e.g. Addis Ababa': ('ለምሳሌ አዲስ አበባ', 'fkn. Finfinnee'),
  'A city or general area is enough. Do not enter a precise address.': (
    'ከተማ ወይም አጠቃላይ አካባቢ በቂ ነው። ትክክለኛ አድራሻ አታስገቢ።',
    'Magaalaa ykn naannoo waliigalaa qofti ni ga’a. Teessoo sirrii hin galchinaa.',
  ),
  'Location stays your choice': (
    'አካባቢ የአንቺ ምርጫ ነው',
    'Iddoon filannoo kee ta\'ee hafa',
  ),
  'GPS is not requested or shared in this report.': (
    'በዚህ ሪፖርት ውስጥ GPS አይጠየቅም ወይም አይጋራም።',
    'Gabaasa kana keessatti GPS hin gaafatamu ykn hin qoodamu.',
  ),
  'Continue to details': ('ወደ ዝርዝር ቀጥዪ', 'Gara bal\'inaatti itti fufi'),
  'Save private draft': ('የግል ረቂቅ አስቀምጪ', 'Dalagaa dhuunfaa olkaa\'i'),
  'Share at your own pace': ('በራስሽ ፍጥነት አጋሪ', 'Saffisa kee irratti qooddadhu'),
  'Only include what feels safe to share. Names, precise addresses and identifying details are not required.':
      (
        'ለማጋራት ደህንነቱ የተጠበቀ የሚመስልሽን ብቻ አካቺ። ስሞች፣ ትክክለኛ አድራሻዎች እና ማንነትን ገላጭ ዝርዝሮች አያስፈልጉም።',
        'Wanta qooduuf nageenyi sitti dhaga’amu qofa dabali. Maqaan, teessoon sirrii fi bal’inni eenyummaa mul’isu hin barbaachisu.',
      ),
  'What happened? · Required': (
    'ምን ተፈጠረ? · ያስፈልጋል',
    'Maaltu ta\'e? · Barbaachisaa',
  ),
  'Describe the concern in your own words…': (
    'ስጋትሽን በራስሽ ቃላት ግለጪ…',
    'Yaaddoo kee jecha keetiin ibsi…',
  ),
  'Continue to privacy & review': (
    'ወደ ግላዊነት እና ግምገማ ቀጥዪ',
    'Gara iccitii fi gamaaggamaatti itti fufi',
  ),
  'Your privacy, your choice': ('ግላዊነትሽ፣ ምርጫሽ', 'Iccitiin kee, filannoon kee'),
  'Anonymous report': ('ማንነት የማይታወቅ ሪፖርት', 'Gabaasa maqaa malee'),
  'Confidential report': ('ሚስጥራዊ ሪፖርት', 'Gabaasa icciitii'),
  'Understand the limits': ('ገደቦቹን ተረጂ', 'Daangaawwan hubadhu'),
  'Details, metadata or your account may identify you. Confidentiality can be limited by legal duties or immediate safety concerns.':
      (
        'ዝርዝሮች፣ የፋይል መረጃዎች ወይም መለያሽ ማንነትሽን ሊገልጹ ይችላሉ። ሚስጥራዊነት በሕጋዊ ግዴታዎች ወይም አፋጣኝ የደህንነት ስጋቶች ምክንያት ሊገደብ ይችላል።',
        'Bal’inni, odeeffannoon dabalataa ykn akkaawuntiin kee eenyummaa kee mul’isuu danda’a. Iccitiin dirqama seeraa ykn yaaddoo nageenyaa ariifachiisaan daangeffamuu danda’a.',
      ),
  'Review your report': ('ሪፖርትሽን ገምግሚ', 'Gabaasa kee gamaaggami'),
  'Non-sensitive summary': ('ሚስጥራዊ ያልሆነ ማጠቃለያ', 'Cuunfaa dhoksaa hin taane'),
  'Your description is hidden here for privacy.': (
    'ለግላዊነት ሲባል መግለጫሽ እዚህ ተደብቋል።',
    'Ibsii kee iccitii eeguuf asitti dhokfameera.',
  ),
  'No location sharing': ('አካባቢ አይጋራም', 'Iddoon hin qooddatamu'),
  'GPS is off. This report does not share your location.': (
    'GPS ጠፍቷል። ይህ ሪፖርት ያለሽበትን አካባቢ አያጋራም።',
    'GPS cufameera. Gabaasni kun iddoo kee hin qoodu.',
  ),
  'I understand who may review this report and the limits above. I consent to submit the information I chose to share.':
      (
        'ይህን ሪፖርት ማን ሊገመግመው እንደሚችል እና ከላይ የተጠቀሱትን ገደቦች ተረድቻለሁ። ለማጋራት የመረጥኩትን መረጃ ለማስገባት ፈቃደኛ ነኝ።',
        'Gabaasa kana eenyu akka gamaaggamu fi daangaa olitti ibsame nan hubadha. Odeeffannoo qooduuf filadhe dabarsuuf walii nan gala.',
      ),
  'Submitting…': ('በመላክ ላይ…', 'Ergaa jira…'),
  'Submit report': ('ሪፖርት አስገቢ', 'Gabaasa ergi'),
  'Submit report · demo only': (
    'ሪፖርት አስገቢ · ለሙከራ ብቻ',
    'Gabaasa ergi · agarsiisaaf qofa',
  ),
  'Back to details': ('ወደ ዝርዝር ተመለሺ', 'Gara bal\'inaatti deebi\'i'),
  'Sign in for a confidential report': (
    'ሚስጥራዊ ሪፖርት ለማድረግ ግቢ',
    'Gabaasa iccitii ta’eef seeni',
  ),
  'Confidential reports are linked to your account so support staff can follow up. Sign in, or choose Anonymous instead.':
      (
        'የድጋፍ ሰራተኞች ክትትል እንዲያደርጉ ሚስጥራዊ ሪፖርቶች ከመለያሽ ጋር ይያያዛሉ። ግቢ፣ ወይም በምትኩ ማንነት የማይታወቅ ምረጪ።',
        'Hojjattoonni deeggarsaa hordoffii akka taasisaniif gabaasni iccitii akkaawuntii kee waliin walqabata. Seeni, ykn bakka isaa Maqaa malee filadhu.',
      ),
  'Not now': ('አሁን አይደለም', 'Amma miti'),
  'No receipt to show': ('የሚታይ ደረሰኝ የለም', 'Rasiidiin agarsiifamu hin jiru'),
  'Open My Cases to see reports saved on this device.': (
    'በዚህ መሣሪያ ላይ የተቀመጡ ሪፖርቶችን ለማየት የእኔ ጉዳዮችን ክፈቺ።',
    'Gabaasota meeshaa kana irratti kuufaman arguuf Dhimmoota Koo bani.',
  ),
  'Go to My Cases': ('ወደ የእኔ ጉዳዮች ሂጂ', 'Gara Dhimmoota Koo deemi'),
  'Your voice has a place.': ('ድምፅሽ ቦታ አለው።', 'Sagaleen kee iddoo ni qaba.'),
  'Demo confirmation': ('የሙከራ ማረጋገጫ', 'Mirkaneessa agarsiisaa'),
  'Your report was received.': ('ሪፖርትሽ ደርሷል።', 'Gabaasni kee nu ga’eera.'),
  'This illustrates a submission receipt. No live report was delivered.': (
    'ይህ የቀረበ ሪፖርት ደረሰኝን ያሳያል። ምንም የቀጥታ ሪፖርት አልተላለፈም።',
    'Kun rasiidii gabaasa dhiyaate agarsiisa. Gabaasni qabatamaa hin dabarfamne.',
  ),
  'Your private access code': ('የግል መግቢያ ኮድሽ', 'Koodii seensaa dhuunfaa kee'),
  'Save this code somewhere only you can reach. It cannot be recovered. It is the only way to follow this report if you chose Anonymous.':
      (
        'ይህን ኮድ አንቺ ብቻ በምትደርሺበት ቦታ አስቀምጪው። ሊመለስ አይችልም። ስም-አልባ የመረጥሽ ከሆነ ይህን ሪፖርት ለመከታተል ብቸኛው መንገድ ይህ ነው።',
        'Koodii kana iddoo ati qofti argachuu dandeessutti olkaa’i. Deebifamuu hin danda’u. Maqaa malee kan filatte yoo ta’e, gabaasa kana hordofuuf karaan jiru isa qofa.',
      ),
  'Copy access code': ('ኮዱን ቅጂ', 'Koodii waraabi'),
  'Code copied.': ('ኮዱ ተቀድቷል።', 'Koodiin garagalchameera.'),
  'A receipt is not a response guarantee': (
    'ደረሰኝ የምላሽ ዋስትና አይደለም',
    'Raasiidiin mirkaneessa deebii miti',
  ),
  'Receiving a report does not guarantee review time, a response or emergency dispatch. SheRise does not automatically contact emergency services.':
      (
        'ሪፖርት መቀበል የግምገማ ጊዜን፣ ምላሽን ወይም የአደጋ ጊዜ ሰራተኞች መላክን ዋስትና አይሰጥም። SheRise የአደጋ ጊዜ አገልግሎቶችን በራሱ አያነጋግርም።',
        'Gabaasa fudhachuun yeroo gamaaggamaa, deebii ykn ergaa ariifachiisaa hin mirkaneessu. SheRise tajaajila ariifachiisaa ofumaan hin quunnamu.',
      ),
  'Some attachments were not uploaded': (
    'አንዳንድ አባሪዎች አልተጫኑም',
    'Faayiloonni tokko tokko hin olkaa’amne',
  ),
  'Track this case': ('ይህን ጉዳይ ተከታተይ', 'Dhimma kana hordofi'),
  'Return home': ('ወደ ቤት ተመለሺ', 'Gara mana deebi\'i'),

  // ----- evidence section
  'Evidence (optional)': ('ማስረጃ (አማራጭ)', 'Ragaa (filannoo)'),
  'Add up to 5 items: photos, PDFs or a voice note. Each up to 10 MB.': (
    'እስከ 5 ንጥሎችን አያይዢ፦ ፎቶዎች፣ PDF ወይም የድምፅ መልእክት። እያንዳንዱ እስከ 10 MB።',
    'Wantoota 5tti dabali: suuraa, PDF ykn ergaa sagalee. Tokkoon tokkoon isaanii hanga 10 MB.',
  ),
  'Add a photo or PDF': ('ፎቶ ወይም PDF ጨምሪ', 'Suuraa ykn PDF dabali'),
  'You can speak instead of typing': (
    'ከመጻፍ ይልቅ መናገር ትችያለሽ',
    'Barreessuu dhiisitee dubbachuu dandeessa',
  ),
  'Record a voice note': ('የድምፅ መልእክት ቅረጪ', 'Ergaa sagalee waraabi'),
  'Stop recording': ('ቀረጻውን አቁሚ', 'Waraabuu dhaabi'),
  'Voice note': ('የድምፅ መልእክት', 'Ergaa sagalee'),
  'Recording…': ('በመቅረጽ ላይ…', 'Waraabaa jira…'),
  'Speak when you are ready. Recording stops after 3 minutes.': (
    'ዝግጁ ስትሆኚ ተናገሪ። ቀረጻው ከ3 ደቂቃዎች በኋላ በራሱ ይቆማል።',
    'Yeroo qophooftu dubbadhu. Waraabbiin daqiiqaa 3 booda dhaabbata.',
  ),
  'Evidence can reveal your identity': (
    'ማስረጃ ማንነትሽን ሊገልጽ ይችላል',
    'Ragaan eenyummaa kee mul’isuu danda’a',
  ),
  'Photos can include hidden details like location and device. A voice can be recognized. Only attach what feels safe. Files are renamed before upload.':
      (
        'ፎቶዎች እንደ አካባቢ እና የመሣሪያ መረጃ ያሉ የተደበቁ ዝርዝሮችን ሊይዙ ይችላሉ። ድምፅ ሊታወቅ ይችላል። ደህንነቱ የተጠበቀ የሚመስልሽን ብቻ አያይዢ። ፋይሎች ከመጫናቸው በፊት ስማቸው ይቀየራል።',
        'Suuraaleen odeeffannoo dhokataa akka iddoo fi gosa meeshaa qabaachuu danda’u. Sagaleen beekamuu danda’a. Nageenya kan sitti qabu qofa maxxansi. Faayiloonni osoo hin fe’amin dura maqaan ni jijjiirama.',
      ),

  // ----- safety center
  'Safety Center': ('የደህንነት ማዕከል', 'Giddugala Nageenyaa'),
  'Take one safe step.': (
    'አንድ ደህንነቱ የተጠበቀ እርምጃ ውሰጂ።',
    'Tarkaanfii nageenya qabu tokko fudhadhu.',
  ),
  'No automatic alerts or dispatch.': (
    'ምንም ራስ-ሰር ማንቂያ ወይም ላኪ የለም።',
    'Akeekkachiisni ykn ergaan ofumaa hin jiru.',
  ),
  'If you are in immediate danger, move to a safer place if possible': (
    'አፋጣኝ አደጋ ላይ ከሆንሽ፣ ከተቻለ ወደ ደህንነቱ ወደተጠበቀ ቦታ ሂጂ',
    'Yoo balaa ariifachiisaa keessa jirte, yoo danda\'ame iddoo nageenya qabu deemi',
  ),
  'Do not rely on SheRise in an emergency. Use a known local emergency resource or reach someone you trust another way.':
      (
        'በአደጋ ጊዜ በSheRise ላይ አትተማመኚ። የሚታወቅ የአካባቢ ድንገተኛ አደጋ መገልገያ ተጠቀሚ ወይም የምታምኚውን ሰው በሌላ መንገድ አግኚ።',
        'Yeroo ariifachiisaa keessatti SheRise irratti hin hirkatin. Madda ariifachiisaa beekamaa fayyadami ykn karaa biraatiin nama amantu quunnami.',
      ),
  'Confirm numbers before relying on them': (
    'ከመመካትሽ በፊት ቁጥሮቹን አረጋግጪ',
    'Osoo hin amanin dura lakkoofsota mirkaneessi',
  ),
  'No verified emergency number is configured yet.': (
    'እስካሁን የተረጋገጠ የአደጋ ጊዜ ቁጥር አልተዘጋጀም።',
    'Lakkoofsi yeroo ariifachiisaa mirkanaa’e ammaaf hin qophoofne.',
  ),
  'Calls only start when you tap. Nothing is dialed automatically.': (
    'ጥሪዎች የሚጀምሩት ስትጫኚ ብቻ ነው። በራሱ ምንም አይደወልም።',
    'Bilbilli kan jalqabu yeroo tuqxu qofa. Ofumaan hin bilbilamu.',
  ),
  'Emergency resources': ('የአደጋ ጊዜ መገልገያዎች', 'Madda yeroo ariifachiisaa'),
  'Reach someone you trust': ('የምታምኚውን ሰው አግኚ', 'Nama amantu quunnamsiisi'),
  'Trusted contact': ('የታመነ ሰው', 'Nama amanamaa'),
  'Add a trusted contact': ('የታመነ ሰው ጨምሪ', 'Nama amanamaa dabali'),
  'No trusted contact yet.': (
    'እስካሁን ምንም የታመነ ሰው አልተጨመረም።',
    'Ammaaf quunnamtiin amanamaan hin jiru.',
  ),
  'Review message & sharing': (
    'መልእክቱንና ማጋራቱን ገምግሚ',
    'Ergaa fi qoodinsa gamaaggami',
  ),
  'Share my location': ('አካባቢዬን አጋራ', 'Iddoo koo qooddadhu'),
  'Not available in this version': (
    'በዚህ ስሪት አይገኝም',
    'Gosa kana keessatti hin argamu',
  ),
  'Planning ahead': ('አስቀድሞ ማቀድ', 'Dursanii karoorfachuu'),
  'My safety plan': ('የደህንነት እቅዴ', 'Karoora nageenya koo'),
  'A simple checklist, kept on this device': (
    'በዚህ መሣሪያ ላይ የሚቀመጥ ቀላል ዝርዝር',
    'Meeshaa kana irratti kan kuufamu tarree salphaa',
  ),
  'While you find support': ('ድጋፍ እስክታገኚ ድረስ', 'Yeroo deeggarsa barbaaddutti'),
  '• Move to a public or safer place if possible.': (
    '• ከተቻለ ወደ ሕዝብ ቦታ ወይም ይበልጥ ወደተጠበቀ ቦታ ሂጂ።',
    '• Yoo danda’ame gara iddoo uummataa ykn nageenya qabuutti deemi.',
  ),
  '• Contact a trusted person using a safe device.': (
    '• ደህንነቱ የተጠበቀ መሣሪያ በመጠቀም የምታምኚውን ሰው አግኚ።',
    '• Meeshaa nageenya qabu fayyadamuun nama amantu quunnami.',
  ),
  '• If a message fails, use another way to reach help.': (
    '• መልእክት ካልደረሰ እርዳታ ለማግኘት ሌላ መንገድ ተጠቀሚ።',
    '• Ergaan yoo hin dabarre, karaa biraatiin gargaarsa argadhu.',
  ),
  'SheRise does not automatically contact emergency services.': (
    'SheRise የአደጋ ጊዜ አገልግሎቶችን በራሱ አያነጋግርም።',
    'SheRise tajaajila yeroo ariifachiisaa ofumaan hin quunnamu.',
  ),
  'Stored only on this device.': (
    'በዚህ መሣሪያ ላይ ብቻ ይቀመጣል።',
    'Meeshaa kana irratti qofa kuufameera.',
  ),
  'Relationship (e.g. sister)': (
    'ዝምድና (ለምሳሌ እህት)',
    'Hariiroo (fkn. obboleettii)',
  ),
  'Phone number': ('የስልክ ቁጥር', 'Lakkoofsa bilbilaa'),
  'Review before sharing': (
    'ከማጋራትሽ በፊት ገምግሚ',
    'Osoo hin qooddatin dura gamaaggami',
  ),
  'Choose what to share with your trusted contact. Nothing is sent until you press send in your messaging app.':
      (
        'ለታመነ ሰውሽ ምን እንደምታጋሪ ምረጪ። በመልእክት መተግበሪያሽ ውስጥ የመላኪያ ቁልፉን እስክትጫኚ ድረስ ምንም አይላክም።',
        'Nama amantuuf maal akka qooddu filadhu. Hanga ati appii ergaa kee keessatti ergi jettuutti homtuu hin ergamu.',
      ),
  'Add a trusted contact first': (
    'በመጀመሪያ የታመነ ሰው ጨምሪ',
    'Dursa nama amanamaa dabali',
  ),
  'Go back to the Safety Center to add someone you trust.': (
    'የምታምኚውን ሰው ለመጨመር ወደ ደህንነት ማዕከሉ ተመለሺ።',
    'Nama amantu dabaluuf gara Giddugala Nageenyaatti deebi’i.',
  ),
  'Back to Safety Center': (
    'ወደ ደህንነት ማዕከል ተመለስ',
    'Gara Giddugala Nageenyaatti deebi’i',
  ),
  'Check this is the right person before continuing.': (
    'ከመቀጠልሽ በፊት ትክክለኛው ሰው መሆኑን አረጋግጪ።',
    'Itti fufuu kee dura nama sirrii ta’uu isaa mirkaneessi.',
  ),
  'Message preview': ('የመልእክት ቅድመ እይታ', 'Dursa ergaa'),
  'Please contact me when you can. I would like support.': (
    'እባክሽ/ህ ስትችል/ይ አግኚኝ/ኝኝ። ድጋፍ እፈልጋለሁ።',
    'Mee yeroo dandeessan na quunnamaa. Deeggarsa nan barbaada.',
  ),
  'Location is not included': ('አካባቢ አልተካተተም', 'Iddoon hin dabalatamne'),
  'Only this message is shared. No location is read, attached or sent.': (
    'ይህ መልእክት ብቻ ነው የሚጋራው። ምንም ዓይነት አካባቢ አይነበብም፣ አይያያዝም ወይም አይላክም።',
    'Ergaa kana qofatu qoodama. Iddoon tokkollee hin dubbifamu, hin maxxanfamu ykn hin ergamu.',
  ),
  'I have reviewed the recipient and message and choose to share only these details.':
      (
        'ተቀባዩንና መልእክቱን ገምግሜ እነዚህን ዝርዝሮች ብቻ ለማጋራት መርጫለሁ።',
        'Nama ergaa fudhatuu fi ergaa gamaaggamee, bal’ina kana qofa qoodachuuf filadheera.',
      ),
  'Review, then share': ('ገምግሚ፣ ከዚያ አጋሪ', 'Gamaaggami, booda qooddadhu'),
  'Delivery stays unconfirmed. SheRise cannot tell whether the message arrived.':
      (
        'መልእክቱ መድረሱ አልተረጋገጠም። SheRise መልእክቱ መድረስ አለመድረሱን ማወቅ አይችልም።',
        'Ergaan ga’uun isaa hin mirkanoofne. SheRise ergaan ga’uu isaa beekuu hin danda’u.',
      ),

  // ----- safety plan items
  'A general checklist to think through. Tick what is already in place.': (
    'ሊታሰብባቸው የሚገቡ አጠቃላይ የማረጋገጫ ነጥቦች። ዝግጁ የሆነውን ምልክት አድርጊበት።',
    'Tarree qabxiilee waliigalaa itti yaadamuu qaban. Wanta qophaa\'e mallattoon agarsiisi.',
  ),
  'I know a safe place I can go to': (
    'የምሄድበት ደህንነቱ የተጠበቀ ቦታ አውቃለሁ',
    'Iddoo nageenya qabu kan deemuu danda’u nan beeka',
  ),
  'I have a trusted person I can contact': (
    'ማነጋገር የምችለው የታመነ ሰው አለኝ',
    'Nama amanamaa qunnamuu danda’u nan qaba',
  ),
  'Important documents and ID are somewhere I can reach': (
    'አስፈላጊ ሰነዶች እና መታወቂያ በቀላሉ በምደርስበት ቦታ አሉ',
    'Sanadoonni barbaachisoo fi waraqaan eenyummaa iddoo dhihootti qaba',
  ),
  'My phone is charged and I can reach some money': (
    'ስልኬ ቻርጅ ተደርጓል እንዲሁም ጥቂት ገንዘብ ማግኘት እችላለሁ',
    'Bilbilli koo chaarjii qaba, qarshii muraasas argachuu nan danda’a',
  ),
  'I have a code word to use with someone I trust': (
    'ከማምነው ሰው ጋር የምጠቀምበት የምስጢር ቃል (ኮድ) አለኝ',
    'Jecha icciitii nama amanu waliin fayyadamu nan qaba',
  ),
  'I know how to reach local support services': (
    'የአካባቢ የድጋፍ አገልግሎቶችን እንዴት እንደማገኝ አውቃለሁ',
    'Tajaajiloota deeggarsa naannoo akkamitti akka quunnamu nan beeka',
  ),
  'This is general guidance': (
    'ይህ አጠቃላይ መመሪያ ነው',
    'Kun qajeelfama waliigalaa dha',
  ),
  'Your situation is unique. A trained gender-based-violence or counseling service can help you build a plan that fits your safety.':
      (
        'የእያንዳንዱ ሰው ሁኔታ የተለየ ነው። የሰለጠነ የጾታ ጥቃት ወይም የምክር አገልግሎት ለደህንነትሽ የሚስማማ እቅድ እንድታወጪ ሊረዳሽ ይችላል።',
        'Haalli kee adda. Tajaajilli miidhaa saalaa ykn gorsaa leenjifame karoora nageenya keetiif ta’u akka qopheessitu si gargaaruu danda’a.',
      ),

  // ----- emergency contacts
  'Police': ('ፖሊስ', 'Poolisii'),
  'Ambulance': ('አምቡላንስ', 'Ambulaansii'),
  'Fire': ('የእሳት አደጋ', 'Balaaf ibiddaa'),
  'Women & GBV hotline': (
    'የሴቶችና የጾታ ጥቃት የስልክ መስመር',
    'Sarara bilbilaa miidhaa saalaa fi dubartootaa',
  ),
  'Free to call': ('ነጻ ጥሪ', 'Bilbila tolaa'),
  'Red Cross ambulance': ('የቀይ መስቀል አምቡላንስ', 'Ambulaansii Fannoo Diimaa'),
  'EWLA · free · Amharic, Afaan Oromo, Tigrinya': (
    'ኢመሕአ · ነጻ · አማርኛ፣ አፋን ኦሮሞ፣ ትግርኛ',
    'EWLA · tola · Afaan Oromoo, Amaariffa, Tigrinyiffa',
  ),

  // ----- support connect
  'SupportConnect': ('የድጋፍ ማዕከል', 'Walqunnamtii Deeggarsaa'),
  'Find trusted counseling, legal-aid and support services.': (
    'የታመኑ የምክር፣ የሕግ ድጋፍ እና ሌሎች የድጋፍ አገልግሎቶችን አግኚ።',
    'Tajaajila gorsaa, gargaarsa seeraa fi deeggarsa amanamaa barbaadi.',
  ),
  'Counseling': ('ምክር', 'Gorsa'),
  'Legal aid': ('የሕግ ድጋፍ', 'Gargaarsa seeraa'),
  'GBV support': ('ጾታ ተኮር ጥቃት ድጋፍ', 'Deeggarsa miidhaa saalaa'),
  'Health': ('ጤና', 'Fayyaa'),
  'Shelter': ('መጠለያ', 'Iddoo of-baraaruu'),
  'Other': ('ሌላ', 'Biraa'),
  'Could not load services': (
    'አገልግሎቶችን መጫን አልተቻለም',
    'Tajaajiloota fe’uu hin dandeenye',
  ),
  'Check your connection and try again.': (
    'ግንኙነትሽን አረጋግጪና እንደገና ሞክሪ።',
    'Walqunnamtii kee mirkaneessii irra deebitee yaali.',
  ),
  'Nothing here yet': (
    'እስካሁን እዚህ ምንም የለም',
    'Ammaaf asitti wanti jiru hin jiru',
  ),
  'No verified services match this filter. Try another category.': (
    'ከዚህ ማጣሪያ ጋር የሚዛመዱ የተረጋገጡ አገልግሎቶች የሉም። ሌላ ምድብ ሞክሪ።',
    'Tajaajilli mirkanaa’e kan calaltuu kanaan walgitu hin jiru. Gosa biraa yaali.',
  ),
  'SheRise does not run these services': (
    'SheRise እነዚህን አገልግሎቶች አያስተዳድርም',
    'SheRise tajaajiloota kana hin bulchu',
  ),
  'Listings are checked before they appear, but please confirm details directly before relying on them.':
      (
        'ዝርዝሮች ከመውጣታቸው በፊት ይረጋገጣሉ፣ ነገር ግን ከመመካትሽ በፊት ዝርዝሮችን በቀጥታ አረጋግጪ።',
        'Tarreeffamoonni osoo hin ba’in dura ni mirkanaa’u, garuu osoo hin hirkatin dura bal’ina kallattiin mirkaneessi.',
      ),
  'Contact details are added after verification.': (
    'የእውቂያ ዝርዝሮች ከማረጋገጫ በኋላ ይጨመራሉ።',
    'Bal’inni quunnamtii erga mirkanaa’ee booda dabalama.',
  ),

  // ----- explore & equal opportunity
  'EqualOpportunity': ('እኩል እድል', 'Carraa Wal-qixa'),
  'Opportunities to grow, and knowledge to stay safe and strong.': (
    'የማደጊያ እድሎች፣ እንዲሁም ደህንነትሽን ጠብቀሽ እንድትጠነክሪ የሚረዱ ዕውቀቶች።',
    'Carraawwan itti guddatan, fi beekumsa nageenya kee eeggattee jabaattu.',
  ),
  'Opportunities': ('እድሎች', 'Carraawwan'),
  'Learn': ('ትምህርት', 'Barnoota'),
  'Scholarship': ('ስኮላርሺፕ', 'Isgoolarshippii'),
  'Internship': ('የልምምድ ስራ', 'Leenjii hojii'),
  'Job': ('ስራ', 'Hojii'),
  'Training': ('ስልጠና', 'Leenjii'),
  'Mentorship': ('መካሪነት', 'Qajeelfama'),
  'Could not load opportunities': (
    'እድሎችን መጫን አልተቻለም',
    'Carraawwan fe’uu hin dandeenye',
  ),
  'No listings yet': ('እስካሁን ምንም ዝርዝር የለም', 'Tarreen ammaaf hin jiru'),
  'Nothing matches this filter. Check back soon.': (
    'ከዚህ ማጣሪያ ጋር የሚዛመድ ምንም ነገር የለም። በቅርቡ ይመለሱ።',
    'Wanti calaltuu kanaan walgitu hin jiru. Yeroo dhiyootti deebitee ilaali.',
  ),
  'View details →': ('ዝርዝር ተመልከቺ →', 'Bal\'ina ilaali →'),
  'Fair and transparent': ('ፍትሃዊ እና ግልጽ', 'Haqummaa fi iftoomina'),
  'Listings should state who can apply and how. A real opportunity should never ask you to pay to apply.':
      (
        'ዝርዝሮች ማን እና እንዴት ማመልከት እንደሚቻል መግለጽ አለባቸው። እውነተኛ ዕድል ለማመልከት ክፍያ በጭራሽ አይጠይቅም።',
        'Tarreeffamoonni eenyu fi akkamitti akka iyyatu ibsuu qabu. Carraan dhugaa iyyachuuf kaffaltii gonkumaa hin gaafatu.',
      ),
  'Who can apply': ('ማን ማመልከት ይችላል', 'Eenyutu iyyachuu danda\'a'),
  'Open application page': ('የማመልከቻ ገጹን ክፈቺ', 'Fuula iyyannoo bani'),
  'This is a sample listing for demonstration.': (
    'ይህ ለማሳያ የቀረበ የናሙና ዝርዝር ነው።',
    'Kun tarree fakkeenyaa agarsiisaaf qophaa’e dha.',
  ),
  'Reviewed content is coming': (
    'የተገመገመ ይዘት በቅርቡ ይመጣል',
    'Qabiyyeen gamaaggamame ni dhufa',
  ),
  'This guidance is general. It will be reviewed by subject-matter experts and localized before launch.':
      (
        'ይህ መመሪያ አጠቃላይ ነው። ከመጀመሩ በፊት በዘርፉ ባለሙያዎች ተገምግሞ ወደ አካባቢ ቋንቋዎች ይተረጎማል።',
        'Qajeelfamni kun waliigalaa dha. Hojiirra ooluun dura ogeessotaan gamaaggamamee naannoodhaaf qophaa\'a.',
      ),

  // ----- learn topics
  'Understanding harassment and discrimination': (
    'ትንኮሳን እና መድልዎን መረዳት',
    'Rakkisuu fi garaagarummaa hubachuu',
  ),
  'Harassment is unwelcome behavior that offends, intimidates or humiliates you. It can be spoken, written, physical or online. Discrimination is unfair treatment because of who you are, such as your gender. If something feels wrong, your feelings are valid even if you are unsure what to call it.':
      (
        'ትንኮሳ የሚያስቀይም፣ የሚያስፈራራ ወይም የሚያዋርድ ያልተፈለገ ባህሪ ነው። በንግግር፣ በጽሑፍ፣ በአካል ወይም በኢንተርኔት ሊሆን ይችላል። መድልዎ በማንነትሽ፣ ለምሳሌ በጾታሽ ምክንያት የሚደረግ ኢፍትሃዊ አያያዝ ነው። የሆነ ነገር ትክክል እንዳልሆነ ከተሰማሽ፣ ምን ብለሽ እንደምትጠሪው እርግጠኛ ባትሆኚም ስሜትሽ ትክክል ነው።',
        'Rakkisuun amala hin barbaachisne kan si aarsu, sodaachisu ykn salphisu dha. Dubbii, barreeffama, qaamaan ykn toora interneetiitiin ta’uu danda’a. Garaagarummaan eenyummaa keetiin, kan akka saala keetiin walqabatee loogii godhamu dha. Wanti tokko sirrii akka hin taane yoo sitti dhaga’ame, maal jettee akka waamtu yoo hin beekne iyyuu miirri kee fudhatama qaba.',
      ),
  'Consent and respectful relationships': (
    'ስምምነት እና አክብሮት የተሞላበት ግንኙነት',
    'Hayyama fi hariiroo kabaja qabu',
  ),
  'Consent is a clear, freely given yes, and it can be withdrawn at any time. Silence is not consent. Pressure, threats, or being unable to decide freely mean there is no consent. Respect means listening to a no without punishment.':
      (
        'ስምምነት ግልጽ እና በነጻነት የተሰጠ እሺታ ነው፤ በማንኛውም ጊዜ ሊነሳ ይችላል። ዝምታ ስምምነት አይደለም። ጫና፣ ማስፈራራት ወይም በነጻነት መወሰን አለመቻል ስምምነት እንደሌለ ያሳያል። አክብሮት ማለት ያለ ምንም ቅጣት ወይም ቂም እምቢታን ማዳመጥ ማለት ነው።',
        'Hayyamni tole ifaa fi bilisummaan kenname dha, yeroo kamiyyuu deebifamuu danda’a. Caldhisuun hayyama miti. Dhiibbaa, doorsisa, ykn bilisaan murteessuu dadhabuun hayyamni akka hin jirre agarsiisa. Kabajni diddaa adabbii malee dhaggeeffachuu dha.',
      ),
  'Digital privacy and online safety': (
    'የዲጂታል ግላዊነት እና የኢንተርኔት ደህንነት',
    'Iccitii dijitaalaa fi nageenya toora interneetii',
  ),
  'Use a strong, different password for each account and turn on two-step verification. Review who can see your posts, photos and location. Block and report people who harass you. Keep evidence such as screenshots somewhere only you can reach.':
      (
        'ለእያንዳንዱ መለያ ጠንካራና የተለያየ የይለፍ ቃል ተጠቀሚ፤ የሁለት ደረጃ ማረጋገጫን አብሪ። ልጥፎችሽን፣ ፎቶዎችሽን እና አካባቢሽን ማን ማየት እንደሚችል ገምግሚ። ትንኮሳ የሚያደርሱብሽን ሰዎች እገጂ እና ሪፖርት አድርጊ። እንደ ስክሪንሽት ያሉ ማስረጃዎችን አንቺ ብቻ በምትደርሺበት ቦታ አስቀምጪ።',
        'Akkaawuntii hundaaf jecha darbii cimaa fi adda ta’e fayyadami, mirkaneessa sadarkaa lamaa bani. Postii, suuraa fi iddoo kee eenyu akka argu gamaaggami. Namoota si rakkisan cufii (block) gabaasi. Ragaalee kan akka iskiriinshootii iddoo ati qofti argachuu dandeessutti olkaa’i.',
      ),
  'Writing down what happened, safely': (
    'የተፈጠረውን ነገር በደህንነት መመዝገብ',
    'Wanta ta’e nageenyaan galmeessuu',
  ),
  'If you can, note the date, time, place and what happened soon after. Store notes somewhere private, not on a shared device. You never have to confront someone if it feels unsafe.':
      (
        'ከተቻለ ቀኑን፣ ሰዓቱን፣ ቦታውን እና የተፈጠረውን ነገር ክስተቱ እንደተፈጠረ ወዲያውኑ መዝግቢ። ማስታወሻዎችን በጋራ መሣሪያ ላይ ሳይሆን ሚስጥራዊ ቦታ አስቀምጪ። ደህንነትሽ የማይሰማሽ ከሆነ ሰውን ፊት ለፊት መጋፈጥ አይጠበቅብሽም።',
        'Yoo dandeesse, guyyaa, sa’aatii, iddoo fi wanta ta’e erga ta’ee booda daftee galmeessi. Yaadannoo meeshaa namoonni waliin fayyadaman irra osoo hin taane, iddoo dhuunfaa olkaa’i. Nageenyi kee kan hin dhaga’amne yoo ta’e nama dura dhaabbachuun sirra hin jiru.',
      ),
  'Supporting someone who is being harassed': (
    'ትንኮሳ የሚደርስባትን ሰው መደገፍ',
    'Nama miidhaan irra ga’e deeggaruu',
  ),
  'Listen without blaming. Believe them. Ask what they need and respect their choices. Share options without pressure, and look after yourself too.':
      (
        'ያለ ምንም ወቀሳ አዳምጪ። እመኛት። ምን እንደምትፈልግ ጠይቂ እና ምርጫዋን አክብሪ። ያለ ጫና አማራጮችን አጋሪያት፤ እንዲሁም ራስሽን ጠብቂ።',
        'Komii malee dhaggeeffadhu. Amanadhu. Maal akka barbaaddu gaafadhu, filannoo ishees kabaji. Dhiibbaa malee filannoowwan qoodiif, akkasumas of eeggadhu.',
      ),
  'Your rights and where to get help': (
    'መብቶችሽ እና እርዳታ የት እንደሚገኝ',
    'Mirga kee fi eessaa gargaarsa akka argattu',
  ),
  'Laws and services differ from place to place. A verified legal-aid or support service can explain your rights where you live. SheRise does not give legal advice.':
      (
        'ሕጎች እና አገልግሎቶች ከቦታ ወደ ቦታ ይለያያሉ። የተረጋገጠ የሕግ ድጋፍ ወይም የእርዳታ አገልግሎት በምትኖሪበት አካባቢ ያሉትን መብቶችሽን ሊያስረዳ ይችላል። SheRise የሕግ ምክር አይሰጥም።',
        'Seerotaa fi tajaajiloonni iddoo gara iddootti garaagarummaa qabu. Tajaajilli gargaarsa seeraa mirkanaa’e mirga ati qabdu siif ibsuu danda’a. SheRise gorsa seeraa hin kennu.',
      ),

  // ----- sample listings
  'Digital Skills Fellowship': (
    'የዲጂታል ክህሎቶች ፌሎውሺፕ',
    'Feloowshippii Dandeettii Dijitaalaa',
  ),
  'A sample training listing showing how programs will appear, with clear eligibility and no application fee.':
      (
        'መርሃግብሮች እንዴት እንደሚታዩ የሚያሳይ የናሙና ስልጠና ዝርዝር፤ ግልጽ የብቁነት መስፈርት ያለው እና ምንም የማመልከቻ ክፍያ የሌለው።',
        'Tarreeffama leenjii fakkeenyaa kan sagantaaleen akkamitti akka mul’atan agarsiisu, ulaagaa ifaa fi kaffaltii iyyannoo malee.',
      ),
  'Open to women and girls aged 18 and over.': (
    'ዕድሜያቸው 18 እና ከዚያ በላይ ለሆኑ ሴቶች እና ልጃገረዶች ክፍት ነው።',
    'Dubartootaa fi durboota umriin isaanii 18 fi isaa ol ta’aniif kan banaame.',
  ),
  'Women in STEM Scholarship': (
    'የሴቶች በSTEM ስኮላርሺፕ',
    'Isgoolarshippii Dubartootaa STEM keessatti',
  ),
  'A sample scholarship listing for university students.': (
    'ለዩኒቨርሲቲ ተማሪዎች የናሙና ስኮላርሺፕ ዝርዝር።',
    'Tarreeffama isgoolarshippii fakkeenyaa barattoota yuunivarsiitiif.',
  ),
  'Enrolled in a STEM degree program.': (
    'በSTEM የዲግሪ ፕሮግራም የተመዘገቡ።',
    'Sagantaa digrii STEM keessatti kan galmaa’an.',
  ),
  'Junior Analyst Internship': (
    'የጀማሪ ተንታኝ የልምምድ ስራ',
    'Leenjii Hojii Xiinxalaa Sadarkaa Duraa',
  ),
  'A sample internship listing with a fair, transparent process.': (
    'ፍትሃዊና ግልጽ ሂደት ያለው የናሙና የልምምድ ስራ ዝርዝር።',
    'Tarreeffama leenjii hojii fakkeenyaa adeemsa haqa qabeessa fi iftoomina qabuun.',
  ),
  'Final-year students and recent graduates.': (
    'የመጨረሻ ዓመት ተማሪዎች እና በቅርብ የተመረቁ።',
    'Barattoota waggaa dhumaa fi eebbifamtoota dhihoo.',
  ),
  'Mentorship Circle': ('የአማካሪነት ክበብ', 'Garee Qajeelfamaa'),
  'A sample mentorship listing connecting women with mentors.': (
    'ሴቶችን ከአማካሪዎች ጋር የሚያገናኝ የናሙና የአማካሪነት ዝርዝር።',
    'Tarreeffama qajeelfamaa fakkeenyaa dubartoota gorsitoota waliin walqunnamsiisu.',
  ),
  'Open to young women starting their careers.': (
    'የስራ ህይወታቸውን ለሚጀምሩ ወጣት ሴቶች ክፍት ነው።',
    'Dubartoota dargaggoota hojii isaanii jalqabaniif banaa dha.',
  ),
  'Apply by 30 Nov 2026': (
    'እስከ ህዳር 30/2026 ያመልክቱ',
    'Hanga Sadaasa 30, 2026tti iyyadhaa',
  ),
  'Apply by 15 Dec 2026': (
    'እስከ ታህሳስ 15/2026 ያመልክቱ',
    'Hanga Muddee 15, 2026tti iyyadhaa',
  ),
  'Apply by 10 Jan 2027': (
    'እስከ ጥር 10/2027 ያመልክቱ',
    'Hanga Amajjii 10, 2027tti iyyadhaa',
  ),
  'Rolling applications': ('ቀጣይነት ያለው ማመልከቻ', 'Iyyannoo walitti fufaa'),
  'Addis Ababa · Hybrid': ('አዲስ አበባ · የተቀናጀ', 'Finfinnee · Makaa'),
  'Ethiopia · Remote': ('ኢትዮጵያ · ከርቀት', 'Itoophiyaa · Fagoodhaa'),
  'Addis Ababa · On site': ('አዲስ አበባ · በአካል', 'Finfinnee · Iddootti'),
  'Online': ('በኢንተርኔት', 'Toora interneetii'),
  'Addis Ababa': ('አዲስ አበባ', 'Finfinnee'),
  'Adama': ('አዳማ', 'Adaamaa'),
  'Amharic, English': ('አማርኛ፣ እንግሊዝኛ', 'Afaan Oromoo, Ingiliffa'),
  'Amharic, Afaan Oromo, English': (
    'አማርኛ፣ አፋን ኦሮሞ፣ እንግሊዝኛ',
    'Afaan Oromoo, Amaariffa, Ingiliffa',
  ),
  'Afaan Oromo, Amharic': ('አፋን ኦሮሞ፣ አማርኛ', 'Afaan Oromoo, Amaariffa'),
  'Sample counseling service': (
    'የናሙና የምክር አገልግሎት',
    'Tajaajila gorsaa fakkeenyaa',
  ),
  'Sample legal-aid clinic': (
    'የናሙና የሕግ ድጋፍ ክሊኒክ',
    'Kilinika gargaarsa seeraa fakkeenyaa',
  ),
  'Sample GBV support service': (
    'የናሙና ጾታ ተኮር ጥቃት ድጋፍ አገልግሎት',
    'Tajaajila deeggarsa miidhaa saalaa fakkeenyaa',
  ),
  "Sample women's health service": (
    'የናሙና የሴቶች ጤና አገልግሎት',
    'Tajaajila fayyaa dubartootaa fakkeenyaa',
  ),
  'Real listings appear here after they are verified.': (
    'ትክክለኛ ዝርዝሮች ከተረጋገጡ በኋላ እዚህ ይታያሉ።',
    'Tarreeffamoonni dhugaa erga mirkanaa’anii booda asitti mul’atu.',
  ),

  // ----- cases
  'My Cases': ('የእኔ ጉዳዮች', 'Dhimmoota koo'),
  'Private updates for reports you saved on this device. Reports are never shown publicly.':
      (
        'በዚህ መሣሪያ ላይ ላስቀመጥሻቸው ሪፖርቶች የግል ዝመናዎች። ሪፖርቶች በይፋ በጭራሽ አይታዩም።',
        'Gabaasa meeshaa kana irratti olkaa’atteef odeeffannoo dhuunfaa. Gabaasni ifatti gonkumaa hin mul’atu.',
      ),
  'No cases yet': ('እስካሁን ምንም ጉዳይ የለም', 'Ammaaf dhimmi hin jiru'),
  'After you submit a report, its private access code is saved here. You can also add a code below.':
      (
        'ሪፖርት ካስገባሽ በኋላ የግል መግቢያ ኮዱ እዚህ ይቀመጣል። ከዚህ በታች ኮድ ማከልም ትችያለሽ።',
        'Gabaasa erga dhiyeessitee booda koodiin seensaa dhuunfaa asitti kuufama. Koodii armaan gadittis dabaluu dandeessa.',
      ),
  'Track a case by code': ('በኮድ ጉዳይ ተከታተይ', 'Koodiidhaan dhimma hordofi'),
  'Private access code': ('የግል መግቢያ ኮድ', 'Koodii seensaa dhuunfaa'),
  'Checking…': ('በማረጋገጥ ላይ…', 'Mirkaneessaa jira…'),
  'Add case': ('ጉዳይ ጨምሪ', 'Dhimma dabali'),
  'Keep your codes private': (
    'ኮዶችሽን በምስጢር ጠብቂ',
    'Koodii kee icciitiin qabadhu',
  ),
  'Anyone with a code can view that case. Codes saved here stay on this device. Remove a case if the device is shared.':
      (
        'ኮዱ ያለው ማንኛውም ሰው ያንን ጉዳይ ማየት ይችላል። እዚህ የተቀመጡ ኮዶች በዚህ መሣሪያ ላይ ብቻ ይቀራሉ። መሣሪያው የጋራ ከሆነ ጉዳዩን አስወግጂው።',
        'Namni koodii qabu hundi dhimma sana ilaaluu danda’a. Koodiin asitti kuufame meeshaa kana irratti qofa hafa. Meeshaan kan namoota biraa waliin ta’e dhimma sana balleessi.',
      ),
  'Case update': ('የጉዳይ ዝመና', 'Haaromsa dhimmaa'),
  'Live status and messages appear once SheRise is connected to the service.': (
    'SheRise ከአገልግሎቱ ጋር ከተገናኘ በኋላ የቀጥታ ሁኔታ እና መልእክቶች ይታያሉ።',
    'SheRise erga tajaajila waliin walqunnamsiifamee booda haalli qabatamaa fi ergaawwan ni mul’atu.',
  ),
  'Messages': ('መልእክቶች', 'Ergaawwan'),
  'No messages yet.': ('እስካሁን ምንም መልእክት የለም።', 'Ammaaf ergaan hin jiru.'),
  'You': ('አንቺ', 'Ati'),
  'Support team': ('የድጋፍ ሰጪ ቡድን', 'Garee deeggarsaa'),
  'Send a private message': ('የግል መልእክት ላኪ', 'Ergaa dhuunfaa ergi'),
  'Send message': ('መልእክት ላኪ', 'Ergaa ergi'),
  'Remove from this device': ('ከዚህ መሣሪያ አስወግጂ', 'Meeshaa kana irraa balleessi'),
  'Removing a case only deletes the saved code on this device. It does not delete the report.':
      (
        'ጉዳይን ማስወገድ በዚህ መሣሪያ ላይ የተቀመጠውን ኮድ ብቻ ይሰርዛል። ሪፖርቱን አይሰርዘውም።',
        'Dhimma balleessuun koodii meeshaa kana irratti kuufame qofa haqa. Gabaasa hin haqu.',
      ),
  'Received': ('ደርሷል', 'Ga’eera'),
  'Under review': ('በግምገማ ላይ', 'Gamaaggama irra'),
  'Referred': ('ተላልፏል', 'Dabarfameera'),
  'Resolved': ('ተፈትቷል', 'Furmaata argate'),
  'Closed': ('ተዘግቷል', 'Cufameera'),

  // ----- profile & help
  'Profile & help': ('መገለጫ እና እገዛ', 'Piroofayilii fi gargaarsa'),
  'Guest': ('እንግዳ', 'Keessummaa'),
  'Your account': ('የአንቺ መለያ', 'Akkaawuntii kee'),
  'Signed in': ('ገብተዋል', 'Seenteetta'),
  'Using SheRise without an account': (
    'SheRiseን ያለ መለያ በመጠቀም ላይ',
    'SheRise akkaawuntii malee fayyadamaa jirta',
  ),
  'Sign in or create access': ('ግቢ ወይም መለያ ፍጠሪ', 'Seeni ykn akkaawuntii uumi'),
  'Privacy & safety': ('ግላዊነት እና ደህንነት', 'Iccitii fi nageenya'),
  'Trusted contact, safety plan, emergency information': (
    'የታመነ ሰው፣ የደህንነት እቅድ፣ የአደጋ ጊዜ መረጃ',
    'Nama amanamaa, karoora nageenyaa, odeeffannoo yeroo ariifachiisaa',
  ),
  'Private updates for saved reports': (
    'ለተቀመጡ ሪፖርቶች የግል ዝመናዎች',
    'Gabaasota kuufamaniif odeeffannoo dhuunfaa',
  ),
  'App lock & discreet mode': (
    'የመተግበሪያ መቆለፊያ እና ስውር ሁነታ',
    'Cufaa appii fi haala dhoksaa',
  ),
  'PIN or biometric lock arrives with the Android build': (
    'የፒን ወይም የጣት አሻራ መቆለፊያ በአንድሮይድ ስሪት ላይ ይካተታል',
    'Cufaan PIN ykn mallattoo qubaa gosa Android keessatti ni dabalama',
  ),
  'Use the Quick exit button on safety screens. Long-press the title on the Notes page to return.':
      (
        'በደህንነት ገጾች ላይ የፈጣን መውጫ ቁልፍን ተጠቀሚ። ለመመለስ በማስታወሻዎች ገጽ ላይ ርዕሱን በረጅሙ ተጫኚ።',
        'Fuulota nageenyaa irratti qabduu saffisaan ba\'uu fayyadami. Deebi\'uuf fuula Yaadannoo irratti mata duree gadi qabi.',
      ),
  'Help & information': ('እገዛ እና መረጃ', 'Gargaarsa fi odeeffannoo'),
  'How SheRise works': ('SheRise እንዴት ይሰራል', 'SheRise akkamitti hojjata'),
  'SheRise helps you find support, report concerns privately and discover opportunities. It is a support and referral platform. It is not an emergency service, a law-enforcement system or an official legal complaint authority.':
      (
        'SheRise ድጋፍ እንድታገኚ፣ ስጋቶችሽን በግል ሪፖርት እንድታደርጊ እና እድሎችን እንድታገኚ ይረዳሻል። ይህ የድጋፍ እና የማገናኛ መድረክ ነው። የአደጋ ጊዜ አገልግሎት፣ የሕግ አስከባሪ ስርዓት ወይም ይፋዊ የሕግ አቤቱታ ተቋም አይደለም።',
        'SheRise deeggarsa akka argattu, dhimmoota kee icciitiin akka gabaastu fi carraawwan akka argattu si gargaara. Kun waltajjii deeggarsaa fi walqunnamsiisaati. Tajaajila yeroo ariifachiisaa, qaama seera kabachiisu ykn abbaa taayitaa himannaa seeraa miti.',
      ),
  'What anonymous means': (
    'ማንነት የማይታወቅ ማለት ምን ማለት ነው',
    'Maqaa malee jechuun maal jechuudha',
  ),
  'An anonymous report has no name, email or account attached. Details you write, evidence, or device information could still reveal who you are, so anonymity cannot be guaranteed.':
      (
        'ስም-አልባ ሪፖርት ምንም ስም፣ ኢሜይል ወይም መለያ አያይዝም። የምትጽፊያቸው ዝርዝሮች፣ ማስረጃዎች ወይም የመሣሪያ መረጃዎች አሁንም ማንነትሽን ሊያሳዩ ስለሚችሉ ሙሉ ስም-አልባነት ዋስትና አይሰጠውም።',
        'Gabaasni maqaa malee maqaa, imeelii ykn akkaawuntii hin qabu. Bal’inni ati barreessitu, ragaan ykn odeeffannoon meeshaa eenyummaa kee mul’isuu danda’a, kanaaf guutummaatti maqaa malee ta’uun mirkanaa’uu hin danda’u.',
      ),
  'What we store': ('ምን እናስቀምጣለን', 'Maal kuufna'),
  'Only what is needed: your report details and a hash of your access code on the server, and optional account details. Your trusted contact, saved case codes and safety plan stay on this device only.':
      (
        'የሚያስፈልገው ብቻ፡ የሪፖርትሽ ዝርዝሮች እና የአክሰስ ኮድሽ ሃሽ በአገልጋዩ (ሰርቨር) ላይ፣ እንዲሁም አማራጭ የመለያ ዝርዝሮች ይቀመጣሉ። የታመነ ሰውሽ፣ የተቀመጡ የጉዳይ ኮዶች እና የደህንነት እቅድሽ በዚህ መሣሪያ ላይ ብቻ ይቀራሉ።',
        'Wanta barbaachisu qofa: bal’ina gabaasa keetii fi haashii koodii seensaa keetii sarvarii irratti, fi filannoo bal’ina akkaawuntii. Namni kee amanamaan, koodiin dhimmaa olkaa’ame fi karoorri nageenyaa meeshaa kana irratti qofa hafa.',
      ),
  'Emergencies': ('የአደጋ ጊዜዎች', 'Yeroo ariifachiisaa'),
  'If you may be in danger now, move to a safer place if possible and use a verified local emergency resource or someone you trust. Reports here are not monitored in real time.':
      (
        'አሁን አደጋ ላይ ከሆንሽ ከተቻለ ወደ ደህንነቱ የተጠበቀ ቦታ ሂጂ እና የተረጋገጠ የአካባቢ አደጋ ጊዜ መገልገያ ወይም የምታምኚውን ሰው ተጠቀሚ። እዚህ የሚገቡ ሪፖርቶች በቀጥታ በቅጽበት ክትትል አይደረግባቸውም።',
        'Amma balaa keessa jiraachuu dandeessa yoo ta’e, yoo danda’ame iddoo nageenya qabutti socho’i, madda ariifachiisaa naannoo mirkanaa’e ykn nama amantu fayyadami. Gabaasni asitti godhamu battalumatti hin hordofamu.',
      ),
  'Your data': ('መረጃሽ', 'Daataa kee'),
  'Delete data on this device': (
    'በዚህ መሣሪያ ላይ ያለውን መረጃ ሰርዢ',
    'Daataa meeshaa kana irra jiru haqi',
  ),
  'Delete data on this device?': (
    'በዚህ መሣሪያ ላይ ያለው ውሂብ ይሰረዝ?',
    'Daataan meeshaa kana irra jiru haa haqamu?',
  ),
  'This removes saved case codes, your trusted contact, your safety plan and language choice from this device. It does not delete reports already submitted.':
      (
        'ይህ የተቀመጡ የጉዳይ ኮዶችን፣ የታመነ ሰውሽን፣ የደህንነት እቅድሽን እና የቋንቋ ምርጫሽን ከዚህ መሣሪያ ያስወግዳል። አስቀድመው የተላኩ ሪፖርቶችን አይሰርዝም።',
        'Kun koodii dhimmaa olkaa’ame, nama amantee, karoora nageenyaa fi filannoo afaanii meeshaa kana irraa balleessa. Gabaasota kanaan dura ergaman hin haqu.',
      ),
  'Sign out': ('ውጪ', 'Ba\'i'),
  'SheRise 0.1 · Safe. Respected. Equal.': (
    'SheRise 0.1 · ደህንነት። ክብር። እኩልነት።',
    'SheRise 0.1 · Nageenya. Kabaja. Wal-qixxummaa.',
  ),

  // ----- decoy quick exit notes screen
  'Notes': ('ማስታወሻዎች', 'Yaadannoo'),
  'Shopping list': ('የግዢ ዝርዝር', 'Tarree bittaa'),
  'Bread, rice, onions, tea': (
    'ዳቦ፣ ሩዝ፣ ሽንኩርት፣ ሻይ',
    'Daabboo, ruuza, shunkurtii, shaayee',
  ),
  'Study plan': ('የጥናት እቅድ', 'Karoora barnootaa'),
  'Read chapter 4 on Thursday': (
    'ሐሙስ ምዕራፍ 4ን ማንበብ',
    'Kamisa boqonnaa 4 dubbisuu',
  ),
  'Ideas': ('ሀሳቦች', 'Yaadota'),
  'Plant herbs on the balcony': (
    'በረንዳ ላይ ቅመማ ቅመም መትከል',
    'Barandaa irratti biqiltuu dhaabuu',
  ),

  // ----- snackbars, validations & notifications
  'You can attach up to 5 items.': (
    'እስከ 5 ንጥሎችን ማያያዝ ትችያለሽ።',
    'Hanga wantoota 5tti maxxansuu dandeessa.',
  ),
  'Could not read that file.': (
    'ያንን ፋይል ማንበብ አልተቻለም።',
    'Faayilii sana dubbisuu hin dandeenye.',
  ),
  'That file is larger than 10 MB.': (
    'ያ ፋይል ከ10 MB በላይ ነው።',
    'Faayiliin sun 10 MB caala.',
  ),
  'Only JPG, PNG and PDF files are allowed.': (
    'የተፈቀዱት JPG፣ PNG እና PDF ፋይሎች ብቻ ናቸው።',
    'Faayiloota JPG, PNG fi PDF qofatu hayyamama.',
  ),
  'Could not open the file picker.': (
    'የፋይል መራጩን መክፈት አልተቻለም።',
    'Filattuu faayilii banuu hin dandeenye.',
  ),
  'Microphone permission is needed to record a voice note.': (
    'የድምፅ መልእክት ለመቅረጽ የማይክሮፎን ፈቃድ ያስፈልጋል።',
    'Ergaa sagalee waraabuuf hayyamni maaykiroofoonii barbaachisaadha.',
  ),
  'Could not start recording.': (
    'ቀረጻ መጀመር አልተቻለም።',
    'Waraabbii jalqabuu hin dandeenye.',
  ),
  'Nothing was recorded.': ('ምንም አልተቀረጸም።', 'Wanti waraabame hin jiru.'),
  'Connect SheRise to the service to track a code.': (
    'ኮድ ለመከታተል SheRiseን ከአገልግሎቱ ጋር አገናኙ።',
    'Koodii hordofuuf SheRise tajaajila waliin walqunnamsiisaa.',
  ),
  'No case found with that code. Check it and try again.': (
    'በዚያ ኮድ የተገኘ ጉዳይ የለም። አረጋግጪና እንደገና ሞክሪ።',
    'Koodii sanaan dhimmi argame hin jiru. Mirkaneessii irra deebi’ii yaali.',
  ),
  'Could not check that code. Try again.': (
    'ያንን ኮድ ማረጋገጥ አልተቻለም። እንደገና ሞክሪ።',
    'Koodii sana mirkaneessuu hin dandeenye. Irra deebitee yaali.',
  ),
  'Could not load this case': (
    'ይህን ጉዳይ መጫን አልተቻለም',
    'Dhimma kana fe’uu hin dandeenye',
  ),
  'Could not send. Try again.': (
    'መላክ አልተቻለም። እንደገና ሞክሪ።',
    'Erguu hin dandeenye. Irra deebi’ii yaali.',
  ),
  'Data removed from this device.': (
    'ውሂብ ከዚህ መሣሪያ ላይ ተወግዷል።',
    'Daataan meeshaa kana irraa haqameera.',
  ),
  'Draft kept while the app stays open.': (
    'መተግበሪያው ክፍት እስካለ ድረስ ረቂቁ ይቀመጣል።',
    'Hanga appiin banaa ta’etti wixineen ni tura.',
  ),
  'Could not submit. Check your connection and try again.': (
    'ማስገባት አልተቻለም። ግንኙነትሽን አረጋግጪና እንደገና ሞክሪ።',
    'Dhiyeessuu hin dandeenye. Walqunnamtii kee mirkaneessii irra deebi’ii yaali.',
  ),
  'Could not open your messaging app. Try another way.': (
    'የመልእክት መተግበሪያሽን መክፈት አልተቻለም። በሌላ መንገድ ሞክሪ።',
    'Appii ergaa kee banuu hin dandeenye. Karaa biraatiin yaali.',
  ),
  'Could not sign in. Check your connection.': (
    'መግባት አልተቻለም። ግንኙነትዎን ያረጋግጡ።',
    'Seenuu hin dandeenye. Walqunnamtii kee mirkaneessi.',
  ),
  'Account created. Check your email if confirmation is required.': (
    'መለያ ተፈጥሯል። ማረጋገጫ የሚያስፈልግ ከሆነ ኢሜይልሽን ተመልከቺ።',
    'Akkaawuntiin uumameera. Mirkaneessi kan barbaachisu yoo ta’e imeelii kee ilaali.',
  ),
  'Could not create the account. Check your connection.': (
    'መለያውን መፍጠር አልተቻለም። ግንኙነትዎን ያረጋግጡ።',
    'Akkaawuntii uumuu hin dandeenye. Walqunnamtii kee mirkaneessi.',
  ),
  'Could not send the email. Try again.': (
    'ኢሜይሉን መላክ አልተቻለም። እንደገና ይሞክሩ።',
    'Imeelii erguu hin dandeenye. Irra deebitee yaali.',
  ),
  'Use a password of at least 8 characters.': (
    'ቢያንስ 8 ፊደላት ያሉት የይለፍ ቃል ተጠቀሙ።',
    'Jecha darbii yoo xiqqaate qubee 8 qabu fayyadamaa.',
  ),

  // ----- institutional board & administration
  'Institution board': ('የተቋም ቦርድ', 'Boordii Dhaabbataa'),
  'For authorized institution staff: view and respond to reports': (
    'ለተፈቀደላቸው የተቋም ሰራተኞች፡ ሪፖርቶችን ይመልከቱ እና ምላሽ ይስጡ',
    'Hojjattoota dhaabbata eeyyamameef: gabaasota ilaalaa fi deebii kennaa',
  ),
  'Manage institutions': ('ተቋማትን አስተዳድር', 'Dhaabbilee bulchi'),
  'Institution': ('ተቋም', 'Dhaabbata'),
  'All reports': ('ሁሉም ሪፖርቶች', 'Gabaasota hunda'),
  'Handle with care': ('በጥንቃቄ ይያዙ', 'Of eeggannoon qabaa'),
  'These reports are sensitive. Only use them for your institution\'s response process. Opening a report is recorded.': (
    'እነዚህ ሪፖርቶች ሚስጥራዊ ናቸው። ለተቋምዎ ምላሽ አሰጣጥ ሂደት ብቻ ይጠቀሙባቸው። ሪፖርት መክፈት ይመዘገባል።',
    'Gabaasotni kun icciitii dha. Adeemsa deebii dhaabbata keessaniif qofa fayyadamaa. Gabaasa banuun ni galmaa\'a.',
  ),
  'Could not load reports': (
    'ሪፖርቶችን መጫን አልተቻለም',
    'Gabaasota fe\'uu hin dandeenye',
  ),
  'Total': ('ጠቅላላ', 'Ida\'ama'),
  'New': ('አዲስ', 'Haaraa'),
  'In progress': ('በሂደት ላይ', 'Adeemsa irra'),
  'No reports here': ('እዚህ ምንም ሪፖርት የለም', 'Asitti gabaasni hin jiru'),
  'New reports sent to this institution will appear here.': (
    'ወደዚህ ተቋም የተላኩ አዳዲስ ሪፖርቶች እዚህ ይታያሉ።',
    'Gabaasotni haaraan gara dhaabbata kanaatti ergaman asitti mul\'atu.',
  ),
  'Refresh': ('አድስ', 'Haaromsi'),
  'GPS': ('ጂፒኤስ', 'GPS'),
  'Could not open this report': (
    'ይህን ሪፖርት መክፈት አልተቻለም',
    'Gabaasa kana banuu hin dandeenye',
  ),
  'It may not exist, or your account may not have access to it.': (
    'አይገኝም ይሆናል፣ ወይም የእርስዎ መለያ የማየት ፈቃድ የለውም።',
    'Hin jiru ta\'a, ykn akkaawuntiin kee eeyyama hin qabu.',
  ),
  'Institution: none chosen (SheRise team)': (
    'ተቋም፦ አልተመረጠም (የSheRise ቡድን)',
    'Dhaabbata: hin filatamne (Garee SheRise)',
  ),
  'Location': ('አካባቢ', 'Bakka'),
  'Rounded to about 1 km. This is the area, not an exact spot.': (
    'ወደ 1 ኪ.ሜ አካባቢ የተጠጋጋ። ይህ ሰፊው አካባቢ እንጂ ትክክለኛው ነጥብ አይደለም።',
    'Gara km 1tti kan siqfame. Kun naannoo sana malee bakka sirrii miti.',
  ),
  'Coordinates copied.': ('መጋጠሚያዎቹ ተቀድተዋል።', 'Qubannoon garagalfameera.'),
  'Copy coordinates': ('መጋጠሚያዎችን ቅዳ', 'Qubannoo garagalchi'),
  'What was reported': ('የተዘገበው ዝርዝር', 'Wanta gabaafame'),
  'Evidence': ('ማስረጃ', 'Ragaa'),
  'No attachments.': ('ምንም አባሪ የለም።', 'Wanti maxxanfame hin jiru.'),
  'Update status': ('ሁኔታውን አዘምን', 'Haala haaromsi'),
  'Private messages': ('የግል መልእክቶች', 'Ergaawwan dhuunfaa'),
  'Reporter': ('ሪፖርት አድራጊ', 'Gabaastuu'),
  'Reply to the reporter': ('ለሪፖርት አድራጊዋ ምላሽ ስጥ', 'Gabaastuuf deebii kenni'),
  'Working…': ('በመስራት ላይ…', 'Hojjechaa jira…'),
  'The reporter sees your reply under My Cases with their private code.': (
    'ሪፖርት አድራጊዋ ምላሽዎን በ«የእኔ ጉዳዮች» ስር በግል ኮዷ ታየዋለች።',
    'Gabaastuun deebii keessan koodii dhuunfaa isheetiin Dhimmoota Koo jalatti argiti.',
  ),
  'File': ('ፋይል', 'Faayilii'),
  'Could not play this voice note.': (
    'የድምፅ ማስታወሻውን ማጫወት አልተቻለም።',
    'Yaadannoo sagalee taphachiisuu hin dandeenye.',
  ),
  'Could not preview this image.': (
    'ምስሉን ማሳየት አልተቻለም።',
    'Fakkii kana agarsiisuu hin dandeenye.',
  ),
  'Pause': ('አፍታ አቁም', 'Dhaabi'),
  'Play': ('አጫውት', 'Taphachiisi'),
  'Link copied. It expires in 10 minutes.': (
    'ሊንኩ ተቀድቷል። በ10 ደቂቃዎች ውስጥ ጊዜው ያልፋል።',
    'Geessituun garagalfameera. Daqiiqaa 10 keessatti tajaajilli isaa dhuma.',
  ),
  'Copy link': ('ሊንኩን ቅዳ', 'Geessituu garagalchi'),
  'Create an institution': ('ተቋም ፍጠር', 'Dhaabbata uumi'),
  'Institution name': ('የተቋም ስም', 'Maqaa dhaabbataa'),
  'e.g. Example University': (
    'ለምሳሌ አዲስ አበባ ዩኒቨርሲቲ',
    'Fkn. Yuunivarsiitii Finfinnee',
  ),
  'Type': ('ዓይነት', 'Gosa'),
  'City': ('ከተማ', 'Magaalaa'),
  'Region': ('ክልል', 'Naannoo'),
  'e.g. Oromia': ('ለምሳሌ ኦሮሚያ', 'Fkn. Oromiyaa'),
  'Contact email (optional)': (
    'የእውቂያ ኢሜይል (አማራጭ)',
    'Imeelii qunnamtii (filannoo)',
  ),
  'Create institution': ('ተቋም ፍጠር', 'Dhaabbata uumi'),
  'Add a staff member': ('ሰራተኛ አክል', 'Hojjataa dabali'),
  'They must already have a SheRise account. Enter the email they signed up with.':
      (
        'አስቀድመው የSheRise መለያ ሊኖራቸው ይገባል። የተመዘገቡበትን ኢሜይል ያስገቡ።',
        'Dursanii akkaawuntii SheRise qabaachuu qabu. Imeelii ittiin galmaa\'an galchaa.',
      ),
  'Create an institution first.': (
    'መጀመሪያ ተቋም ይፍጠሩ።',
    'Dursa dhaabbata uumaa.',
  ),
  'Staff email address': (
    'የሰራተኛ ኢሜይል አድራሻ',
    'Teessoo imeelii hojjataa',
  ),
  'Reviewer': ('ገምጋሚ', 'Gamaaggamaa'),
  'Manager': ('አስተዳዳሪ', 'Hogganaa'),
  'Adding…': ('በማከል ላይ…', 'Dabalamaa jira…'),
  'Add staff member': ('ሰራተኛ አክል', 'Hojjataa dabali'),
  'Institutions': ('ተቋማት', 'Dhaabbilee'),
  'Enter the institution name.': (
    'የተቋሙን ስም ያስገቡ።',
    'Maqaa dhaabbataa galchaa.',
  ),
  'Institution created.': ('ተቋሙ ተፈጥሯል።', 'Dhaabbanni uumameera.'),
  'Choose an institution and enter an email address.': (
    'ተቋም ይምረጡ እና የኢሜይል አድራሻ ያስገቡ።',
    'Dhaabbata filadhaa fi teessoo imeelii galchaa.',
  ),
  'Staff member added.': ('ሰራተኛው ተጨምሯል።', 'Hojjataan dabalameera.'),
  'Administrators only': ('ለአስተዳዳሪዎች ብቻ', 'Bulchitoota qofaaf'),
  'Your account does not have permission to manage institutions.': (
    'የእርስዎ መለያ ተቋማትን የማስተዳደር ፈቃድ የለውም።',
    'Akkaawuntiin keessan dhaabbilee bulchuuf eeyyama hin qabu.',
  ),
  'Sign in required': ('መግባት ያስፈልጋል', 'Seensisa barbaachisa'),
  'Institution staff must sign in to view reports.': (
    'የተቋም ሰራተኞች ሪፖርቶችን ለማየት መግባት አለባቸው።',
    'Hojjattoonni dhaabbataa gabaasota arguuf seenuu qabu.',
  ),
  'No access yet': (
    'እስካሁን ምንም ፈቃድ የለም',
    'Hanga ammaatti eeyyamni hin jiru',
  ),
  'Your account is not linked to an institution. Ask your institution\'s administrator to add your email address.':
      (
        'የእርስዎ መለያ ከአንድም ተቋም ጋር አልተገናኘም። የተቋምዎ አስተዳዳሪ የኢሜይል አድራሻዎን እንዲያክል ይጠይቁ።',
        'Akkaawuntiin kee dhaabbata tokkooniyyuu wal hin qabanne. Bulchaan dhaabbata keetii imeelii kee akka dabalu gaafadhu.',
      ),
  'Reports sent to your institution. The reporter\'s identity is never shown here.':
      (
        'ወደ ተቋምዎ የተላኩ ሪፖርቶች። የሪፖርት አድራጊዋ ማንነት እዚህ በጭራሽ አይታይም።',
        'Gabaasota gara dhaabbata keetti ergaman. Eenyummaan gabaastuu asitti gonkumaa hin mul\'atu.',
      ),
  'Institutional Review Portal': (
    'የተቋም አስተዳደርና ክትትል ፖርታል',
    'Poortaalii Gamaaggama Dhaabbataa',
  ),
  'Secure access for authorized institutional reviewers and administrators.': (
    'ለተፈቀደላቸው የተቋም ገምጋሚዎች እና አስተዳዳሪዎች የተጠበቀ መግቢያ።',
    'Seensa eegamaa gamaaggamtota fi bulchitoota dhaabbataaf.',
  ),
  'Restricted Portal': ('የተገደበ ፖርታል', 'Poortaalii Daangeffame'),
  'This portal is restricted to registered institution officials and reviewers. Case data is strictly confidential.':
      (
        'ይህ ፖርታል ለተመዘገቡ የተቋም ኃላፊዎች እና ገምጋሚዎች ብቻ የተወሰነ ነው። የጉዳዩ መረጃዎች በጥብቅ ሚስጥራዊ ናቸው።',
        'Poortaaliin kun itti gaafatamtoota fi gamaaggamtota dhaabbata galmaa\'aniif qofa. Odeeffannoon dhimmaa icciitii guddaadhaan kan qabamuudha.',
      ),
  'Demo accounts for testing': (
    'ለሙከራ የቀረቡ የናሙና መለያዎች',
    'Akkaawuntiiwwan fakkeenyaa qorannoof',
  ),
  'Quick Login (Staff)': (
    'ፈጣን መግቢያ (ሰራተኛ)',
    'Seensa Ariifataa (Hojjataa)',
  ),
  'Quick Login (Admin)': (
    'ፈጣን መግቢያ (አስተዳዳሪ)',
    'Seensa Ariifataa (Bulchaa)',
  ),
  'Staff email': ('የሰራተኛ ኢሜይል', 'Imeelii Hojjataa'),
  'e.g. staff@institution.org': (
    'ለምሳሌ staff@institution.org',
    'Fkn. staff@institution.org',
  ),
  'Sign in to Portal': ('ወደ ፖርታል ግባ', 'Gara Poortaaliitti Seeni'),
  'Return to safe app': (
    'ወደ ዋናው መተግበሪያ ተመለስ',
    'Gara Appii Nageenyaatti Deebi\'i',
  ),
  'Enter your institutional email and password.': (
    'የተቋምዎን ኢሜይል እና የይለፍ ቃል ያስገቡ።',
    'Imeelii fi jecha darbii dhaabbata keessanii galchaa.',
  ),
  'Invalid staff credentials. Please check your email and password.': (
    'የተሳሳተ የተቋም መለያ ወይም የይለፍ ቃል። እባክዎ ኢሜይልዎን እና የይለፍ ቃልዎን ያረጋግጡ።',
    'Galmi hojjataa sirrii miti. Maaloo imeelii fi jecha darbii kee mirkaneeffadhu.',
  ),
  'Invalid staff credentials': (
    'የተሳሳተ የተቋም መለያ ወይም የይለፍ ቃል',
    'Galmi hojjataa sirrii miti',
  ),
  'Access Restricted': ('መግባት የተከለከለ ነው', 'Seensi Daangeffameera'),
  'Staff sign in required': (
    'የሰራተኞች መግቢያ ያስፈልጋል',
    'Seensi hojjattootaa barbaachisa',
  ),
  'This area is restricted to authorized institution staff and reviewers.': (
    'ይህ ክፍል ለተፈቀደላቸው የተቋም ሰራተኞች እና ገምጋሚዎች ብቻ የተወሰነ ነው።',
    'Kutaan kun hojjattoota dhaabbataa fi gamaaggamtota eeyyamameef qofa.',
  ),
  'Log out': ('ውጣ', 'Ba\'i'),
  'Logged out of institution board': (
    'ከተቋም ቦርድ ወጥተዋል',
    'Boordii dhaabbataa irraa baataniiru',
  ),
  'Connect SheRise to Supabase and run supabase/schema.sql to use the institution board with real reports. Showing demo reports for testing.':
      (
        'እውነተኛ ሪፖርቶችን የያዘውን የተቋም ቦርድ ለመጠቀም SheRiseን ከSupabase ጋር ያገናኙ እና supabase/schema.sqlን ያሂዱ። ለሙከራ የናሙና ሪፖርቶችን በማሳየት ላይ።',
        'Gabaasota qabatamaa qabu fayyadamuuf SheRise Supabase waliin walqunnamsiisaa fi supabase/schema.sql oofaa. Qorannoof gabaasota fakkeenyaa agarsiisaa jira.',
      ),
  'Sample University (demo)': (
    'የናሙና ዩኒቨርሲቲ (ማሳያ)',
    'Yuunivarsiitii Fakkeenyaa (demo)',
  ),
  'Sample Secondary School (demo)': (
    'የናሙና ሁለተኛ ደረጃ ት/ቤት (ማሳያ)',
    'Manoo Barnootaa Sadarkaa 2ffaa Fakkeenyaa (demo)',
  ),
  'Sample Employer (demo)': (
    'የናሙና አሰሪ (ማሳያ)',
    'Hojjachiisaa Fakkeenyaa (demo)',
  ),
  'Main Campus Library, Addis Ababa': (
    'ዋናው ግቢ ቤተ-መጽሐፍት፣ አዲስ አበባ',
    'Wirtuu Mana Kitaabaa, Finfinnee',
  ),
  'Headquarters, Addis Ababa': (
    'ዋና መሥሪያ ቤት፣ አዲስ አበባ',
    'Waajjira Muummee, Finfinnee',
  ),
  'Unwelcome behavior and repeated comments occurred near the study hall.': (
    'በጥናት አዳራሹ አቅራቢያ የማይፈለግ ባህሪ እና ተደጋጋሚ አስተያየቶች ተከስተዋል።',
    'Naannoo galma qo\'annootti amalli hin barbaachisnee fi yaadolee irra deddeebi\'an mul\'ataniiru.',
  ),
  'Unwelcome behavior and repeated comments occurred near the study hall. Requesting guidance on campus safety protocol.':
      (
        'በጥናት አዳራሹ አቅራቢያ የማይፈለግ ባህሪ እና ተደጋጋሚ አስተያየቶች ተከስተዋል። በግቢው የደህንነት ደንብ ላይ መመሪያ እንዲሰጠኝ እጠይቃለሁ።',
        'Naannoo galma qo\'annootti amalli hin barbaachisnee fi yaadolee irra deddeebi\'an mul\'ataniiru. Qajeelfama nageenya mooraa irratti gargaarsi na barbaachisa.',
      ),
  'Denied promotion opportunity despite meeting all criteria; treated differently than male peers.':
      (
        'ሁሉንም መስፈርቶች ባሟላም የእድገት እድል ተከልክያለሁ፤ ከወንድ ባልደረቦች በተለየ አያያዝ ተደርጎብኛል።',
        'Ulaagaalee hunda yoon guuttellee carraan guddinaa na dhowwatame; qixxee dhiirotaan ala addatti qabameera.',
      ),
  'Denied promotion opportunity despite meeting all criteria; treated differently than male peers. Seeking support from HR and management review.':
      (
        'ሁሉንም መስፈርቶች ባሟላም የእድገት እድል ተከልክያለሁ፤ ከወንድ ባልደረቦች በተለየ አያያዝ ተደርጎብኛል። ከሰው ኃይል እና ከአመራሩ ግምገማ ድጋፍ እፈልጋለሁ።',
        'Ulaagaalee hunda yoon guuttellee carraan guddinaa na dhowwatame; qixxee dhiirotaan ala addatti qabameera. Deeggarsa garee hojjattootaa fi gamaaggama hoggansaa barbaada.',
      ),
  'University': ('ዩኒቨርሲቲ', 'Yuunivarsiitii'),
  'School': ('ትምህርት ቤት', 'Mana Barumsaa'),
  'Workplace': ('የስራ ቦታ', 'Iddoo Hojii'),
  'Health facility': ('የጤና ተቋም', 'Dhaabbata Fayyaa'),
  'NGO': ('መንግስታዊ ያልሆነ ድርጅት', 'NGO'),
  'Government office': ('የመንግስት መስሪያ ቤት', 'Waajjira Mootummaa'),
  'Community': ('ማህበረሰብ', 'Hawaasa'),

  // ----- organizations & directory resources
  'Get help now — crisis lines': (
    'አሁን እርዳታ ያግኙ — የአደጋ ጊዜ መስመሮች',
    'Amma gargaarsa argadhaa — Sarara yeroo ariifachiisaa',
  ),
  'Find more resources online': (
    'ተጨማሪ መረጃዎችን በኢንተርኔት ያግኙ',
    'Maddoota dabalataa toora interneetii irraa barbaadaa',
  ),
  'Visit website': ('ድህረ ገጽ ይጎብኙ', 'Marsariitii daawwadhaa'),
  'Ethiopia Police Emergency': (
    'የኢትዮጵያ ፖሊስ አደጋ ጊዜ',
    'Poolisii Yeroo Ariifachiisaa Itoophiyaa',
  ),
  'Addis Ababa GBV Hotline': (
    'የአዲስ አበባ ጾታ ተኮር ጥቃት የስልክ መስመር',
    'Sarara Bilbilaa Miidhaa Saalaa Finfinnee',
  ),
  'Addis Ababa Rape Crisis Center': (
    'የአዲስ አበባ የአስገድዶ መድፈር ቀውስ ማዕከል',
    'Wiirtuu Qophii Balaa Gudeeddii Finfinnee',
  ),
  'EWLA Legal Aid Helpline': (
    'የኢሰሕባ የነፃ ሕግ እርዳታ መስመር',
    'Sarara Deeggarsa Seeraa EWLA',
  ),
  'Ethiopian Women Lawyers Association (EWLA)': (
    'የኢትዮጵያ ሴት የሕግ ባለሙያዎች ማህበር (ኢሰሕባ)',
    'Waldaa Dubartoota Abbootii Seeraa Itoophiyaa (EWLA)',
  ),
  'Free legal aid for women and girls in Ethiopia.': (
    'በኢትዮጵያ ውስጥ ለሚገኙ ሴቶችና ልጃገረዶች ነፃ የሕግ ድጋፍ።',
    'Dubartootaa fi durboota Itoophiyaa keessa jiraniif deeggarsa seeraa tolaa.',
  ),
  'ActionAid Ethiopia (ACSO)': ('አክሽን ኤድ ኢትዮጵያ', 'Aakshin Eed Itoophiyaa'),
  'Programs for women and girls affected by poverty and violence.': (
    'በድህነት እና በጥቃት ለተጎዱ ሴቶችና ልጃገረዶች የተዘጋጁ ፕሮግራሞች።',
    'Sagantaalee dubartootaa fi durboota hiyyummaa fi miidhaan miidhamaniif.',
  ),
  "Black Lion Hospital – Women's Clinic": (
    'ጥቁር አንበሳ ሆስፒታል – የሴቶች ክሊኒክ',
    'Hospitaala Sooriyyaa Gurraacha – Kilinika Dubartootaa',
  ),
  'Medical care and referral services for women.': (
    'ለሴቶች የሕክምና እንክብካቤ እና የሪፈራል አገልግሎቶች።',
    'Yaala fayyaa fi tajaajila dabarsa dubartootaaf.',
  ),
  'Rehabilitation Center for Women': (
    'የሴቶች ማገገሚያ ማዕከል',
    'Wiirtuu Haaromsa Dubartootaa',
  ),
  'Shelter, counseling and reintegration support for women.': (
    'ለሴቶች መጠለያ፣ የምክር አገልግሎት እና መልሶ ማቋቋም ድጋፍ።',
    'Dahannoo, gorsa fi deeggarsa walitti makamuu dubartootaaf.',
  ),
  'Support and counseling for GBV survivors.': (
    'ለጾታ ተኮር ጥቃት ተጎጂዎች ድጋፍ እና የምክር አገልግሎት።',
    'Miidhamtoota miidhaa saalaatiif deeggarsaa fi gorsa.',
  ),
  'African Women in Technology Scholarship': (
    'የአፍሪካ ሴቶች በቴክኖሎጂ ስኮላርሺፕ',
    'Isgoolarshippii Dubartoota Afrikaa Teeknooloojii Keessatti',
  ),
  'AWIT Africa': ('AWIT አፍሪካ', 'AWIT Afrikaa'),
  'Africa · Remote': ('አፍሪካ · ከርቀት', 'Afrikaa · Fagoodhaa'),
  'Check website for current cycle': (
    'ወቅታዊውን ዙር ለማየት ድህረ ገጹን ይመልከቱ',
    'Marsariitii marsaa ammaa ilaalaa',
  ),
  'AWIT supports African women pursuing technology education and careers through scholarships, mentorship and a pan-African network.':
      (
        'AWIT አፍሪካውያን ሴቶችን በስኮላርሺፕ፣ በአማካሪነት እና በመላው አፍሪካ ባለው አውታረመረብ በኩል የቴክኖሎጂ ትምህርታቸውን እና ሙያቸውን እንዲያሳድጉ ይደግፋል።',
        'AWIT dubartoonni Afrikaa barnootaa fi hojii teeknooloojii akka hordofaniif isgoolarshippii, gorsaa fi hidhata Afrikaa maraatiin deeggarsa kenna.',
      ),
  'African women in technology-related degree or diploma programs.': (
    'ከቴክኖሎጂ ጋር በተያያዙ የዲግሪ ወይም የዲፕሎማ ፕሮግራሞች የሚማሩ አፍሪካውያን ሴቶች።',
    'Dubartoota Afrikaa sagantaalee digrii ykn dippiloomaa teeknooloojiin walqabatan hordofan.',
  ),
  'Generation Ethiopia Skills Program': (
    'የጄኔሬሽን ኢትዮጵያ ክህሎት ፕሮግራም',
    'Sagantaa Dandeettii Jenereshinii Itoophiyaa',
  ),
  'Generation': ('ጄኔሬሽን', 'Jenereshinii'),
  'Rolling admissions': ('ቀጣይነት ያለው ቅበላ', 'Simannaa walitti fufaa'),
  'Generation Ethiopia offers intensive, employer-linked training programs in customer service, coding and other in-demand sectors — at no cost to participants.':
      (
        'ጄኔሬሽን ኢትዮጵያ በደንበኞች አገልግሎት፣ በኮዲንግ እና በሌሎች ተፈላጊ ዘርፎች ከአሰሪዎች ጋር የተገናኙ የተጠናከሩ የስልጠና ፕሮግራሞችን ያለምንም ክፍያ ይሰጣል።',
        'Jenereshiniin Itoophiyaa tajaajila maamilaa, koodiingii fi kutaalee barbaadaman biroo irratti leenjii kaffaltii malee kenna.',
      ),
  'Young women and men aged 18-35 who are unemployed or underemployed.': (
    'ዕድሜያቸው ከ18-35 የሆኑ ስራ አጥ ወይም በቂ ስራ የሌላቸው ወጣት ሴቶች እና ወንዶች።',
    'Dargaggoota dubartootaa fi dhiirota umrii 18-35 hojii hin qabne ykn gahaa hin qabne.',
  ),
  'Tony Elumelu Foundation Entrepreneurship Programme': (
    'የቶኒ ኤሉሜሉ ፋውንዴሽን የስራ ፈጠራ ፕሮግራም',
    'Sagantaa Hojii Uumuu Faawundeeshinii Toonii Elumeeluu',
  ),
  'Tony Elumelu Foundation': (
    'ቶኒ ኤሉሜሉ ፋውንዴሽን',
    'Faawundeeshinii Toonii Elumeeluu',
  ),
  'Apply by 31 Jan each year': (
    'በየዓመቱ እስከ ጥር 31 ያመልክቱ',
    'Waggaa waggaatti hanga Amajjii 31tti iyyadhaa',
  ),
  'TEEP provides \$5,000 seed capital, 12 weeks of business training and lifelong mentorship to African entrepreneurs.':
      (
        'TEEP ለአፍሪካ ስራ ፈጣሪዎች የ5,000 ዶላር መነሻ ካፒታል፣ የ12 ሳምንታት የንግድ ስልጠና እና የህይወት ዘመን አማካሪነት ይሰጣል።',
        'TEEP dureeyyii Afrikaatiif kaappitaala jalqabaa \$5,000, leenjii daldalaa torban 12 fi gorsa umurii guutuu kenna.',
      ),
  'African entrepreneurs with a business idea or early-stage business.': (
    'የንግድ ሃሳብ ወይም ጀማሪ ንግድ ያላቸው አፍሪካውያን ስራ ፈጣሪዎች።',
    'Dureeyyii Afrikaa yaada daldalaa ykn daldala sadarkaa jalqabaa qaban.',
  ),
  'Mastercard Foundation Scholars Program': (
    'የማስተርካርድ ፋውንዴሽን ምሁራን ፕሮግራም',
    'Sagantaa Barattoota Faawundeeshinii Maastarkaard',
  ),
  'Mastercard Foundation': (
    'ማስተርካርድ ፋውንዴሽን',
    'Faawundeeshinii Maastarkaard',
  ),
  'Africa · University placements': (
    'አፍሪካ · የዩኒቨርሲቲ ምደባዎች',
    'Afrikaa · Ramaddii Yuunivarsiitii',
  ),
  'Varies by partner university': (
    'እንደ አጋር ዩኒቨርሲቲው ይለያያል',
    'Akka yuunivarsiitii michuutti garaagarummaa qaba',
  ),
  'Full scholarships for academically talented but financially disadvantaged young Africans to study at leading universities.':
      (
        'በትምህርታቸው ጎበዝ ሆነው ነገር ግን የገንዘብ አቅም ለሌላቸው ወጣት አፍሪካውያን በታዋቂ ዩኒቨርሲቲዎች ለመማር ሙሉ ስኮላርሺፕ።',
        'Dargaggoota Afrikaa barnootaan cimaa ta\'anii garuu hanqina maallaqaa qabaniif isgoolarshippii guutuu.',
      ),
  'Academically strong students with demonstrated financial need.': (
    'በትምህርታቸው ጠንካራ ሆነው የገንዘብ ችግር ያለባቸው ተማሪዎች።',
    'Barattoota barnootaan jabaatanii fi gargaarsi maallaqaa kan isaan barbaachisu.',
  ),
  'She Leads Africa Accelerator': (
    'ሺ ሊድስ አፍሪካ አክስለሬተር',
    'Shii Liidsi Afrikaa Aksalareetarii',
  ),
  'She Leads Africa': ('ሺ ሊድስ አፍሪካ', 'Shii Liidsi Afrikaa'),
  'She Leads Africa connects ambitious African women entrepreneurs with world-class mentors, investors and a curated business accelerator curriculum.':
      (
        'ሺ ሊድስ አፍሪካ ከፍተኛ አላማ ያላቸውን አፍሪካውያን ሴት ስራ ፈጣሪዎችን ከዓለም አቀፍ ደረጃ አማካሪዎች፣ ባለሀብቶች እና የተመረጡ የቢዝነስ ማፋጠኛ ስልጠናዎች ጋር ያገናኛል።',
        'Shii Liidsi Afrikaa dubartoota dureeyyii gorsitoota addunyaa, abbootii qabeenyaa fi leenjii saffisiisaa daldalaa waliin wal qunnamsiisa.',
      ),
  'African women entrepreneurs with an existing business.': (
    'ነባር ንግድ ያላቸው አፍሪካውያን ሴት ስራ ፈጣሪዎች።',
    'Dubartoota dureeyyii Afrikaa daldala duraan qaban.',
  ),
  'UN Women – Opportunities for Women': (
    'የተመድ ሴቶች – ለሴቶች የተዘጋጁ እድሎች',
    'Dhaabbata Mootummoota Gamtoomanii Dubartootaa – Carraawwan',
  ),
  'UN Women': ('የተመድ ሴቶች (UN Women)', 'UN Women'),
  'Ethiopia & Global · Various': (
    'ኢትዮጵያ እና ዓለም አቀፍ · የተለያዩ',
    'Itoophiyaa fi Addunyaa · Adda addaa',
  ),
  'Rolling – see website': (
    'ቀጣይነት ያለው – ድህረ ገጹን ይመልከቱ',
    'Walitti fufaa – marsariitii ilaalaa',
  ),
  'UN Women regularly posts jobs, consultancies, fellowships and calls-for-proposals focusing on gender equality and women\'s empowerment across Ethiopia and beyond.':
      (
        'የተመድ ሴቶች በኢትዮጵያ እና በዓለም አቀፍ ደረጃ በጾታ እኩልነት እና የሴቶች አቅም ግንባታ ላይ ያተኮሩ ስራዎችን፣ የማማከር አገልግሎቶችን፣ ፌሎውሺፖችን እና የፕሮፖዛል ጥሪዎችን አዘውትሮ ያወጣል።',
        'UN Women yeroo hunda carraawwan hojii, gorsaa fi fedhii pirooppozaalaa mirga wal-qixxummaa dubartootaa irratti fuulleffatan baasa.',
      ),
  'Varies by position — check individual postings.': (
    'እንደየስራ መደቡ ይለያያል — እያንዳንዱን ማስታወቂያ ይመልከቱ።',
    'Akka gosa hojiitti garaagarummaa qaba — beeksisa tokkoon tokkoo ilaala.',
  ),
  'Amref Health Africa Training & Fellowships': (
    'የአምሬፍ ሔልዝ አፍሪካ ስልጠናዎች እና ፌሎውሺፖች',
    'Leenjiilee fi Feloowshippii Amref Health Africa',
  ),
  'Amref Health Africa': ('አምሬፍ ሔልዝ አፍሪካ', 'Amref Health Africa'),
  'Ethiopia · Addis Ababa / Remote': (
    'ኢትዮጵያ · አዲስ አበባ / ከርቀት',
    'Itoophiyaa · Finfinnee / Fagoodhaa',
  ),
  'Varies by program': (
    'እንደ ፕሮግራሙ ይለያያል',
    'Akka sagantaatti garaagarummaa qaba',
  ),
  'Amref offers health-focused training programs, fellowships and community health worker courses to build capacity for African women in healthcare.':
      (
        'አምሬፍ በጤናው ዘርፍ የአፍሪካውያን ሴቶችን አቅም ለመገንባት በጤና ላይ ያተኮሩ የስልጠና ፕሮግራሞችን፣ ፌሎውሺፖችን እና የማህበረሰብ ጤና አጠባበቅ ኮርሶችን ይሰጣል።',
        'Amref dandeettii dubartoota Afrikaa damee fayyaa keessatti guddisuuf leenjiilee fi koorsota adda addaa kenna.',
      ),
  'Health workers, students and community volunteers.': (
    'የጤና ባለሙያዎች፣ ተማሪዎች እና የማህበረሰብ በጎ ፈቃደኞች።',
    'Hojjattoota fayyaa, barattootaa fi tola ooltota hawaasaa.',
  ),
  'USAID Women in Science Fellowship': (
    'የዩኤስኤአይዲ የሴቶች በሳይንስ ፌሎውሺፕ',
    'Feloowshippii Dubartoota Saayinsii USAID',
  ),
  'USAID': ('ዩኤስኤአይዲ (USAID)', 'USAID'),
  'Check USAID website for open cycles': (
    'ክፍት ዙሮችን ለማየት የዩኤስኤአይዲ ድህረ ገጽን ይመልከቱ',
    'Marsariitii USAID ilaalaa',
  ),
  'USAID funds fellowships and internships that support women in science, technology, engineering and mathematics across developing countries.':
      (
        'ዩኤስኤአይዲ በማደግ ላይ ባሉ አገሮች ውስጥ በሳይንስ፣ ቴክኖሎጂ፣ ምህንድስና እና ሂሳብ (STEM) ዘርፎች ሴቶችን የሚደግፉ ፌሎውሺፖችን እና ልምምዶችን በገንዘብ ይደግፋል።',
        'USAID feloowshippii fi leenjii hojii dubartoota saayinsii, teeknooloojii, injinarringii fi herregaa keessatti hirmaatan deeggarsa maallaqaa kenna.',
      ),
  'Women pursuing STEM degrees or early-career professionals.': (
    'በSTEM የዲግሪ ትምህርት ላይ ያሉ ሴቶች ወይም ጀማሪ ባለሙያዎች።',
    'Dubartoota digrii STEM hordofaa jiran ykn ogeessota jalqabaa.',
  ),
  'Posted today': ('ዛሬ ተለጠፈ', 'Har\'a maxxanfame'),
  'Posted 1 day ago': ('ከ1 ቀን በፊት ተለጠፈ', 'Guyyaa 1 dura maxxanfame'),
};
