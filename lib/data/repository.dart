import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';

abstract class CheckInRepository {
  Future<List<CheckIn>> load();
  Future<void> save(CheckInDraft draft);
  Future<void> delete(CheckIn entry);
  Future<Uint8List> photo(CheckIn entry);
  Stream<List<Map<String, dynamic>>>? get changes => null;
}

class SupabaseRepository extends CheckInRepository {
  SupabaseRepository(this.client, this.member);
  final SupabaseClient client;
  final Membership member;

  @override
  Future<List<CheckIn>> load() async {
    final rows = await client
        .from('check_ins')
        .select()
        .eq('couple_id', member.coupleId)
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(CheckIn.fromJson).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> get changes => client
      .from('check_ins')
      .stream(primaryKey: ['id'])
      .eq('couple_id', member.coupleId);

  @override
  Future<void> save(CheckInDraft draft) async {
    if (!member.writer) {
      throw StateError('To konto może tylko odczytywać wpisy.');
    }
    final id = const Uuid().v4();
    final path = draft.photo == null
        ? null
        : '${member.coupleId}/${member.userId}/$id.jpg';
    if (path != null) {
      await client.storage
          .from('photos')
          .uploadBinary(
            path,
            draft.photo!,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
    }
    try {
      await client.from('check_ins').insert({
        'id': id,
        'couple_id': member.coupleId,
        'author_id': member.userId,
        'mood': draft.mood,
        'phase': draft.phase.name,
        'note': draft.note,
        'photo_path': path,
      });
    } catch (_) {
      // Best-effort cleanup. Preserve the original database error.
      if (path != null) {
        try {
          await client.storage.from('photos').remove([path]);
        } catch (_) {}
      }
      rethrow;
    }
  }

  @override
  Future<void> delete(CheckIn entry) async {
    if (!member.writer || entry.authorId != member.userId) {
      throw StateError('Możesz usuwać tylko swoje wpisy.');
    }
    // Do not claim full deletion if the photo could not be removed.
    if (entry.photoPath != null) {
      await client.storage.from('photos').remove([entry.photoPath!]);
    }
    await client
        .from('check_ins')
        .delete()
        .eq('id', entry.id)
        .eq('author_id', member.userId);
  }

  @override
  Future<Uint8List> photo(CheckIn entry) =>
      client.storage.from('photos').download(entry.photoPath!);
}

class DemoRepository extends CheckInRepository {
  DemoRepository({bool seed = true}) {
    if (seed) {
      _entries.add(
        CheckIn(
          id: 'example',
          coupleId: 'demo',
          authorId: 'demo-writer',
          mood: 4,
          phase: CyclePhase.follicular,
          note: 'Dzisiaj mam więcej energii. Może mały spacer wieczorem? 🌿',
          createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
      );
    }
  }
  final List<CheckIn> _entries = [];
  @override
  Future<List<CheckIn>> load() async => List.unmodifiable(_entries);
  @override
  Future<void> save(CheckInDraft draft) async {
    _entries.insert(
      0,
      CheckIn(
        id: const Uuid().v4(),
        coupleId: 'demo',
        authorId: 'demo-writer',
        mood: draft.mood,
        phase: draft.phase,
        note: draft.note,
        createdAt: DateTime.now(),
        demoPhoto: draft.photo,
      ),
    );
  }

  @override
  Future<void> delete(CheckIn entry) async =>
      _entries.removeWhere((e) => e.id == entry.id);
  @override
  Future<Uint8List> photo(CheckIn entry) async => entry.demoPhoto!;
}
