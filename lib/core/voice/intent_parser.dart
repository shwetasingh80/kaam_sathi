import '../../data/models.dart';

/// Allowed intents. The AI/parser can only ever produce one of these — the
/// backend ([AppState]) decides what actually happens.
enum VoiceIntent {
  readJobs,
  openJob,
  acceptJob,
  rejectJob,
  readWage,
  readLocation,
  readEarnings,
  readAttendance,
  markAttendance,
  endDay,
  readNextWork,
  readSchedule,
  readBreak,
  reportAbsence,
  leaveJob,
  callContractor,
  openProfile,
  readProfile,
  help,
  unsafeWork,
  paymentIssue,
  yes,
  no,
  unknown;

  String get code => switch (this) {
        VoiceIntent.readJobs => 'READ_JOBS',
        VoiceIntent.openJob => 'OPEN_JOB',
        VoiceIntent.acceptJob => 'ACCEPT_JOB',
        VoiceIntent.rejectJob => 'REJECT_JOB',
        VoiceIntent.readWage => 'READ_WAGE',
        VoiceIntent.readLocation => 'READ_LOCATION',
        VoiceIntent.readEarnings => 'READ_EARNINGS',
        VoiceIntent.readAttendance => 'READ_ATTENDANCE',
        VoiceIntent.markAttendance => 'MARK_ATTENDANCE',
        VoiceIntent.endDay => 'END_DAY',
        VoiceIntent.readNextWork => 'READ_NEXT_WORK',
        VoiceIntent.readSchedule => 'READ_SCHEDULE',
        VoiceIntent.readBreak => 'READ_BREAK',
        VoiceIntent.reportAbsence => 'REPORT_ABSENCE',
        VoiceIntent.leaveJob => 'LEAVE_JOB',
        VoiceIntent.callContractor => 'CALL_CONTRACTOR',
        VoiceIntent.openProfile => 'OPEN_PROFILE',
        VoiceIntent.readProfile => 'READ_PROFILE',
        VoiceIntent.help => 'HELP',
        VoiceIntent.unsafeWork => 'REPORT_UNSAFE',
        VoiceIntent.paymentIssue => 'REPORT_PAYMENT',
        VoiceIntent.yes => 'CONFIRM_YES',
        VoiceIntent.no => 'CONFIRM_NO',
        VoiceIntent.unknown => 'UNKNOWN',
      };
}

class ParsedIntent {
  const ParsedIntent(this.intent, {this.reason, this.dayOffset = 0, this.index, this.number, required this.text});

  final VoiceIntent intent;
  final AbsenceReason? reason;

  /// 0 = today, 1 = tomorrow.
  final int dayOffset;

  /// For OPEN_JOB: 0-based job position ("pehla kaam").
  final int? index;
  final int? number;
  final String text;

  Map<String, String> get slots => {
        if (reason != null) 'reason': reason!.name.toUpperCase(),
        if (intent == VoiceIntent.reportAbsence) 'date': dayOffset == 0 ? 'today' : 'tomorrow',
        if (index != null) 'index': '${index! + 1}',
        if (number != null) 'number': '$number',
      };
}

/// Rule-based Hindi / Hinglish intent detection.
///
/// Android's hi-IN recogniser usually returns Devanagari, while Hinglish
/// speakers may get Roman script — so every keyword list carries both.
class IntentParser {
  IntentParser._();

