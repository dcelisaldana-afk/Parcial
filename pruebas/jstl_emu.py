"""
Emulador minimo de JSP+JSTL (core, fmt, fn, sql) para VERIFICAR la logica de las paginas
sin Tomcat ni MySQL.  Ejecuta las paginas reales de /web contra SQLite (con funciones
MySQL simuladas).  No es un servidor: solo interpreta la parte JSTL/EL que usa el proyecto.
Lo que NO valida: sintaxis exacta de MySQL, comportamiento real del contenedor.
"""
import re, os, sys, html, sqlite3, math
from urllib.parse import quote
from datetime import datetime

sys.path.insert(0, os.path.dirname(__file__))
import sqlite_mysql as sm

# ----------------------------------------------------------------------------- errores
class JspError(Exception): pass
class Redirect(Exception):
    def __init__(self, url): self.url = url

# ----------------------------------------------------------------------------- modelo de datos
class Row(dict):
    """Fila de sql:query: acceso insensible a mayusculas, como Result.getRows()."""
    def __init__(self, items):
        super().__init__({k.lower(): v for k, v in items})
        self._orig = [k for k, _ in items]
    def get(self, k, d=None): return super().get(str(k).lower(), d)

class ResultObj:
    def __init__(self, rows):
        self.rows = rows; self.rowCount = len(rows)
        self.rowsByIndex = rows

class Entry:
    def __init__(self, k, v): self.key = k; self.value = v

class Obj:
    def __init__(self, **kw): self.__dict__.update(kw)

# ----------------------------------------------------------------------------- EL
KEYWORDS = {'and', 'or', 'not', 'empty', 'div', 'mod', 'eq', 'ne', 'lt', 'gt', 'le', 'ge', 'true', 'false', 'null'}
TOK = re.compile(r"""\s*(?:
    (?P<num>\d+\.\d+|\d+)|
    (?P<str>'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")|
    (?P<id>[A-Za-z_][A-Za-z_0-9]*(?::[A-Za-z_][A-Za-z_0-9]*(?=\())?)|
    (?P<op>==|!=|<=|>=|&&|\|\||[<>!?:+\-*/%.\[\](),])
)""", re.X)

def tokenize(s):
    pos, out = 0, []
    s = s.rstrip()
    while pos < len(s):
        m = TOK.match(s, pos)
        if not m: raise JspError(f"EL: caracter inesperado en '{s[pos:pos+15]}' (expr: {s})")
        pos = m.end()
        if m.group('num'): out.append(('num', m.group('num')))
        elif m.group('str'): out.append(('str', re.sub(r"\\(.)", r"\1", m.group('str')[1:-1])))
        elif m.group('id'): out.append(('id', m.group('id')))
        else: out.append(('op', m.group('op')))
    return out

def java_str(v):
    if v is None: return ''
    if v is True: return 'true'
    if v is False: return 'false'
    if isinstance(v, float):
        if v == int(v) and abs(v) < 1e7: return f"{int(v)}.0"
        return repr(v)
    return str(v)

def to_bool(v):
    if v is None: return False
    if isinstance(v, bool): return v
    if isinstance(v, str):
        if v.lower() == 'true': return True
        if v.lower() == 'false': return False
    raise JspError(f"EL: no se puede convertir {v!r} a Boolean")

def to_num(v):
    if v is None or v == '': return 0
    if isinstance(v, bool): raise JspError("EL: Boolean no es numerico")
    if isinstance(v, (int, float)): return v
    if isinstance(v, str):
        try:
            return float(v) if re.search(r"[.eE]", v) else int(v)
        except ValueError:
            raise JspError(f"EL: '{v}' no es un numero")
    raise JspError(f"EL: {type(v).__name__} no es numerico")

def is_empty(v):
    if v is None or v == '': return True
    if isinstance(v, (list, dict, tuple)): return len(v) == 0
    return False

