<%--
    estudiante/panel.jsp - Panel del estudiante: sus trabajos de grado, la fase
    en la que van y el plazo restante. Desde aqui inscribe una idea nueva.
--%>
<c:set var="tituloPagina" value="Mi panel"/>
<c:set var="rolRequerido" value="ESTUDIANTE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<sql:query var="rsMis" dataSource="${ds}">
    SELECT t.id_trabajo, t.titulo, t.fase_actual, t.estado, t.fecha_limite_entrega, t.numero_prorrogas,
           DATEDIFF(t.fecha_limite_entrega, CURDATE()) AS dias_restantes,
           f.nombre AS fase
    FROM trabajo_grado t
    JOIN trabajo_grado_estudiante e ON e.id_trabajo = t.id_trabajo
    JOIN fase f ON f.id_fase = t.fase_actual
    WHERE e.id_usuario_estudiante = ?
    ORDER BY t.id_trabajo DESC
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>

<sql:query var="rsActivo" dataSource="${ds}">
    SELECT COUNT(*) AS n
    FROM trabajo_grado t JOIN trabajo_grado_estudiante e ON e.id_trabajo = t.id_trabajo
    WHERE e.id_usuario_estudiante = ? AND t.estado = 'ACTIVO'
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>

<div class="d-flex justify-content-between align-items-center mb-3">
  <h3><i class="bi bi-mortarboard"></i> Mis trabajos de grado</h3>
  <c:if test="${rsActivo.rows[0].n == 0}">
    <a class="btn btn-warning" href="${ctx}/estudiante/inscripcion.jsp"><i class="bi bi-plus-circle"></i> Inscribir trabajo</a>
  </c:if>
</div>

<c:if test="${rsMis.rowCount == 0}">
  <div class="alert alert-info">
    Todav&iacute;a no tiene un trabajo de grado. Elija una idea del <a href="${ctx}/banco_ideas.jsp">banco de ideas</a>
    o proponga la suya, y adjunte la URL del recibo de pago de sus derechos de grado.
  </div>
</c:if>

<c:forEach var="t" items="${rsMis.rows}">
  <div class="card shadow-sm mb-3"><div class="card-body">
    <div class="d-flex justify-content-between">
      <h5 class="card-title mb-1"><c:out value="${t.titulo}"/></h5>
      <t:badge valor="${t.estado}"/>
    </div>
    <t:fases actual="${t.fase_actual}" estado="${t.estado}"/>
    <div class="mt-2 small text-muted">
      Fase actual: <b><c:out value="${t.fase}"/></b>
      <c:if test="${not empty t.fecha_limite_entrega}">
        &middot; Fecha l&iacute;mite: <fmt:formatDate value="${t.fecha_limite_entrega}" pattern="dd/MM/yyyy"/>
        (<c:choose>
           <c:when test="${t.dias_restantes < 0}"><span class="text-danger">vencido hace ${-t.dias_restantes} d&iacute;as</span></c:when>
           <c:otherwise>${t.dias_restantes} d&iacute;as restantes</c:otherwise>
         </c:choose>)
        &middot; Pr&oacute;rrogas usadas: ${t.numero_prorrogas}
      </c:if>
    </div>
    <a class="btn btn-sm btn-primary mt-2" href="${ctx}/trabajo.jsp?id=${t.id_trabajo}">Ver detalle</a>
  </div></div>
</c:forEach>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
