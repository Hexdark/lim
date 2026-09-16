import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:we_two/models.dart';
import 'package:we_two/services/widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Android widget receives each mood and clears its label on logout',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const channel = MethodChannel('home_widget');
      final stored = <String, dynamic>{};
      var updates = 0;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'saveWidgetData') {
          final args = call.arguments as Map;
          stored[args['id'] as String] = args['data'];
        } else if (call.method == 'updateWidget') {
          updates++;
        }
        return true;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
        debugDefaultTargetPlatformOverride = null;
      });

      const faces = ['😭', '🥹', '😼', '🤓', '👹'];
      const labels = ['Smutas', 'Mil', 'Lim', 'Dobrze', 'Super'];
      for (var mood = 1; mood <= 5; mood++) {
        await WidgetService.update(
          CheckIn(
            id: 'test-$mood',
            coupleId: 'couple',
            authorId: 'author',
            mood: mood,
            phase: CyclePhase.unknown,
            note: '',
            createdAt: DateTime(2026, 9, 17),
          ),
        );
        expect(stored['mood'], '${faces[mood - 1]} $mood/5');
        expect(stored['mood_label'], labels[mood - 1]);
      }

      await WidgetService.update(null);
      expect(stored['mood'], '♡');
      expect(stored['mood_label'], '');
      expect(updates, 6);
    },
  );
}
