import 'package:flutter_test/flutter_test.dart';
import 'package:kaam_sathi/core/voice/intent_parser.dart';
import 'package:kaam_sathi/data/models.dart';

void main() {
  group('IntentParser', () {
    final cases = <String, VoiceIntent>{
      'Kaam batao': VoiceIntent.readJobs,
      'Meri kamai kitni hai?': VoiceIntent.readEarnings,
      'Aaj meri attendance lagi hai?': VoiceIntent.readAttendance,
      'Pehla kaam kholo': VoiceIntent.openJob,
      'Ye kaam karunga': VoiceIntent.acceptJob,
      'Ye kaam nahi karunga': VoiceIntent.rejectJob,
      'Main aaj bimaar hoon': VoiceIntent.reportAbsence,
      'Main kaam chhodna chahta hoon': VoiceIntent.leaveJob,
      'Ab main ye kaam nahi kar paunga': VoiceIntent.leaveJob,
      'Contractor ko phone karo': VoiceIntent.callContractor,
      'Kaam kahan hai?': VoiceIntent.readLocation,
      'Kitna paisa milega?': VoiceIntent.readWage,
      'Kal kaam hai?': VoiceIntent.readNextWork,
      'Mera profile dikhao': VoiceIntent.openProfile,
      'Mere profile mein kya hai?': VoiceIntent.readProfile,
      'Main kaam par pahunch gaya': VoiceIntent.markAttendance,
      'Madad chahiye': VoiceIntent.help,
      'Yahan kaam safe nahi hai': VoiceIntent.unsafeWork,
      'Main aaj kaam par nahi aa sakta': VoiceIntent.reportAbsence,
      'मैं आज बीमार हूं': VoiceIntent.reportAbsence,
      'काम बताओ': VoiceIntent.readJobs,
      'मेरी कमाई कितनी है': VoiceIntent.readEarnings,
      'मैं काम पर पहुँच गया': VoiceIntent.markAttendance,
    };
    cases.forEach((text, intent) {
      test(text, () => expect(IntentParser.parse(text).intent, intent));
    });

    test('absence reason + date', () {
      final p = IntentParser.parse('Mujhe chot lag gayi hai');
      expect(p.intent, VoiceIntent.reportAbsence);
      expect(p.reason, AbsenceReason.injury);
      expect(p.dayOffset, 0);
    });

    test('numbers', () {
      expect(IntentParser.parseWage('Mujhe 800 rupaye roz chahiye'), 800);
      expect(IntentParser.parseWage('आठ सौ रुपये'), 800);
      expect(IntentParser.parseYears('Mujhe raj mistri ka kaam 8 saal se aata hai'), 8);
      expect(IntentParser.parseYears('das saal'), 10);
    });

    test('skills in spoken order', () {
      expect(IntentParser.parseSkills('Main raj mistri aur helper ka kaam karta hoon'), ['MASON', 'HELPER']);
    });

    test('yes / no', () {
      expect(IntentParser.parseYesNo('haan'), true);
      expect(IntentParser.parseYesNo('हाँ सही है'), true);
      expect(IntentParser.parseYesNo('nahi'), false);
    });
  });
}
