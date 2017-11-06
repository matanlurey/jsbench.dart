## 0.2.1

* Supports reading from the `.tar` file format when `--archive=tar` is passed.

This is an _experimental_ feature that has only been tested on UNIX systems; it
allows listing and reading files from within supported archive formats as-if
the archive was just a folder on disk. Imagine the following:

```
output/
  bar.dart.js
  build.tar
```

Previously, `jsbench` would only "see" `output/bar.dart.js`.

Now, `jsbench --archive=tar` would _also_ read the contents of `build.tar` and
process as-if `build.tar` was actually the name of a folder. So, if there was a
`.dart.js` file in, it would also be found and processed by `jsbench`.

## 0.2.0

* Collapses libraries from a package. Use `--no-collapse-package` to opt-out.

## 0.1.0

* Initial commit. See `README.md` for example usage.