class Parser:
    def __init__(self, toks, expr): self.t, self.i, self.expr = toks, 0, expr
    def peek(self): return self.t[self.i] if self.i < len(self.t) else (None, None)
    def nxt(self): x = self.peek(); self.i += 1; return x
    def isop(self, *ops):
        k, v = self.peek(); return (k == 'op' and v in ops) or (k == 'id' and v in ops and v in KEYWORDS)
    def eat(self, v):
        k, x = self.nxt()
        if x != v: raise JspError(f"EL: se esperaba '{v}' y llego '{x}' en {self.expr}")
    def parse(self):
        n = self.ternary()
        if self.i != len(self.t): raise JspError(f"EL: sobra '{self.t[self.i][1]}' en {self.expr}")
        return n
    def ternary(self):
        c = self.orx()
        if self.isop('?'):
            self.nxt(); a = self.ternary(); self.eat(':'); b = self.ternary()
            return ('?', c, a, b)
        return c
    def orx(self):
        l = self.andx()
        while self.isop('||', 'or'): self.nxt(); l = ('or', l, self.andx())
        return l
    def andx(self):
        l = self.eqx()
        while self.isop('&&', 'and'): self.nxt(); l = ('and', l, self.eqx())
        return l
    def eqx(self):
        l = self.rel()
        while self.isop('==', '!=', 'eq', 'ne'):
            op = self.nxt()[1]; l = ('eq' if op in ('==', 'eq') else 'ne', l, self.rel())
        return l
    def rel(self):
        l = self.add()
        while self.isop('<', '>', '<=', '>=', 'lt', 'gt', 'le', 'ge'):
            op = self.nxt()[1]
            op = {'lt': '<', 'gt': '>', 'le': '<=', 'ge': '>='}.get(op, op)
            l = ('cmp', op, l, self.add())
        return l
    def add(self):
        l = self.mul()
        while self.isop('+', '-'): op = self.nxt()[1]; l = ('arith', op, l, self.mul())
        return l
    def mul(self):
        l = self.unary()
        while self.isop('*', '/', 'div', '%', 'mod'):
            op = self.nxt()[1]; op = {'div': '/', 'mod': '%'}.get(op, op)
            l = ('arith', op, l, self.unary())
        return l
    def unary(self):
        if self.isop('!', 'not'): self.nxt(); return ('not', self.unary())
        if self.isop('-'): self.nxt(); return ('neg', self.unary())
        if self.isop('empty'): self.nxt(); return ('empty', self.unary())
        return self.postfix()
    def postfix(self):
        n = self.primary()
        while True:
            if self.isop('.'):
                self.nxt(); k, v = self.nxt(); n = ('prop', n, ('lit', v))
            elif self.isop('['):
                self.nxt(); e = self.ternary(); self.eat(']'); n = ('prop', n, e)
            else: return n
    def primary(self):
        k, v = self.nxt()
        if k == 'num': return ('lit', float(v) if '.' in v else int(v))
        if k == 'str': return ('lit', v)
        if k == 'op' and v == '(':
            e = self.ternary(); self.eat(')'); return e
        if k == 'id':
            if v == 'true': return ('lit', True)
            if v == 'false': return ('lit', False)
            if v == 'null': return ('lit', None)
            if ':' in v:
                self.eat('('); args = []
                if not self.isop(')'):
                    args.append(self.ternary())
                    while self.isop(','): self.nxt(); args.append(self.ternary())
                self.eat(')'); return ('fn', v, args)
            return ('var', v)
        raise JspError(f"EL: token inesperado '{v}' en {self.expr}")

_el_cache = {}
def compile_el(expr):
    if expr not in _el_cache: _el_cache[expr] = Parser(tokenize(expr), expr).parse()
    return _el_cache[expr]

def el_eq(a, b):
    if a is b: return True
    if a is None or b is None: return False
    if isinstance(a, (int, float)) and not isinstance(a, bool) or isinstance(b, (int, float)) and not isinstance(b, bool):
        return to_num(a) == to_num(b)
    if isinstance(a, bool) or isinstance(b, bool): return to_bool(a) == to_bool(b)
    return java_str(a) == java_str(b)

def el_cmp(op, a, b):
    if a is None or b is None: return False
    if isinstance(a, (int, float)) or isinstance(b, (int, float)):
        x, y = to_num(a), to_num(b)
    else:
        x, y = java_str(a), java_str(b)
    return {'<': x < y, '>': x > y, '<=': x <= y, '>=': x >= y}[op]

