import '../data/catalog.dart';

class QuizSession {
  final Lesson lesson;
  int index = 0;
  int? selected;
  bool checked = false;
  final List<int> _answers = [];
  QuizSession(this.lesson);
  Question get question => lesson.questions[index];
  List<int> get answers => List.unmodifiable(_answers);
  bool get isLast => index == lesson.questions.length - 1;
  bool get isFinished => isLast && checked;
  int get correctCount => List.generate(
    _answers.length,
    (i) => _answers[i] == lesson.questions[i].answer ? 1 : 0,
  ).fold(0, (a, b) => a + b);
  int get score => (correctCount / lesson.questions.length * 100).round();
  void select(int value) {
    if (value < 0 || value >= question.options.length) {
      throw RangeError('Pilihan tidak valid');
    }
    if (!checked) selected = value;
  }

  void check() {
    if (checked) return;
    if (selected == null) throw StateError('Pilih satu jawaban.');
    _answers.add(selected!);
    checked = true;
  }

  void next() {
    if (!checked || isLast) throw StateError('Belum dapat melanjutkan.');
    index++;
    selected = null;
    checked = false;
  }
}
