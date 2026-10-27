// Exercise the package through its public API, without Swan or a file database.
import std;
import sqlite from "..";

var checks: i64 = 0;

fn check(ok: bool, label: const u8[:]) {
    if !ok { abort(str("FAIL: ", label)); }
    checks += 1;
}

fn scalar(db: i64, sql: const u8[:]) -> i64 {
    var err: u8[>..] = [];
    let st = sqlite::prepare_or_die(db, sql);
    check(sqlite::step(st, err) == 1, "scalar returns one row");
    let result = sqlite::col_int(st, 0);
    check(sqlite::step(st, err) == 0, "scalar ends");
    sqlite::finalize(st);
    return result;
}

fn main() {
    var err: u8[>..] = [];
    check(sqlite::open("", err) == 0, "empty path rejected");
    check(err == "bad path", "open error text");
    err.clear();
    let db = sqlite::open(":memory:", err);
    check(db != 0 && err.len == 0, "open in-memory database");
    check(sqlite::exec(db, "CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE);", err), "create schema");

    // Parameters preserve quotes, UTF-8, embedded NUL, and 64-bit integers.
    let insert = sqlite::prepare_or_die(db, "INSERT INTO t (id, name) VALUES (?1, ?2)");
    var name: u8[>..] = [];
    format(name, "O'Reilly — Goose");
    name.push(0);
    format(name, "tail");
    check(sqlite::bind_int(insert, 1, 5000000000), "bind 64-bit id");
    check(sqlite::bind_text(insert, 2, name), "bind text");
    // SQLITE_TRANSIENT must own a copy rather than retain this builder's bytes.
    name.clear();
    format(name, "changed after bind");
    check(!sqlite::bind_int(insert, 3, 1), "invalid parameter rejected");
    check(sqlite::step(insert, err) == 0, "insert is done");
    check(sqlite::last_rowid(db) == 5000000000, "last_rowid preserves 64-bit value");
    sqlite::reset(insert);
    check(sqlite::bind_int(insert, 1, -7), "rebind id");
    check(sqlite::bind_text(insert, 2, "swan"), "rebind text");
    sqlite::step_done(insert);
    sqlite::finalize(insert);

    let select = sqlite::prepare_or_die(db, "SELECT name FROM t WHERE id = ?1");
    check(sqlite::bind_int(select, 1, 5000000000), "bind select");
    check(sqlite::step(select, err) == 1, "select row");
    var got: u8[>..] = [];
    format(got, "prefix:");
    sqlite::col_text(select, 0, got);
    var expected: u8[>..] = [];
    format(expected, "prefix:O'Reilly — Goose");
    expected.push(0);
    format(expected, "tail");
    check(got == expected, "col_text appends exact bytes; binding owns text");
    check(sqlite::step(select, err) == 0, "select ends");
    sqlite::reset(select);
    check(sqlite::step(select, err) == 0, "reset clears select binding");
    sqlite::finalize(select);
    print("PASS bindings, text bytes, row iteration, reset, last_rowid");

    // A reset clears every binding, including one not rebound by the caller.
    let parameters = sqlite::prepare_or_die(db, "SELECT ?1 IS NULL, ?2 IS NULL");
    check(sqlite::bind_int(parameters, 1, 9), "bind first parameter");
    check(sqlite::bind_text(parameters, 2, "x"), "bind second parameter");
    check(sqlite::step(parameters, err) == 1, "bound parameters row");
    check(sqlite::col_int(parameters, 0) == 0 && sqlite::col_int(parameters, 1) == 0, "both parameters bound");
    sqlite::reset(parameters);
    check(sqlite::step(parameters, err) == 1, "reset parameters row");
    check(sqlite::col_int(parameters, 0) == 1 && sqlite::col_int(parameters, 1) == 1, "reset clears both bindings");
    sqlite::finalize(parameters);

    check(sqlite::exec(db, "BEGIN; INSERT INTO t VALUES (3, 'rolled back'); ROLLBACK;", err), "multi-statement rollback");
    check(scalar(db, "SELECT count(*) FROM t") == 2, "rollback restores row count");
    sqlite::exec_or_die(db, "BEGIN; INSERT INTO t VALUES (4, 'committed'); COMMIT;");
    check(scalar(db, "SELECT count(*) FROM t") == 3, "commit persists row");
    print("PASS transactions and multi-statement exec");

    check(sqlite::prepare(db, "SELECT FROM", err) == 0, "invalid SQL prepare fails");
    check(err.len > 0, "prepare error reported");
    err.clear();
    check(!sqlite::exec(db, "INSERT INTO no_such_table VALUES (1)", err), "exec error reported");
    check(err.len > 0, "exec error text");
    err.clear();
    let duplicate = sqlite::prepare_or_die(db, "INSERT INTO t VALUES (?1, ?2)");
    check(sqlite::bind_int(duplicate, 1, 4), "bind duplicate id");
    check(sqlite::bind_text(duplicate, 2, "duplicate"), "bind duplicate name");
    check(sqlite::step(duplicate, err) == -1, "constraint violation returns -1");
    check(err.len > 0, "step error text");
    err.clear();
    sqlite::reset(duplicate);
    check(sqlite::bind_int(duplicate, 1, 5), "rebind after failed step");
    check(sqlite::bind_text(duplicate, 2, "recovered"), "rebind text after failed step");
    check(sqlite::step(duplicate, err) == 0, "statement reusable after error/reset");
    sqlite::finalize(duplicate);
    check(scalar(db, "SELECT count(*) FROM t") == 4, "failed insert did not add row");
    // A NUL ends the SQL (SQLite reads no further): trailing NULs are the
    // end, text after one is an error; neither may loop forever.
    var nul_sql: u8[>..] = [];
    format(nul_sql, "SELECT 1;");
    nul_sql.push(0);
    check(sqlite::exec(db, nul_sql, err), "exec stops at a trailing NUL");
    format(nul_sql, "SELECT 2;");
    check(!sqlite::exec(db, nul_sql, err), "exec refuses SQL after a NUL");
    check(err == "SQL holds a NUL byte", "NUL error text");
    err.clear();
    // step_done finishes a statement that returns rows.
    let returning = sqlite::prepare_or_die(db, "INSERT INTO t (id, name) VALUES (?1, ?2) RETURNING id");
    check(sqlite::bind_int(returning, 1, 6), "bind RETURNING id");
    check(sqlite::bind_text(returning, 2, "returned"), "bind RETURNING name");
    sqlite::step_done(returning);
    sqlite::finalize(returning);
    check(scalar(db, "SELECT count(*) FROM t WHERE id = 6") == 1, "step_done ran the RETURNING insert");
    sqlite::close(db);
    print("PASS error paths and recovery");
    print("goose-sqlite: ", checks, " standalone API checks passed");
}
