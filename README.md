# Mavenize eXist

Creates a Mavenized project layout for eXist.

```bash
$ git clone https://github.com/adamretter/mavenize-exist.git
```

Edit the file `mavenize.sh` and set the variable `SRC_DIR` to a local git clone of https://github.com/exist-db/exist.git, e.g.:


```bash
SRC_DIR=/Users/aretter/code/exist-for-release
```

You must have compiled the local eXist-db clone at least once using `build.sh`.

You can then run `./mavenize.sh`. A Mavenized version of eXist-db will then be present in the `target/` sub-folder.
