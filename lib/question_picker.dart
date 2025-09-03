import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class WeightedQuestionPicker {
  final List<dynamic> allQuestions;
  final String quizType;
  final String langCode;
  final int pickCount;

  WeightedQuestionPicker({
    required this.allQuestions,
    required this.quizType,
    required this.langCode,
    this.pickCount = 5,
  });

  String _prefsKey() => 'question_counts_${langCode}_$quizType';

  Future<List<dynamic>> pickQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefsKey();
    final counts = prefs.getStringList(key) ?? List.filled(allQuestions.length, '0');
    final List<int> countList = counts.map((e) => int.tryParse(e) ?? 0).toList();

    // Filter questions by type
    final filtered = quizType == 'any'
        ? allQuestions
        : allQuestions.where((q) => q['type'] == quizType).toList();

    // Associate each question with its counter
    final List<Map<String, dynamic>> questionWithCount = [];
    for (int i = 0; i < filtered.length; i++) {
      final idx = allQuestions.indexOf(filtered[i]);
      questionWithCount.add({
        'question': filtered[i],
        'count': countList[idx],
        'index': idx,
      });
    }

    // Sort by ascending counter
    questionWithCount.sort((a, b) => a['count'].compareTo(b['count']));

    // Select the pickCount least asked questions
    final selected = <Map<String, dynamic>>[];
    int i = 0;
    while (selected.length < pickCount && i < questionWithCount.length) {
      final currentCount = questionWithCount[i]['count'];
      // Get all questions with this counter
      final sameCount = questionWithCount.where((q) => q['count'] == currentCount).toList();
      sameCount.shuffle(Random());
      for (final q in sameCount) {
        if (selected.length < pickCount && !selected.contains(q)) {
          selected.add(q);
        }
      }
      i += sameCount.length;
    }

    // Return the list of questions
    return selected.map((e) => e['question']).toList();
  }

  Future<void> incrementCounts(List<dynamic> usedQuestions) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefsKey();
    final counts = prefs.getStringList(key) ?? List.filled(allQuestions.length, '0');
    final List<int> countList = counts.map((e) => int.tryParse(e) ?? 0).toList();

    for (final q in usedQuestions) {
      final idx = allQuestions.indexOf(q);
      if (idx != -1) countList[idx]++;
    }
    await prefs.setStringList(key, countList.map((e) => e.toString()).toList());
  }

  Future<void> resetCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefsKey();
    await prefs.setStringList(key, List.filled(allQuestions.length, '0'));
  }
}
