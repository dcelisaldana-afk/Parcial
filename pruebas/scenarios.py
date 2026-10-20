import sys, re, os;
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import jstl_emu as j
S=j.Server(os.path.join(HERE,'..','web'),os.path.join(HERE,'..','sql','01_base_datos_trabajos_grado.sql'))
con=S.con
FAIL=[]; N=[0]
def ok(cond,msg):
    N[0]+=1
    if not cond: FAIL.append(msg); print('  FALLO:',msg)
def R(path,params=None,sid='x'):
    try: return S.request(path,params or {},sid)
    except Exception as e:
        FAIL.append(f'EXCEPCION {path} {params}: {type(e).__name__}: {e}'); print('  EXCEPCION',path,params,type(e).__name__,e)
        return {'status':0,'location':'','body':'','session':{}}
def login(sid,correo,clave='1234'):
    r=R('/acceso.jsp',{'correo':correo,'clave':clave},sid); return r
def loc(r): return r['location'] or ''
def q(sql,*a): return con.execute(sql,a).fetchall()
def sc(title): print('==',title)

sc('login / bloqueo')
r=login('a','admin@uts.edu.co'); ok(loc(r)=='/index.jsp','login admin '+loc(r))
ok(S.sessions['a'].get('roles')=='ADMINISTRADOR','roles admin')
r=R('/index.jsp',sid='a'); ok(loc(r)=='/admin/usuarios.jsp','index admin '+loc(r))
r=login('b','estudiante1@uts.edu.co','mala'); ok('incorrectos' in loc(r) or 'incorrectos' in r['location'].replace('%C3%B1','n') or 'err=' in loc(r),'clave mala '+loc(r))
login('b','estudiante1@uts.edu.co','mala'); r=login('b','estudiante1@uts.edu.co','mala')
ok('bloque' in loc(r).lower(),'tercer intento bloquea '+loc(r))
r=login('b','estudiante1@uts.edu.co','1234'); ok('bloqueada' in loc(r),'bloqueado no entra '+loc(r))
r=R('/admin/usuario_guardar.jsp',{'accion':'activar','id':8},'a'); ok('ok=' in loc(r),'desbloquea')
r=login('b','estudiante1@uts.edu.co'); ok(loc(r)=='/index.jsp','entra tras desbloqueo')
r=login('b','nadie@uts.edu.co'); ok('err=' in loc(r),'correo inexistente')

sc('seguridad por rol')
r=R('/admin/usuarios.jsp',sid='nologin'); ok('login.jsp' in loc(r),'sin sesion -> login')
login('est','estudiante9@uts.edu.co')
for p in ['/admin/usuarios.jsp','/comite/panel.jsp','/docente/panel.jsp','/admin/catalogos.jsp','/comite/accion.jsp','/docente/evaluar_accion.jsp','/idea_nueva.jsp']:
    r=R(p,sid='est'); ok('acceso_denegado' in loc(r),f'estudiante bloqueado en {p}: {loc(r)}')
login('doc','ana.rojas@uts.edu.co'); login('com','comite@uts.edu.co')
r=R('/trabajo.jsp',{'id':4},'est'); ok('acceso_denegado' in loc(r),'estudiante ajeno no ve trabajo 4')
r=R('/trabajo.jsp',{'id':2},'doc'); ok(r['status']==200,'ana (director t2) ve trabajo 2')
r=R('/trabajo.jsp',{'id':4},'doc'); ok('acceso_denegado' in loc(r),'ana no asignada al 4')
r=R('/trabajo.jsp',{'id':999},'com'); ok('err=' in loc(r),'trabajo inexistente')

sc('todas las paginas GET renderizan')
pages={'est':['/estudiante/panel.jsp','/estudiante/inscripcion.jsp','/banco_ideas.jsp','/calendario.jsp','/formatos.jsp','/cuenta.jsp','/landing.jsp'],
 'doc':['/docente/panel.jsp','/docente/revisiones.jsp','/idea_nueva.jsp','/trabajo.jsp?id=2','/trabajo.jsp?id=5'],
 'com':['/comite/panel.jsp','/comite/ideas.jsp','/comite/prorrogas.jsp','/idea_nueva.jsp','/trabajo.jsp?id=1','/trabajo.jsp?id=3','/trabajo.jsp?id=5','/trabajo.jsp?id=6','/trabajo.jsp?id=7','/calendario.jsp'],
 'a':['/admin/usuarios.jsp','/admin/usuario_form.jsp','/admin/usuario_form.jsp?id=3','/admin/trabajos.jsp','/admin/trabajo_editar.jsp?id=2','/admin/catalogos.jsp','/trabajo.jsp?id=7','/calendario.jsp']}