# --- funciones fn:
def _fn(name, a):
    n = name[3:]
    S = lambda i: java_str(a[i])
    if n == 'contains': return S(1) in S(0)
    if n == 'containsIgnoreCase': return S(1).lower() in S(0).lower()
    if n == 'startsWith': return S(0).startswith(S(1))
    if n == 'endsWith': return S(0).endswith(S(1))
    if n == 'trim': return S(0).strip()
    if n == 'toLowerCase': return S(0).lower()
    if n == 'toUpperCase': return S(0).upper()
    if n == 'length':
        v = a[0]
        if v is None: return 0
        if isinstance(v, (list, dict)): return len(v)
        return len(java_str(v))
    if n == 'substringBefore': s, d = S(0), S(1); return s.split(d, 1)[0] if d in s else ''
    if n == 'substringAfter': s, d = S(0), S(1); return s.split(d, 1)[1] if d in s else ''
    if n == 'replace': return S(0).replace(S(1), S(2))
    if n == 'indexOf': return S(0).find(S(1))
    if n == 'escapeXml': return html.escape(S(0))
    if n == 'split': return [x for x in S(0).split(S(1))] if S(1) else [S(0)]
    if n == 'join': return S(1).join(java_str(x) for x in (a[0] or []))
    if n == 'substring': return S(0)[int(to_num(a[1])):int(to_num(a[2])) if int(to_num(a[2])) >= 0 else None]
    raise JspError(f"Funcion EL no soportada/no existe: {name}")

def prop(base, key):
    key_s = java_str(key) if not isinstance(key, int) else key
    if base is None: return None
    if isinstance(base, Row): return base.get(key_s)
    if isinstance(base, dict): return base.get(key_s)
    if isinstance(base, (list, tuple)):
        try: return base[int(to_num(key))]
        except (IndexError, JspError): return None
    if isinstance(base, str): return None
    return getattr(base, str(key_s), None)

def ev(node, ctx):
    k = node[0]
    if k == 'lit': return node[1]
    if k == 'var': return ctx.lookup(node[1])
    if k == 'prop': return prop(ev(node[1], ctx), ev(node[2], ctx))
    if k == '?': return ev(node[2], ctx) if to_bool(ev(node[1], ctx)) else ev(node[3], ctx)
    if k == 'or': return to_bool(ev(node[1], ctx)) or to_bool(ev(node[2], ctx))
    if k == 'and': return to_bool(ev(node[1], ctx)) and to_bool(ev(node[2], ctx))
    if k == 'not': return not to_bool(ev(node[1], ctx))
    if k == 'neg': return -to_num(ev(node[1], ctx))
    if k == 'empty': return is_empty(ev(node[1], ctx))
    if k == 'eq': return el_eq(ev(node[1], ctx), ev(node[2], ctx))
    if k == 'ne': return not el_eq(ev(node[1], ctx), ev(node[2], ctx))
    if k == 'cmp': return el_cmp(node[1], ev(node[2], ctx), ev(node[3], ctx))
    if k == 'arith':
        op = node[1]; a, b = to_num(ev(node[2], ctx)), to_num(ev(node[3], ctx))
        if op == '+': return a + b
        if op == '-': return a - b
        if op == '*': return a * b
        if op == '/':
            if b == 0: return float('inf')
            return float(a) / float(b)          # EL: div siempre es Double
        if op == '%': return math.fmod(a, b) if isinstance(a, float) or isinstance(b, float) else a % b
    if k == 'fn': return _fn(node[1], [ev(x, ctx) for x in node[2]])
    raise JspError(f"EL interno: nodo {k}")

def find_expr_end(s, i):
    """i apunta justo despues de '${'; devuelve el indice de la '}' que cierra."""
    q = None
    while i < len(s):
        ch = s[i]
        if q:
            if ch == '\\': i += 1
            elif ch == q: q = None
        else:
            if ch in "'\"": q = ch
            elif ch == '}': return i
        i += 1
    raise JspError("EL sin cerrar: " + s[:60])

