<%--
    trabajo.jsp - Detalle de UN trabajo de grado, compartido por todos los roles.
    Quien puede verlo: sus estudiantes, sus docentes (director/evaluador),
    el Comite y el Administrador. Todos VEN las 6 fases; cada rol solo ve el
    formulario de la accion que le corresponde en la fase actual.
--%>
<c:set var="tituloPagina" value="Detalle del trabajo"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>

<c:set var="priv" value="${fn:contains(sessionScope.roles, 'COMITE') or fn:contains(sessionScope.roles, 'ADMINISTRADOR') ? 'S' : 'N'}"/>
<c:set var="idT" value="${param.id}"/>

<%-- Control de acceso a nivel de registro --%>
<sql:query var="rsAcc" dataSource="${ds}">
    SELECT (SELECT COUNT(*) FROM trabajo_grado_estudiante WHERE id_trabajo = ? AND id_usuario_estudiante = ?) AS est,
           (SELECT COUNT(*) FROM rol_docente WHERE id_trabajo = ? AND id_usuario_docente = ? AND activo = 1) AS doc,
           (SELECT COUNT(*) FROM trabajo_grado WHERE id_trabajo = ?) AS existe
    <sql:param value="${idT}"/><sql:param value="${sessionScope.idUsuario}"/>
    <sql:param value="${idT}"/><sql:param value="${sessionScope.idUsuario}"/>
    <sql:param value="${idT}"/>
</sql:query>
<c:set var="acc" value="${rsAcc.rows[0]}"/>
<c:if test="${acc.existe == 0}">
    <c:redirect url="/index.jsp"><c:param name="err" value="El trabajo no existe."/></c:redirect>
</c:if>
<c:if test="${priv == 'N' and acc.est == 0 and acc.doc == 0}">
    <c:redirect url="/acceso_denegado.jsp"/>
</c:if>
<c:set var="soyEst" value="${acc.est > 0}"/>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<sql:query var="rsT" dataSource="${ds}">
    SELECT t.*, l.nombre AS linea, p.nombre AS programa, f.nombre AS fase,
           DATEDIFF(t.fecha_limite_entrega, CURDATE()) AS dias_restantes,
           DATEDIFF(CURDATE(), t.fecha_aprob_propuesta) AS dias_desde_aprob
    FROM trabajo_grado t
    JOIN linea_investigacion l ON l.id_linea = t.id_linea
    JOIN programa_academico p ON p.id_programa = t.id_programa
    JOIN fase f ON f.id_fase = t.fase_actual
    WHERE t.id_trabajo = ?
    <sql:param value="${idT}"/>
</sql:query>
<c:set var="t" value="${rsT.rows[0]}"/>

<sql:query var="rsParam" dataSource="${ds}">SELECT clave, valor FROM parametro_sistema</sql:query>
<c:forEach var="pr" items="${rsParam.rows}">
    <c:if test="${pr.clave == 'dias_minimos_informe'}"><c:set var="diasMin" value="${pr.valor}"/></c:if>
    <c:if test="${pr.clave == 'max_prorrogas'}"><c:set var="maxPro" value="${pr.valor}"/></c:if>
</c:forEach>

<sql:query var="rsEst" dataSource="${ds}">
    SELECT u.id_usuario, u.nombres, u.apellidos, u.correo
    FROM trabajo_grado_estudiante e JOIN usuario u ON u.id_usuario = e.id_usuario_estudiante
    WHERE e.id_trabajo = ? ORDER BY u.apellidos
    <sql:param value="${idT}"/>
</sql:query>
<sql:query var="rsDoc" dataSource="${ds}">
    SELECT rd.tipo_rol, rd.id_usuario_docente, u.nombres, u.apellidos
    FROM rol_docente rd JOIN usuario u ON u.id_usuario = rd.id_usuario_docente
    WHERE rd.id_trabajo = ? AND rd.activo = 1 ORDER BY rd.tipo_rol
    <sql:param value="${idT}"/>
</sql:query>
<c:set var="miRol" value=""/>
<c:set var="hayDirector" value="false"/>
<c:forEach var="d" items="${rsDoc.rows}">
    <c:if test="${d.id_usuario_docente == sessionScope.idUsuario}"><c:set var="miRol" value="${d.tipo_rol}"/></c:if>
    <c:if test="${d.tipo_rol == 'DIRECTOR'}"><c:set var="hayDirector" value="true"/></c:if>