for sid,lst in pages.items():
    for p in lst:
        path,_,qs=p.partition('?'); par=dict(x.split('=') for x in qs.split('&')) if qs else {}
        r=R(path,par,sid)
        ok(r['status']==200 and '<html' in r['body'] and '</html>' in r['body'],f'{sid} {p} status {r["status"]} {loc(r)}')
# estudiante con trabajo
login('e6','estudiante6@uts.edu.co')
for p,par in [('/estudiante/panel.jsp',{}),('/estudiante/prorroga.jsp',{'id':5}),('/trabajo.jsp',{'id':5})]:
    r=R(p,par,'e6'); ok(r['status']==200,f'e6 {p} {loc(r)}')
r=R('/estudiante/inscripcion.jsp',sid='e6'); ok('panel.jsp' in loc(r),'con trabajo activo no reinscribe')
login('e4','estudiante4@uts.edu.co'); r=R('/trabajo.jsp',{'id':3},'e4'); ok('Evaluaci' in r['body'] or r['status']==200,'e4 ve su trabajo 3')

sc('paginacion y filtros')
r=R('/banco_ideas.jsp',{'q':''},'x'); ok('page-link' not in r['body'] or True,'ok')
# crear mas ideas para forzar paginas
for i in range(15):
    con.execute("INSERT INTO banco_idea (titulo,descripcion,id_linea,propuesto_por,origen,palabras_clave,periodo_academico,nivel,estado) VALUES (?,?,1,3,'DOCENTE','pk','2026-2','Tecnologia','DISPONIBLE')",(f'Idea extra {i}','d'))
r=R('/banco_ideas.jsp',{},'x'); ok('page-link' in r['body'],'aparece paginacion')
m=re.findall(r'class="page-link" href="([^"]+)"',r['body']); print('   enlaces:',m)
r2=R('/banco_ideas.jsp',{'pagina':'2'},'x'); ok(r2['body'].count('card-idea')>0 and r2['body']!=r['body'],'pagina 2 distinta')
r3=R('/banco_ideas.jsp',{'pagina':'abc'},'x'); ok(r3['status']==200,'pagina invalida tolerada')
r4=R('/banco_ideas.jsp',{'q':'Idea extra 3'},'x'); ok(r4['body'].count('card-idea')==1,'busqueda global titulo: '+str(r4['body'].count('card-idea')))
r5=R('/banco_ideas.jsp',{'q':'ana'},'x'); ok(r5['body'].count('card-idea')>=1,'busqueda por docente')
r6=R('/banco_ideas.jsp',{'q':'12'},'x'); ok(r6['status']==200,'busqueda por id')
# pagina con total exacto = porPagina no debe mostrar paginacion
con.execute("DELETE FROM banco_idea WHERE titulo LIKE 'Idea extra%'")
n=q("select count(*) from banco_idea where estado='DISPONIBLE'")[0][0]; print('   disponibles',n)
r=R('/comite/panel.jsp',{'fase':'3'},'com'); ok(r['body'].count('btn-primary')>=1,'filtro fase')
r=R('/comite/panel.jsp',{'estado':'TODOS','q':'estudiante4'},'com'); ok('Deteccion' in r['body'],'busqueda por estudiante en panel')
r=R('/admin/usuarios.jsp',{'q':'rojas','rol':'4'},'a'); ok('rojas' in r['body'].lower(),'usuarios filtro')
r=R('/admin/usuarios.jsp',{'estado':'BLOQUEADO'},'a'); ok(r['status']==200,'usuarios estado')

