<%--
    docente/revisiones.jsp - Bandeja de pendientes del docente:
      * director: anteproyectos por conceptuar (Fase 2) e informes por registrar (Fase 4)
      * evaluador: evaluaciones con plazo de 5 dias habiles (Fases 3 y 5)
--%>
<c:set var="tituloPagina" value="Revisiones pendientes"/>
<c:set var="rolRequerido" value="DOCENTE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<sql:query var="rsDir" dataSource="${ds}">
    SELECT t.id_trabajo, t.titulo, t.fase_actual,
           CASE WHEN t.fase_actual = 2 THEN 'Conceptuar anteproyecto' ELSE 'Registrar informe' END AS tarea
    FROM rol_docente rd JOIN trabajo_grado t ON t.id_trabajo = rd.id_trabajo
    WHERE rd.id_usuario_docente = ? AND rd.tipo_rol = 'DIRECTOR' AND rd.activo = 1 AND t.estado = 'ACTIVO'
      AND ((t.fase_actual = 2 AND EXISTS (SELECT 1 FROM entrega e WHERE e.id_trabajo = t.id_trabajo AND e.tipo_documento = 'FD124' AND e.estado = 'PENDIENTE'))
        OR (t.fase_actual = 4))
    ORDER BY t.id_trabajo
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<sql:query var="rsEv" dataSource="${ds}">
    SELECT t.id_trabajo, t.titulo, t.fase_actual, ev.fecha_limite_respuesta,
           DATEDIFF(ev.fecha_limite_respuesta, NOW()) AS dias
    FROM evaluacion ev
    JOIN entrega e ON e.id_entrega = ev.id_entrega
    JOIN trabajo_grado t ON t.id_trabajo = e.id_trabajo
    WHERE ev.id_usuario_evaluador = ? AND ev.rol_evaluador = 'EVALUADOR' AND ev.concepto IS NULL AND t.estado = 'ACTIVO'
    ORDER BY ev.fecha_limite_respuesta
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>

<h3 class="mb-3"><i class="bi bi-inbox"></i> Revisiones pendientes</h3>

<h5>Como director</h5>
<table class="table tabla-compacta"><thead><tr><th>#</th><th>Trabajo</th><th>Tarea</th><th></th></tr></thead><tbody>
  <c:forEach var="d" items="${rsDir.rows}">
    <tr><td>${d.id_trabajo}</td><td><c:out value="${d.titulo}"/></td><td>${d.tarea}</td>
      <td><a class="btn btn-sm btn-primary" href="${ctx}/trabajo.jsp?id=${d.id_trabajo}">Abrir</a></td></tr>
  </c:forEach>
  <c:if test="${rsDir.rowCount == 0}"><tr><td colspan="4" class="text-muted">Nada pendiente como director.</td></tr></c:if>
</tbody></table>

<h5 class="mt-4">Como evaluador</h5>
<table class="table tabla-compacta"><thead><tr><th>#</th><th>Trabajo</th><th>Fase</th><th>Plazo</th><th></th></tr></thead><tbody>
  <c:forEach var="e" items="${rsEv.rows}">
    <tr><td>${e.id_trabajo}</td><td><c:out value="${e.titulo}"/></td><td>${e.fase_actual}</td>
      <td><fmt:formatDate value="${e.fecha_limite_respuesta}" pattern="dd/MM/yyyy"/>
        <c:if test="${e.dias < 0}"><span class="badge text-bg-danger">vencido</span></c:if></td>
      <td><a class="btn btn-sm btn-success" href="${ctx}/trabajo.jsp?id=${e.id_trabajo}">Evaluar</a></td></tr>
  </c:forEach>
  <c:if test="${rsEv.rowCount == 0}"><tr><td colspan="5" class="text-muted">Nada pendiente como evaluador.</td></tr></c:if>
</tbody></table>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