</c:forEach>

<sql:query var="rsPagos" dataSource="${ds}">
    SELECT pg.id_pago, pg.tipo_pago, pg.valor, pg.comprobante_url, pg.estado, pg.fecha_pago, pg.id_usuario_estudiante,
           u.nombres, u.apellidos
    FROM pago pg JOIN usuario u ON u.id_usuario = pg.id_usuario_estudiante
    WHERE pg.id_trabajo = ? ORDER BY pg.id_pago
    <sql:param value="${idT}"/>
</sql:query>
<sql:query var="rsEnt" dataSource="${ds}">
    SELECT e.id_entrega, e.id_fase, e.tipo_documento, e.version, e.estado, e.fecha_entrega,
           d.url_documento, u.nombres, u.apellidos
    FROM entrega e
    LEFT JOIN documento d ON d.id_entrega = e.id_entrega
    LEFT JOIN usuario u ON u.id_usuario = d.subido_por
    WHERE e.id_trabajo = ? ORDER BY e.id_fase, e.version
    <sql:param value="${idT}"/>
</sql:query>
<sql:query var="rsEval" dataSource="${ds}">
    SELECT ev.id_evaluacion, ev.id_entrega, ev.rol_evaluador, ev.concepto, ev.observaciones,
           ev.fecha_limite_respuesta, ev.fecha_evaluacion, ev.id_usuario_evaluador,
           u.nombres, u.apellidos, e.tipo_documento, e.version
    FROM evaluacion ev JOIN entrega e ON e.id_entrega = ev.id_entrega
    JOIN usuario u ON u.id_usuario = ev.id_usuario_evaluador
    WHERE e.id_trabajo = ? ORDER BY ev.id_evaluacion
    <sql:param value="${idT}"/>
</sql:query>
<sql:query var="rsPro" dataSource="${ds}">
    SELECT numero_prorroga, estado, fecha_solicitud, nuevo_plazo_fecha FROM prorroga WHERE id_trabajo = ? ORDER BY numero_prorroga
    <sql:param value="${idT}"/>
</sql:query>

<%-- Ultima entrega del documento de la fase actual (FD124 en fases 2-3, FD125 en fases 4-5) --%>
<c:set var="tipoDoc" value="${t.fase_actual <= 3 ? 'FD124' : 'FD125'}"/>
<sql:query var="rsUlt" dataSource="${ds}">
    SELECT id_entrega, version, estado FROM entrega
    WHERE id_trabajo = ? AND tipo_documento = ? ORDER BY version DESC LIMIT 1
    <sql:param value="${idT}"/><sql:param value="${tipoDoc}"/>
</sql:query>
<c:set var="ult" value="${rsUlt.rowCount > 0 ? rsUlt.rows[0] : null}"/>
<c:set var="puedeNuevaVersion" value="${empty ult or ult.estado == 'APLAZADA' or ult.estado == 'RECHAZADA'}"/>

<sql:query var="rsMiEval" dataSource="${ds}">
    SELECT ev.id_evaluacion, ev.fecha_limite_respuesta
    FROM evaluacion ev JOIN entrega e ON e.id_entrega = ev.id_entrega
    WHERE e.id_trabajo = ? AND ev.id_usuario_evaluador = ? AND ev.rol_evaluador = 'EVALUADOR' AND ev.concepto IS NULL
    <sql:param value="${idT}"/><sql:param value="${sessionScope.idUsuario}"/>
</sql:query>

<%-- ===================== ENCABEZADO ===================== --%>
<div class="d-flex justify-content-between align-items-start">
  <div>
    <h3 class="mb-1"><c:out value="${t.titulo}"/></h3>
    <div class="text-muted small">Trabajo #${t.id_trabajo} &middot; <c:out value="${t.linea}"/> &middot; <c:out value="${t.programa}"/> &middot; <c:out value="${t.modalidad}"/></div>
  </div>
  <t:badge valor="${t.estado}"/>
</div>
<div class="my-3"><t:fases actual="${t.fase_actual}" estado="${t.estado}"/></div>

