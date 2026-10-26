# goose-sqlite

[SQLite](https://sqlite.org) for [Goose](https://aardappel.github.io/goose/)
programs: a Goose API and helpers over a thin C shim and the SQLite 3.54.1
C amalgamation in `vendor/`. It can be imported independently of Swan,
tree-sitter, or any language server.

The first build that uses SQLite compiles its native sources. Goose caches
that native build for reuse by compatible later builds; a cold cache or
changed native inputs requires recompilation. The small Goose layer is
compiled with the consuming program. This is a Goose package around SQLite,
not a rewrite of SQLite in Goose.

## Use

In your root file:

```goose
import sqlite from "shetautnetjer/goose-sqlite@v0.1.0";
```

```goose
var err: u8[>..] = [];
let db = sqlite::open("map.db", err);              // 0 on failure, the reason in err
sqlite::exec_or_die(db, "CREATE TABLE IF NOT EXISTS t (id INTEGER PRIMARY KEY, name TEXT)");
let st = sqlite::prepare_or_die(db, "SELECT name FROM t WHERE id = ?1");
sqlite::bind_int(st, 1, 7);
var out: u8[>..] = [];
while sqlite::step(st, err) == 1 { sqlite::col_text(st, 0, out); }
sqlite::finalize(st);
sqlite::close(db);
```

A database or statement is an i64 handle. `open`, `close`, `exec`, `prepare`,
`bind_text`, `bind_int`, `step` (1 a row, 0 done, -1 an error), `col_int`,
`col_text` (appends), `reset`, `finalize`, `last_rowid`, and `exec_or_die`,
`prepare_or_die`, `step_done` for statements whose failure is a bug. See
`examples/hello.goose`.

Built with `SQLITE_OMIT_LOAD_EXTENSION`, `SQLITE_THREADSAFE=0`,
`SQLITE_DQS=0` and `SQLITE_DEFAULT_MEMSTATUS=0`.

The caller owns each handle: finalize statements and close databases, and
do not reuse released handles. `reset` also clears parameter bindings.
Text and error builders are appended to, so clear them when starting a new
result. SQLite mutexes are disabled; callers must serialize access to this
package across threads. The API does not provide automatic lifetime or
transaction management.

## Standalone tests

With Goose v2026.3 and a C compiler already installed:

```bash
GOOSE=/path/to/goose scripts/test.sh
```

The test imports this checkout with `import sqlite from "..";` and uses an
in-memory database. It covers parameter binding, exact text bytes and copied
bindings, 64-bit values, row iteration, statement reset, transaction
commit/rollback, SQL errors, constraint errors, and recovery after a failed
step. Swan and external services are not required. Builds run offline;
the runner defaults to `.test-build/` for outputs and its Goose cache.
Set `TEST_BUILD_DIR` and `GOOSE_HOME` to reuse other local output/cache paths.
The package sidecar excludes `tests/`, keeping test entry points out of
consuming programs.

## License

The shim and package: MIT. SQLite is in the public domain
(https://sqlite.org/copyright.html). Swan (https://github.com/shetautnetjer/Swan)
is its first user.