def interp(s, ctx):
    """Evalua ${...} dentro de un texto. Si el texto ES una sola expresion conserva el tipo."""
    if '${' not in s: return s
    parts, i = [], 0
    while True:
        j = s.find('${', i)
        if j < 0:
            if i < len(s): parts.append(('t', s[i:]))
            break
        if j > i: parts.append(('t', s[i:j]))
        e = find_expr_end(s, j + 2)
        parts.append(('e', s[j + 2:e])); i = e + 1
    if len(parts) == 1 and parts[0][0] == 'e':
        return ev(compile_el(parts[0][1]), ctx)
    return ''.join(p[1] if p[0] == 't' else java_str(ev(compile_el(p[1]), ctx)) for p in parts)

# ----------------------------------------------------------------------------- parser de plantillas
class Node:
    def __init__(self, kind, name=None, attrs=None, text=None):
        self.kind, self.name, self.attrs, self.text = kind, name, attrs or {}, text
        self.children = []; self.src = None

TAG = re.compile(
    r'<(?P<close>/)?(?P<pre>c|sql|fmt|t):(?P<name>\w+)(?P<attrs>(?:\s+[\w:-]+\s*=\s*(?:"[^"]*"|\'[^\']*\'))*)\s*(?P<self>/)?>'
    r'|<%--.*?--%>|<%@.*?%>|<%(?!--|@).*?%>', re.S)
ATTR = re.compile(r'([\w:-]+)\s*=\s*(?:"([^"]*)"|\'([^\']*)\')')

def read_expanded(path, webroot, seen=()):
    """Lee un JSP quitando comentarios y expandiendo <%@ include %> (inclusion estatica)."""
    text = open(path, encoding='utf-8').read()
    text = re.sub(r"<%--.*?--%>", "", text, flags=re.S)
    def inc(m):
        f = m.group(1)
        target = os.path.join(webroot, f.lstrip('/')) if f.startswith('/') else os.path.join(os.path.dirname(path), f)
        if not os.path.exists(target): raise JspError(f"include no existe: {f} (en {path})")
        if target in seen: raise JspError(f"include recursivo: {f}")
        return read_expanded(target, webroot, seen + (path,))
    return re.sub(r'<%@\s*include\s+file\s*=\s*"([^"]+)"\s*%>', inc, text)

def parse_template(text, label=''):
    root = Node('root'); stack = [root]; pos = 0; tagattrs = []
    for m in TAG.finditer(text):
        if m.start() > pos: stack[-1].children.append(Node('text', text=text[pos:m.start()]))
        pos = m.end(); g = m.group(0)
        if g.startswith('<%@'):
            if re.match(r'<%@\s*attribute', g):
                mm = re.search(r'name\s*=\s*"([^"]+)"', g); tagattrs.append(mm.group(1))
            continue
        if g.startswith('<%--'): continue
        if g.startswith('<%'):
            raise JspError(f"{label}: scriptlet/expresion Java encontrado: {g[:40]}")
        pre, name = m.group('pre'), m.group('name')
        if m.group('close'):
            top = stack.pop()
            if top.name != f"{pre}:{name}" or len(stack) == 0:
                raise JspError(f"{label}: cierre </{pre}:{name}> no coincide con <{top.name}>")
            continue
        attrs = {a.group(1): (a.group(2) if a.group(2) is not None else a.group(3)) for a in ATTR.finditer(m.group('attrs'))}
        n = Node('tag', f"{pre}:{name}", attrs); n.src = label
        stack[-1].children.append(n)
        if not m.group('self'): stack.append(n)
    if pos < len(text): stack[-1].children.append(Node('text', text=text[pos:]))
    if len(stack) != 1: raise JspError(f"{label}: etiqueta sin cerrar <{stack[-1].name}>")
    root.tagattrs = tagattrs
    return root

