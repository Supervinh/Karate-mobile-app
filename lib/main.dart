import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shinpan/l10n/app_localizations.dart';
import 'welcome_page.dart';

void main() {
  runApp(const ShinpanRootApp());
}

// Main application widget
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

  // Loads the selected locale from shared preferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('selected_language');
    setState(() {
      _selectedLocale = langCode != null ? Locale(langCode) : null;
      _loading = false;
    });
  }

  // Handles language selection and updates shared preferences
  void _onLanguageSelected(BuildContext context, String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageCode);
    setState(() {
      _selectedLocale = Locale(languageCode);
    });
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WelcomePage(
          locale: _selectedLocale!,
          onLanguageSelected: _onLanguageSelected,
        ),
      ),
    );
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
        AppLocalizations.delegate,
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
          : WelcomePage(locale: _selectedLocale!, onLanguageSelected: _onLanguageSelected),
    );
  }
}

class LanguageSelectionScreen extends StatelessWidget {
  final void Function(BuildContext, String) onSelected;
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
                onTap: () => onSelected(context, 'fr'),
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
                onTap: () => onSelected(context, 'en'),
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