<div class="row g-3">
  <div class="col-lg-6"><div class="card h-100"><div class="card-body">
    <h6><i class="bi bi-people"></i> Equipo</h6>
    <p class="small mb-1"><b>Estudiantes:</b></p>
    <ul class="small">
      <c:forEach var="e" items="${rsEst.rows}"><li><c:out value="${e.nombres} ${e.apellidos}"/> (<c:out value="${e.correo}"/>)</li></c:forEach>
    </ul>
    <p class="small mb-1"><b>Docentes:</b></p>
    <ul class="small mb-0">
      <c:forEach var="d" items="${rsDoc.rows}"><li><span class="badge text-bg-dark">${d.tipo_rol}</span> <c:out value="${d.nombres} ${d.apellidos}"/></li></c:forEach>
      <c:if test="${rsDoc.rowCount == 0}"><li class="text-muted">Pendientes de asignar por el Comit&eacute;.</li></c:if>
    </ul>
  </div></div></div>
  <div class="col-lg-6"><div class="card h-100"><div class="card-body small">
    <h6><i class="bi bi-calendar-event"></i> Plazos</h6>
    <p class="mb-1"><b>Fase actual:</b> <c:out value="${t.fase}"/></p>
    <p class="mb-1"><b>Aprobaci&oacute;n del anteproyecto:</b>
      <c:choose><c:when test="${empty t.fecha_aprob_propuesta}">pendiente</c:when>
        <c:otherwise><fmt:formatDate value="${t.fecha_aprob_propuesta}" pattern="dd/MM/yyyy"/> (hace ${t.dias_desde_aprob} d&iacute;as)</c:otherwise></c:choose></p>
    <p class="mb-1"><b>Fecha l&iacute;mite:</b>
      <c:choose><c:when test="${empty t.fecha_limite_entrega}">se define al aprobar el anteproyecto</c:when>
        <c:otherwise><fmt:formatDate value="${t.fecha_limite_entrega}" pattern="dd/MM/yyyy"/>
          <c:if test="${t.estado == 'ACTIVO' and t.dias_restantes < 0}"><span class="badge text-bg-danger">vencido</span></c:if></c:otherwise></c:choose></p>
    <p class="mb-1"><b>Pr&oacute;rrogas usadas:</b> ${t.numero_prorrogas} de ${maxPro}</p>
    <c:if test="${not empty t.repositorio_url}">
      <p class="mb-0"><b>Repositorio:</b> <a class="url-doc" target="_blank" rel="noopener" href="<c:out value='${t.repositorio_url}'/>"><c:out value="${t.repositorio_url}"/></a></p>
    </c:if>
  </div></div></div>
</div>

<%-- ===================== ACCIONES POR ROL ===================== --%>
<c:if test="${t.estado == 'ACTIVO'}">

<%-- ESTUDIANTE --%>
<c:if test="${soyEst}">
  <c:if test="${t.fase_actual == 1}">
    <c:forEach var="pg" items="${rsPagos.rows}">
      <c:if test="${pg.estado == 'RECHAZADO' and pg.id_usuario_estudiante == sessionScope.idUsuario and pg.tipo_pago == 'DERECHOS_GRADO'}">
        <div class="card border-danger mt-3"><div class="card-body">
          <h6 class="text-danger">Su recibo de pago fue rechazado</h6>
          <form class="row g-2" action="${ctx}/estudiante/entrega_accion.jsp" method="post">
            <input type="hidden" name="accion" value="pago"><input type="hidden" name="id_trabajo" value="${t.id_trabajo}">
            <input type="hidden" name="id_pago" value="${pg.id_pago}">
            <div class="col-md-9"><input type="url" class="form-control" name="url" data-url required placeholder="Nueva URL del recibo de pago"></div>
            <div class="col-md-3 d-grid"><button class="btn btn-danger">Reenviar recibo</button></div>
          </form></div></div>
      </c:if>
    </c:forEach>
  </c:if>
  <c:if test="${t.fase_actual == 2 and puedeNuevaVersion}">
    <div class="card border-warning mt-3"><div class="card-body">
      <h6>Fase 2 &mdash; Registrar anteproyecto (FD-124)</h6>
      <form class="row g-2" action="${ctx}/estudiante/entrega_accion.jsp" method="post">
        <input type="hidden" name="accion" value="anteproyecto"><input type="hidden" name="id_trabajo" value="${t.id_trabajo}">
        <div class="col-md-9"><input type="url" class="form-control" name="url" data-url required placeholder="URL del anteproyecto (no del recibo de pago)"></div>
        <div class="col-md-3 d-grid"><button class="btn btn-warning">Registrar URL</button></div>
      </form></div></div>
  </c:if>
  <c:if test="${t.fase_actual >= 2 and not puedeNuevaVersion and t.fase_actual == 2}">
    <div class="alert alert-info mt-3 mb-0">Su anteproyecto est&aacute; pendiente de respuesta del director. Consulte aqu&iacute; el estado.</div>
  </c:if>
  <c:if test="${t.fase_actual >= 4}">
    <div class="alert alert-secondary mt-3 mb-0">En esta fase el informe lo registra el director; usted solo consulta el estado.</div>
  </c:if>
  <c:if test="${t.fase_actual >= 3 and not empty t.fecha_limite_entrega}">
    <a class="btn btn-outline-primary mt-3" href="${ctx}/estudiante/prorroga.jsp?id=${t.id_trabajo}"><i class="bi bi-hourglass-split"></i> Pr&oacute;rrogas</a>
  </c:if>