# ----------------------------------------------------------------------------- contexto de ejecucion
class Ctx:
    def __init__(self, server, request, page=None):
        self.server, self.request = server, request
        self.page = page if page is not None else {}
        self.out = []; self.in_tx = False
        self.params_stack = []

    @property
    def session(self): return self.server.sessions[self.request['sid']]
    @property
    def app(self): return self.server.app

    def lookup(self, name):
        for scope in (self.page, self.request['attrs'], self.session, self.app):
            if name in scope: return scope[name]
        r = self.request
        if name == 'param': return {k: v[0] for k, v in r['params'].items()}
        if name == 'paramValues': return r['params']
        if name == 'sessionScope': return self.session
        if name == 'applicationScope': return self.app
        if name == 'requestScope': return r['attrs']
        if name == 'pageScope': return self.page
        if name == 'pageContext':
            return Obj(request=Obj(contextPath='', servletPath=r['path']))
        return None

    def scope(self, name):
        return {'page': self.page, 'request': self.request['attrs'], 'session': self.session,
                'application': self.app, None: self.page}[name]

# ----------------------------------------------------------------------------- ejecucion
SQL_TAGS = {'sql:query', 'sql:update', 'sql:transaction', 'sql:setDataSource', 'sql:param'}

class Server:
    def __init__(self, webroot, sqlfile):
        self.webroot = webroot
        self.con = sm.make_db(sqlfile)
        self.con.row_factory = None
        self.app = {}; self.sessions = {}
        self.cache = {}
        self.sqllog = []
    def template(self, path):
        full = os.path.join(self.webroot, path.lstrip('/'))
        if full not in self.cache:
            self.cache[full] = parse_template(read_expanded(full, self.webroot), path)
        return self.cache[full]
    def tagfile(self, name):
        full = os.path.join(self.webroot, 'WEB-INF/tags', name + '.tag')
        if not os.path.exists(full): raise JspError(f"tag file inexistente: {name}")
        if full not in self.cache:
            self.cache[full] = parse_template(read_expanded(full, self.webroot), full)
        return self.cache[full]

    def request(self, path, params=None, sid='s1', method='GET'):
        """Ejecuta una pagina. Devuelve dict(status, location, body, session)."""
        params = {k: (v if isinstance(v, list) else [v]) for k, v in (params or {}).items()}
        self.sessions.setdefault(sid, {})
        req = {'path': path, 'params': params, 'attrs': {}, 'sid': sid}
        ctx = Ctx(self, req)
        try:
            run_nodes(self.template(path).children, ctx)
            return {'status': 200, 'body': ''.join(ctx.out), 'session': self.sessions[sid], 'location': None}
        except Redirect as r:
            return {'status': 302, 'location': r.url, 'body': ''.join(ctx.out), 'session': self.sessions[sid]}

def attr(n, name, ctx, default=None):
    if name not in n.attrs: return default
    return interp(n.attrs[name], ctx)

def body_text(n, ctx):
    """Texto del cuerpo (con EL evaluado) ignorando etiquetas hijas de tipo sql:param."""
    out = []
    for c in n.children:
        if c.kind == 'text': out.append(interp(c.text, ctx) if '${' in c.text else c.text)
    return ''.join(out) if all(isinstance(x, str) for x in out) else ''.join(java_str(x) for x in out)

ALLOWED = {
    'c:set': {'var', 'value', 'scope'}, 'c:remove': {'var', 'scope'}, 'c:if': {'test', 'var'},
    'c:choose': set(), 'c:when': {'test'}, 'c:otherwise': set(),
    'c:forEach': {'items', 'var', 'begin', 'end', 'varStatus', 'step'},
    'c:forTokens': {'items', 'delims', 'var', 'varStatus'},
    'c:out': {'value', 'default', 'escapeXml'}, 'c:redirect': {'url'}, 'c:url': {'value', 'var'},
    'c:param': {'name', 'value'}, 'c:catch': {'var'},
    'sql:query': {'var', 'dataSource', 'scope', 'startRow', 'maxRows'}, 'sql:update': {'var', 'dataSource', 'scope'},
    'sql:transaction': {'dataSource'}, 'sql:param': {'value'},
    'sql:setDataSource': {'var', 'scope', 'driver', 'url', 'user', 'password', 'dataSource'},
    'fmt:requestEncoding': {'value'}, 'fmt:setLocale': {'value'},
    'fmt:formatDate': {'value', 'pattern', 'type', 'var'}, 'fmt:formatNumber': {'value', 'pattern', 'var', 'type'},
    'fmt:parseNumber': {'value', 'var', 'integerOnly', 'parseLocale', 'pattern', 'type'},
}

