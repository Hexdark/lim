import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models.dart';

class WidgetService {
  static Future<void> _queue = Future<void>.value();

  static Future<void> update(CheckIn? entry, {bool demo = false}) {
    // Preserve ordering so sign-out always clears even an in-flight update.
    _queue = _queue
        .catchError((Object _) {})
        .then((_) => _write(entry, demo: demo));
    return _queue;
  }

  static Future<void> _write(CheckIn? entry, {bool demo = false}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await HomeWidget.saveWidgetData<String>(
      'mood',
      entry == null ? '♡' : '${entry.mood}/5',
    );
    await HomeWidget.saveWidgetData<String>(
      'phase',
      entry?.phase.shortLabel ?? 'Jeszcze bez wpisu',
    );
    await HomeWidget.saveWidgetData<String>(
      'note',
      entry?.note ?? 'Otwórz Blisko, aby się połączyć.',
    );
    final date = entry?.createdAt;
    final stamp = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    await HomeWidget.saveWidgetData<String>(
      'updated',
      demo ? 'DEMO • $stamp' : 'Wpis: $stamp • dotknij, by odświeżyć',
    );
    await HomeWidget.updateWidget(androidName: 'BliskoWidgetProvider');
  }
}
