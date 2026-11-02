import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../data/catalog.dart';
import 'theme.dart';
import 'transitions.dart';

Future<void> perform(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AppException
                ? e.message
                : 'Tindakan belum berhasil. Silakan coba lagi.',
          ),
        ),
      );
    }
  }
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String action = 'Lanjutkan',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title, style: Nusa.heading(22)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('confirm_action'),
            onPressed: () => Navigator.pop(c, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

class Art extends StatelessWidget {
  final String path;
  final double? height, width;
  final double radius;
  final BoxFit fit;
  const Art(
    this.path, {
    super.key,
    this.height,
    this.width,
    this.radius = 20,
    this.fit = BoxFit.cover,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image.asset(
      path,
      height: height,
      width: width,
      fit: fit,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => Container(
        height: height,
        width: width,
        color: Nusa.soft,
        alignment: Alignment.center,
        child: const Icon(Icons.landscape_outlined, color: Nusa.green),
      ),
    ),
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'JelajahNusa',
    image: true,
    child: Image.asset('assets/brand/logo_compass.png', width: 42, height: 42),
  );
}

class RoundIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const RoundIcon(this.icon, {super.key, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: label,
    onPressed: onTap,
    style: IconButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Nusa.green,
      minimumSize: const Size(48, 48),
    ),
    icon: Icon(icon, size: 21),
  );
}

class PageHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool back;
  const PageHeader(this.title, {super.key, this.trailing, this.back = true});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(
      children: [
        if (back)
          RoundIcon(
            Icons.chevron_left,
            label: 'Kembali',
            onTap: () => Navigator.maybePop(context),
          )
        else
          const Brand(),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            maxLines: 2,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class PageBody extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  const PageBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 32),
  });
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class HintBox extends StatelessWidget {
  final String title, body;
  final IconData icon;
  const HintBox({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.auto_awesome_outlined,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Nusa.soft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Nusa.green, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    color: Nusa.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              if (title.isNotEmpty) const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12,
                  color: Nusa.muted,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class Stats extends StatelessWidget {
  final List<(String, String)> items;
  const Stats(this.items, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Expanded(
              child: Column(
                children: [
                  Text(
                    item.$1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: Nusa.green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Nusa.muted),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
}

class ProgressLine extends StatelessWidget {
  final double value;
  const ProgressLine(this.value, {super.key});
  @override
  Widget build(BuildContext context) => AnimatedProgressBar(value);
}

class CategoryTabs extends StatelessWidget {
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelect;
  const CategoryTabs({
    super.key,
    this.labels = const ['Semua', 'Budaya', 'Bahasa'],
    required this.selected,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: labels
        .map(
          (label) => ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected == label ? Colors.white : Nusa.muted,
              ),
            ),
            selected: selected == label,
            onSelected: (_) => onSelect(label),
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: Nusa.green,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: const StadiumBorder(),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
        )
        .toList(),
  );
}

class LessonTile extends StatelessWidget {
  final Lesson lesson;
  final AppState state;
  final VoidCallback onTap;
  final bool withImage;
  const LessonTile({
    super.key,
    required this.lesson,
    required this.state,
    required this.onTap,
    this.withImage = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('lesson_${lesson.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (withImage)
                Art(
                  state.catalog.region(lesson.regionId).image,
                  width: 80,
                  height: 106,
                  radius: 14,
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Nusa.soft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    state.completed(lesson.id)
                        ? Icons.check
                        : lesson.category == 'Bahasa'
                        ? Icons.translate_outlined
                        : Icons.eco_outlined,
                    color: Nusa.green,
                    size: 22,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (withImage)
                      Text(
                        state.catalog
                            .region(lesson.regionId)
                            .name
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Nusa.green,
                        ),
                      ),
                    Text(
                      lesson.title,
                      style: withImage
                          ? Nusa.heading(17)
                          : const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lesson.minutes} menit · ${lesson.category}${state.completed(lesson.id) ? ' · Selesai' : ''}',
                      style: const TextStyle(fontSize: 10, color: Nusa.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Nusa.green, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String title, body, action;
  final VoidCallback onAction;
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const Icon(Icons.explore_outlined, size: 46, color: Nusa.green),
        const SizedBox(height: 18),
        Text(title, style: Nusa.heading(23), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(color: Nusa.muted, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        TextButton(onPressed: onAction, child: Text(action)),
      ],
    ),
  );
}
