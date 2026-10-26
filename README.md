# goose-sqlite

[SQLite](https://sqlite.org) for [Goose](https://aardappel.github.io/goose/)
programs: the amalgamation (3.54.1, in `vendor/`) and a thin C shim, as a
Goose package. Its native part is built once per C compiler and cached by
Goose, so SQLite's 9 MB of C never adds to your program's build.

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

## License

The shim and package: MIT. SQLite is in the public domain
(https://sqlite.org/copyright.html). Swan (https://github.com/shetautnetjer/Swan)
is its first user.