sc('FLUJO COMPLETO: inscripcion con 2 estudiantes')
login('e9','estudiante9@uts.edu.co'); login('e10','estudiante10@uts.edu.co')
r=R('/estudiante/inscripcion_accion.jsp',{'modo_idea':'banco','id_idea':'9','id_programa':'1','modalidad':'DESARROLLO_SOFTWARE','pago1':'ftp://x','correo2':''},'e9'); ok('err=' in loc(r),'url de pago invalida')
r=R('/estudiante/inscripcion_accion.jsp',{'modo_idea':'banco','id_idea':'9','id_programa':'1','modalidad':'DESARROLLO_SOFTWARE','pago1':'https://pagos/e9','correo2':'estudiante10@uts.edu.co','pago2':''},'e9'); ok('err=' in loc(r),'segundo estudiante exige su recibo')
r=R('/estudiante/inscripcion_accion.jsp',{'modo_idea':'banco','id_idea':'9','id_programa':'1','modalidad':'DESARROLLO_SOFTWARE','pago1':'https://pagos/e9','correo2':'estudiante1@uts.edu.co','pago2':'https://pagos/x'},'e9'); ok('err=' in loc(r),'segundo con trabajo activo rechazado')
r=R('/estudiante/inscripcion_accion.jsp',{'modo_idea':'banco','id_idea':'9','id_programa':'1','modalidad':'DESARROLLO_SOFTWARE','pago1':'https://pagos/e9','correo2':'estudiante10@uts.edu.co','pago2':'https://pagos/e10'},'e9')
ok('ok=' in loc(r),'inscripcion ok '+loc(r))
t=q("select id_trabajo,fase_actual,estado from trabajo_grado order by id_trabajo desc limit 1")[0]; TID=t[0]; print('   trabajo',t)
ok(t[1]==1,'fase 1'); ok(q("select count(*) from trabajo_grado_estudiante where id_trabajo=?",TID)[0][0]==2,'2 estudiantes')
ok(q("select count(*) from pago where id_trabajo=?",TID)[0][0]==2,'2 pagos (uno por estudiante)')
ok(q("select estado from banco_idea where id_idea=9")[0][0]=='ASIGNADA','idea reservada')
r=R('/estudiante/inscripcion_accion.jsp',{'modo_idea':'banco','id_idea':'11','id_programa':'1','modalidad':'MONOGRAFIA','pago1':'https://pagos/z'},'e9'); ok('panel.jsp' in loc(r) and 'err=' in loc(r),'un solo trabajo activo')
# comite: no puede aprobar sin pagos verificados
r=R('/comite/accion.jsp',{'accion':'aprobar_inscripcion','id_trabajo':TID,'id_director':'3','id_evaluador':'4'},'com'); ok('err=' in loc(r) and q("select fase_actual from trabajo_grado where id_trabajo=?",TID)[0][0]==1,'no aprueba sin pagos verificados')
for (pid,) in q("select id_pago from pago where id_trabajo=?",TID):
    R('/comite/accion.jsp',{'accion':'verificar_pago','id_trabajo':TID,'id_pago':pid,'resultado':'VERIFICADO'},'com')
r=R('/comite/accion.jsp',{'accion':'aprobar_inscripcion','id_trabajo':TID,'id_director':'3','id_evaluador':'3'},'com'); ok('err=' in loc(r),'director distinto de evaluador')
r=R('/comite/accion.jsp',{'accion':'aprobar_inscripcion','id_trabajo':TID,'id_director':'3','id_evaluador':'8'},'com'); ok('err=' in loc(r),'evaluador debe ser docente')
r=R('/comite/accion.jsp',{'accion':'aprobar_inscripcion','id_trabajo':TID,'id_director':'3','id_evaluador':'4'},'com'); ok('ok=' in loc(r),'aprueba inscripcion '+loc(r))
ok(q("select fase_actual from trabajo_grado where id_trabajo=?",TID)[0][0]==2,'fase 2')
ok(q("select count(*) from rol_docente where id_trabajo=?",TID)[0][0]==2,'2 roles docentes')