</c:if>

<%-- DIRECTOR --%>
<c:if test="${miRol == 'DIRECTOR'}">
  <c:if test="${t.fase_actual == 2 and not empty ult and ult.estado == 'PENDIENTE'}">
    <div class="card border-primary mt-3"><div class="card-body">
      <h6>Fase 2 &mdash; Concepto del director sobre el anteproyecto</h6>
      <form action="${ctx}/docente/evaluar_accion.jsp" method="post">
        <input type="hidden" name="accion" value="dir_anteproyecto"><input type="hidden" name="id_trabajo" value="${t.id_trabajo}">
        <input type="hidden" name="id_entrega" value="${ult.id_entrega}">
        <div class="row g-2">
          <div class="col-md-3"><select class="form-select" name="concepto" required>
            <option value="APROBADO">Aprobado</option><option value="APLAZADO">Aplazado</option><option value="RECHAZADO">Rechazado</option></select></div>
          <div class="col-md-7"><input class="form-control" name="observaciones" placeholder="Observaciones" maxlength="500"></div>
          <div class="col-md-2 d-grid"><button class="btn btn-primary">Guardar</button></div>
        </div>
      </form></div></div>
  </c:if>
  <c:if test="${t.fase_actual == 4}">
    <div class="card border-primary mt-3"><div class="card-body">
      <h6>Fase 4 &mdash; Registrar el informe del trabajo de grado (FD-125)</h6>
      <c:choose>
        <c:when test="${t.dias_desde_aprob < diasMin}">
          <div class="alert alert-warning mb-0">Deben pasar al menos ${diasMin} d&iacute;as desde la aprobaci&oacute;n del anteproyecto (van ${t.dias_desde_aprob}).</div>
        </c:when>
        <c:when test="${not puedeNuevaVersion}">
          <div class="alert alert-info mb-0">El informe ya fue registrado y est&aacute; en revisi&oacute;n.</div>
        </c:when>
        <c:otherwise>
          <form action="${ctx}/docente/evaluar_accion.jsp" method="post">
            <input type="hidden" name="accion" value="dir_informe"><input type="hidden" name="id_trabajo" value="${t.id_trabajo}">
            <div class="row g-2">
              <div class="col-12"><input type="url" class="form-control" name="url" data-url required placeholder="URL del informe del trabajo de grado"></div>
              <div class="col-md-3"><select class="form-select" name="concepto" required>
                <option value="APROBADO">Aprobado</option><option value="APLAZADO">Aplazado</option><option value="RECHAZADO">Reemplazado / rechazado</option></select></div>
              <div class="col-md-7"><input class="form-control" name="observaciones" placeholder="Observaciones" maxlength="500"></div>
              <div class="col-md-2 d-grid"><button class="btn btn-primary">Registrar</button></div>
            </div>
          </form>
        </c:otherwise>
      </c:choose>
    </div></div>
  </c:if>
</c:if>

