import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ShinpanRootApp());
}

class ShinpanRootApp extends StatefulWidget {
  const ShinpanRootApp({super.key});

  @override
  State<ShinpanRootApp> createState() => _ShinpanRootAppState();
}

class _ShinpanRootAppState extends State<ShinpanRootApp> {
  Locale? _selectedLocale;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('selected_language');
    setState(() {
      _selectedLocale = langCode != null ? Locale(langCode) : null;
      _loading = false;
    });
  }

  void _onLanguageSelected(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageCode);
    setState(() {
      _selectedLocale = Locale(languageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      title: 'Shinpan App',
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      locale: _selectedLocale,
      home: _selectedLocale == null
          ? LanguageSelectionScreen(onSelected: _onLanguageSelected)
          : const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class LanguageSelectionScreen extends StatelessWidget {
  final void Function(String) onSelected;
  const LanguageSelectionScreen({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected('fr'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'lib/assets/flags/fr.png',
                      width: 100,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.flag, size: 60),
                    ),
                    const SizedBox(height: 8),
                    const Text('Français'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected('en'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'lib/assets/flags/en.png',
                      width: 100,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.flag, size: 60),
                    ),
                    const SizedBox(height: 8),
                    const Text('English'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