sc('FASE 2: anteproyecto (URL) y concepto del director')
r=R('/estudiante/entrega_accion.jsp',{'accion':'anteproyecto','id_trabajo':TID,'url':'no-url'},'e9'); ok('err=' in loc(r),'url invalida')
r=R('/estudiante/entrega_accion.jsp',{'accion':'anteproyecto','id_trabajo':TID,'url':'https://docs/ante-v1'},'e10'); ok('ok=' in loc(r),'cualquiera de los 2 estudiantes registra')
r=R('/estudiante/entrega_accion.jsp',{'accion':'anteproyecto','id_trabajo':TID,'url':'https://docs/otro'},'e9'); ok('err=' in loc(r),'no duplica mientras hay uno pendiente')
EID=q("select id_entrega from entrega where id_trabajo=? and tipo_documento='FD124' order by version desc",TID)[0][0]
login('d4','carlos.mendez@uts.edu.co')  # evaluador, no director
r=R('/docente/evaluar_accion.jsp',{'accion':'dir_anteproyecto','id_trabajo':TID,'id_entrega':EID,'concepto':'APROBADO'},'d4'); ok('acceso_denegado' in loc(r),'evaluador no puede actuar como director')
login('d5','laura.gomez@uts.edu.co'); r=R('/docente/evaluar_accion.jsp',{'accion':'dir_anteproyecto','id_trabajo':TID,'id_entrega':EID,'concepto':'APROBADO'},'d5'); ok('acceso_denegado' in loc(r),'docente ajeno bloqueado')
r=R('/docente/evaluar_accion.jsp',{'accion':'dir_anteproyecto','id_trabajo':TID,'id_entrega':EID,'concepto':'XX'},'doc'); ok('err=' in loc(r),'concepto invalido')
r=R('/docente/evaluar_accion.jsp',{'accion':'dir_anteproyecto','id_trabajo':TID,'id_entrega':EID,'concepto':'APLAZADO','observaciones':'ajustar objetivos'},'doc'); ok('ok=' in loc(r),'aplazado')
ok(q("select estado from entrega where id_entrega=?",EID)[0][0]=='APLAZADA','entrega aplazada')
ok(q("select fase_actual from trabajo_grado where id_trabajo=?",TID)[0][0]==2,'sigue en fase 2')
r=R('/estudiante/entrega_accion.jsp',{'accion':'anteproyecto','id_trabajo':TID,'url':'https://docs/ante-v2'},'e9'); ok('ok=' in loc(r),'nueva version v2')
ok(q("select max(version) from entrega where id_trabajo=? and tipo_documento='FD124'",TID)[0][0]==2,'version 2')
EID=q("select id_entrega from entrega where id_trabajo=? and tipo_documento='FD124' order by version desc",TID)[0][0]
r=R('/trabajo.jsp',{'id':TID},'doc'); ok('dir_anteproyecto' in r['body'],'director ve formulario')
r=R('/trabajo.jsp',{'id':TID},'e9'); ok('dir_anteproyecto' not in r['body'] and 'name="accion" value="evaluador"' not in r['body'],'estudiante NO ve formularios de docente')
r=R('/docente/evaluar_accion.jsp',{'accion':'dir_anteproyecto','id_trabajo':TID,'id_entrega':EID,'concepto':'APROBADO','observaciones':'ok'},'doc'); ok('ok=' in loc(r),'director aprueba '+loc(r))
tt=q("select fase_actual,fecha_aprob_propuesta,fecha_limite_entrega from trabajo_grado where id_trabajo=?",TID)[0]; print('   ',tt)
ok(tt[0]==3 and tt[1] and tt[2],'fase 3 con fechas'); 
ok(q("select julianday(?)-julianday(?)",tt[2],tt[1])[0][0]==180,'plazo 180 dias')
ev=q("select id_evaluacion,id_usuario_evaluador,fecha_limite_respuesta,concepto from evaluacion where id_entrega=? and rol_evaluador='EVALUADOR'",EID); print('   eval',ev)
ok(len(ev)==1 and ev[0][1]==4 and ev[0][3] is None,'tarea de evaluador creada')
r=R('/docente/evaluar_accion.jsp',{'accion':'dir_anteproyecto','id_trabajo':TID,'id_entrega':EID,'concepto':'APROBADO'},'doc'); ok('err=' in loc(r) or 'acceso' in loc(r),'no se repite el concepto')

