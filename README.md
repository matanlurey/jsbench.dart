# `jsbench`

A minimal Dart -> JavaScript size and performance tool.

This library assumes you are either using `pub build` or a similar tool to
generate `.dart.js` files from `.dart` files, but otherwise makes no other
assumptions. It is recommended to use `--dump-info` to output additional
information about the compilation.

## Example

The following is an example of running `jsbench` on this repository:

```bash
$ pub build
$ pub run jsbench
```

 | main.dart.js                             | 35.9 kB    |            |
 | ---------------------------------------- | ---------- | ---------- |
 | compiler overhead                        | 16.6 kB    | 46.1%      |
 | minified?                                | Yes        |            |
 | noSuchMethod?                            | No         |            |
 | ---------------------------------------- | ---------- | ---------- |
 | dart:_js_helper                          | 10.9 kB    | 30.3%      |
 | dart:html                                | 3.39 kB    | 09.4%      |
 | dart:core                                | 2.47 kB    | 06.9%      |
 | dart:_interceptors                       | 2.06 kB    | 05.7%      |

## Usage

This tool should either be used via [`pub global activate`][activate] or as
part of your [`dev_dependencies`][dev_dependencies].

[activate]: https://www.dartlang.org/tools/pub/cmd/pub-global#activating-a-package
[dev_dependencies]: https://www.dartlang.org/tools/pub/dependencies#dev-dependencies

Then, build your application, and run `jsbench`. For example:

```bash
$ pub build
$ pub run jsbench
```

To get more interesting information (not just disk size), add `--dump-info`:

```yaml
transformers:
  - $dart2js:
      commandLineOptions:
          - --dump-info
```

See this packages' `pubspec.yaml` for an example.

If you want _more_ information check out [`dump-info-visualizer`][dump-site].

[dump-site]: https://github.com/dart-lang/dump-info-visualizer

### Flags

`--no-dump`: Ignores all `.info.json` files on disk.

`--no-collapse-package`: Do not collapse all `package:<name>` libraries.

`--dump-trivial-size`: Threshold number of bytes to print out a library name.

`--input`: Glob pattern(s) to find emitted JavaScript files.

`--exclude` Glob pattern(s) to exclude when finding inputs.

`--archive`: Archive formats to recursively read from when finding inputs. Only
`tar` is currently supported.
