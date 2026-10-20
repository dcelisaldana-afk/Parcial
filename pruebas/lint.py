import sys, os, re; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import jstl_emu as j
W=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','web')
errs=0
files=[os.path.join(d,f) for d,_,fs in os.walk(W) for f in fs if f.endswith(('.jsp','.jspf','.tag'))]
def walk(n, f):
    global errs
    if n.kind=='tag':
        if not n.name.startswith('t:'):
            if n.name not in j.ALLOWED: print(f,'tag desconocido',n.name); errs+=1
            else:
                bad=set(n.attrs)-j.ALLOWED[n.name]
                if bad: print(f,'attr invalido',n.name,bad); errs+=1
        if n.name in('sql:query','sql:update'):
            txt=''.join(c.text for c in n.children if c.kind=='text')
            q=len(re.findall(r"\?",re.sub(r"'[^']*'","''",txt)))
            p=sum(1 for c in n.children if c.kind=='tag' and c.name=='sql:param')
            if q!=p: print(f,'params',q,p,txt.strip()[:60]); errs+=1
        # EL balance
        for k,v in n.attrs.items():
            if v.count('${')!=v.count('}') and v.count('${')>0 and v.count('{')!=v.count('}'): print(f,'EL desbalanceado',v); errs+=1
            try: j.interp  # noqa
            except: pass
            for m in re.finditer(r'\$\{',v):
                e=j.find_expr_end(v,m.end()); j.compile_el(v[m.end():e])
    elif n.kind=='text':
        for m in re.finditer(r'\$\{',n.text):
            try:
                e=j.find_expr_end(n.text,m.end()); j.compile_el(n.text[m.end():e])
            except Exception as ex: print(f,'EL error',ex); errs+=1
    for c in n.children: walk(c,f)
for f in sorted(files):
    if f.endswith('.jspf') or f.endswith('.txt'): continue
    rel=f[len(W):]
    try:
        if f.endswith('.tag'):
            t=j.parse_template(j.read_expanded(f,W),rel)
        else:
            t=j.parse_template(j.read_expanded(f,W),rel)
        walk(t,rel)
    except Exception as ex:
        print(rel,'ERROR',ex); errs+=1
print('archivos',len(files),'errores',errs)