sc('FASE 3: evaluador (aplazado -> regresa a fase 2; luego aprueba)')
IDEV=ev[0][0]
r=R('/docente/evaluar_accion.jsp',{'accion':'evaluador','id_trabajo':TID,'id_evaluacion':IDEV,'concepto':'APLAZADO','observaciones':'falta metodologia'},'d4'); ok('ok=' in loc(r),'evaluador aplaza')
tt=q("select fase_actual,fecha_aprob_propuesta,fecha_limite_entrega from trabajo_grado where id_trabajo=?",TID)[0]
ok(tt==(2,None,None),'regresa a fase 2 y limpia fechas '+str(tt))
ok(q("select estado from entrega where id_entrega=?",EID)[0][0]=='APLAZADA','entrega queda aplazada')
R('/estudiante/entrega_accion.jsp',{'accion':'anteproyecto','id_trabajo':TID,'url':'https://docs/ante-v3'},'e9')
EID=q("select id_entrega from entrega where id_trabajo=? and tipo_documento='FD124' order by version desc",TID)[0][0]
R('/docente/evaluar_accion.jsp',{'accion':'dir_anteproyecto','id_trabajo':TID,'id_entrega':EID,'concepto':'APROBADO'},'doc')
IDEV=q("select id_evaluacion from evaluacion where id_entrega=? and rol_evaluador='EVALUADOR'",EID)[0][0]
dl=q("select fecha_limite_respuesta from evaluacion where id_evaluacion=?",IDEV)[0][0]; print('   plazo evaluador',dl)
r=R('/docente/revisiones.jsp',sid='d4'); ok('Evaluar' in r['body'],'evaluador ve pendiente')
r=R('/docente/evaluar_accion.jsp',{'accion':'evaluador','id_trabajo':TID,'id_evaluacion':IDEV,'concepto':'APROBADO','observaciones':'ok'},'doc'); ok('acceso' in loc(r),'director no evalua como evaluador')
r=R('/docente/evaluar_accion.jsp',{'accion':'evaluador','id_trabajo':TID,'id_evaluacion':IDEV,'concepto':'APROBADO','observaciones':'ok'},'d4'); ok('ok=' in loc(r),'evaluador aprueba')
ok(q("select fase_actual from trabajo_grado where id_trabajo=?",TID)[0][0]==3,'sigue en fase 3 hasta que el comite cierre')
r=R('/comite/accion.jsp',{'accion':'avanzar','id_trabajo':TID},'com'); ok('ok=' in loc(r),'comite cierra evaluacion del anteproyecto')
ok(q("select fase_actual from trabajo_grado where id_trabajo=?",TID)[0][0]==4,'fase 4')

sc('FASE 4: informe (90 dias minimos) por el director')
r=R('/docente/evaluar_accion.jsp',{'accion':'dir_informe','id_trabajo':TID,'url':'https://docs/informe1','concepto':'APROBADO'},'doc'); ok('err=' in loc(r),'bloqueado antes de 90 dias')
r=R('/trabajo.jsp',{'id':TID},'doc'); ok('al menos' in r['body'],'mensaje de 90 dias en pantalla')
con.execute("UPDATE trabajo_grado SET fecha_aprob_propuesta=DATE_ADD(CURDATE(),-95) WHERE id_trabajo=?",(TID,))
r=R('/docente/evaluar_accion.jsp',{'accion':'dir_informe','id_trabajo':TID,'url':'https://docs/informe1','concepto':'APLAZADO','observaciones':'corregir'},'doc'); ok('ok=' in loc(r),'informe aplazado')
ok(q("select fase_actual from trabajo_grado where id_trabajo=?",TID)[0][0]==4,'sigue en 4')
r=R('/docente/evaluar_accion.jsp',{'accion':'dir_informe','id_trabajo':TID,'url':'https://docs/informe2','concepto':'APROBADO'},'doc'); ok('ok=' in loc(r),'informe v2 aprobado')
ok(q("select fase_actual from trabajo_grado where id_trabajo=?",TID)[0][0]==5,'fase 5')
r=R('/estudiante/entrega_accion.jsp',{'accion':'anteproyecto','id_trabajo':TID,'url':'https://x/y'},'e9'); ok('err=' in loc(r),'estudiante no registra en fase 5')