def run_nodes(nodes, ctx):
    for n in nodes: run(n, ctx)

def run(n, ctx):
    if n.kind == 'text':
        ctx.out.append(java_str(interp(n.text, ctx)) if '${' in n.text else n.text)
        return
    name = n.name
    if name.startswith('t:'):
        return run_tagfile(n, ctx)
    if name not in ALLOWED: raise JspError(f"{n.src}: etiqueta no soportada/inexistente <{name}>")
    bad = set(n.attrs) - ALLOWED[name]
    if bad: raise JspError(f"{n.src}: atributo(s) invalido(s) {bad} en <{name}>")
    H[name](n, ctx)

def run_tagfile(n, ctx):
    tname = n.name[2:]
    tf = ctx.server.tagfile(tname)
    page = {}
    for a in tf.tagattrs: page[a] = None
    for k, v in n.attrs.items():
        if k not in tf.tagattrs: raise JspError(f"{n.src}: atributo '{k}' no declarado en tag {tname}")
        val = interp(v, ctx)
        page[k] = None if val is None else java_str(val)      # atributos de tag file: String
    sub = Ctx(ctx.server, ctx.request, page); sub.out = ctx.out; sub.in_tx = ctx.in_tx
    run_nodes(tf.children, sub)

# ------------------------- handlers core
def h_set(n, ctx):
    scope = attr(n, 'scope', ctx)
    if 'value' in n.attrs: v = attr(n, 'value', ctx)
    else:
        sub = Ctx(ctx.server, ctx.request, ctx.page); run_nodes(n.children, sub); v = ''.join(sub.out)
    d = ctx.scope(scope)
    var = interp(n.attrs['var'], ctx)
    if v is None: d.pop(var, None)
    else: d[var] = v

def h_remove(n, ctx): ctx.scope(attr(n, 'scope', ctx)).pop(n.attrs['var'], None)
def h_if(n, ctx):
    t = to_bool(attr(n, 'test', ctx))
    if 'var' in n.attrs: ctx.page[n.attrs['var']] = t
    if t: run_nodes(n.children, ctx)
def h_choose(n, ctx):
    for c in n.children:
        if c.kind == 'text':
            if c.text.strip(): raise JspError("texto dentro de c:choose")
            continue
        if c.name == 'c:when':
            if to_bool(attr(c, 'test', ctx)): run_nodes(c.children, ctx); return
        elif c.name == 'c:otherwise': run_nodes(c.children, ctx); return
        else: raise JspError(f"{c.name} no permitido dentro de c:choose")
def h_foreach(n, ctx):
    items = attr(n, 'items', ctx) if 'items' in n.attrs else None
    var = n.attrs.get('var'); vs = n.attrs.get('varStatus')
    if items is None and 'items' not in n.attrs:
        b = int(to_num(attr(n, 'begin', ctx))); e = int(to_num(attr(n, 'end', ctx)))
        seq = list(range(b, e + 1))
    else:
        if items is None: seq = []
        elif isinstance(items, ResultObj): seq = items.rows
        elif isinstance(items, dict) and not isinstance(items, Row): seq = [Entry(k, v[0] if isinstance(v, list) else v) for k, v in items.items()]
        elif isinstance(items, (list, tuple)): seq = list(items)
        elif isinstance(items, str): seq = items.split(',')
        else: raise JspError(f"c:forEach items no iterable: {items!r}")
        if 'begin' in n.attrs: seq = seq[int(to_num(attr(n, 'begin', ctx))):]
        if 'end' in n.attrs: seq = seq[:int(to_num(attr(n, 'end', ctx))) + 1]
    for idx, it in enumerate(seq):
        if var: ctx.page[var] = it
        if vs: ctx.page[vs] = Obj(index=idx, count=idx + 1, first=idx == 0, last=idx == len(seq) - 1, current=it)
        run_nodes(n.children, ctx)
    if var: ctx.page.pop(var, None)
