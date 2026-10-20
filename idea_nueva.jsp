<%--
    idea_nueva.jsp - Un docente (o el Comite) propone una idea para el banco.
    La idea de un docente queda PENDIENTE hasta que el Comite la apruebe
    (FASE 1); la del Comite queda DISPONIBLE de una vez.
--%>
<c:set var="tituloPagina" value="Proponer idea"/>
<c:set var="rolRequerido" value="DOCENTE,COMITE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<sql:query var="rsLineas" dataSource="${ds}">SELECT id_linea, nombre FROM linea_investigacion ORDER BY nombre</sql:query>
<sql:query var="rsDocentes" dataSource="${ds}">
    SELECT u.id_usuario, u.nombres, u.apellidos FROM usuario u
    JOIN usuario_rol ur ON ur.id_usuario = u.id_usuario JOIN rol r ON r.id_rol = ur.id_rol
    WHERE r.nombre = 'DOCENTE' AND u.estado = 'ACTIVO' ORDER BY u.apellidos
</sql:query>

<h3 class="mb-3"><i class="bi bi-lightbulb"></i> Proponer una idea</h3>
<form action="${ctx}/idea_guardar.jsp" method="post" class="card card-body shadow-sm">
  <div class="mb-2"><label class="form-label">T&iacute;tulo</label><input class="form-control" name="titulo" maxlength="200" required></div>
  <div class="mb-2"><label class="form-label">Descripci&oacute;n</label><textarea class="form-control" name="descripcion" rows="3" required></textarea></div>
  <div class="mb-2"><label class="form-label">Objetivos</label><textarea class="form-control" name="objetivos" rows="2"></textarea></div>
  <div class="row">
    <div class="col-md-6 mb-2"><label class="form-label">L&iacute;nea de investigaci&oacute;n</label>
      <select class="form-select" name="id_linea" required>
        <c:forEach var="l" items="${rsLineas.rows}"><option value="${l.id_linea}"><c:out value="${l.nombre}"/></option></c:forEach>
      </select></div>
    <div class="col-md-6 mb-2"><label class="form-label">Director sugerido</label>
      <select class="form-select" name="director">
        <option value="">Sin sugerencia</option>
        <c:forEach var="d" items="${rsDocentes.rows}"><option value="${d.id_usuario}" ${d.id_usuario == sessionScope.idUsuario ? 'selected' : ''}><c:out value="${d.nombres} ${d.apellidos}"/></option></c:forEach>
      </select></div>
  </div>
  <div class="row">
    <div class="col-md-6 mb-2"><label class="form-label">Palabras clave</label><input class="form-control" name="palabras_clave" maxlength="200"></div>
    <div class="col-md-3 mb-2"><label class="form-label">Per&iacute;odo</label><input class="form-control" name="periodo" value="2026-2" maxlength="10" required></div>
    <div class="col-md-3 mb-2"><label class="form-label">Nivel</label>
      <select class="form-select" name="nivel"><option>Tecnolog&iacute;a</option><option>Profesional</option></select></div>
  </div>
  <div class="mt-2"><button class="btn btn-primary">Guardar idea</button>
    <a class="btn btn-outline-secondary" href="${ctx}/index.jsp">Cancelar</a></div>
</form>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
