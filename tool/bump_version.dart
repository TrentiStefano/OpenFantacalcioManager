import 'dart:io';

class SemVer {
  final int major;
  final int minor;
  final int patch;
  final int build;

  const SemVer({
    required this.major,
    required this.minor,
    required this.patch,
    this.build = 1,
  });

  String get versionString => '$major.$minor.$patch';
  String get fullVersionString => '$major.$minor.$patch+$build';

  static SemVer parse(String text) {
    final clean = text.trim().replaceFirst('v', '');
    final plusParts = clean.split('+');
    final versionCore = plusParts[0];
    final buildNum = plusParts.length > 1 ? int.tryParse(plusParts[1]) ?? 1 : 1;

    final dotParts = versionCore.split('.');
    final major = dotParts.isNotEmpty ? int.tryParse(dotParts[0]) ?? 0 : 0;
    final minor = dotParts.length > 1 ? int.tryParse(dotParts[1]) ?? 0 : 0;
    final patch = dotParts.length > 2 ? int.tryParse(dotParts[2]) ?? 0 : 0;

    return SemVer(
      major: major,
      minor: minor,
      patch: patch,
      build: buildNum,
    );
  }

  SemVer bumpMajor() => SemVer(major: major + 1, minor: 0, patch: 0, build: build + 1);
  SemVer bumpMinor() => SemVer(major: major, minor: minor + 1, patch: 0, build: build + 1);
  SemVer bumpPatch() => SemVer(major: major, minor: minor, patch: patch + 1, build: build + 1);
  SemVer bumpBuild() => SemVer(major: major, minor: minor, patch: patch, build: build + 1);
}

void main(List<String> args) async {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('Error: pubspec.yaml not found.');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final versionRegex = RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?)', multiLine: true);
  final match = versionRegex.firstMatch(pubspecContent);

  if (match == null) {
    stderr.writeln('Error: version line not found in pubspec.yaml');
    exit(1);
  }

  final currentVer = SemVer.parse(match.group(1)!);

  if (args.contains('--get')) {
    stdout.writeln(currentVer.fullVersionString);
    exit(0);
  }

  if (args.contains('--get-version')) {
    stdout.writeln(currentVer.versionString);
    exit(0);
  }

  if (args.contains('--is-major-or-minor')) {
    // If patch is 0 (e.g. 1.0.0, 1.1.0, 2.0.0), it's a major or minor release
    if (currentVer.patch == 0) {
      stdout.writeln('true');
    } else {
      stdout.writeln('false');
    }
    exit(0);
  }

  if (args.contains('--extract-notes')) {
    final targetVer = args.length > args.indexOf('--extract-notes') + 1
        ? args[args.indexOf('--extract-notes') + 1]
        : currentVer.versionString;
    final notes = _extractNotesForVersion(targetVer);
    stdout.writeln(notes);
    exit(0);
  }

  String? explicitSet;
  String? bumpType;
  bool isAuto = false;
  bool isRelease = false;
  bool createTag = false;

  for (int i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--set' && i + 1 < args.length) {
      explicitSet = args[++i];
    } else if (arg == '--type' && i + 1 < args.length) {
      bumpType = args[++i].toLowerCase();
    } else if (arg == '--auto') {
      isAuto = true;
    } else if (arg == '--release') {
      isRelease = true;
      createTag = true;
    } else if (arg == '--tag') {
      createTag = true;
    }
  }

  SemVer nextVer = currentVer;

  if (explicitSet != null) {
    nextVer = SemVer.parse(explicitSet);
  } else if (bumpType != null) {
    switch (bumpType) {
      case 'major':
        nextVer = currentVer.bumpMajor();
        break;
      case 'minor':
        nextVer = currentVer.bumpMinor();
        break;
      case 'patch':
        nextVer = currentVer.bumpPatch();
        break;
      default:
        stderr.writeln('Unknown bump type: $bumpType (use major, minor, or patch)');
        exit(1);
    }
  } else if (isAuto) {
    final detectedType = await _detectBumpTypeFromGit();
    switch (detectedType) {
      case 'major':
        nextVer = currentVer.bumpMajor();
        break;
      case 'minor':
        nextVer = currentVer.bumpMinor();
        break;
      case 'patch':
      default:
        nextVer = currentVer.bumpPatch();
        break;
    }
    stdout.writeln('Auto-detected SemVer bump: $detectedType (${currentVer.versionString} -> ${nextVer.versionString})');
  }

  // Update pubspec.yaml
  final updatedPubspec = pubspecContent.replaceFirst(
    versionRegex,
    'version: ${nextVer.fullVersionString}',
  );
  pubspecFile.writeAsStringSync(updatedPubspec);
  stdout.writeln('Updated pubspec.yaml version to ${nextVer.fullVersionString}');

  // Update CHANGELOG.md
  await _updateChangelog(nextVer);

  // If --release is requested, create git commit and tag
  if (isRelease) {
    stdout.writeln('Creating release commit and tag for v${nextVer.versionString}...');
    await _runProcess('git', ['add', 'pubspec.yaml', 'CHANGELOG.md']);
    final commitMsg = 'chore(release): ${nextVer.versionString}';
    final res = await _runProcess('git', ['commit', '-m', commitMsg]);
    if (res.exitCode != 0) {
      stderr.writeln('Commit failed: ${res.stderr}');
      exit(res.exitCode);
    }
    if (createTag) {
      final tagRes = await _runProcess('git', ['tag', '-a', 'v${nextVer.versionString}', '-m', 'Release v${nextVer.versionString}']);
      if (tagRes.exitCode == 0) {
        stdout.writeln('Created git tag: v${nextVer.versionString}');
      }
    }
    stdout.writeln('🎉 Successfully released version v${nextVer.versionString}!');
  }
}

