// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart' show Archive, TarDecoder;
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'archives.dart';

/// An implementation of [ArchiveFormat] for `.tar` (Tar) files.
class TarArchiveFormat extends ArchiveFormat {
  const TarArchiveFormat();

  @override
  final extensions = const ['.tar'];

  @override
  ArchiveReader read(String path) {
    final bytes = new File(path).readAsBytesSync();
    final archive = new TarDecoder().decodeBytes(bytes);
    return new _ArchiveReader(archive);
  }
}

/// A generic implementation of [ArchiveReader] using `package:archive`.
class _ArchiveReader implements ArchiveReader {
  final Archive _archive;

  _ArchiveReader(this._archive);

  @override
  Iterable<String> listFiles([String path]) {
    if (path != null) {
      return _listFilesIn(path);
    }
    return _archive
        .map((f) => f.name)
        // Ignore special classes of OS-dependent files we don't care about.
        .where((f) => !f.startsWith('./._'));
  }

  Iterable<String> _listFilesIn(String path) {
    return listFiles().where((f) => p.isWithin(path, f));
  }

  @override
  String readAsString(String path, {Encoding encoding: UTF8}) {
    final List<int> content = _archive.findFile(path).content;
    return encoding.decode(content);
  }
}

class FileFinder {
  final List<Glob> include;
  final List<Glob> exclude;
  final List<ArchiveFormat> archives;

  final _archiveCache = <String, ArchiveReader>{};

  /// Creates a new finder with CLI provided arguments.
  factory FileFinder(
    List<String> include, {
    List<String> exclude: const [],
    List<String> archive: const [],
  }) {
    var formats = const <ArchiveFormat>[];
    if (archive.isNotEmpty) {
      // Make a copy of 'include' to augment further.
      include = include.toList();
      formats = archive.map((name) {
        final format = const {
          'tar': const TarArchiveFormat(),
        }[name];
        if (format == null) {
          throw new UnsupportedError('Unsupported archive format: $name');
        }
        return format;
      }).toList();
      final newIncludes = <String>[];
      for (final format in formats) {
        for (final pattern in include) {
          final parts = p.split(pattern);
          if (!parts.last.contains('*')) {
            continue;
          }
          final wildcard = parts.last.contains('**') ? '**' : '*';
          for (final extension in format.extensions) {
            final newParts = parts.toList();
            newParts[parts.length - 1] = '$wildcard$extension';
            newIncludes.add(p.joinAll(newParts));
          }
        }
      }
      include.addAll(newIncludes);
    }
    return new FileFinder._(
      include.map((p) => new Glob(p)).toList(),
      exclude.map((p) => new Glob(p)).toList(),
      formats,
    );
  }

  FileFinder._(this.include, this.exclude, this.archives);

  bool _isArchive(String path) => archives.any((a) => a.isFormat(path));

  bool _isInput(String path) {
    print('>>> _isInput($path)');
    return include.any((g) => g.matches(path));
  }

  bool _isNotExcluded(String path) => !exclude.any((g) => g.matches(path));

  /// Returns whether [path] exists on disk or in an archive.
  bool exists(String path) {
    // TODO: Implement better.
    try {
      readAsString(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns paths to all matching files.
  ///
  /// **NOTE**: If [archives] was supplied, some files do not exist on disk.
  Iterable<String> find() sync* {
    for (final file in _findIncludes()) {
      if (_isArchive(file.path)) {
        yield* _findArchived(file.path)
            .where((path) => !_isArchive(path))
            .map((path) => p.join(file.path, path))
            .where(_isInput);
      } else {
        yield file.path;
      }
    }
  }

  /// Reads the file at [path] as a string (UTF8).
  String readAsString(String path) {
    if (_archiveCache.isEmpty) {
      return new File(path).readAsStringSync();
    }
    for (final archive in _archiveCache.keys) {
      if (p.isWithin(archive, path)) {
        final reader = _archiveCache[archive];
        return reader.readAsString(p.relative(path, from: archive));
      }
    }
    return new File(path).readAsStringSync();
  }

  ArchiveReader _readArchive(String path) => _archiveCache.putIfAbsent(
      path, () => archives.firstWhere((f) => f.isFormat(path)).read(path));

  Iterable<String> _findArchived(String path) => _readArchive(path).listFiles();

  Iterable<File> _findIncludes() => include.map(_findMatches).expand((i) => i);

  Iterable<File> _findMatches(Glob pattern) {
    try {
      return pattern
          .listSync()
          .where((file) => file is File)
          .where((file) => _isNotExcluded(file.path)) as Iterable<File>;
    } on FileSystemException catch (_) {
      return const [];
    }
  }
}