def h_fortokens(n, ctx):
    items = java_str(attr(n, 'items', ctx)); delims = java_str(attr(n, 'delims', ctx))
    toks = [t for t in re.split('[' + re.escape(delims) + ']', items) if t != '']
    for idx, t in enumerate(toks):
        if 'var' in n.attrs: ctx.page[n.attrs['var']] = t
        if 'varStatus' in n.attrs: ctx.page[n.attrs['varStatus']] = Obj(index=idx, count=idx + 1, first=idx == 0, last=idx == len(toks) - 1)
        run_nodes(n.children, ctx)
def h_out(n, ctx):
    v = attr(n, 'value', ctx)
    if v is None: v = attr(n, 'default', ctx, '')
    s = java_str(v)
    esc = attr(n, 'escapeXml', ctx, True)
    ctx.out.append(html.escape(s, quote=True) if esc in (True, 'true') else s)

def collect_params(n, ctx):
    ps = []
    for c in n.children:
        if c.kind == 'tag':
            if c.name == 'c:param':
                ps.append((java_str(attr(c, 'name', ctx)), java_str(attr(c, 'value', ctx))))
            else:
                # c:if / c:forEach con c:param dentro
                ctx.params_stack.append(ps)
                # ejecutar para que los c:param internos se acumulen
                saved = ctx.out; ctx.out = []
                run(c, ctx); ctx.out = saved
                ctx.params_stack.pop()
    return ps
def h_param(n, ctx):
    if ctx.params_stack: ctx.params_stack[-1].append((java_str(attr(n, 'name', ctx)), java_str(attr(n, 'value', ctx))))
    else: raise JspError(f"{n.src}: c:param fuera de c:url/c:redirect")
def build_url(n, ctx):
    base = java_str(attr(n, 'url' if n.name == 'c:redirect' else 'value', ctx))
    if not base: raise JspError(f"{n.src}: URL vacia en {n.name}")
    ps = []
    ctx.params_stack.append(ps)
    saved = ctx.out; ctx.out = []
    for c in n.children:
        if c.kind == 'tag': run(c, ctx)
    ctx.out = saved; ctx.params_stack.pop()
    q = '&'.join(f"{quote(k)}={quote(v)}" for k, v in ps)
    return base + (('&' if '?' in base else '?') + q if q else '')
def h_redirect(n, ctx): raise Redirect(build_url(n, ctx))
def h_url(n, ctx):
    u = build_url(n, ctx)
    if 'var' in n.attrs: ctx.page[n.attrs['var']] = u
    else: ctx.out.append(u)
def h_catch(n, ctx):
    var = n.attrs.get('var')
    try:
        run_nodes(n.children, ctx)
        if var: ctx.page.pop(var, None)
    except Redirect: raise
    except (sqlite3.Error, JspError, ArithmeticError, ValueError) as e:
        if var: ctx.page[var] = e
        ctx.server.last_caught = e

# ------------------------- handlers sql
def h_setds(n, ctx):
    scope = attr(n, 'scope', ctx)
    ctx.scope(scope)[n.attrs['var']] = 'DATASOURCE'
def sql_prep(n, ctx):
    ds = n.attrs.get('dataSource')
    if ctx.in_tx and ds: raise JspError(f"{n.src}: dataSource no permitido dentro de sql:transaction")
    if not ctx.in_tx:
        if not ds: raise JspError(f"{n.src}: falta dataSource fuera de sql:transaction")
        if attr(n, 'dataSource', ctx) != 'DATASOURCE': raise JspError(f"{n.src}: dataSource nulo/invalido")
    parts, params = [], []
    for c in n.children:
        if c.kind == 'text': parts.append(java_str(interp(c.text, ctx)) if '${' in c.text else c.text)
        elif c.name == 'sql:param': params.append(attr(c, 'value', ctx))
        else: raise JspError(f"{n.src}: {c.name} no permitido dentro de {n.name}")
    sql = ''.join(parts).strip()
    qm = len(re.findall(r"\?", re.sub(r"'[^']*'", "''", sql)))
    if qm != len(params): raise JspError(f"{n.src}: {qm} marcadores ? y {len(params)} sql:param -> {sql[:70]!r}")
    for p in params:
        if isinstance(p, (Row, dict, list)): raise JspError(f"{n.src}: parametro con tipo invalido")
    return sm.translate_sql(sql), params, sql
