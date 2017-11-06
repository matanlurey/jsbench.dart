// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:kilobyte/kilobyte.dart';
import 'package:path/path.dart' as p;

import 'package:jsbench/src/finder.dart';
import 'package:jsbench/src/output.dart';

Future<Null> main(List<String> args) async {
  final results = _parser.parse(args);
  if (results['version'] == true) {
    stdout.writeln('jsbench version: 0.2.0');
    return;
  }
  if (results['help'] == true) {
    stdout.writeln(_parser.usage);
    return;
  }
  final dumpTrivialSize = new Size(
    bytes: int.parse(results['dump-trivial-size'] as String),
  );
  final bool collapsePackages = results['collapse-package'];
  final excludes = (results['exclude'] as List<String>);
  final includes = (results['input'] as List<String>);
  final archive = (results['archive'] as List<String>) ?? const [];
  final finder = new FileFinder(includes, exclude: excludes, archive: archive);
  final inputs = finder.find().toList();
  if (inputs.isEmpty) {
    stderr.writeln('No files found in $includes (exclude=$excludes).');
    exitCode = 1;
    return;
  }
  final checkDumpInfo = results['dump'] != false;
  for (final path in inputs) {
    final buffer = new StringBuffer();

    void writeRow(String f1, [String f2 = '', String f3 = '']) {
      buffer
        ..write(' | ')
        ..write(f1)
        ..write(' ' * (40 - f1.length))
        ..write(' | ')
        ..write(f2)
        ..write(' ' * (10 - f2.length))
        ..write(' | ')
        ..write(f3)
        ..write(' ' * (10 - f3.length))
        ..writeln(' | ');
    }

    void writeSeparator() {
      writeRow('-' * 40, '-' * 10, '-' * 10);
    }

    final proxy = new _FileProxy(path, finder);
    final output = new JsOutput(proxy);

    String formatAsPercent(num amount) {
      final percentNum = ((amount / output.size.inBytes) * 100);
      var percent = percentNum.toStringAsFixed(1);
      if (percentNum < 10) {
        percent = '0$percent';
      }
      return '$percent%';
    }

    writeRow(p.basename(proxy.path), output.size.toString(), '');
    writeSeparator();

    if (checkDumpInfo && output.hasDumpFile) {
      final dump = output.readDump();
      writeRow(
        'compiler overhead',
        dump.compiledOverhead.toString(),
        formatAsPercent(dump.compiledOverhead.inBytes),
      );
      writeRow('minified?', dump.minified ? 'Yes' : 'No');
      writeRow('noSuchMethod?', dump.noSuchMethodEnabled ? 'Yes' : 'No');
      writeSeparator();
      var libs = dump.orderedLibraries;
      if (collapsePackages) {
        libs = (collapse(libs).toList()..sort()).reversed;
      }
      for (final source in libs.where((lib) => lib.size >= dumpTrivialSize)) {
        writeRow(
          source.url,
          source.size.toString(),
          formatAsPercent(source.size.inBytes),
        );
      }
    }
    stdout.writeln(buffer);
  }
}

class _FileProxy implements FileProxy {
  final FileFinder _finder;
  String _stringContents;

  _FileProxy(this.path, this._finder);

  @override
  bool exists() => _finder.exists(path);

  @override
  final String path;

  @override
  String readAsStringSync() => _stringContents ??= _finder.readAsString(path);

  @override
  FileProxy relative(String relative) {
    return new _FileProxy(relative, _finder);
  }

  @override
  int get size => readAsStringSync().length;
}

final _parser = new ArgParser()
  ..addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Display usage information.',
  )
  ..addFlag(
    'version',
    negatable: false,
    help: 'Display version information.',
  )
  ..addFlag(
    'dump',
    defaultsTo: null,
    help: ''
        'Read {input}.info.json files to determine size contributions.\n'
        '(defaults to whether .info.json files are found on disk)',
  )
  ..addFlag(
    'collapse-package',
    defaultsTo: true,
    help: 'Collapse all libraries from a package into one.',
  )
  ..addOption(
    'dump-trivial-size',
    defaultsTo: new Size(kilobytes: 1).inBytes.toString(),
    help: 'Byte sizes smaller than this amount are ignored with --dump.',
  )
  ..addOption(
    'input',
    abbr: 'i',
    defaultsTo: 'build/**.dart.js',
    allowMultiple: true,
    help: 'What pattern(s) to use to fining outputs.',
  )
  ..addOption(
    'exclude',
    abbr: 'e',
    defaultsTo: 'build/*/packages/**',
    allowMultiple: true,
    help: 'What pattern(s) to exclude when finding outputs.',
  )
  ..addOption(
    'archive',
    abbr: 'a',
    allowMultiple: true,
    allowed: ['tar'],
    help: 'Archive formats to search. By default this is not used.',
  );
