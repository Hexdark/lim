import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'controller.dart';
import 'models.dart';
import 'services/photo_service.dart';

const ink = Color(0xFF353C34);
const sage = Color(0xFF52684D);
const paper = Color(0xFFFAF8F2);
const rose = Color(0xFFEDD6CC);

class BliskoApp extends StatefulWidget {
  const BliskoApp({super.key, required this.controller});
  final AppController controller;
  @override
  State<BliskoApp> createState() => _BliskoAppState();
}

class _BliskoAppState extends State<BliskoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.controller.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Blisko',
    debugShowCheckedModeBanner: false,
    locale: const Locale('pl'),
    supportedLocales: const [Locale('pl')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(seedColor: sage, surface: paper),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE3E6DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE3E6DD)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    ),
    home: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        if (!c.signedIn) return Welcome(controller: c);
        if (c.member == null) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Brand(),
                        const SizedBox(height: 32),
                        if (c.busy)
                          const CircularProgressIndicator()
                        else ...[
                          Text(
                            c.error ?? 'Łączę Waszą przestrzeń…',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: c.connect,
                            child: const Text('Spróbuj ponownie'),
                          ),
                          TextButton(
                            onPressed: c.logout,
                            child: const Text('Wyloguj'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return Home(controller: c);
      },
    ),
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.favorite_rounded, color: sage, size: 24),
      SizedBox(width: 10),
      Text(
        'blisko',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 30,
          fontWeight: FontWeight.w600,
          letterSpacing: -1,
        ),
      ),
    ],
  );
}

class Welcome extends StatefulWidget {
  const Welcome({super.key, required this.controller});
  final AppController controller;
  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  final email = TextEditingController();
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool hidden = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Brand(),
                    ),
                    const SizedBox(height: 48),
                    const Text(
                      'Mały gest.\nWięcej bliskości.',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 42,
                        height: 1.12,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Jedno miejsce na to, jak się czujesz.\nTylko dla Was dwojga.',
                      style: TextStyle(fontSize: 17, height: 1.6, color: sage),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: rose.withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Row(
                        children: [
                          Text('🙂', style: TextStyle(fontSize: 38)),
                          SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              '„Dobrze wiedzieć,\nco u Ciebie.”',
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 22,
                                height: 1.4,
                              ),
                            ),
                          ),
                          Icon(Icons.favorite_border, color: sage),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (c.configured) ...[
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        validator: (value) =>
                            value != null && value.contains('@')
                            ? null
                            : 'Wpisz swój e-mail.',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: password,
                        obscureText: hidden,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Hasło',
                          suffixIcon: IconButton(
                            tooltip: hidden ? 'Pokaż hasło' : 'Ukryj hasło',
                            onPressed: () => setState(() => hidden = !hidden),
                            icon: Icon(
                              hidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wpisz hasło.' : null,
                        onFieldSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 16),
                      if (c.error != null) ErrorBox(c.error!),
                      FilledButton(
                        onPressed: c.busy ? null : _login,
                        child: Text(
                          c.busy ? 'Łączenie…' : 'Wejdź do naszej przestrzeni',
                        ),
                      ),
                    ] else ...[
                      Text(
                        c.bootError ??
                            'Projekt jest gotowy do podłączenia. Na razie możesz obejrzeć przykładową przestrzeń.',
                        style: const TextStyle(height: 1.6),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: c.busy ? null : c.enterDemo,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 52),
                      ),
                      child: const Text('Zobacz demo'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Demo używa przykładowych danych. Wpisy znikają po jego zamknięciu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, height: 1.5, color: sage),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _login() {
    if (form.currentState!.validate() && !widget.controller.busy) {
      widget.controller.login(email.text, password.text);
    }
  }
}