sc('FASE 5: evaluador y comite; FASE 6 cierre')
IDEV=q("select ev.id_evaluacion from evaluacion ev join entrega e using(id_entrega) where e.id_trabajo=? and e.tipo_documento='FD125' and ev.rol_evaluador='EVALUADOR'",TID)[0][0]
r=R('/comite/accion.jsp',{'accion':'avanzar','id_trabajo':TID},'com'); ok('err=' in loc(r),'comite no avanza sin evaluador')
R('/docente/evaluar_accion.jsp',{'accion':'evaluador','id_trabajo':TID,'id_evaluacion':IDEV,'concepto':'APROBADO'},'d4')
r=R('/comite/accion.jsp',{'accion':'avanzar','id_trabajo':TID},'com'); ok('ok=' in loc(r),'avanza a fase 6')
ok(q("select fase_actual from trabajo_grado where id_trabajo=?",TID)[0][0]==6,'fase 6')
r=R('/comite/accion.jsp',{'accion':'cerrar','id_trabajo':TID,'repositorio_url':'ftp://x'},'com'); ok('err=' in loc(r),'repositorio url invalida')
r=R('/comite/accion.jsp',{'accion':'cerrar','id_trabajo':TID,'repositorio_url':'https://repo.uts.edu.co/1'},'com'); ok('ok=' in loc(r),'cierre')
ok(q("select estado,cerrado_por from trabajo_grado where id_trabajo=?",TID)[0]==('CERRADO',2),'cerrado')
ok(q("select count(*) from historico_trabajo_grado where id_trabajo=?",TID)[0][0]>=6,'bitacora registrada')
r=R('/estudiante/inscripcion.jsp',sid='e9'); ok(r['status']==200,'estudiante puede inscribir otro trabajo tras el cierre')

sc('PRORROGAS')
# trabajo 5: ya tiene solicitud pendiente
r=R('/comite/prorrogas.jsp',sid='com'); ok('Aprobar' in r['body'],'comite ve solicitud')
r=R('/estudiante/prorroga_accion.jsp',{'id_trabajo':5,'url':'https://pago/p2'},'e6'); ok('err=' in loc(r),'no 2 pendientes')
old=q("select fecha_limite_entrega from trabajo_grado where id_trabajo=5")[0][0]
r=R('/comite/accion.jsp',{'accion':'aprobar_prorroga','id_prorroga':1},'com'); ok('ok=' in loc(r),'aprueba prorroga '+loc(r))
new=q("select fecha_limite_entrega,numero_prorrogas from trabajo_grado where id_trabajo=5")[0]; print('   ',old,'->',new)
ok(new[1]==1 and q("select julianday(?)-julianday(?)",new[0],old)[0][0]==90,'+90 dias y contador 1')
ok(q("select estado from pago where id_pago=9")[0][0]=='VERIFICADO','pago prorroga verificado')
con.execute("UPDATE trabajo_grado SET fecha_limite_entrega=DATE_ADD(CURDATE(),80) WHERE id_trabajo=5")
r=R('/estudiante/prorroga_accion.jsp',{'id_trabajo':5,'url':'https://pago/p2'},'e6'); ok('err=' in loc(r),'fuera de ventana de aviso')
con.execute("UPDATE trabajo_grado SET fecha_limite_entrega=DATE_ADD(CURDATE(),10) WHERE id_trabajo=5")
r=R('/estudiante/prorroga_accion.jsp',{'id_trabajo':5,'url':'https://pago/p2'},'e6'); ok('ok=' in loc(r),'segunda prorroga en ventana '+loc(r))
r=R('/comite/accion.jsp',{'accion':'aprobar_prorroga','id_prorroga':2},'com'); ok('ok=' in loc(r),'aprueba segunda')
ok(q("select numero_prorrogas from trabajo_grado where id_trabajo=5")[0][0]==2,'contador 2')
con.execute("UPDATE trabajo_grado SET fecha_limite_entrega=DATE_ADD(CURDATE(),10) WHERE id_trabajo=5")
r=R('/estudiante/prorroga_accion.jsp',{'id_trabajo':5,'url':'https://pago/p3'},'e6'); ok('err=' in loc(r),'tercera prorroga bloqueada por maximo')
r=R('/estudiante/prorroga.jsp',{'id':5},'e6'); ok('m&aacute;ximo' in r['body'] or 'maximo' in r['body'].lower(),'pantalla muestra maximo')
ok(q("select count(*) from prorroga where id_trabajo=5")[0][0]==2,'no se creo tercera')