<%-- EVALUADOR --%>
<c:if test="${miRol == 'EVALUADOR' and rsMiEval.rowCount > 0 and (t.fase_actual == 3 or t.fase_actual == 5)}">
  <div class="card border-success mt-3"><div class="card-body">
    <h6>Fase ${t.fase_actual} &mdash; Su evaluaci&oacute;n
      <small class="text-muted">(plazo: <fmt:formatDate value="${rsMiEval.rows[0].fecha_limite_respuesta}" pattern="dd/MM/yyyy"/>)</small></h6>
    <form action="${ctx}/docente/evaluar_accion.jsp" method="post">
      <input type="hidden" name="accion" value="evaluador"><input type="hidden" name="id_trabajo" value="${t.id_trabajo}">
      <input type="hidden" name="id_evaluacion" value="${rsMiEval.rows[0].id_evaluacion}">
      <div class="row g-2">
        <div class="col-md-3"><select class="form-select" name="concepto" required>
          <option value="APROBADO">Aprobado</option><option value="APLAZADO">Aplazado</option><option value="RECHAZADO">Rechazado</option></select></div>
        <div class="col-md-7"><input class="form-control" name="observaciones" placeholder="Observaciones" maxlength="500"></div>
        <div class="col-md-2 d-grid"><button class="btn btn-success">Enviar</button></div>
      </div>
    </form></div></div>
</c:if>

<%-- COMITE --%>
<c:if test="${fn:contains(sessionScope.roles, 'COMITE')}">
  <sql:query var="rsEvalEv" dataSource="${ds}">
    SELECT ev.concepto FROM evaluacion ev JOIN entrega e ON e.id_entrega = ev.id_entrega
    WHERE e.id_trabajo = ? AND e.tipo_documento = ? AND ev.rol_evaluador = 'EVALUADOR'
    ORDER BY e.version DESC LIMIT 1
    <sql:param value="${idT}"/><sql:param value="${tipoDoc}"/>
  </sql:query>
  <c:set var="conceptoEv" value="${rsEvalEv.rowCount > 0 ? rsEvalEv.rows[0].concepto : ''}"/>
  <div class="card border-dark mt-3"><div class="card-body">
    <h6><i class="bi bi-clipboard-check"></i> Acciones del Comit&eacute;</h6>
    <c:choose>
      <c:when test="${t.fase_actual == 1}">
        <sql:query var="rsDocentes" dataSource="${ds}">
          SELECT u.id_usuario, u.nombres, u.apellidos FROM usuario u
          JOIN usuario_rol ur ON ur.id_usuario = u.id_usuario JOIN rol r ON r.id_rol = ur.id_rol
          WHERE r.nombre = 'DOCENTE' AND u.estado = 'ACTIVO' ORDER BY u.apellidos
        </sql:query>
        <p class="small">Verifique primero cada recibo de pago (tabla de pagos) y luego apruebe la inscripci&oacute;n asignando director y evaluador (deben ser distintos).</p>
        <form action="${ctx}/comite/accion.jsp" method="post" class="row g-2">
          <input type="hidden" name="accion" value="aprobar_inscripcion"><input type="hidden" name="id_trabajo" value="${t.id_trabajo}">
          <div class="col-md-4"><select class="form-select" name="id_director" required><option value="">Director...</option>
            <c:forEach var="d" items="${rsDocentes.rows}"><option value="${d.id_usuario}"><c:out value="${d.nombres} ${d.apellidos}"/></option></c:forEach></select></div>
          <div class="col-md-4"><select class="form-select" name="id_evaluador" required><option value="">Evaluador...</option>
            <c:forEach var="d" items="${rsDocentes.rows}"><option value="${d.id_usuario}"><c:out value="${d.nombres} ${d.apellidos}"/></option></c:forEach></select></div>
          <div class="col-md-4 d-grid"><button class="btn btn-success">Aprobar inscripci&oacute;n (pasa a Fase 2)</button></div>
        </form>
        <form action="${ctx}/comite/accion.jsp" method="post" class="mt-2">
          <input type="hidden" name="accion" value="rechazar_inscripcion"><input type="hidden" name="id_trabajo" value="${t.id_trabajo}">
          <button class="btn btn-outline-danger btn-sm" data-confirmar="¿Rechazar la inscripción? El trabajo quedará cancelado.">Rechazar inscripci&oacute;n</button>
        </form>
      </c:when>
      <c:when test="${t.fase_actual == 3 or t.fase_actual == 5}">
        <c:choose>
          <c:when test="${conceptoEv == 'APROBADO'}">
            <form action="${ctx}/comite/accion.jsp" method="post">
              <input type="hidden" name="accion" value="avanzar"><input type="hidden" name="id_trabajo" value="${t.id_trabajo}">
              <button class="btn btn-success">
                <c:choose><c:when test="${t.fase_actual == 3}">Cerrar evaluaci&oacute;n del anteproyecto (pasa a Fase 4)</c:when>
                  <c:otherwise>Aprobar el trabajo de grado (pasa a Fase 6)</c:otherwise></c:choose></button>
            </form>
          </c:when>
          <c:otherwise><p class="small text-muted mb-0">Se habilita cuando el evaluador emita concepto APROBADO (concepto actual: <b>${empty conceptoEv ? 'pendiente' : conceptoEv}</b>).</p></c:otherwise>
        </c:choose>
      </c:when>
      <c:when test="${t.fase_actual == 6}">
        <form action="${ctx}/comite/accion.jsp" method="post" class="row g-2">
          <input type="hidden" name="accion" value="cerrar"><input type="hidden" name="id_trabajo" value="${t.id_trabajo}">
          <div class="col-md-9"><input type="url" class="form-control" name="repositorio_url" data-url placeholder="URL del repositorio institucional (opcional)"></div>
          <div class="col-md-3 d-grid"><button class="btn btn-dark" data-confirmar="¿Cerrar definitivamente el trabajo?">Cierre final</button></div>
        </form>
        <p class="small text-muted mt-2 mb-0">La sustentaci&oacute;n y la entrega a biblioteca se realizan fuera del software.</p>
      </c:when>
      <c:otherwise><p class="small text-muted mb-0">En esta fase la acci&oacute;n corresponde al director/estudiante; el Comit&eacute; solo consulta.</p></c:otherwise>
    </c:choose>
  </div></div>