Future<String> _detectBumpTypeFromGit() async {
  // Find latest tag
  final tagRes = await Process.run('git', ['describe', '--tags', '--abbrev=0']);
  final latestTag = tagRes.exitCode == 0 ? (tagRes.stdout as String).trim() : null;

  final logArgs = ['log', '--no-merges', '--pretty=format:%B---COMMIT_END---'];
  if (latestTag != null && latestTag.isNotEmpty) {
    logArgs.add('$latestTag..HEAD');
  }

  final logRes = await Process.run('git', logArgs);
  final logOutput = logRes.exitCode == 0 ? (logRes.stdout as String) : '';
  final commits = logOutput.split('---COMMIT_END---').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();

  bool hasMajor = false;
  bool hasMinor = false;
  bool hasPatch = false;

  for (final commit in commits) {
    final firstLine = commit.split('\n').first.trim();
    if (commit.contains('BREAKING CHANGE:') || commit.contains('BREAKING-CHANGE:') || firstLine.contains('!:')) {
      hasMajor = true;
    } else if (firstLine.startsWith('feat')) {
      hasMinor = true;
    } else if (firstLine.startsWith('fix') || firstLine.startsWith('perf') || firstLine.startsWith('refactor')) {
      hasPatch = true;
    }
  }

  if (hasMajor) return 'major';
  if (hasMinor) return 'minor';
  if (hasPatch) return 'patch';
  return 'patch';
}

Future<void> _updateChangelog(SemVer version) async {
  final changelogFile = File('CHANGELOG.md');
  final existingContent = changelogFile.existsSync() ? changelogFile.readAsStringSync() : '';

  final now = DateTime.now();
  final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  // Read commits since last tag
  final tagRes = await Process.run('git', ['describe', '--tags', '--abbrev=0']);
  final latestTag = tagRes.exitCode == 0 ? (tagRes.stdout as String).trim() : null;

  final logArgs = ['log', '--no-merges', '--pretty=format:%s'];
  if (latestTag != null && latestTag.isNotEmpty) {
    logArgs.add('$latestTag..HEAD');
  }

  final logRes = await Process.run('git', logArgs);
  final commitLines = logRes.exitCode == 0
      ? (logRes.stdout as String).split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList()
      : <String>[];

  final features = <String>[];
  final fixes = <String>[];
  final others = <String>[];

  for (final msg in commitLines) {
    if (msg.startsWith('feat')) {
      features.add(msg);
    } else if (msg.startsWith('fix')) {
      fixes.add(msg);
    } else if (!msg.startsWith('chore(release)')) {
      others.add(msg);
    }
  }

  final buffer = StringBuffer();
  buffer.writeln('## [${version.versionString}] - $dateStr\n');

  if (features.isNotEmpty) {
    buffer.writeln('### 🚀 Features');
    for (final f in features) {
      buffer.writeln('- $f');
    }
    buffer.writeln();
  }

  if (fixes.isNotEmpty) {
    buffer.writeln('### 🐛 Bug Fixes');
    for (final f in fixes) {
      buffer.writeln('- $f');
    }
    buffer.writeln();
  }

  if (others.isNotEmpty) {
    buffer.writeln('### 🛠️ Maintenance & Improvements');
    for (final o in others) {
      buffer.writeln('- $o');
    }
    buffer.writeln();
  }

  if (features.isEmpty && fixes.isEmpty && others.isEmpty) {
    buffer.writeln('- Initial release of Open Fantacalcio Manager v${version.versionString}\n');
  }

  final newEntry = buffer.toString();
  if (!existingContent.contains('## [${version.versionString}]')) {
    final updated = '# Changelog\n\nAll notable changes to Open Fantacalcio Manager are documented here.\nFormat is based on [Keep a Changelog](https://keepachangelog.com/) and adheres to [Semantic Versioning](https://semver.org/).\n\n$newEntry' +
        existingContent.replaceFirst(RegExp(r'^# Changelog\s*', multiLine: true), '');
    changelogFile.writeAsStringSync(updated.trim() + '\n');
    stdout.writeln('Updated CHANGELOG.md for v${version.versionString}');
  }
}

Future<ProcessResult> _runProcess(String exe, List<String> args) async {
  return await Process.run(exe, args);
}

String _extractNotesForVersion(String version) {
  final cleanVer = version.trim().replaceFirst('v', '').split('+').first;
  final changelogFile = File('CHANGELOG.md');
  if (!changelogFile.existsSync()) {
    return 'Release $version';
  }

  final content = changelogFile.readAsStringSync().replaceAll('\r\n', '\n');
  final pattern = RegExp(
    r'## \[' + RegExp.escape(cleanVer) + r'\][^\n]*\n([\s\S]*?)(?=\n## \[|$)',
  );
  final match = pattern.firstMatch(content);
  if (match != null && match.group(1)!.trim().isNotEmpty) {
    return match.group(1)!.trim();
  }
  return 'Release v$cleanVer';
}
