<%--
    docente/panel.jsp - Trabajos donde el docente es director o evaluador.
    Ve todas las fases de sus trabajos; edita solo donde le corresponde.
--%>
<c:set var="tituloPagina" value="Panel docente"/>
<c:set var="rolRequerido" value="DOCENTE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<sql:query var="rsMis" dataSource="${ds}">
    SELECT t.id_trabajo, t.titulo, t.fase_actual, t.estado, rd.tipo_rol, f.nombre AS fase,
           DATEDIFF(t.fecha_limite_entrega, CURDATE()) AS dias_restantes
    FROM rol_docente rd
    JOIN trabajo_grado t ON t.id_trabajo = rd.id_trabajo
    JOIN fase f ON f.id_fase = t.fase_actual
    WHERE rd.id_usuario_docente = ? AND rd.activo = 1
    ORDER BY t.estado, t.fase_actual, t.id_trabajo
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>

<div class="d-flex justify-content-between align-items-center mb-3">
  <h3><i class="bi bi-person-workspace"></i> Mis trabajos como docente</h3>
  <div>
    <a class="btn btn-outline-primary" href="${ctx}/docente/revisiones.jsp"><i class="bi bi-inbox"></i> Revisiones pendientes</a>
    <a class="btn btn-warning" href="${ctx}/idea_nueva.jsp"><i class="bi bi-lightbulb"></i> Proponer idea</a>
  </div>
</div>

<div class="table-responsive"><table class="table table-hover tabla-compacta">
  <thead><tr><th>#</th><th>T&iacute;tulo</th><th>Mi rol</th><th>Fase</th><th>Estado</th><th>D&iacute;as restantes</th><th></th></tr></thead>
  <tbody>
  <c:forEach var="t" items="${rsMis.rows}">
    <tr><td>${t.id_trabajo}</td><td><c:out value="${t.titulo}"/></td>
      <td><span class="badge text-bg-dark">${t.tipo_rol}</span></td>
      <td>${t.fase_actual}. <c:out value="${t.fase}"/></td><td><t:badge valor="${t.estado}"/></td>
      <td><c:out value="${t.dias_restantes}"/></td>
      <td><a class="btn btn-sm btn-primary" href="${ctx}/trabajo.jsp?id=${t.id_trabajo}">Abrir</a></td></tr>
  </c:forEach>
  <c:if test="${rsMis.rowCount == 0}"><tr><td colspan="7" class="text-muted">No tiene trabajos asignados.</td></tr></c:if>
  </tbody></table></div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
