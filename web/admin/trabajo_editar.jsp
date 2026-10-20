<%--
    admin/trabajo_editar.jsp - El Administrador corrige datos del trabajo
    (titulo, resumen, linea, programa, modalidad, fecha limite) o lo cancela /
    reactiva de forma logica. Todo cambio queda en historico_trabajo_grado.
--%>
<c:set var="tituloPagina" value="Editar trabajo"/>
<c:set var="rolRequerido" value="ADMINISTRADOR"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="rsT" dataSource="${ds}">SELECT * FROM trabajo_grado WHERE id_trabajo = ?<sql:param value="${param.id}"/></sql:query>
<c:if test="${rsT.rowCount == 0}"><c:redirect url="/admin/trabajos.jsp"><c:param name="err" value="Trabajo inexistente."/></c:redirect></c:if>
<c:set var="t" value="${rsT.rows[0]}"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<sql:query var="rsLineas" dataSource="${ds}">SELECT id_linea, nombre FROM linea_investigacion ORDER BY nombre</sql:query>
<sql:query var="rsProg" dataSource="${ds}">SELECT id_programa, nombre FROM programa_academico ORDER BY nombre</sql:query>

<h3 class="mb-3">Editar trabajo #${t.id_trabajo}</h3>
<form action="${ctx}/admin/trabajo_guardar.jsp" method="post" class="card card-body shadow-sm">
  <input type="hidden" name="id" value="${t.id_trabajo}">
  <div class="mb-2"><label class="form-label">T&iacute;tulo</label><input class="form-control" name="titulo" required maxlength="200" value="<c:out value='${t.titulo}'/>"></div>
  <div class="mb-2"><label class="form-label">Resumen</label><textarea class="form-control" name="resumen" rows="3"><c:out value="${t.resumen}"/></textarea></div>
  <div class="row">
    <div class="col-md-4 mb-2"><label class="form-label">L&iacute;nea</label><select class="form-select" name="id_linea">
      <c:forEach var="l" items="${rsLineas.rows}"><option value="${l.id_linea}" ${l.id_linea == t.id_linea ? 'selected' : ''}><c:out value="${l.nombre}"/></option></c:forEach></select></div>
    <div class="col-md-4 mb-2"><label class="form-label">Programa</label><select class="form-select" name="id_programa">
      <c:forEach var="p" items="${rsProg.rows}"><option value="${p.id_programa}" ${p.id_programa == t.id_programa ? 'selected' : ''}><c:out value="${p.nombre}"/></option></c:forEach></select></div>
    <div class="col-md-4 mb-2"><label class="form-label">Modalidad</label><select class="form-select" name="modalidad">
      <option value="DESARROLLO_SOFTWARE" ${t.modalidad == 'DESARROLLO_SOFTWARE' ? 'selected' : ''}>Desarrollo de software</option>
      <option value="INVESTIGACION" ${t.modalidad == 'INVESTIGACION' ? 'selected' : ''}>Investigaci&oacute;n</option>
      <option value="MONOGRAFIA" ${t.modalidad == 'MONOGRAFIA' ? 'selected' : ''}>Monograf&iacute;a</option></select></div>
  </div>
  <div class="mb-2"><label class="form-label">Fecha l&iacute;mite (aaaa-mm-dd; vac&iacute;a = sin fecha)</label>
    <input class="form-control" name="fecha_limite" pattern="\d{4}-\d{2}-\d{2}|" value="<c:out value='${t.fecha_limite_entrega}'/>"></div>
  <div class="mt-2 d-flex gap-2">
    <button class="btn btn-primary" name="accion" value="guardar">Guardar cambios</button>
    <c:choose>
      <c:when test="${t.estado == 'ACTIVO'}"><button class="btn btn-outline-danger" name="accion" value="cancelar" data-confirmar="¿Cancelar (borrado lógico) este trabajo?">Cancelar trabajo</button></c:when>
      <c:when test="${t.estado == 'CANCELADO'}"><button class="btn btn-outline-success" name="accion" value="reactivar">Reactivar</button></c:when>
    </c:choose>
    <a class="btn btn-outline-secondary" href="${ctx}/admin/trabajos.jsp">Volver</a>
  </div>
</form>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
