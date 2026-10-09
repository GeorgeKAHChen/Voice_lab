import 'package:flutter/material.dart';

import 'engine.dart';
import 'l10n/app_localizations.dart';
import 'locale_utils.dart';
import 'screens/live_screen.dart';
import 'screens/recordings_screen.dart';
import 'settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load();
  runApp(AmakawaApp(settings: settings));
}

class AmakawaApp extends StatelessWidget {
  const AmakawaApp({super.key, required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    // Rebuild when the language changes.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'amakawa',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF26C6DA),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0F1417),
          cardTheme: const CardThemeData(color: Color(0xFF182025)),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: settings.locale, // null = follow the system
        localeResolutionCallback: resolveLocale,
        home: Home(settings: settings),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key, required this.settings});
  final AppSettings settings;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final EngineController engine = EngineController(widget.settings);
  final GlobalKey<RecordingsScreenState> _recKey = GlobalKey();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    engine.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keep the engine's (notification) strings in the current language.
    engine.setStrings(AppLocalizations.of(context));
  }

  @override
  void dispose() {
    engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pages = [
      LiveScreen(
        engine: engine,
        onRecordingSaved: () => _recKey.currentState?.refresh(),
      ),
      RecordingsScreen(key: _recKey, engine: engine),
    ];
    final wide = MediaQuery.of(context).size.width > 700;
    final body = IndexedStack(index: _tab, children: pages);
    void select(int i) {
      setState(() => _tab = i);
      if (i == 1) _recKey.currentState?.refresh();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.multitrack_audio),
            SizedBox(width: 8),
            Text('amakawa'),
          ],
        ),
        toolbarHeight: 46,
      ),
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _tab,
                    onDestinationSelected: select,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      NavigationRailDestination(
                        icon: const Icon(Icons.show_chart),
                        label: Text(t.tabLive),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.folder_open),
                        label: Text(t.tabRecordings),
                      ),
                    ],
                  ),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: select,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.show_chart),
                  label: t.tabLive,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.folder_open),
                  label: t.tabRecordings,
                ),
              ],
            ),
    );
  }
}
