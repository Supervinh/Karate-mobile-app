import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shinpan/l10n/app_localizations.dart';
import 'package:confetti/confetti.dart';
import 'package:shinpan/question_picker.dart';

class QuizPage extends StatefulWidget {
  final String quizType; // 'kumite', 'kata', 'any'
  final Locale locale;
  const QuizPage({super.key, required this.quizType, required this.locale});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  // List of questions for the quiz
  late List<dynamic> questions;
  // Controller for confetti animation
  late ConfettiController _confettiController;
  // Controller for shake animation
  late AnimationController _shakeController;
  // Animation for shake effect
  late Animation<double> _shakeAnimation;
  static const int timerDuration = 20;
  int currentIndex = 0;
  int score = 0;
  bool loading = true;
  bool finished = false;
  int timer = timerDuration;
  Timer? _timer;
  bool answered = false;
  bool? selectedAnswer; // null: not selected, true/false: selected
  bool showResult = false; // Added to display the result
  bool? wasCorrect; // Added to know if the answer was correct

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 32)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final langCode = widget.locale.languageCode;
    final assetPath = 'lib/assets/questions/questions_$langCode.json';
    final data = await rootBundle.loadString(assetPath);
    final allQuestions = json.decode(data) as List<dynamic>;
    // Use weighted picker for question selection
    final picker = WeightedQuestionPicker(
      allQuestions: allQuestions,
      quizType: widget.quizType,
      langCode: langCode,
      pickCount: 5,
    );
    questions = await picker.pickQuestions();
    setState(() {
      loading = false;
      timer = timerDuration;
      answered = false;
      selectedAnswer = null;
      showResult = false;
      wasCorrect = null;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      timer = timerDuration;
      answered = false;
      selectedAnswer = null;
      showResult = false;
      wasCorrect = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || finished || loading) return;
      setState(() {
        timer--;
        if (timer <= 0) {
          _timer?.cancel();
          if (!answered) {
            // Automatic validation
            answered = true;
            showResult = true;
            if (selectedAnswer != null &&
                questions[currentIndex]['answer'] == selectedAnswer) {
              score++;
              wasCorrect = true;
              _confettiController.play();
            } else {
              wasCorrect = false;
            }
            // If no answer, wasCorrect remains false
          }
        }
      });
    });
  }

  void _nextQuestion() async {
    if (currentIndex < 4) {
      setState(() {
        currentIndex++;
        timer = timerDuration;
        answered = false;
        selectedAnswer = null;
        showResult = false;
        wasCorrect = null;
      });
      _startTimer();
    } else {
      // Increment the appearance counters for used questions
      final langCode = widget.locale.languageCode;
      final assetPath = 'lib/assets/questions/questions_$langCode.json';
      final data = await rootBundle.loadString(assetPath);
      final allQuestions = json.decode(data) as List<dynamic>;
      final picker = WeightedQuestionPicker(
        allQuestions: allQuestions,
        quizType: widget.quizType,
        langCode: langCode,
        pickCount: 5,
      );
      await picker.incrementCounts(questions);
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
      setState(() {
        answered = true;
        showResult = true;
        if (questions[currentIndex]['answer'] == selectedAnswer) {
          score++;
          wasCorrect = true;
          _confettiController.play();
        } else {
          wasCorrect = false;
          _shakeController.forward(from: 0); // Trigger shake animation
        }
      });
      _timer?.cancel();
      if (questions[currentIndex]['answer'] != selectedAnswer) {
        // Reset position after shake animation
        Future.delayed(_shakeController.duration!, () {
          if (mounted) _shakeController.reset();
        });
      }
    }
  }

  Color? _getButtonColor(bool buttonValue) {
    if (!showResult) {
      // Normal selection
      if (selectedAnswer == buttonValue) {
        return Colors.blue;
      }
      return null;
    }
    // After validation
    final correctAnswer = questions[currentIndex]['answer'] as bool;
    if (selectedAnswer == null) {
      // If no answer, color the correct one in green
      if (buttonValue == correctAnswer) return Colors.green;
      return null;
    }
    if (buttonValue == selectedAnswer) {
      if (selectedAnswer == correctAnswer) return Colors.green;
      return Colors.red;
    }
    // If not the selected button, but it's the correct answer
    if (buttonValue == correctAnswer) return Colors.green;
    return null;
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
      body: Stack(
        children: [
          Column(
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.red,
                            ),
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
              // Added padding between the circle and the text
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
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            double offset = 0;
                            if (showResult && wasCorrect == false && selectedAnswer == true) {
                              offset = _shakeAnimation.value * (Random().nextBool() ? 1 : -1);
                            }
                            return Transform.translate(
                              offset: Offset(offset, 0),
                              child: child,
                            );
                          },
                          child: ElevatedButton(
                            onPressed: (!answered && !showResult)
                                ? () => _answer(true)
                                : () {}, // Toujours enabled
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color?>((
                                    states,
                                  ) {
                                    return _getButtonColor(true);
                                  }),
                              foregroundColor: WidgetStateProperty.all<Color>(
                                Colors.black,
                              ),
                            ),
                            child: Text(langTrueText(l10n)),
                          ),
                        ),
                        const SizedBox(width: 32),
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            double offset = 0;
                            if (showResult && wasCorrect == false && selectedAnswer == false) {
                              offset = _shakeAnimation.value * (Random().nextBool() ? 1 : -1);
                            }
                            return Transform.translate(
                              offset: Offset(offset, 0),
                              child: child,
                            );
                          },
                          child: ElevatedButton(
                            onPressed: (!answered && !showResult)
                                ? () => _answer(false)
                                : () {}, // Toujours enabled
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color?>((
                                    states,
                                  ) {
                                    return _getButtonColor(false);
                                  }),
                              foregroundColor: WidgetStateProperty.all<Color>(
                                Colors.black,
                              ),
                            ),
                            child: Text(langFalseText(l10n)),
                          ),
                        ),
                      ],
                    ),
                    if (!answered && selectedAnswer != null && !showResult)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton(
                          onPressed: _validate,
                          child: Text(l10n.validateButton),
                        ),
                      ),
                    if (showResult)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          wasCorrect == true
                              ? l10n.correctResult
                              : l10n.falseResult,
                          style: TextStyle(
                            color: wasCorrect == true
                                ? Colors.green
                                : Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (showResult)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton(
                          onPressed: _nextQuestion,
                          child: Text(
                            currentIndex == 4
                                ? l10n.endButton
                                : l10n.nextButton,
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
          // Confetti widget
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.orange,
                Colors.purple,
              ],
              createParticlePath: null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    _shakeController.dispose();
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
