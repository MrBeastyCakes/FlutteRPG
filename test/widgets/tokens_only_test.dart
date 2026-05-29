import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-grep guard: the redesigned widget files must style themselves only
/// through the 7a design system (`DSColors`, `DSText`, `DSSpace`, `DSRadius`,
/// `DSMotion`) and the Game* primitives — never raw `Color(0x...)` hex literals
/// and never the legacy `GameTheme`.
///
/// As each redesign PR lands, add its directory to [targetDirs].
void main() {
  // Directories whose .dart files must be token-only. Paths are relative to the
  // package root (the test runner's working directory).
  const targetDirs = <String>[
    'lib/views/dashboard',
  ];

  // Matches raw ARGB/hex color literals like `Color(0xFF112233)`.
  final rawColorLiteral = RegExp(r'Color\(\s*0x');
  // Matches any reference to the legacy GameTheme.
  final gameThemeRef = RegExp(r'\bGameTheme\b');

  for (final dir in targetDirs) {
    test('$dir uses design tokens only (no raw Color/GameTheme)', () {
      final directory = Directory(dir);
      expect(directory.existsSync(), isTrue,
          reason: 'Expected directory to exist: $dir');

      final offenders = <String>[];
      final dartFiles = directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (rawColorLiteral.hasMatch(line)) {
            offenders.add('${file.path}:${i + 1}  raw Color literal → $line');
          }
          if (gameThemeRef.hasMatch(line)) {
            offenders.add('${file.path}:${i + 1}  GameTheme reference → $line');
          }
        }
      }

      expect(offenders, isEmpty,
          reason: 'Use DSColors/DSText tokens instead:\n${offenders.join('\n')}');
    });
  }
}
