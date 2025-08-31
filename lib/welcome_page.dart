import 'package:flutter/material.dart';
import 'package:shinpan/l10n/app_localizations.dart';

class WelcomePage extends StatelessWidget {
  final Locale locale;
  final void Function(BuildContext, String) onLanguageSelected;
  const WelcomePage({super.key, required this.locale, required this.onLanguageSelected});

  static const Map<String, String> flagPaths = {
    'fr': 'lib/assets/flags/fr.png',
    'en': 'lib/assets/flags/en.png',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langCode = locale.languageCode;
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () async {
                final selected = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      title: Text(l10n.selectLanguage),
                      children: flagPaths.entries.map((entry) {
                        return SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, entry.key),
                          child: Row(
                            children: [
                              Image.asset(entry.value, width: 40, height: 24, errorBuilder: (context, error, stackTrace) => Icon(Icons.flag)),
                              const SizedBox(width: 12),
                              Text(entry.key == 'fr' ? 'Français' : 'English'),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
                if (selected != null && selected != langCode) {
                  onLanguageSelected(context, selected);
                }
              },
              child: Image.asset(
                flagPaths[langCode] ?? flagPaths['en']!,
                width: 40,
                height: 24,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.flag),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Text(
          l10n.welcomeTitle,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
