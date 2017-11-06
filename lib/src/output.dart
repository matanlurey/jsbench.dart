// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:kilobyte/kilobyte.dart';

abstract class FileProxy {
  FileProxy relative(String relative);
  bool exists();
  String get path;
  int get size;
  String readAsStringSync();
}

class JsOutput {
  /// The `.dart.js` file on disk.
  final FileProxy file;

  // Cached attributes.
  bool _hasDumpFile;
  Size _size;

  JsOutput(this.file);

  @override
  bool operator ==(Object o) => o is JsOutput && file.path == o.file.path;

  @override
  int get hashCode => file.path.hashCode;

  FileProxy get _dumpFile => file.relative('${file.path}.info.json');

  /// Whether a `{file}.info.json` file exists relative to [file].
  ///
  /// If `true`, may use [readDump].
  bool get hasDumpFile => _hasDumpFile ??= _dumpFile.exists();

  /// Reads the `.info.json` file from disk.
  JsOutputDump readDump() {
    final Map<String, dynamic> json = JSON.decode(_dumpFile.readAsStringSync());
    final Map<String, Map<String, dynamic>> libs = json['elements']['library'];
    final results = <JsOutputDumpLibrary>[];
    libs.forEach((_, Map<String, dynamic> info) {
      results.add(
        new JsOutputDumpLibrary._(
          info['canonicalUri'] as String,
          new Size(bytes: info['size'] as int),
        ),
      );
    });
    return new JsOutputDump._(
      results,
      size,
      minified: json['program']['minified'] as bool,
      noSuchMethodEnabled: json['program']['noSuchMethodEnabled'] as bool,
    );
  }

  /// Total size of the [file] on disk.
  Size get size => _size ??= new Size(bytes: file.size);

  @override
  String toString() => 'JsOutput {${file.path}}';
}

class JsOutputDump {
  final List<JsOutputDumpLibrary> _libraries;
  final Size _outputSize;

  const JsOutputDump._(
    this._libraries,
    this._outputSize, {
    this.minified,
    this.noSuchMethodEnabled,
  });

  /// Libraries in descending order of size (i.e. largest first).
  Iterable<JsOutputDumpLibrary> get orderedLibraries {
    final libs = _libraries.toList()..sort();
    return libs.reversed;
  }

  /// Size not accounted for in any source file (i.e. overhead of the compiler).
  Size get compiledOverhead {
    final size = _libraries.fold<int>(0, (b, lib) => b + lib.size.inBytes);
    return new Size(bytes: _outputSize.inBytes - size);
  }

  /// Whether the output is minified.
  final bool minified;

  /// Whether the output had to support `noSuchMethod`.
  final bool noSuchMethodEnabled;
}

Iterable<JsOutputDumpLibrary> collapse(
  Iterable<JsOutputDumpLibrary> libs,
) sync* {
  final collate = <String, List<JsOutputDumpLibrary>>{};
  for (final lib in libs) {
    if (lib.url.startsWith('package:')) {
      final url = Uri.parse(lib.url);
      collate.putIfAbsent(url.pathSegments.first, () => []).add(lib);
    } else {
      yield lib;
    }
  }
  for (final name in collate.keys) {
    yield new JsOutputDumpLibrary._(
      'package:$name',
      new Size(bytes: collate[name].fold<int>(0, (b, l) => b + l.size.inBytes)),
    );
  }
}

class JsOutputDumpLibrary implements Comparable<JsOutputDumpLibrary> {
  final String url;
  final Size size;

  const JsOutputDumpLibrary._(this.url, this.size);

  @override
  int compareTo(JsOutputDumpLibrary o) => size.compareTo(o.size);

  @override
  bool operator ==(Object o) => o is JsOutputDumpLibrary && url == o.url;

  @override
  int get hashCode => url.hashCode;
}