class Home extends StatefulWidget {
  const Home({super.key, required this.controller});
  final AppController controller;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int page = 0;
  int dashboardVersion = 0;
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        title: const Brand(),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Odśwież wpisy',
            onPressed: c.busy ? null : c.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                if (c.demo)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E7D7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'DEMO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.writer
                                ? 'Widok osoby wysyłającej'
                                : 'Widok osoby odbierającej',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => page = 0);
                            c.switchDemoRole();
                          },
                          child: const Text('Zmień'),
                        ),
                      ],
                    ),
                  ),
                if (c.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: ErrorBox(c.error!),
                  ),
                if (c.busy) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: switch (page) {
                    0 => Dashboard(
                      key: ValueKey('${c.writer}:$dashboardVersion'),
                      controller: c,
                      onCompose: _compose,
                    ),
                    1 => History(controller: c),
                    _ => Settings(controller: c),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (v) => setState(() => page = v),
        backgroundColor: paper,
        indicatorColor: const Color(0xFFE3E8D9),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Dzisiaj',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: 'Historia',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            label: 'Nasza przestrzeń',
          ),
        ],
      ),
    );
  }

  Future<void> _compose() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => Compose(controller: widget.controller)),
    );
    if (mounted) setState(() => dashboardVersion++);
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.controller,
    required this.onCompose,
  });
  final AppController controller;
  final VoidCallback onCompose;
  @override
  Widget build(BuildContext context) {
    final entry = controller.entries.firstOrNull;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        children: [
          Text(
            controller.writer
                ? 'Jak się dzisiaj czujesz?'
                : 'Małe wieści od niej.',
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 33,
              letterSpacing: -.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            controller.writer
                ? 'Nie musisz szukać idealnych słów.'
                : 'Czasem wystarczy wiedzieć, jak być obok.',
            style: const TextStyle(color: sage, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          if (entry == null)
            const EmptyCard()
          else
            EntryCard(entry: entry, controller: controller, prominent: true),
          const SizedBox(height: 22),
          if (controller.writer)
            FilledButton.icon(
              onPressed: controller.busy ? null : onCompose,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Daj znać, co u Ciebie'),
            ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEAEEDF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.spa_outlined, color: sage),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Każdy dzień może być inny.\nTu jest miejsce na wszystkie.',
                    style: TextStyle(height: 1.6, color: sage),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              controller.lastSync == null
                  ? ''
                  : 'Ostatnie pobranie: ${stamp(controller.lastSync!)}',
              style: const TextStyle(fontSize: 11, color: sage),
            ),
          ),
        ],
      ),
    );
  }
}

class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.entry,
    required this.controller,
    this.prominent = false,
  });
  final CheckIn entry;
  final AppController controller;
  final bool prominent;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(prominent ? 24 : 20),
      decoration: BoxDecoration(
        color: prominent ? const Color(0xFFF0DFD6) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: prominent ? const Color(0xFFE8D5C9) : const Color(0xFFE9E8DF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  prominent ? 'OSTATNI SYGNAŁ' : stamp(entry.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: sage,
                  ),
                ),
              ),
              const Icon(Icons.favorite_rounded, size: 16, color: sage),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                moodFaces[entry.mood - 1],
                style: TextStyle(fontSize: prominent ? 58 : 38),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moodLabels[entry.mood - 1],
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: prominent ? 30 : 24,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Samopoczucie ${entry.mood} / 5',
                      style: const TextStyle(color: sage),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '◌  ${entry.phase.shortLabel}',
                  style: const TextStyle(fontSize: 12, color: sage),
                ),
              ),
            ],
          ),
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              entry.note,
              style: const TextStyle(fontSize: 16, height: 1.65),
            ),
          ],
          if (entry.hasPhoto) ...[
            const SizedBox(height: 18),
            PrivatePhoto(
              key: ValueKey(entry.id),
              entry: entry,
              controller: controller,
            ),
          ],
          if (prominent) ...[
            const SizedBox(height: 20),
            Text(
              'Wysłano ${stamp(entry.createdAt)}',
              style: const TextStyle(fontSize: 11, color: sage),
            ),
          ],
          if (!prominent &&
              controller.writer &&
              entry.authorId == controller.member?.userId)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: controller.busy
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Usunąć ten wpis?'),
                            content: const Text(
                              'Wpis i dołączone zdjęcie znikną z Waszej przestrzeni.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Zostaw'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Usuń'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) await controller.delete(entry);
                      },
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Usuń wpis'),
              ),
            ),
        ],
      ),
    );
  }
}

class PrivatePhoto extends StatefulWidget {
  const PrivatePhoto({
    super.key,
    required this.entry,
    required this.controller,
  });
  final CheckIn entry;
  final AppController controller;
  @override
  State<PrivatePhoto> createState() => _PrivatePhotoState();
}

