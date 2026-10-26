// goose build examples/hello.goose -o hello && ./hello
import std;
import sqlite from "..";

fn main() {
    var err: u8[>..] = [];
    let db = sqlite::open(":memory:", err);
    guard db != 0 else { abort(str("open: ", err)); }
    sqlite::exec_or_die(db, "CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT); INSERT INTO t (name) VALUES ('goose'), ('swan');");
    let st = sqlite::prepare_or_die(db, "SELECT id, name FROM t ORDER BY id");
    var out: u8[>..] = [];
    while sqlite::step(st, err) == 1 {
        format(out, sqlite::col_int(st, 0), " ");
        sqlite::col_text(st, 1, out);
        out.push('\n');
    }
    sqlite::finalize(st);
    sqlite::close(db);
    print(out);
    assert(out == "1 goose\n2 swan\n");
}
