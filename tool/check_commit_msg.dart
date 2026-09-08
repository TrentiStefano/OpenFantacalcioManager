import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Error: Path to commit message file required.');
    exit(1);
  }

  final msgFile = File(args[0]);
  if (!msgFile.existsSync()) {
    stderr.writeln('Error: Commit message file not found: ${args[0]}');
    exit(1);
  }

  final lines = msgFile.readAsLinesSync();
  // Filter out git comments starting with #
  final contentLines = lines.where((l) => !l.trim().startsWith('#')).toList();
  if (contentLines.isEmpty) {
    stderr.writeln('Error: Commit message cannot be empty.');
    exit(1);
  }

  final firstLine = contentLines.first.trim();
  if (firstLine.isEmpty) {
    stderr.writeln('Error: First line of commit message cannot be empty.');
    exit(1);
  }

  // Allow automatic merge commits from git
  if (firstLine.startsWith('Merge branch ') ||
      firstLine.startsWith('Merge remote-tracking branch ') ||
      firstLine.startsWith('Merge pull request ') ||
      firstLine.startsWith('Revert "')) {
    exit(0);
  }

  // Conventional Commits regex pattern
  // <type>(<scope>)?: <description> OR <type>(<scope>)?!: <description>
  final conventionalPattern = RegExp(
    r'^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-zA-Z0-9_\-\./]+\))?(!)?:\s+(.+)$',
  );

  final match = conventionalPattern.firstMatch(firstLine);
  if (match == null) {
    stderr.writeln('\n❌ INVALID COMMIT MESSAGE');
    stderr.writeln('------------------------------------------------------------');
    stderr.writeln('Your commit message does not follow Conventional Commits rules:');
    stderr.writeln('  "$firstLine"\n');
    stderr.writeln('Format required:');
    stderr.writeln('  <type>(<scope>): <subject>\n');
    stderr.writeln('Allowed types:');
    stderr.writeln('  feat:     A new feature (triggers MINOR version bump)');
    stderr.writeln('  fix:      A bug fix (triggers PATCH version bump)');
    stderr.writeln('  docs:     Documentation only changes');
    stderr.writeln('  style:    Code style changes (white-space, formatting, etc)');
    stderr.writeln('  refactor: Code change that neither fixes a bug nor adds a feature');
    stderr.writeln('  perf:     Code change that improves performance');
    stderr.writeln('  test:     Adding missing tests or correcting existing tests');
    stderr.writeln('  build:    Changes affecting build system or external dependencies');
    stderr.writeln('  ci:       CI configuration files and scripts');
    stderr.writeln('  chore:    Routine tasks, release commits, maintenance');
    stderr.writeln('  revert:   Revert a previous commit\n');
    stderr.writeln('Examples:');
    stderr.writeln('  feat(auction): add fast autocomplete search for players');
    stderr.writeln('  fix(parser): handle empty strings in Quotazioni importer');
    stderr.writeln('  chore(release): 1.0.0');
    stderr.writeln('  feat!: breaking change redesign of player entity\n');
    stderr.writeln('------------------------------------------------------------\n');
    exit(1);
  }

  // Check subject line length
  if (firstLine.length > 100) {
    stderr.writeln('Warning: First line of commit message is longer than 100 characters.');
  }

  exit(0);
}
