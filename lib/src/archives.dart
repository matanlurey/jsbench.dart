// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

// Utilities around working with and accessing archive formats (i.e. `.tar`).
//
// This sub-library intentionally is not opinionated on _how_ to read from
// archive formats - this is to allow switching to/from `package:archive`
// depending on how performance looks - especially on large archive files.

/// A supported archive format for reading and listing files.
abstract class ArchiveFormat {
  const ArchiveFormat();

  /// Extension formats to explicitly support for this archive format.
  ///
  /// Reading the first few bits of a file is more conclusive, but this often
  /// faster/simpler assuming that the naming of archive files is consistent.
  List<String> get extensions;

  /// Whether [path] represents this archive format.
  ///
  /// The default implementation just checks [extensions].
  bool isFormat(String path) => extensions.any(path.endsWith);

  /// Returns a reader for the archive file at [path].
  ArchiveReader read(String path);
}

/// Narrow interface from listing and reading files from an archive format.
///
/// It may be assumed that this class is _stateful_ (i.e. uses in-memory cache).
abstract class ArchiveReader {
  /// Returns a list of file names within this archive.
  ///
  /// If [path] is provided, then it is treated as the sub-directory to search.
  Iterable<String> listFiles([String path]);

  /// Returns the string content of the file in [path].
  String readAsString(String path, {Encoding encoding: UTF8});
}
