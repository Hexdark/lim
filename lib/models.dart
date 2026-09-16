import 'dart:typed_data';

enum CyclePhase {
  unknown('Nie wiem / nie podaję', 'Bez określonej fazy'),
  menstruation('Miesiączka', 'Miesiączka'),
  follicular('Faza folikularna', 'Faza folikularna'),
  ovulation('Owulacja', 'Owulacja'),
  luteal('Faza lutealna', 'Faza lutealna');

  const CyclePhase(this.label, this.shortLabel);
  final String label;
  final String shortLabel;
  static CyclePhase parse(String value) =>
      values.firstWhere((p) => p.name == value, orElse: () => unknown);
}

const moodLabels = [
  'Bardzo słabo',
  'Słabiej',
  'W porządku',
  'Dobrze',
  'Świetnie',
];
const moodFaces = ['😞', '🙁', '😐', '🙂', '🥰'];

class Membership {
  const Membership({
    required this.coupleId,
    required this.userId,
    required this.writer,
  });
  final String coupleId;
  final String userId;
  final bool writer;
}

class CheckIn {
  const CheckIn({
    required this.id,
    required this.coupleId,
    required this.authorId,
    required this.mood,
    required this.phase,
    required this.note,
    required this.createdAt,
    this.photoPath,
    this.demoPhoto,
  });
  final String id;
  final String coupleId;
  final String authorId;
  final int mood;
  final CyclePhase phase;
  final String note;
  final DateTime createdAt;
  final String? photoPath;
  final Uint8List? demoPhoto;
  bool get hasPhoto => photoPath != null || demoPhoto != null;

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
    id: json['id'] as String,
    coupleId: json['couple_id'] as String,
    authorId: json['author_id'] as String,
    mood: json['mood'] as int,
    phase: CyclePhase.parse(json['phase'] as String),
    note: json['note'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    photoPath: json['photo_path'] as String?,
  );
}

class CheckInDraft {
  CheckInDraft({
    required this.mood,
    required this.phase,
    required String note,
    this.photo,
  }) : note = note.trim() {
    if (mood < 1 || mood > 5) {
      throw const FormatException('Wybierz samopoczucie od 1 do 5.');
    }
    if (this.note.runes.length > 1500) {
      throw const FormatException('Notatka może mieć maksymalnie 1500 znaków.');
    }
    if (photo != null && photo!.length > 2 * 1024 * 1024) {
      throw const FormatException(
        'Zdjęcie po zmniejszeniu musi mieć mniej niż 2 MB.',
      );
    }
  }
  final int mood;
  final CyclePhase phase;
  final String note;
  final Uint8List? photo;
}
