import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shinpan/l10n/app_localizations.dart';

class QuizPage extends StatefulWidget {
  final String quizType; // 'kumite', 'kata', 'any'
  final Locale locale;
  const QuizPage({super.key, required this.quizType, required this.locale});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late List<dynamic> questions;
  int currentIndex = 0;
  int score = 0;
  bool loading = true;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final langCode = widget.locale.languageCode;
    final assetPath = 'lib/assets/questions/questions_$langCode.json';
    final data = await rootBundle.loadString(assetPath);
    final allQuestions = json.decode(data) as List<dynamic>;
    List<dynamic> filtered;
    if (widget.quizType == 'any') {
      filtered = List.from(allQuestions);
    } else {
      filtered = allQuestions.where((q) => q['type'] == widget.quizType).toList();
    }
    filtered.shuffle(Random());
    questions = filtered.take(5).toList();
    setState(() {
      loading = false;
    });
  }

  void _answer(bool userAnswer) {
    if (questions[currentIndex]['answer'] == userAnswer) {
      score++;
    }
    if (currentIndex < 4) {
      setState(() {
        currentIndex++;
      });
    } else {
      setState(() {
        finished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (finished) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                langScoreText(l10n, score),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(langBackText(l10n)),
              ),
            ],
          ),
        ),
      );
    }
    final q = questions[currentIndex];
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${langQuestionText(l10n)} ${currentIndex + 1}/5',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(
              q['question'],
              style: const TextStyle(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _answer(true),
                  child: Text(langTrueText(l10n)),
                ),
                const SizedBox(width: 32),
                ElevatedButton(
                  onPressed: () => _answer(false),
                  child: Text(langFalseText(l10n)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String langTrueText(AppLocalizations l10n) {
    return widget.locale.languageCode == 'fr' ? 'Vrai' : 'True';
  }
  String langFalseText(AppLocalizations l10n) {
    return widget.locale.languageCode == 'fr' ? 'Faux' : 'False';
  }
  String langScoreText(AppLocalizations l10n, int score) {
    return widget.locale.languageCode == 'fr'
        ? 'Votre score : $score / 5'
        : 'Your score: $score / 5';
  }
  String langBackText(AppLocalizations l10n) {
    return widget.locale.languageCode == 'fr' ? 'Retour' : 'Back';
  }
  String langQuestionText(AppLocalizations l10n) {
    return widget.locale.languageCode == 'fr' ? 'Question' : 'Question';
  }
}