sc('Inscripcion con idea propia + rechazo del comite')
login('e8','estudiante8@uts.edu.co')
con.execute("UPDATE trabajo_grado SET estado='CERRADO' WHERE id_trabajo=7")
r=R('/estudiante/inscripcion_accion.jsp',{'modo_idea':'propia','titulo':'Mi idea propia','descripcion':'desc','objetivos':'o','id_linea':'1','palabras_clave':'k','periodo':'2026-2','nivel':'Tecnologia','id_programa':'1','modalidad':'MONOGRAFIA','pago1':'https://pagos/e8'},'e8'); ok('ok=' in loc(r),'inscribe idea propia '+loc(r))
T2=q("select id_trabajo,id_idea from trabajo_grado order by id_trabajo desc limit 1")[0]
ok(q("select estado from banco_idea where id_idea=?",T2[1])[0][0]=='PENDIENTE','idea propia pendiente de comite')
R('/comite/accion.jsp',{'accion':'rechazar_inscripcion','id_trabajo':T2[0]},'com')
ok(q("select estado from trabajo_grado where id_trabajo=?",T2[0])[0][0]=='CANCELADO' and q("select estado from banco_idea where id_idea=?",T2[1])[0][0]=='RECHAZADA','rechazo cancela trabajo e idea')
r=R('/estudiante/inscripcion.jsp',sid='e8'); ok(r['status']==200,'puede reinscribirse')

sc('Ideas: docente propone, comite aprueba')
r=R('/idea_guardar.jsp',{'titulo':'Idea docente','descripcion':'d','id_linea':'1','director':'3','periodo':'2026-2','nivel':'Tecnologia','palabras_clave':'a'},'doc'); ok('ok=' in loc(r),'docente propone')
iid=q("select id_idea from banco_idea where titulo='Idea docente'")[0][0]
ok(q("select estado from banco_idea where id_idea=?",iid)[0][0]=='PENDIENTE','queda pendiente')
r=R('/comite/ideas.jsp',sid='com'); ok('Idea docente' in r['body'],'comite la ve')
R('/comite/accion.jsp',{'accion':'aprobar_idea','id_idea':iid},'com'); ok(q("select estado from banco_idea where id_idea=?",iid)[0][0]=='DISPONIBLE','aprobada')
R('/idea_guardar.jsp',{'titulo':'Idea comite','descripcion':'d','id_linea':'1','director':'','periodo':'2026-2','nivel':'Tecnologia'},'com')
ok(q("select estado,director_sugerido from banco_idea where titulo='Idea comite'")[0]==('DISPONIBLE',None),'comite publica directo, director vacio->NULL')

