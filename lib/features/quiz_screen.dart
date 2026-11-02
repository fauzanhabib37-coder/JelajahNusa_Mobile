import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/quiz_session.dart';
import '../data/catalog.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final AppState state;
  final Lesson lesson;
  const QuizScreen({super.key, required this.state, required this.lesson});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizSession quiz;
  final scroll = ScrollController();
  bool busy = false, allowExit = false, asking = false;
  @override
  void initState() {
    super.initState();
    quiz = QuizSession(widget.lesson);
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Future<void> leave() async {
    if (busy || asking) return;
    asking = true;
    final exit = await confirm(
      context,
      title: 'Keluar dari kuis?',
      message:
          'Jawaban kuis ini belum disimpan. Progres kuis yang sudah selesai sebelumnya tetap tersedia.',
      action: 'Keluar kuis',
    );
    asking = false;
    if (!exit || !mounted) return;
    setState(() => allowExit = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  Future<void> act() async {
    if (busy) return;
    if (!quiz.checked) {
      setState(quiz.check);
      return;
    }
    if (!quiz.isLast) {
      setState(quiz.next);
      scroll.jumpTo(0);
      return;
    }
    setState(() => busy = true);
    try {
      final before = widget.state.badges.toSet();
      final delta = await widget.state.finishLesson(
        widget.lesson.id,
        quiz.correctCount,
      );
      final badges = widget.state.badges
          .where((b) => !before.contains(b))
          .toList();
      if (!mounted) return;
      setState(() => allowExit = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ResultScreen(
              state: widget.state,
              lesson: widget.lesson,
              answers: quiz.answers,
              delta: delta,
              newBadges: badges,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = quiz.question,
        correct = quiz.checked && quiz.selected == question.answer;
    return PopScope(
      canPop: allowExit,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    RoundIcon(
                      Icons.close,
                      label: 'Tutup kuis',
                      onTap: busy ? null : leave,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Kuis budaya',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${quiz.index + 1} / ${widget.lesson.questions.length}',
                      style: const TextStyle(color: Nusa.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProgressLine(
                        quiz.answers.length / widget.lesson.questions.length,
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Nusa.green,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            widget.lesson.category == 'Bahasa'
                                ? 'Keragaman bahasa'
                                : 'Pemahaman budaya',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(question.prompt, style: Nusa.heading(25)),
                      const SizedBox(height: 18),
                      const Text(
                        'Pilih satu jawaban yang paling tepat.',
                        style: TextStyle(fontSize: 12, color: Nusa.muted),
                      ),
                      const SizedBox(height: 24),
                      for (var i = 0; i < question.options.length; i++)
                        _answer(i),
                      const SizedBox(height: 14),
                      if (quiz.checked)
                        Semantics(
                          liveRegion: true,
                          child: HintBox(
                            title: correct
                                ? 'Benar, langkah yang baik!'
                                : 'Mari pahami bersama',
                            body:
                                'Jawaban benar: ${question.options[question.answer]}. ${question.explanation}',
                            icon: correct
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                          ),
                        )
                      else
                        const HintBox(
                          title: '',
                          body: 'Jawaban dikonfirmasi setelah diperiksa.',
                          icon: Icons.info_outline,
                        ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('quiz_action'),
                        onPressed: busy || quiz.selected == null ? null : act,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                busy
                                    ? 'Menyimpan hasil…'
                                    : !quiz.checked
                                    ? 'Periksa jawaban'
                                    : quiz.isLast
                                    ? 'Lihat hasil'
                                    : 'Soal berikutnya',
                              ),
                            ),
                            if (!busy)
                              Icon(
                                !quiz.checked
                                    ? Icons.check
                                    : Icons.arrow_forward,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _answer(int i) {
    final chosen = quiz.selected == i;
    final right = quiz.checked && i == quiz.question.answer;
    final wrong = quiz.checked && chosen && !right;
    final color = wrong ? Nusa.red : Nusa.green;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: chosen || right ? Nusa.soft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(19),
          side: BorderSide(
            color: chosen || right ? color : const Color(0xFFE5E9E2),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('answer_$i'),
          onTap: quiz.checked || busy
              ? null
              : () => setState(() => quiz.select(i)),
          child: Semantics(
            selected: chosen,
            button: true,
            label:
                'Pilihan ${String.fromCharCode(65 + i)}${quiz.checked ? (right
                          ? ', jawaban benar'
                          : wrong
                          ? ', jawabanmu belum tepat'
                          : '') : ''}',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: chosen || right ? color : Nusa.soft,
                      shape: BoxShape.circle,
                    ),
                    child: right
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : wrong
                        ? const Icon(Icons.close, color: Colors.white, size: 18)
                        : Text(
                            String.fromCharCode(65 + i),
                            style: TextStyle(
                              color: chosen ? Colors.white : Nusa.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      quiz.question.options[i],
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