  static String normalize(String input) {
    var s = input.toLowerCase().trim();
    const dev = '०१२३४५६७८९';
    for (var i = 0; i < dev.length; i++) {
      s = s.replaceAll(dev[i], '$i');
    }
    s = s.replaceAll(RegExp(r'[।?!.,"“”]'), ' ');
    // Common nukta / chandrabindu variants → base form
    s = s
        .replaceAll('ँ', 'ं')
        .replaceAll('ड़', 'ड')
        .replaceAll('ढ़', 'ढ')
        .replaceAll('ज़', 'ज')
        .replaceAll('ख़', 'ख')
        .replaceAll('फ़', 'फ');
    return s.replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool _any(String s, List<String> words) => words.any(s.contains);

  // Keyword groups (normalized forms)
  static const _negative = ['nahi', 'nahin', 'nai ', 'नहीं', 'नही', 'mat ', 'मत'];
  static const _today = ['aaj', 'आज', 'abhi', 'अभी'];
  static const _tomorrow = ['kal ', 'kal', 'कल'];
  static const _work = ['kaam', 'kam ', 'काम', 'job', 'naukri', 'नौकरी'];

  static ParsedIntent parse(String raw) {
    final s = ' ${normalize(raw)} ';
    final neg = _any(s, _negative);

    ParsedIntent r(VoiceIntent i, {AbsenceReason? reason, int dayOffset = 0, int? index}) =>
        ParsedIntent(i, reason: reason, dayOffset: dayOffset, index: index, number: parseNumber(raw), text: raw);

    // 1. Safety first
    if (_any(s, ['safe nahi', 'safe nahin', 'surakshit nahi', 'khatra', 'khatarnak', 'सेफ नहीं', 'सुरक्षित नहीं', 'खतरा', 'खतरनाक', 'unsafe'])) {
      return r(VoiceIntent.unsafeWork);
    }
    if (_any(s, ['madad', 'मदद', 'help', 'sahayata', 'सहायता', 'bachao', 'बचाओ'])) {
      return r(VoiceIntent.help);
    }
    if (_any(s, ['paisa nahi mila', 'paise nahi mile', 'payment nahi', 'पैसा नहीं मिला', 'पैसे नहीं मिले', 'पेमेंट नहीं', 'mazdoori nahi mili', 'मजदूरी नहीं मिली'])) {
      return r(VoiceIntent.paymentIssue);
    }

    // 2. Leaving / absence (most sensitive)
    final leaveWords = ['chhod', 'chod', 'छोड', 'quit', 'aage nahi', 'आगे नहीं', 'ab nahi kar', 'अब नहीं कर'];
    if (_any(s, leaveWords) || (_any(s, ['nahi kar paunga', 'nahi kar paaunga', 'नहीं कर पाऊंगा', 'नहीं कर पाउंगा']) && !_any(s, _today) && !_any(s, _tomorrow))) {
      if (!_any(s, ['bimaar', 'बीमार', 'tabiyat', 'तबीयत'])) return r(VoiceIntent.leaveJob);
    }
    final reason = _absenceReason(s);
    final absenceWords = [
      'nahi aa', 'nahi aaunga', 'nahi aaoonga', 'nahi ja', 'नहीं आ', 'नहीं जा',
      'chhutti', 'छुट्टी', 'nahi kar paunga', 'नहीं कर पाऊंगा', 'नहीं कर पाउंगा',
    ];
    if (reason != null || _any(s, absenceWords)) {
      final offset = _any(s, _tomorrow) && !_any(s, _today) ? 1 : 0;
      return r(VoiceIntent.reportAbsence, reason: reason ?? AbsenceReason.other, dayOffset: offset);
    }

    // 3. Attendance / day
    if (_any(s, ['khatam', 'खत्म', 'ख़त्म', 'poora ho gaya', 'pura ho gaya', 'पूरा हो गया', 'chhutti ho gayi', 'ghar ja raha'])) {
      return r(VoiceIntent.endDay);
    }
    if (_any(s, ['pahunch', 'पहुंच', 'पहुच', 'aa gaya', 'आ गया', 'reach'])) {
      return r(VoiceIntent.markAttendance);
    }
    final attWords = ['attendance', 'haazri', 'hazri', 'hajri', 'हाजिरी', 'हाज़िरी', 'अटेंडेंस', 'हाजरी'];
    if (_any(s, attWords)) {
      if (_any(s, ['laga do', 'lagao', 'laga de', 'lagaiye', 'लगा दो', 'लगाओ', 'लगा दे', 'लगाइए', 'mark'])) {
        return r(VoiceIntent.markAttendance);
      }
      return r(VoiceIntent.readAttendance);
    }

    // 4. Contractor call
    if (_any(s, ['phone', 'call', 'फोन', 'फ़ोन', 'कॉल', 'baat karao', 'बात कराओ', 'baat karni'])) {
      return r(VoiceIntent.callContractor);
    }

    // 5. Money
    if (_any(s, ['milega', 'मिलेगा', 'milenge', 'मिलेंगे', 'mazdoori', 'मजदूरी', 'rate kya', 'roz ka'])) {
      return r(VoiceIntent.readWage);
    }
    if (_any(s, ['kamai', 'कमाई', 'kamaya', 'कमाया', 'kamaye', 'कमाए', 'earning', 'kitna paisa', 'कितना पैसा', 'kitne paise', 'कितने पैसे', 'hisab', 'हिसाब'])) {
      return r(VoiceIntent.readEarnings);
    }

    // 6. Info about job
    if (_any(s, ['kahan', 'kaha ', 'कहां', 'कहाँ', 'location', 'jagah', 'जगह', 'pata ', 'पता', 'rasta', 'रास्ता'])) {
      return r(VoiceIntent.readLocation);
    }
    if (_any(s, ['break', 'ब्रेक', 'lunch', 'लंच', 'khana', 'खाना', 'aaram', 'आराम', 'chai', 'चाय'])) {
      return r(VoiceIntent.readBreak);
    }
    if (_any(s, ['kitne baje', 'कितने बजे', 'samay', 'समय', 'time', 'timing', 'टाइम'])) {
      return r(VoiceIntent.readSchedule);
    }
    if ((_any(s, _tomorrow) && _any(s, _work)) || _any(s, ['agla kaam', 'अगला काम', 'next'])) {
      return r(VoiceIntent.readNextWork);
    }

    // 7. Jobs
    final idx = _ordinal(s);
    if (_any(s, ['kholo', 'खोलो', 'open', 'dikhao', 'दिखाओ', 'batao', 'बताओ', 'suna']) && idx != null) {
      return r(VoiceIntent.openJob, index: idx);
    }
    if (_any(s, ['reject', 'mana', 'मना', 'nahi chahiye', 'नहीं चाहिए', 'nahi karunga', 'नहीं करूंगा', 'नहीं करुंगा', 'nahi lena', 'नहीं लेना'])) {
      return r(VoiceIntent.rejectJob);
    }
    if (!neg && _any(s, ['karunga', 'करूंगा', 'करुंगा', 'accept', 'pakka', 'पक्का', 'le lo', 'ले लो', 'manzoor', 'मंजूर', 'chahiye ye', 'ye kaam chahiye'])) {
      return r(VoiceIntent.acceptJob);
    }
    if (_any(s, ['profile', 'प्रोफाइल', 'प्रोफ़ाइल', 'mere bare', 'मेरे बारे'])) {
      if (_any(s, ['kya hai', 'क्या है', 'kya likha', 'suna', 'सुना', 'batao', 'बताओ', 'padh', 'पढ'])) {
        return r(VoiceIntent.readProfile);
      }
      return r(VoiceIntent.openProfile);
    }
    if (_any(s, _work) && _any(s, ['batao', 'बताओ', 'dikhao', 'दिखाओ', 'naya', 'नया', 'naye', 'नए', 'hai kya', 'है क्या', 'chahiye', 'चाहिए', 'milega', 'koi'])) {
      return r(VoiceIntent.readJobs);
    }

    // 8. Bare confirmations
    final yn = parseYesNo(raw);
    if (yn == true) return r(VoiceIntent.yes);
    if (yn == false) return r(VoiceIntent.no);

    if (_any(s, _work)) return r(VoiceIntent.readJobs);
    return r(VoiceIntent.unknown);
  }

  static AbsenceReason? _absenceReason(String s) {
    if (_any(s, ['chot', 'चोट', 'injury', 'zakhm', 'जख्म', 'gir gaya', 'गिर गया'])) return AbsenceReason.injury;
    if (_any(s, ['bimaar', 'bimar', 'बीमार', 'tabiyat', 'tabiyat', 'तबीयत', 'तबियत', 'bukhar', 'बुखार', 'sick', 'dard', 'दर्द'])) {
      return AbsenceReason.sick;
    }
    if (_any(s, ['emergency', 'इमरजेंसी', 'एमरजेंसी', 'hospital', 'अस्पताल'])) return AbsenceReason.emergency;
    if (_any(s, ['saadhan', 'sadhan', 'साधन', 'gaadi', 'गाड़ी', 'गाडी', 'bus ', 'बस नहीं', 'transport'])) return AbsenceReason.transport;
    if (_any(s, ['ghar mein', 'ghar me', 'घर में', 'parivar', 'परिवार', 'shaadi', 'शादी', 'zaroori kaam', 'जरूरी काम'])) {
      return AbsenceReason.family;
    }
    return null;
  }

  static int? _ordinal(String s) {
    if (_any(s, ['pehla', 'pehle', 'pahla', 'पहला', 'पहले', 'first', ' 1 ', 'ek '])) return 0;
    if (_any(s, ['doosra', 'dusra', 'दूसरा', 'second', ' 2 '])) return 1;
    if (_any(s, ['teesra', 'tisra', 'तीसरा', 'third', ' 3 '])) return 2;
    if (_any(s, ['chautha', 'चौथा', ' 4 '])) return 3;
    return null;
  }

  /// true = haan, false = nahi, null = unclear.
  static bool? parseYesNo(String raw) {
    final s = ' ${normalize(raw)} ';
    if (_any(s, [' nahi ', ' nahin ', ' नहीं ', ' नही ', ' na ', ' ना ', ' mat ', ' galat ', ' गलत ', ' dobara ', ' दोबारा ', ' cancel ', ' ruko ', ' रुको '])) {
      return false;
    }
    if (_any(s, [
      ' haan ', ' han ', ' ha ', ' haa ', ' हां ', ' हाँ ', ' हा ', ' ji ', ' जी ', ' sahi ', ' सही ', ' theek ', ' ठीक ',
      ' ok ', ' okay ', ' ओके ', ' bilkul ', ' बिल्कुल ', ' pakka ', ' पक्का ', ' yes ', ' kar do ', ' कर दो ', ' bata do ', ' बता दो ',
    ])) {
      return true;
    }
    return null;
  }

  // ─────────────────────────────────────────────── numbers

  static const _numberWords = <String, int>{
    'ek': 1, 'एक': 1, 'do': 2, 'दो': 2, 'teen': 3, 'तीन': 3, 'char': 4, 'chaar': 4, 'चार': 4,
    'paanch': 5, 'panch': 5, 'पांच': 5, 'पाँच': 5, 'chhe': 6, 'chah': 6, 'छह': 6, 'छः': 6, 'छे': 6,
    'saat': 7, 'सात': 7, 'aath': 8, 'आठ': 8, 'nau': 9, 'नौ': 9, 'das': 10, 'दस': 10,
    'gyarah': 11, 'ग्यारह': 11, 'barah': 12, 'baarah': 12, 'बारह': 12, 'terah': 13, 'तेरह': 13,
    'chaudah': 14, 'चौदह': 14, 'pandrah': 15, 'पंद्रह': 15, 'solah': 16, 'सोलह': 16,
    'satrah': 17, 'सत्रह': 17, 'atharah': 18, 'अठारह': 18, 'unnis': 19, 'उन्नीस': 19,
    'bees': 20, 'बीस': 20, 'pachchees': 25, 'pachees': 25, 'पच्चीस': 25, 'tees': 30, 'तीस': 30,
    'chalis': 40, 'chaalis': 40, 'चालीस': 40, 'pachas': 50, 'pachaas': 50, 'पचास': 50,
    'saath': 60, 'साठ': 60, 'sattar': 70, 'सत्तर': 70, 'assi': 80, 'अस्सी': 80, 'nabbe': 90, 'नब्बे': 90,
    'dedh': 1, 'डेढ़': 1, 'dhai': 2, 'ढाई': 2,
  };

  /// Extracts the first number from speech: "800", "आठ सौ", "aath sau rupaye",
  /// "1 hazaar", "8 saal". Returns null if none.
  static int? parseNumber(String raw) {
    final s = normalize(raw);
    final digit = RegExp(r'(\d[\d,]*)').firstMatch(s);
    final tokens = s.split(' ');
    int? fromDigits;
    if (digit != null) {
      fromDigits = int.tryParse(digit.group(1)!.replaceAll(',', ''));
      // "1 hazaar", "8 sau"
      final after = s.substring(digit.end).trim();
      if (fromDigits != null) {
        if (after.startsWith('hazar') || after.startsWith('hazaar') || after.startsWith('हजार') || after.startsWith('thousand')) {
          return fromDigits * 1000;
        }
        if (after.startsWith('sau') || after.startsWith('सौ') || after.startsWith('hundred')) return fromDigits * 100;
        return fromDigits;
      }
    }
    var total = 0;
    var current = 0;
    var found = false;
    for (final t in tokens) {
      final w = _numberWords[t];
      if (w != null) {
        current += w;
        found = true;
      } else if (t == 'sau' || t == 'सौ' || t == 'so') {
        current = (current == 0 ? 1 : current) * 100;
        found = true;
      } else if (t == 'hazar' || t == 'hazaar' || t == 'हजार' || t == 'हज़ार') {
        total += (current == 0 ? 1 : current) * 1000;
        current = 0;
        found = true;
      } else if (found && current + total > 0 && !['rupaye', 'rupees', 'रुपये', 'रुपए', 'saal', 'साल', 'baras', 'बरस'].contains(t)) {
        // stop at first non-number word after a number
        if (!['aur', 'और', 'and'].contains(t)) break;
      }
    }
    return found ? total + current : null;
  }

  /// Skills mentioned in speech, in spoken order (first = primary).
  static List<String> parseSkills(String raw) {
    final s = ' ${normalize(raw)} ';
    final hits = <({String id, int pos})>[];
    for (final skill in SkillCatalog.all) {
      var best = -1;
      for (final k in skill.keywords) {
        final i = s.indexOf(normalize(k));
        if (i >= 0 && (best < 0 || i < best)) best = i;
      }
      if (best >= 0) hits.add((id: skill.id, pos: best));
    }
    // "raj mistri" also contains "mistri" — dedupe handled by id; sort by position.
    hits.sort((a, b) => a.pos.compareTo(b.pos));
    return hits.map((h) => h.id).toSet().toList();
  }

  /// "8 saal se" → 8. Also handles "das saal".
  static int? parseYears(String raw) {
    final n = parseNumber(raw);
    if (n == null) return null;
    if (n > 60) return null;
    return n;
  }

  /// "800 rupaye roz" → 800. Rejects implausible values.
  static int? parseWage(String raw) {
    final n = parseNumber(raw);
    if (n == null || n < 100 || n > 5000) return null;
    return n;
  }
}
