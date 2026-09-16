import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:we_two/controller.dart';
import 'package:we_two/data/repository.dart';
import 'package:we_two/models.dart';
import 'package:we_two/services/photo_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Mood scores map to the requested names and emoji in order', () {
    expect(moodLabels, ['Smutas', 'Mil', 'Lim', 'Dobrze', 'Super']);
    expect(moodFaces, ['😭', '🥹', '😼', '🤓', '👹']);
  });
  test('Draft rejects invalid mood, overlong note and oversized photo', () {
    for (final mood in [0, 6]) {
      expect(
        () => CheckInDraft(mood: mood, phase: CyclePhase.unknown, note: ''),
        throwsFormatException,
      );
    }
    expect(
      () => CheckInDraft(mood: 3, phase: CyclePhase.unknown, note: 'x' * 1501),
      throwsFormatException,
    );
    expect(
      () => CheckInDraft(
        mood: 3,
        phase: CyclePhase.unknown,
        note: '',
        photo: Uint8List(2097153),
      ),
      throwsFormatException,
    );
  });
  test('Photo becomes a bounded JPEG without metadata', () {
    final input = img.Image(width: 1800, height: 900);
    input.exif.imageIfd.imageDescription = 'private metadata';
    final result = compressPhoto(Uint8List.fromList(img.encodeJpg(input)));
    final decoded = img.decodeJpg(result)!;
    expect(decoded.width, 1280);
    expect(decoded.height, 640);
    expect(decoded.exif.imageIfd.imageDescription, isNull);
    expect(result.length, lessThan(2097152));
  });
  test(
    'Reader cannot save, writer can save and delete, logout clears state',
    () async {
      final c = AppController();
      await c.enterDemo();
      final draft = CheckInDraft(
        mood: 1,
        phase: CyclePhase.unknown,
        note: '  odpoczywam  ',
      );
      c.switchDemoRole();
      expect(await c.save(draft), isFalse);
      c.switchDemoRole();
      expect(await c.save(draft), isTrue);
      expect(c.entries.first.note, 'odpoczywam');
      final id = c.entries.first.id;
      await c.delete(c.entries.first);
      expect(c.entries.any((e) => e.id == id), isFalse);
      await c.logout();
      expect(c.entries, isEmpty);
      expect(c.repository, isNull);
      c.dispose();
    },
  );
  test('Late request cannot put private data back after logout', () async {
    final c = AppController();
    await c.enterDemo();
    final previous = c.entries;
    final delayed = _DelayedRepository();
    c.repository = delayed;
    final refresh = c.refresh();
    await c.logout();
    delayed.result.complete(previous);
    await refresh;
    expect(c.entries, isEmpty);
    c.dispose();
  });
  test('Older refresh cannot overwrite a newer result', () async {
    final c = AppController();
    await c.enterDemo();
    final previous = c.entries;
    final old = _DelayedRepository();
    c.repository = old;
    final first = c.refresh();
    c.repository = DemoRepository(seed: false);
    await c.refresh();
    old.result.complete(previous);
    await first;
    expect(c.entries, isEmpty);
    c.dispose();
  });
}

class _DelayedRepository extends DemoRepository {
  final result = Completer<List<CheckIn>>();
  @override
  Future<List<CheckIn>> load() => result.future;
}
