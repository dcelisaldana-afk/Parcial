"""Traduce el script MySQL del proyecto a SQLite y registra funciones MySQL (solo para verificar)."""
import re, sqlite3, hashlib, uuid, random
from datetime import datetime, timedelta, date

def _parse(s):
    if s is None: return None
    s = str(s)
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d"):
        try: return datetime.strptime(s[:19] if ' ' in s else s[:10], fmt)
        except ValueError: pass
    return None

def _date_add(a, n):
    d = _parse(a)
    if d is None or n is None: return None
    d = d + timedelta(days=int(n))
    return d.strftime("%Y-%m-%d %H:%M:%S") if (a and ' ' in str(a)) else d.strftime("%Y-%m-%d")

def _datediff(a, b):
    da, db = _parse(a), _parse(b)
    if da is None or db is None: return None
    return (da.date() - db.date()).days

def _dayofweek(a):
    d = _parse(a)
    return None if d is None else (d.isoweekday() % 7) + 1

def register(con):
    f = con.create_function
    f("NOW", 0, lambda: datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    f("CURDATE", 0, lambda: date.today().strftime("%Y-%m-%d"))
    f("DATE_ADD", 2, _date_add)
    f("DATEDIFF", 2, _datediff)
    f("DAYOFWEEK", 1, _dayofweek)
    f("SHA2", 2, lambda s, b: None if s is None else hashlib.sha256(str(s).encode()).hexdigest())
    f("MD5", 1, lambda s: None if s is None else hashlib.md5(str(s).encode()).hexdigest())
    f("UUID", 0, lambda: str(uuid.uuid4()))
    f("RAND", 0, random.random)
    f("SUBSTRING", 3, lambda s, a, b: None if s is None else str(s)[int(a)-1:int(a)-1+int(b)])
    f("IF", 3, lambda c, a, b: a if c else b)
    f("DATE", 1, lambda a: None if _parse(a) is None else _parse(a).strftime("%Y-%m-%d"))
    f("LAST_INSERT_ID", 0, lambda: con.execute("select last_insert_rowid()").fetchone()[0])
    def concat(*a):
        if any(x is None for x in a): return None
        return "".join(str(x) for x in a)
    f("CONCAT", -1, concat)
    def concat_ws(sep, *a):
        if sep is None: return None
        return str(sep).join(str(x) for x in a if x is not None)
    f("CONCAT_WS", -1, concat_ws)

def translate_sql(sql):
    """Traduce una sentencia DML/consulta MySQL del proyecto a SQLite."""
    sql = re.sub(r",\s*INTERVAL\s+", ", ", sql, flags=re.I)
    sql = re.sub(r"\s+DAY\)", ")", sql, flags=re.I)
    return sql

def translate_ddl(text):
    out = []
    for line in text.splitlines():
        if re.match(r"\s*(SET NAMES|SET FOREIGN_KEY_CHECKS|DROP DATABASE|CREATE DATABASE|USE )", line, re.I):
            continue
        out.append(line)
    t = "\n".join(out)
    t = re.sub(r"\)\s*ENGINE=InnoDB", ")", t)
    t = re.sub(r"INT AUTO_INCREMENT PRIMARY KEY", "INTEGER PRIMARY KEY AUTOINCREMENT", t)
    t = re.sub(r"ENUM\([^)]*\)", "TEXT", t)
    return translate_sql(t)

def make_db(sql_path):
    con = sqlite3.connect(":memory:", check_same_thread=False)
    con.isolation_level = None
    register(con)
    text = open(sql_path, encoding="utf-8").read()
    t = translate_ddl(text)
    con.execute("PRAGMA foreign_keys=ON")
    con.executescript(t)
    return con

if __name__ == "__main__":
    import sys
    c = make_db(sys.argv[1])
    for (n,) in c.execute("select name from sqlite_master where type='table' and name not like 'sqlite_%' order by 1"):
        print(n, c.execute(f"select count(*) from {n}").fetchone()[0])