class _PrivatePhotoState extends State<PrivatePhoto> {
  late Future<Uint8List> data;
  @override
  void initState() {
    super.initState();
    data = widget.controller.repository!.photo(widget.entry);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: data,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton.icon(
          onPressed: () => setState(
            () => data = widget.controller.repository!.photo(widget.entry),
          ),
          icon: const Icon(Icons.refresh),
          label: const Text('Spróbuj wczytać zdjęcie ponownie'),
        );
      }
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.memory(
          snapshot.data!,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              const Text('Nie można wyświetlić tego zdjęcia.'),
        ),
      );
    },
  );
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 24),
    decoration: BoxDecoration(
      color: rose.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(28),
    ),
    child: const Column(
      children: [
        Icon(Icons.mark_email_unread_outlined, size: 40, color: sage),
        SizedBox(height: 18),
        Text(
          'Pierwszy mały sygnał\njeszcze przed Wami.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Georgia', fontSize: 25, height: 1.4),
        ),
      ],
    ),
  );
}

class History extends StatelessWidget {
  const History({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: controller.refresh,
    child: ListView(
      padding: const EdgeInsets.all(24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const Text(
          'Wasze małe chwile.',
          style: TextStyle(fontFamily: 'Georgia', fontSize: 32),
        ),
        const SizedBox(height: 10),
        const Text(
          'Ostatnie 100 wpisów, od najnowszego.',
          style: TextStyle(color: sage),
        ),
        const SizedBox(height: 24),
        if (controller.entries.isEmpty) const EmptyCard(),
        for (final entry in controller.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: EntryCard(
              key: ValueKey(entry.id),
              entry: entry,
              controller: controller,
            ),
          ),
      ],
    ),
  );
}

class Compose extends StatefulWidget {
  const Compose({super.key, required this.controller});
  final AppController controller;
  @override
  State<Compose> createState() => _ComposeState();
}

class _ComposeState extends State<Compose> {
  int mood = 3;
  CyclePhase phase = CyclePhase.unknown;
  final note = TextEditingController();
  Uint8List? photo;
  bool working = false;
  String? error;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> pick(ImageSource source) async {
    setState(() {
      working = true;
      error = null;
    });
    try {
      final bytes = await PhotoService.pick(source);
      if (mounted && bytes != null) setState(() => photo = bytes);
    } catch (e) {
      if (mounted) setState(() => error = AppController.messageFor(e));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> save() async {
    setState(() {
      working = true;
      error = null;
    });
    try {
      final saved = await widget.controller.save(
        CheckInDraft(mood: mood, phase: phase, note: note.text, photo: photo),
      );
      if (!mounted) return;
      if (saved) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.controller.demo
                  ? 'Zapisano w demo — tylko w tej sesji.'
                  : 'Twój sygnał został wysłany ♡',
            ),
          ),
        );
      } else {
        setState(
          () =>
              error = widget.controller.error ?? 'Nie udało się zapisać wpisu.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = AppController.messageFor(e));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !working,
    child: Scaffold(
      appBar: AppBar(title: const Text('Mały sygnał'), backgroundColor: paper),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Jak jest u Ciebie?',
                  style: TextStyle(fontFamily: 'Georgia', fontSize: 34),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tyle, ile chcesz powiedzieć.',
                  style: TextStyle(color: sage),
                ),
                const SizedBox(height: 30),
                const SectionLabel('SAMOPOCZUCIE'),
                const SizedBox(height: 14),
                Row(
                  children: List.generate(
                    5,
                    (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 4 ? 0 : 8),
                        child: Semantics(
                          label: 'Samopoczucie ${i + 1}: ${moodLabels[i]}',
                          selected: mood == i + 1,
                          button: true,
                          child: InkWell(
                            key: ValueKey('mood-${i + 1}'),
                            borderRadius: BorderRadius.circular(20),
                            onTap: working
                                ? null
                                : () => setState(() => mood = i + 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: mood == i + 1 ? rose : Colors.white,
                                border: Border.all(
                                  color: mood == i + 1
                                      ? sage
                                      : const Color(0xFFE3E6DD),
                                  width: mood == i + 1 ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    moodFaces[i],
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('${i + 1}'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    moodLabels[mood - 1],
                    style: const TextStyle(color: sage),
                  ),
                ),
                const SizedBox(height: 30),
                const SectionLabel('FAZA CYKLU'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: CyclePhase.values
                      .map(
                        (p) => ChoiceChip(
                          label: Text(p.label),
                          selected: phase == p,
                          onSelected: working
                              ? null
                              : (_) => setState(() => phase = p),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Wybierasz sama. Aplikacja nie wylicza faz ani owulacji.',
                  style: TextStyle(fontSize: 12, color: sage, height: 1.5),
                ),
                const SizedBox(height: 28),
                const SectionLabel('KILKA SŁÓW • OPCJONALNIE'),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  enabled: !working,
                  maxLength: 1500,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Czego dzisiaj potrzebujesz? Co Cię ucieszyło?',
                  ),
                ),
                const SizedBox(height: 18),
                const SectionLabel('KADR Z DNIA • OPCJONALNIE'),
                const SizedBox(height: 12),
                if (photo != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(photo!, height: 200, fit: BoxFit.cover),
                  ),
                  TextButton.icon(
                    onPressed: working
                        ? null
                        : () => setState(() => photo = null),
                    icon: const Icon(Icons.close),
                    label: const Text('Usuń zdjęcie'),
                  ),
                ],
                Wrap(
                  spacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: working
                          ? null
                          : () => pick(ImageSource.gallery),
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Galeria'),
                    ),
                    OutlinedButton.icon(
                      onPressed: working
                          ? null
                          : () => pick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Aparat'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (error != null) ErrorBox(error!),
                FilledButton.icon(
                  onPressed: working ? null : save,
                  icon: const Icon(Icons.favorite_border),
                  label: Text(working ? 'Chwileczkę…' : 'Wyślij mały sygnał'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class Settings extends StatelessWidget {
  const Settings({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Text(
        'Tylko Wasza\nprzestrzeń.',
        style: TextStyle(fontFamily: 'Georgia', fontSize: 34, height: 1.2),
      ),
      const SizedBox(height: 24),
      _tile(
        Icons.people_outline,
        'Twoja rola',
        controller.writer
            ? 'Dzielisz się samopoczuciem i zarządzasz swoimi wpisami.'
            : 'Odbierasz wpisy i jesteś blisko.',
      ),
      _tile(
        Icons.lock_outline,
        'Prywatność',
        'Dostęp do danych mają konta przypisane do Waszej pary. Ta wersja nie ma szyfrowania end-to-end.',
      ),
      _tile(
        Icons.add_to_home_screen,
        'Na iPhonie',
        'Otwórz adres aplikacji w Safari → Udostępnij → Dodaj do ekranu początkowego.',
      ),
      _tile(
        Icons.widgets_outlined,
        'Widget Androida',
        'Przytrzymaj ekran główny → Widgety → Blisko. Pokazuje ostatnio pobrany wpis. Dotknięcie otwiera aplikację i pobiera aktualizacje.',
      ),
      _tile(
        Icons.notifications_none,
        'Aktualizacje',
        'Wpisy odświeżają się przy otwarciu i podczas korzystania z aplikacji. Powiadomienia push i automatyczne odświeżanie widgetu w tle nie są jeszcze włączone.',
      ),
      _tile(
        Icons.visibility_outlined,
        'Dyskrecja',
        'Widget pokazuje samopoczucie, fazę i fragment notatki. Dodaj go tylko, jeśli chcesz mieć te dane na ekranie głównym.',
      ),
      const SizedBox(height: 20),
      OutlinedButton(
        onPressed: controller.logout,
        child: Text(controller.demo ? 'Zamknij demo' : 'Wyloguj się'),
      ),
    ],
  );
  Widget _tile(IconData icon, String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: sage),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(body, style: const TextStyle(height: 1.6, color: sage)),
            ],
          ),
        ),
      ],
    ),
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      letterSpacing: 1.3,
      fontWeight: FontWeight.w700,
      color: sage,
    ),
  );
}

class ErrorBox extends StatelessWidget {
  const ErrorBox(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error, height: 1.5),
    ),
  );
}

String stamp(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
