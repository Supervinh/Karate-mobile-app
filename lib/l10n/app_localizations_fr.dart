// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get welcomeTitle => 'Bienvenue sur l\'application Shinpan';

  @override
  String get selectLanguage => 'Choisir la langue';

  @override
  String get kataQuiz => 'Quiz Kata';

  @override
  String get kumiteQuiz => 'Quiz Kumite';

  @override
  String get anyQuiz => 'Quiz Aléatoire';

  @override
  String get nextButton => 'Suivant';

  @override
  String get endButton => 'Finir';

  @override
  String get validateButton => 'Valider';

  @override
  String get correctResult => 'Bonne réponse +1 point';

  @override
  String get falseResult => 'Mauvaise réponse aucun point';
}