def h_squery(n, ctx):
    sql, params, orig = sql_prep(n, ctx)
    cur = ctx.server.con.execute(sql, params)
    cols = [d[0] for d in cur.description]
    rows = [Row(list(zip(cols, r))) for r in cur.fetchall()]
    ctx.server.sqllog.append(orig)
    if 'var' in n.attrs: ctx.scope(attr(n, 'scope', ctx))[n.attrs['var']] = ResultObj(rows)
def h_supdate(n, ctx):
    sql, params, orig = sql_prep(n, ctx)
    cur = ctx.server.con.execute(sql, params)
    ctx.server.sqllog.append(orig)
    if 'var' in n.attrs: ctx.scope(attr(n, 'scope', ctx))[n.attrs['var']] = cur.rowcount
def h_stx(n, ctx):
    if ctx.in_tx: raise JspError("transaccion anidada")
    if attr(n, 'dataSource', ctx) != 'DATASOURCE': raise JspError(f"{n.src}: sql:transaction sin dataSource")
    con = ctx.server.con; con.execute("BEGIN"); ctx.in_tx = True
    try:
        run_nodes(n.children, ctx)
        con.execute("COMMIT")
    except Redirect:
        con.execute("COMMIT"); raise
    except Exception:
        con.execute("ROLLBACK"); raise
    finally: ctx.in_tx = False

# ------------------------- handlers fmt
def h_noop(n, ctx): pass
def h_fdate(n, ctx):
    v = attr(n, 'value', ctx)
    if v is None or v == '': return
    d = sm._parse(v)
    if d is None: raise JspError(f"formatDate: valor no es fecha: {v!r}")
    p = java_str(attr(n, 'pattern', ctx, 'dd/MM/yyyy'))
    py = p.replace('yyyy', '%Y').replace('dd', '%d').replace('MM', '%m').replace('HH', '%H').replace('mm', '%M')
    s = d.strftime(py)
    if 'var' in n.attrs: ctx.page[n.attrs['var']] = s
    else: ctx.out.append(s)
def h_fnum(n, ctx):
    v = attr(n, 'value', ctx)
    if v is None or v == '': return
    x = to_num(v)
    s = f"{int(round(x)):,}".replace(',', '.')
    if 'var' in n.attrs: ctx.page[n.attrs['var']] = s
    else: ctx.out.append(s)
def h_pnum(n, ctx):
    v = attr(n, 'value', ctx)
    if v is None or java_str(v) == '':
        ctx.page.pop(n.attrs['var'], None); return
    s = java_str(v).strip()
    loc = attr(n, 'parseLocale', ctx)
    if loc != 'en_US':
        # con es_CO el punto es separador de miles y la coma el decimal
        s = s.replace('.', '')
    if not re.match(r"^-?\d+(\.\d+)?$", s.replace(',', '.') if loc != 'en_US' else s):
        raise JspError(f"parseNumber: no es numero: {v!r}")
    val = float(s.replace(',', '.')) if loc != 'en_US' else float(s)
    if to_bool(attr(n, 'integerOnly', ctx, False)): val = int(val)
    ctx.page[n.attrs['var']] = val

H = {
    'c:set': h_set, 'c:remove': h_remove, 'c:if': h_if, 'c:choose': h_choose, 'c:forEach': h_foreach,
    'c:forTokens': h_fortokens, 'c:out': h_out, 'c:redirect': h_redirect, 'c:url': h_url, 'c:catch': h_catch,
    'c:param': h_param, 'c:when': lambda n, c: (_ for _ in ()).throw(JspError('c:when fuera de c:choose')),
    'c:otherwise': lambda n, c: (_ for _ in ()).throw(JspError('c:otherwise fuera de c:choose')),
    'sql:setDataSource': h_setds, 'sql:query': h_squery, 'sql:update': h_supdate, 'sql:transaction': h_stx,
    'sql:param': lambda n, c: (_ for _ in ()).throw(JspError('sql:param fuera de sql:query/update')),
    'fmt:requestEncoding': h_noop, 'fmt:setLocale': h_noop, 'fmt:formatDate': h_fdate,
    'fmt:formatNumber': h_fnum, 'fmt:parseNumber': h_pnum,
}
