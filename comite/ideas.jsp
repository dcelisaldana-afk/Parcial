<%-- comite/ideas.jsp - Ideas PENDIENTES (propuestas por docentes o estudiantes) para aprobar o rechazar. --%>
<c:set var="tituloPagina" value="Ideas por aprobar"/>
<c:set var="rolRequerido" value="COMITE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<sql:query var="rsI" dataSource="${ds}">
    SELECT i.id_idea, i.titulo, i.descripcion, i.origen, l.nombre AS linea, CONCAT(u.nombres, ' ', u.apellidos) AS proponente,
           (SELECT COUNT(*) FROM trabajo_grado t WHERE t.id_idea = i.id_idea AND t.estado = 'ACTIVO') AS en_uso
    FROM banco_idea i JOIN linea_investigacion l ON l.id_linea = i.id_linea JOIN usuario u ON u.id_usuario = i.propuesto_por
    WHERE i.estado = 'PENDIENTE' ORDER BY i.id_idea
</sql:query>

<h3 class="mb-3"><i class="bi bi-check2-square"></i> Ideas por aprobar</h3>
<c:forEach var="i" items="${rsI.rows}">
  <div class="card mb-2"><div class="card-body">
    <div class="d-flex justify-content-between">
      <div><span class="badge text-bg-secondary">${i.origen}</span> <b><c:out value="${i.titulo}"/></b>
        <div class="small text-muted"><c:out value="${i.linea}"/> &middot; <c:out value="${i.proponente}"/></div></div>
      <c:choose>
        <c:when test="${i.en_uso > 0}"><span class="text-muted small">Se aprueba junto con la inscripci&oacute;n del trabajo</span></c:when>
        <c:otherwise>
          <form action="${ctx}/comite/accion.jsp" method="post" class="d-flex gap-1 align-items-start">
            <input type="hidden" name="id_idea" value="${i.id_idea}">
            <button name="accion" value="aprobar_idea" class="btn btn-sm btn-success">Aprobar</button>
            <button name="accion" value="rechazar_idea" class="btn btn-sm btn-outline-danger">Rechazar</button>
          </form>
        </c:otherwise>
      </c:choose>
    </div>
    <p class="small mt-2 mb-0"><c:out value="${i.descripcion}"/></p>
  </div></div>
</c:forEach>
<c:if test="${rsI.rowCount == 0}"><div class="alert alert-info">No hay ideas pendientes.</div></c:if>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
