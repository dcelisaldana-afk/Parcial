<%--
    comite/panel.jsp - Tablero del Comite: conteo de trabajos por fase y listado
    con filtros opcionales (fase, estado, programa, busqueda global) y paginacion.
--%>
<c:set var="tituloPagina" value="Panel del Comité"/>
<c:set var="rolRequerido" value="COMITE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/pagina.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<c:set var="fFase" value="${empty param.fase ? '' : param.fase}"/>
<c:set var="fEstado" value="${empty param.estado ? 'ACTIVO' : param.estado}"/>
<c:set var="fProg" value="${empty param.programa ? '' : param.programa}"/>
<c:set var="q" value="${empty param.q ? '' : fn:trim(param.q)}"/>

<sql:query var="rsFases" dataSource="${ds}">
    SELECT f.id_fase, f.nombre, (SELECT COUNT(*) FROM trabajo_grado t WHERE t.fase_actual = f.id_fase AND t.estado = 'ACTIVO') AS n
    FROM fase f ORDER BY f.orden
</sql:query>
<sql:query var="rsProg" dataSource="${ds}">SELECT id_programa, nombre FROM programa_academico ORDER BY nombre</sql:query>
<sql:query var="rsPend" dataSource="${ds}">
    SELECT (SELECT COUNT(*) FROM banco_idea WHERE estado = 'PENDIENTE') AS ideas,
           (SELECT COUNT(*) FROM prorroga WHERE estado = 'PENDIENTE') AS prorrogas
</sql:query>

<sql:query var="rsTotal" dataSource="${ds}">
    SELECT COUNT(*) AS n FROM trabajo_grado t
    WHERE (? = '' OR t.fase_actual = ?) AND (? = 'TODOS' OR t.estado = ?) AND (? = '' OR t.id_programa = ?)
      AND (? = '' OR t.id_trabajo = ? OR t.titulo LIKE CONCAT('%', ?, '%')
           OR EXISTS (SELECT 1 FROM trabajo_grado_estudiante e JOIN usuario u ON u.id_usuario = e.id_usuario_estudiante
                      WHERE e.id_trabajo = t.id_trabajo AND CONCAT_WS(' ', u.nombres, u.apellidos, u.correo) LIKE CONCAT('%', ?, '%')))
    <sql:param value="${fFase}"/><sql:param value="${fFase}"/><sql:param value="${fEstado}"/><sql:param value="${fEstado}"/>
    <sql:param value="${fProg}"/><sql:param value="${fProg}"/>
    <sql:param value="${q}"/><sql:param value="${q}"/><sql:param value="${q}"/><sql:param value="${q}"/>
</sql:query>
<c:set var="total" value="${rsTotal.rows[0].n}"/>

<sql:query var="rsLista" dataSource="${ds}">
    SELECT t.id_trabajo, t.titulo, t.fase_actual, t.estado, p.nombre AS programa, t.fecha_limite_entrega,
           (SELECT CAST(GROUP_CONCAT(u.apellidos) AS CHAR) FROM trabajo_grado_estudiante e JOIN usuario u ON u.id_usuario = e.id_usuario_estudiante
             WHERE e.id_trabajo = t.id_trabajo) AS estudiantes
    FROM trabajo_grado t JOIN programa_academico p ON p.id_programa = t.id_programa
    WHERE (? = '' OR t.fase_actual = ?) AND (? = 'TODOS' OR t.estado = ?) AND (? = '' OR t.id_programa = ?)
      AND (? = '' OR t.id_trabajo = ? OR t.titulo LIKE CONCAT('%', ?, '%')
           OR EXISTS (SELECT 1 FROM trabajo_grado_estudiante e JOIN usuario u ON u.id_usuario = e.id_usuario_estudiante
                      WHERE e.id_trabajo = t.id_trabajo AND CONCAT_WS(' ', u.nombres, u.apellidos, u.correo) LIKE CONCAT('%', ?, '%')))
    ORDER BY t.fase_actual, t.id_trabajo
    LIMIT ?, ?
    <sql:param value="${fFase}"/><sql:param value="${fFase}"/><sql:param value="${fEstado}"/><sql:param value="${fEstado}"/>
    <sql:param value="${fProg}"/><sql:param value="${fProg}"/>
    <sql:param value="${q}"/><sql:param value="${q}"/><sql:param value="${q}"/><sql:param value="${q}"/>
    <sql:param value="${desde}"/><sql:param value="${porPagina}"/>
