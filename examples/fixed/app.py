"""Fixed version for the local P9 DevSecOps demonstration."""
import os
import sqlite3

from flask import Flask, request

app = Flask(__name__)
DB_PATH = os.environ.get("DB_PATH", "/tmp/p9-demo.db")


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT, role TEXT)")
    conn.execute("INSERT INTO users (username, role) SELECT 'admin', 'admin' WHERE NOT EXISTS (SELECT 1 FROM users)")
    conn.commit()
    return conn


@app.route("/")
def home():
    return "DevSecOps demo app is running. Try /user?name=admin"


@app.route("/user")
def get_user():
    name = request.args.get("name", "")
    conn = get_db()
    try:
        rows = conn.execute(
            "SELECT id, username, role FROM users WHERE username = ?", (name,)
        ).fetchall()
        return {"results": rows}
    finally:
        conn.close()


@app.route("/health")
def health():
    return {"status": "ok"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