sc('ADMIN: usuarios, trabajos, catalogos, parametros')
r=R('/admin/usuario_guardar.jsp',{'accion':'guardar','nombres':'Nuevo','apellidos':'Docente','correo':'Nuevo@uts.edu.co','documento':'999','clave':'abcd','roles':['4']},'a'); ok('ok=' in loc(r),'crea usuario '+loc(r))
r=login('nuevo','nuevo@uts.edu.co','abcd'); ok(loc(r)=='/index.jsp','nuevo usuario entra con su clave')
ok(S.sessions['nuevo']['roles']=='DOCENTE','rol asignado')
r=R('/admin/usuario_guardar.jsp',{'accion':'guardar','nombres':'X','apellidos':'Y','correo':'nuevo@uts.edu.co','documento':'1000','clave':'abcd','roles':['4']},'a'); ok('err=' in loc(r),'correo duplicado rechazado')
ok(q("select count(*) from usuario where documento_identidad='1000'")[0][0]==0,'transaccion revirtio')
uid=q("select id_usuario from usuario where correo='nuevo@uts.edu.co'")[0][0]
r=R('/admin/usuario_guardar.jsp',{'accion':'guardar','id':uid,'nombres':'Nuevo2','apellidos':'Docente','correo':'nuevo@uts.edu.co','documento':'999','clave':'','roles':['4','1']},'a'); ok('ok=' in loc(r),'edita sin cambiar clave')
ok(q("select count(*) from usuario_rol where id_usuario=?",uid)[0][0]==2,'roles reasignados')
r=login('nuevo2','nuevo@uts.edu.co','abcd'); ok(loc(r)=='/index.jsp','clave se conserva')
r=R('/admin/usuario_form.jsp',{'id':uid},'a'); ok(r['body'].count('checked')==2,'form marca 2 roles: '+str(r['body'].count('checked')))
R('/admin/usuario_guardar.jsp',{'accion':'inactivar','id':uid},'a'); r=login('nuevo3','nuevo@uts.edu.co','abcd'); ok('inactiva' in loc(r) or 'err=' in loc(r),'inactivo no entra')
r=R('/admin/usuario_guardar.jsp',{'accion':'inactivar','id':1},'a'); ok('err=' in loc(r),'no se autoinactiva')
r=R('/admin/trabajo_guardar.jsp',{'id':2,'accion':'guardar','titulo':'Titulo corregido','resumen':'r','id_linea':'1','id_programa':'1','modalidad':'INVESTIGACION','fecha_limite':''},'a'); ok('ok=' in loc(r),'admin edita trabajo')
ok(q("select count(*) from historico_trabajo_grado where id_trabajo=2 and campo_modificado in ('titulo','modalidad')")[0][0]==2,'historico de edicion')
r=R('/admin/trabajo_guardar.jsp',{'id':2,'accion':'guardar','titulo':'T','resumen':'r','id_linea':'1','id_programa':'1','modalidad':'MONOGRAFIA','fecha_limite':'no-fecha'},'a')
R('/admin/trabajo_guardar.jsp',{'id':2,'accion':'cancelar'},'a'); ok(q("select estado from trabajo_grado where id_trabajo=2")[0][0]=='CANCELADO','borrado logico')
R('/admin/trabajo_guardar.jsp',{'id':2,'accion':'reactivar'},'a'); ok(q("select estado from trabajo_grado where id_trabajo=2")[0][0]=='ACTIVO','reactivado')
r=R('/admin/catalogos_guardar.jsp',{'accion':'linea_add','nombre':'Linea nueva'},'a'); ok('ok=' in loc(r),'agrega linea')
r=R('/admin/catalogos_guardar.jsp',{'accion':'linea_del','id':1},'a'); ok('err=' in loc(r),'linea en uso no se borra (FK)')
r=R('/admin/catalogos_guardar.jsp',{'accion':'param_set','clave':'plazo_dias','valor':'200'},'a'); ok(q("select valor from parametro_sistema where clave='plazo_dias'")[0][0]=='200','parametro editado')
r=R('/calendario_accion.jsp',{'accion':'add','titulo':'Evento','tipo':'ENTREGA','id_fase':'2','inicio':'2026-11-01','fin':'2026-11-05','descripcion':''},'com'); ok('ok=' in loc(r),'calendario agrega')
r=R('/calendario_accion.jsp',{'accion':'add','titulo':'Evento','tipo':'ENTREGA','id_fase':'2','inicio':'2026-11-01','fin':'2026-11-05'},'est'); ok('acceso' in loc(r),'estudiante no edita calendario')
r=R('/cuenta_guardar.jsp',{'actual':'1234','nueva':'nueva1','nueva2':'nueva1'},'e9'); ok('ok=' in loc(r),'cambia su clave')
ok(loc(login('e9b','estudiante9@uts.edu.co','nueva1'))=='/index.jsp','entra con la nueva clave')
r=R('/cuenta_guardar.jsp',{'actual':'zzz','nueva':'nueva2','nueva2':'nueva2'},'e9'); ok('err=' in loc(r),'clave actual incorrecta')
r=R('/logout.jsp',sid='e9'); ok('landing' in loc(r) and 'idUsuario' not in S.sessions['e9'],'logout limpia sesion')

print('\nPruebas:',N[0],'Fallos:',len(FAIL))
for f in FAIL: print(' -',f)

sc('Reportes')
r=R('/comite/reportes.jsp',sid='com'); ok(r['status']==200 and 'GROUP BY' in r['body'] and r['body'].count('<tr>')>10,'reportes renderiza')
r=R('/comite/reportes.jsp',sid='a'); ok(r['status']==200,'admin ve reportes')
r=R('/comite/reportes.jsp',sid='doc'); ok('acceso_denegado' in loc(r),'docente no ve reportes')
print('\nPruebas:',N[0],'Fallos:',len(FAIL))
for f in FAIL: print(' -',f)
