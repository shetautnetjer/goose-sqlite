// SQLite for Goose: the vendored amalgamation (vendor/, version 3.54.1) and a
// thin C shim (src/gsq.c). A database or a prepared statement is an i64
// handle; 0 means it failed and the reason is in `err`.
//
//   import sqlite from "shetautnetjer/goose-sqlite@v0.1.1";   // in the root file
//   let db = sqlite::open("map.db", err);
//   let st = sqlite::prepare(db, "SELECT name FROM t WHERE id = ?1", err);
//   sqlite::bind_int(st, 1, 7);
//   while sqlite::step(st, err) == 1 { sqlite::col_text(st, 0, out); }
//   sqlite::finalize(st);

namespace sqlite;

import std;

extern "gsq_open" fn open(path: const u8[:], err: u8[>..]&) -> i64;   // creates the file if needed
extern "gsq_close" fn close(db: i64);
extern "gsq_exec" fn exec(db: i64, sql: const u8[:], err: u8[>..]&) -> bool;   // one or more statements
extern "gsq_prepare" fn prepare(db: i64, sql: const u8[:], err: u8[>..]&) -> i64;
extern "gsq_bind_text" fn bind_text(st: i64, i: i32, v: const u8[:]) -> bool;   // parameters count from 1
extern "gsq_bind_int" fn bind_int(st: i64, i: i32, v: i64) -> bool;
extern "gsq_step" fn step(st: i64, err: u8[>..]&) -> i32;     // 1 a row, 0 done, -1 an error
extern "gsq_col_int" fn col_int(st: i64, i: i32) -> i64;      // columns count from 0
extern "gsq_col_text" fn col_text(st: i64, i: i32, out: u8[>..]&);   // appends
extern "gsq_reset" fn reset(st: i64);                          // and clears the bindings
extern "gsq_finalize" fn finalize(st: i64);
extern "gsq_last_rowid" fn last_rowid(db: i64) -> i64;

// The same, aborting with SQLite's message on failure: for statements that
// are part of the program, where failing is a bug.
fn exec_or_die(db: i64, sql: const u8[:]) {
    var err: u8[>..] = [];
    if !exec(db, sql, err) { abort(str("sqlite: ", err, " in: ", sql)); }
}

fn prepare_or_die(db: i64, sql: const u8[:]) -> i64 {
    var err: u8[>..] = [];
    let st = prepare(db, sql, err);
    if st == 0 { abort(str("sqlite: ", err, " in: ", sql)); }
    return st;
}

// Runs an insert or update that was bound already, then resets it.
fn step_done(st: i64) {
    var err: u8[>..] = [];
    if step(st, err) < 0 { abort(str("sqlite: ", err)); }
    reset(st);
}