</c:if>

</c:if>

<%-- ===================== HISTORIAL (solo lectura para todos) ===================== --%>
<h5 class="mt-4">Pagos</h5>
<div class="table-responsive"><table class="table table-sm tabla-compacta">
  <thead><tr><th>Estudiante</th><th>Tipo</th><th>Valor</th><th>Recibo (URL)</th><th>Estado</th>
    <c:if test="${fn:contains(sessionScope.roles, 'COMITE') and t.estado == 'ACTIVO'}"><th>Verificar</th></c:if></tr></thead>
  <tbody>
  <c:forEach var="pg" items="${rsPagos.rows}">
    <tr><td><c:out value="${pg.nombres} ${pg.apellidos}"/></td><td>${pg.tipo_pago}</td>
      <td>$<fmt:formatNumber value="${pg.valor}" pattern="#,##0"/></td>
      <td class="url-doc"><a target="_blank" rel="noopener" href="<c:out value='${pg.comprobante_url}'/>"><c:out value="${pg.comprobante_url}"/></a></td>
      <td><t:badge valor="${pg.estado}"/></td>
      <c:if test="${fn:contains(sessionScope.roles, 'COMITE') and t.estado == 'ACTIVO'}">
        <td>
          <c:if test="${pg.estado == 'PENDIENTE' and pg.tipo_pago == 'DERECHOS_GRADO'}">
            <form class="d-inline" action="${ctx}/comite/accion.jsp" method="post">
              <input type="hidden" name="accion" value="verificar_pago"><input type="hidden" name="id_trabajo" value="${t.id_trabajo}">
              <input type="hidden" name="id_pago" value="${pg.id_pago}">
              <button name="resultado" value="VERIFICADO" class="btn btn-sm btn-success">Verificar</button>
              <button name="resultado" value="RECHAZADO" class="btn btn-sm btn-outline-danger">Rechazar</button>
            </form>
          </c:if>
        </td>
      </c:if></tr>
  </c:forEach></tbody></table></div>

