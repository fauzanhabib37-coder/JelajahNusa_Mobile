import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../data/catalog.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatelessWidget {
  final AppState state;
  final Lesson lesson;
  final List<int> answers;
  final int delta;
  final List<String> newBadges;
  const ResultScreen({
    super.key,
    required this.state,
    required this.lesson,
    required this.answers,
    required this.delta,
    this.newBadges = const [],
  });
  int get correct => List.generate(
    answers.length,
    (i) => answers[i] == lesson.questions[i].answer ? 1 : 0,
  ).fold(0, (a, b) => a + b);
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const PageHeader('Hasil belajarmu'),
          Expanded(
            child: PageBody(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: const BoxDecoration(
                      color: Nusa.soft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.explore_outlined,
                      color: Nusa.green,
                      size: 54,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Langkah kecil,',
                  style: Nusa.heading(28),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'wawasan baru.',
                  style: Nusa.heading(28, Nusa.green),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Kuis ${lesson.title.toLowerCase()} telah kamu selesaikan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Nusa.muted),
                ),
                const SizedBox(height: 28),
                Stats([
                  (
                    '${(correct / lesson.questions.length * 100).round()}',
                    'Skor',
                  ),
                  ('$correct / ${lesson.questions.length}', 'Benar'),
                  ('+$delta', 'Poin baru'),
                ]),
                const SizedBox(height: 18),
                if (newBadges.isNotEmpty)
                  HintBox(
                    title: 'Lencana baru untukmu',
                    body: newBadges.map((b) => badgeName(b)).join(' · '),
                    icon: Icons.eco_outlined,
                  )
                else
                  HintBox(
                    title: delta == 0
                        ? 'Terus asah pemahamanmu'
                        : 'Pemahamanmu bertumbuh',
                    body: delta == 0
                        ? 'Poin dihitung dari hasil terbaik. Ulangi kuis untuk memperbaiki pemahamanmu.'
                        : 'Hasil terbaikmu kini tersimpan. Temukan cerita berikutnya.',
                    icon: Icons.eco_outlined,
                  ),
                const SizedBox(height: 26),
                SectionTitle(
                  'Progres ${state.catalog.region(lesson.regionId).name}',
                ),
                const SizedBox(height: 10),
                ProgressLine(
                  state.completedIn(lesson.regionId) /
                      state.catalog.forRegion(lesson.regionId).length,
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.completedIn(lesson.regionId)} / ${state.catalog.forRegion(lesson.regionId).length} materi selesai',
                  style: const TextStyle(color: Nusa.muted, fontSize: 11),
                ),
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Expanded(child: Text('Lanjutkan jelajah')),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => _Review(lesson: lesson, answers: answers),
                    ),
                  ),
                  child: const Text('Lihat pembahasan jawaban'),
                ),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => QuizScreen(state: state, lesson: lesson),
                    ),
                  ),
                  child: const Text('Ulangi kuis'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

String badgeName(String id) => switch (id) {
  'langkah_pertama' => 'Langkah Pertama',
  'penjelajah' => 'Penjelajah',
  _ => 'Lintas Daerah',
};

class _Review extends StatelessWidget {
  final Lesson lesson;
  final List<int> answers;
  const _Review({required this.lesson, required this.answers});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const PageHeader('Pembahasan kuis'),
          Expanded(
            child: PageBody(
              children: [
                Text(lesson.title, style: Nusa.heading(25)),
                const SizedBox(height: 24),
                for (var i = 0; i < lesson.questions.length; i++) ...[
                  Text(
                    '${i + 1}. ${lesson.questions[i].prompt}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Jawabanmu: ${lesson.questions[i].options[answers[i]]}',
                    style: TextStyle(
                      fontSize: 12,
                      color: answers[i] == lesson.questions[i].answer
                          ? Nusa.green
                          : Nusa.red,
                    ),
                  ),
                  const SizedBox(height: 10),
                  HintBox(
                    title:
                        'Jawaban benar: ${lesson.questions[i].options[lesson.questions[i].answer]}',
                    body: lesson.questions[i].explanation,
                    icon: Icons.lightbulb_outline,
                  ),
                  const SizedBox(height: 28),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
