import 'dart:convert';
import 'dart:math';
import 'dart:async';
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
  static const int timerDuration = 20;
  int currentIndex = 0;
  int score = 0;
  bool loading = true;
  bool finished = false;
  int timer = timerDuration;
  Timer? _timer;
  bool answered = false;
  bool? selectedAnswer; // null: not selected, true/false: selected

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
      filtered = allQuestions
          .where((q) => q['type'] == widget.quizType)
          .toList();
    }
    filtered.shuffle(Random());
    questions = filtered.take(5).toList();
    setState(() {
      loading = false;
      timer = timerDuration;
      answered = false;
      selectedAnswer = null;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      timer = timerDuration;
      answered = false;
      selectedAnswer = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || finished || loading) return;
      setState(() {
        timer--;
        if (timer <= 0) {
          _timer?.cancel();
          if (!answered) {
            // Validate automatically with selected answer or no answer
            answered = true;
            if (selectedAnswer != null &&
                questions[currentIndex]['answer'] == selectedAnswer) {
              score++;
            }
            _nextQuestion();
          }
        }
      });
    });
  }

  void _nextQuestion() {
    if (currentIndex < 4) {
      setState(() {
        currentIndex++;
        timer = timerDuration;
        answered = false;
        selectedAnswer = null;
      });
      _startTimer();
    } else {
      setState(() {
        finished = true;
      });
      _timer?.cancel();
    }
  }

  void _answer(bool userAnswer) {
    if (!answered) {
      setState(() {
        selectedAnswer = userAnswer;
      });
    }
  }

  void _validate() {
    if (!answered && selectedAnswer != null) {
      answered = true;
      if (questions[currentIndex]['answer'] == selectedAnswer) {
        score++;
      }
      _timer?.cancel();
      _nextQuestion();
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
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
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
      body: Column(
        children: [
          // Large circular timer at the very top
          Padding(
            padding: const EdgeInsets.only(top: 32.0, bottom: 8.0),
            child: Center(
              child: SizedBox(
                height: 160,
                width: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: CircularProgressIndicator(
                        value: timer / timerDuration,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    ),
                    Text(
                      '$timer',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Ajoute du padding entre le cercle et le texte
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${langQuestionText(l10n)} ${currentIndex + 1}/5',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  q['question'],
                  style: const TextStyle(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: answered ? null : () => _answer(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedAnswer == true
                            ? Colors.blue
                            : null,
                      ),
                      child: Text(langTrueText(l10n)),
                    ),
                    const SizedBox(width: 32),
                    ElevatedButton(
                      onPressed: answered ? null : () => _answer(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedAnswer == false
                            ? Colors.blue
                            : null,
                      ),
                      child: Text(langFalseText(l10n)),
                    ),
                  ],
                ),
                if (!answered && selectedAnswer != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: _validate,
                      child: Text(
                        widget.locale.languageCode == 'fr'
                            ? 'Valider'
                            : 'Validate',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Fill remaining space
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String langTimerText(AppLocalizations l10n) {
    return widget.locale.languageCode == 'fr' ? 'Temps' : 'Time';
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
