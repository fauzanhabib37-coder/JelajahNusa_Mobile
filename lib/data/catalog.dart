import 'dart:convert';
import 'package:flutter/services.dart';

class Region {
  final String id, name, tagline, image, description;
  Region.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      name = j['name'] as String,
      tagline = j['tagline'] as String,
      image = j['image'] as String,
      description = j['description'] as String;
}

class Section {
  final String title, body;
  Section.fromJson(Map<String, dynamic> j)
    : title = j['title'] as String,
      body = j['body'] as String;
}

class ContentSource {
  final String title, publisher, url;
  ContentSource.fromJson(Map<String, dynamic> j)
    : title = j['title'] as String,
      publisher = j['publisher'] as String,
      url = j['url'] as String;
}

class Question {
  final String id, prompt, explanation;
  final List<String> options;
  final int answer;
  Question.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      prompt = j['prompt'] as String,
      explanation = j['explanation'] as String,
      answer = j['answer'] as int,
      options = List<String>.unmodifiable(j['options'] as List);
}

class Lesson {
  final String id, regionId, title, category, subtitle, reflection;
  final int minutes;
  final List<Section> sections;
  final List<ContentSource> sources;
  final List<Question> questions;
  Lesson.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      regionId = j['regionId'] as String,
      title = j['title'] as String,
      category = j['category'] as String,
      subtitle = j['subtitle'] as String,
      reflection = j['reflection'] as String,
      minutes = j['minutes'] as int,
      sections = List.unmodifiable(
        (j['sections'] as List).map(
          (e) => Section.fromJson(e as Map<String, dynamic>),
        ),
      ),
      sources = List.unmodifiable(
        (j['sources'] as List).map(
          (e) => ContentSource.fromJson(e as Map<String, dynamic>),
        ),
      ),
      questions = List.unmodifiable(
        (j['questions'] as List).map(
          (e) => Question.fromJson(e as Map<String, dynamic>),
        ),
      );
}

class Catalog {
  final List<Region> regions;
  final List<Lesson> lessons;
  Catalog.fromJson(Map<String, dynamic> j)
    : regions = List.unmodifiable(
        (j['regions'] as List).map(
          (e) => Region.fromJson(e as Map<String, dynamic>),
        ),
      ),
      lessons = List.unmodifiable(
        (j['lessons'] as List).map(
          (e) => Lesson.fromJson(e as Map<String, dynamic>),
        ),
      ) {
    final ids = regions.map((r) => r.id).toSet();
    if (ids.length != regions.length ||
        lessons.map((l) => l.id).toSet().length != lessons.length) {
      throw const FormatException('Identitas katalog duplikat.');
    }
    final questionIds = <String>{};
    for (final l in lessons) {
      if (!ids.contains(l.regionId) ||
          l.questions.length != 5 ||
          !['Budaya', 'Bahasa'].contains(l.category) ||
          l.sections.isEmpty ||
          l.sources.isEmpty) {
        throw FormatException('Materi tidak valid: ${l.id}');
      }
      for (final s in l.sources) {
        if (Uri.tryParse(s.url)?.scheme != 'https') {
          throw const FormatException('Sumber tidak valid.');
        }
      }
      for (final q in l.questions) {
        if (q.options.length != 4 ||
            q.answer < 0 ||
            q.answer > 3 ||
            !questionIds.add(q.id) ||
            q.explanation.isEmpty) {
          throw FormatException('Soal tidak valid: ${q.id}');
        }
      }
    }
  }
  static Future<Catalog> load() async => Catalog.fromJson(
    jsonDecode(await rootBundle.loadString('assets/data/content.json'))
        as Map<String, dynamic>,
  );
  Region region(String id) => regions.firstWhere((r) => r.id == id);
  Lesson lesson(String id) => lessons.firstWhere((l) => l.id == id);
  bool hasLesson(String id) => lessons.any((l) => l.id == id);
  List<Lesson> forRegion(String id) =>
      lessons.where((l) => l.regionId == id).toList(growable: false);
  List<Lesson> search(String query, String category) {
    final needle = query.trim().toLowerCase();
    return lessons
        .where(
          (l) =>
              (category == 'Semua' || l.category == category) &&
              '${l.title} ${l.subtitle} ${region(l.regionId).name} ${l.category}'
                  .toLowerCase()
                  .contains(needle),
        )
        .toList(growable: false);
  }
}