<h5 class="mt-4">Documentos entregados</h5>
<div class="table-responsive"><table class="table table-sm tabla-compacta">
  <thead><tr><th>Fase</th><th>Documento</th><th>Versi&oacute;n</th><th>URL</th><th>Registrado por</th><th>Fecha</th><th>Estado</th></tr></thead>
  <tbody>
  <c:forEach var="e" items="${rsEnt.rows}">
    <tr><td>${e.id_fase}</td><td>${e.tipo_documento}</td><td>v${e.version}</td>
      <td class="url-doc"><a target="_blank" rel="noopener" href="<c:out value='${e.url_documento}'/>"><c:out value="${e.url_documento}"/></a></td>
      <td><c:out value="${e.nombres} ${e.apellidos}"/></td>
      <td><fmt:formatDate value="${e.fecha_entrega}" pattern="dd/MM/yyyy"/></td><td><t:badge valor="${e.estado}"/></td></tr>
  </c:forEach>
  <c:if test="${rsEnt.rowCount == 0}"><tr><td colspan="7" class="text-muted">Sin documentos todav&iacute;a.</td></tr></c:if>
  </tbody></table></div>

<h5 class="mt-4">Evaluaciones</h5>
<div class="table-responsive"><table class="table table-sm tabla-compacta">
  <thead><tr><th>Documento</th><th>Rol</th><th>Docente</th><th>Concepto</th><th>Observaciones</th><th>Plazo de respuesta</th></tr></thead>
  <tbody>
  <c:forEach var="ev" items="${rsEval.rows}">
    <tr><td>${ev.tipo_documento} v${ev.version}</td><td>${ev.rol_evaluador}</td><td><c:out value="${ev.nombres} ${ev.apellidos}"/></td>
      <td><c:choose><c:when test="${empty ev.concepto}"><span class="badge text-bg-warning">PENDIENTE</span></c:when><c:otherwise><t:badge valor="${ev.concepto}"/></c:otherwise></c:choose></td>
      <td><c:out value="${ev.observaciones}"/></td>
      <td><c:if test="${not empty ev.fecha_limite_respuesta}"><fmt:formatDate value="${ev.fecha_limite_respuesta}" pattern="dd/MM/yyyy"/></c:if></td></tr>
  </c:forEach>
  <c:if test="${rsEval.rowCount == 0}"><tr><td colspan="6" class="text-muted">Sin evaluaciones todav&iacute;a.</td></tr></c:if>
  </tbody></table></div>

<c:if test="${rsPro.rowCount > 0}">
  <h5 class="mt-4">Pr&oacute;rrogas</h5>
  <ul class="small">
    <c:forEach var="p" items="${rsPro.rows}">
      <li>Pr&oacute;rroga ${p.numero_prorroga}: <t:badge valor="${p.estado}"/>
        <c:if test="${not empty p.nuevo_plazo_fecha}"> &mdash; nuevo plazo <fmt:formatDate value="${p.nuevo_plazo_fecha}" pattern="dd/MM/yyyy"/></c:if></li>
    </c:forEach>
  </ul>
</c:if>

<c:if test="${priv == 'S'}">
  <sql:query var="rsHist" dataSource="${ds}">
    SELECT h.campo_modificado, h.valor_anterior, h.valor_nuevo, h.fecha, u.nombres, u.apellidos
    FROM historico_trabajo_grado h JOIN usuario u ON u.id_usuario = h.modificado_por
    WHERE h.id_trabajo = ? ORDER BY h.id_historico DESC LIMIT 15
    <sql:param value="${idT}"/>
  </sql:query>
  <h5 class="mt-4">Bit&aacute;cora de cambios</h5>
  <ul class="small">
    <c:forEach var="h" items="${rsHist.rows}">
      <li><fmt:formatDate value="${h.fecha}" pattern="dd/MM/yyyy HH:mm"/> &mdash; <c:out value="${h.nombres} ${h.apellidos}"/>:
          <b><c:out value="${h.campo_modificado}"/></b> <c:out value="${h.valor_anterior}"/> &rarr; <c:out value="${h.valor_nuevo}"/></li>
    </c:forEach>
  </ul>
  <c:if test="${fn:contains(sessionScope.roles, 'ADMINISTRADOR')}">
    <a class="btn btn-outline-secondary btn-sm" href="${ctx}/admin/trabajo_editar.jsp?id=${t.id_trabajo}"><i class="bi bi-pencil"></i> Editar datos (Administrador)</a>
  </c:if>
</c:if>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
