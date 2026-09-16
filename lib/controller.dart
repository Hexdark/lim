import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/repository.dart';
import 'models.dart';
import 'services/widget_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    this.client,
    this.bootError,
    this.widgetUpdater = WidgetService.update,
  });
  final Future<void> Function(CheckIn?, {bool demo}) widgetUpdater;
  final SupabaseClient? client;
  final String? bootError;
  Membership? member;
  CheckInRepository? repository;
  List<CheckIn> entries = [];
  bool demo = false;
  bool busy = false;
  String? error;
  DateTime? lastSync;
  StreamSubscription<AuthState>? _auth;
  StreamSubscription<List<Map<String, dynamic>>>? _changes;
  int _generation = 0;
  int _refreshVersion = 0;
  bool _disposed = false;
  bool get configured => client != null;
  bool get signedIn => demo || client?.auth.currentSession != null;
  bool get writer => member?.writer ?? false;

  Future<void> start() async {
    _auth = client?.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedOut) {
        unawaited(_clear());
      } else if (state.event == AuthChangeEvent.signedIn &&
          member == null &&
          !busy) {
        unawaited(connect());
      }
    });
    if (signedIn) await connect();
  }

  Future<void> connect() async {
    if (demo) return;
    final user = client?.auth.currentUser;
    if (user == null) return;
    final generation = ++_generation;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final row = await client!
          .from('couple_members')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (generation != _generation) return;
      if (row == null) {
        throw StateError(
          'Konto nie jest jeszcze przypisane do Waszej pary. Dokończ konfigurację opisaną w README projektu.',
        );
      }
      member = Membership(
        coupleId: row['couple_id'] as String,
        userId: user.id,
        writer: row['role'] == 'writer',
      );
      repository = SupabaseRepository(client!, member!);
      await _changes?.cancel();
      _changes = repository!.changes?.listen(
        (_) {
          unawaited(refresh());
        },
        onError: (Object _) {
          error =
              'Połączenie na żywo zostało przerwane. Odśwież, aby sprawdzić nowe wpisy.';
          notifyListeners();
        },
      );
      await refresh();
    } catch (e) {
      if (generation == _generation) error = messageFor(e);
    } finally {
      if (generation == _generation) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> login(String email, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await client!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      await connect();
    } catch (e) {
      error = messageFor(e);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> enterDemo() async {
    await _changes?.cancel();
    _generation++;
    demo = true;
    error = null;
    member = const Membership(
      coupleId: 'demo',
      userId: 'demo-writer',
      writer: true,
    );
    repository = DemoRepository();
    await refresh();
  }

  void switchDemoRole() {
    if (!demo) return;
    member = Membership(
      coupleId: 'demo',
      userId: writer ? 'demo-reader' : 'demo-writer',
      writer: !writer,
    );
    notifyListeners();
  }

  Future<void> refresh() async {
    final active = repository;
    if (active == null) return;
    final generation = _generation;
    final version = ++_refreshVersion;
    try {
      final loaded = await active.load();
      if (generation != _generation || version != _refreshVersion) return;
      entries = loaded;
      lastSync = DateTime.now();
      error = null;
      await _updateWidget();
    } catch (e) {
      if (generation == _generation && version == _refreshVersion) {
        error = messageFor(e);
      }
    }
    if (generation == _generation) notifyListeners();
  }

  Future<bool> save(CheckInDraft draft) async {
    if (!writer || repository == null || busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await repository!.save(draft);
      await refresh();
      return true;
    } catch (e) {
      error = messageFor(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> delete(CheckIn entry) async {
    if (!writer || repository == null || busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await repository!.delete(entry);
      await refresh();
    } catch (e) {
      error = messageFor(e);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      if (!demo) await client?.auth.signOut(scope: SignOutScope.local);
      await _clear();
    } catch (e) {
      error = messageFor(e);
      notifyListeners();
    }
  }

  Future<void> _clear() async {
    _generation++;
    await _changes?.cancel();
    _changes = null;
    member = null;
    repository = null;
    entries = [];
    demo = false;
    busy = false;
    error = null;
    lastSync = null;
    try {
      await widgetUpdater(null);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _updateWidget() async {
    try {
      await widgetUpdater(entries.firstOrNull, demo: demo);
    } catch (_) {
      // A launcher/plugin failure must never turn a successful save into a retry.
    }
  }

  static String messageFor(Object e) {
    if (e is AuthException) {
      return 'Nie udało się zalogować. Sprawdź e-mail i hasło oraz połączenie z internetem.';
    }
    if (e is FormatException) return e.message;
    if (e is StateError) return e.message;
    return 'Nie udało się połączyć. Sprawdź internet i spróbuj ponownie. Twój formularz pozostaje na ekranie.';
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _auth?.cancel();
    _changes?.cancel();
    super.dispose();
  }
}