</sql:query>

<div class="d-flex justify-content-between align-items-center mb-3">
  <h3><i class="bi bi-clipboard-data"></i> Panel del Comit&eacute;</h3>
  <div>
    <a class="btn btn-outline-primary" href="${ctx}/comite/ideas.jsp">Ideas por aprobar <span class="badge text-bg-warning">${rsPend.rows[0].ideas}</span></a>
    <a class="btn btn-outline-primary" href="${ctx}/comite/prorrogas.jsp">Pr&oacute;rrogas <span class="badge text-bg-warning">${rsPend.rows[0].prorrogas}</span></a>
    <a class="btn btn-outline-primary" href="${ctx}/comite/reportes.jsp">Reportes</a>
    <a class="btn btn-warning" href="${ctx}/idea_nueva.jsp">Publicar idea</a>
  </div>
</div>

<div class="row g-2 mb-3">
  <c:forEach var="f" items="${rsFases.rows}">
    <div class="col-6 col-md-2"><a class="text-decoration-none" href="?fase=${f.id_fase}">
      <div class="card text-center"><div class="card-body py-2"><div class="h4 mb-0">${f.n}</div>
        <small class="text-muted">Fase ${f.id_fase}</small></div></div></a></div>
  </c:forEach>
</div>

<form class="row g-2 mb-3" method="get">
  <div class="col-md-4"><input class="form-control" name="q" value="<c:out value='${q}'/>" placeholder="ID, t&iacute;tulo o estudiante"></div>
  <div class="col-md-2"><select class="form-select" name="fase"><option value="">Todas las fases</option>
    <c:forEach var="f" items="${rsFases.rows}"><option value="${f.id_fase}" ${fFase == f.id_fase ? 'selected' : ''}>Fase ${f.id_fase}</option></c:forEach></select></div>
  <div class="col-md-2"><select class="form-select" name="estado">
    <option value="TODOS" ${fEstado == 'TODOS' ? 'selected' : ''}>Todos</option>
    <option value="ACTIVO" ${fEstado == 'ACTIVO' ? 'selected' : ''}>Activos</option>
    <option value="CERRADO" ${fEstado == 'CERRADO' ? 'selected' : ''}>Cerrados</option>
    <option value="CANCELADO" ${fEstado == 'CANCELADO' ? 'selected' : ''}>Cancelados</option></select></div>
  <div class="col-md-3"><select class="form-select" name="programa"><option value="">Todos los programas</option>
    <c:forEach var="p" items="${rsProg.rows}"><option value="${p.id_programa}" ${fProg == p.id_programa ? 'selected' : ''}><c:out value="${p.nombre}"/></option></c:forEach></select></div>
  <div class="col-md-1 d-grid"><button class="btn btn-primary">Filtrar</button></div>
</form>

<p class="small text-muted">${total} trabajo(s).</p>
<div class="table-responsive"><table class="table table-hover tabla-compacta">
  <thead><tr><th>#</th><th>T&iacute;tulo</th><th>Estudiantes</th><th>Programa</th><th>Fase</th><th>Estado</th><th>L&iacute;mite</th><th></th></tr></thead>
  <tbody>
  <c:forEach var="t" items="${rsLista.rows}">
    <tr><td>${t.id_trabajo}</td><td><c:out value="${t.titulo}"/></td><td><c:out value="${t.estudiantes}"/></td>
      <td><c:out value="${t.programa}"/></td><td>${t.fase_actual}</td><td><t:badge valor="${t.estado}"/></td>
      <td><c:if test="${not empty t.fecha_limite_entrega}"><fmt:formatDate value="${t.fecha_limite_entrega}" pattern="dd/MM/yyyy"/></c:if></td>
      <td><a class="btn btn-sm btn-primary" href="${ctx}/trabajo.jsp?id=${t.id_trabajo}">Abrir</a></td></tr>
  </c:forEach>
  <c:if test="${rsLista.rowCount == 0}"><tr><td colspan="8" class="text-muted">Sin resultados.</td></tr></c:if>
  </tbody></table></div>
<t:paginacion pagina="${pagina}" total="${total}" porPagina="${porPagina}"/>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
