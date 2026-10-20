<%-- admin/usuario_form.jsp - Crear o editar un usuario y asignarle roles. --%>
<c:set var="tituloPagina" value="Usuario"/>
<c:set var="rolRequerido" value="ADMINISTRADOR"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<sql:query var="rsRoles" dataSource="${ds}">SELECT id_rol, nombre FROM rol ORDER BY nombre</sql:query>
<c:set var="u" value="${null}"/>
<c:set var="misRoles" value=""/>
<c:if test="${not empty param.id}">
    <sql:query var="rsU" dataSource="${ds}">
        SELECT id_usuario, correo, documento_identidad, nombres, apellidos FROM usuario WHERE id_usuario = ?
        <sql:param value="${param.id}"/>
    </sql:query>
    <c:if test="${rsU.rowCount > 0}"><c:set var="u" value="${rsU.rows[0]}"/></c:if>
    <sql:query var="rsMis" dataSource="${ds}">
        SELECT CAST(GROUP_CONCAT(id_rol) AS CHAR) AS ids FROM usuario_rol WHERE id_usuario = ?
        <sql:param value="${param.id}"/>
    </sql:query>
    <c:set var="misRoles" value=",${rsMis.rows[0].ids},"/>
</c:if>

<h3 class="mb-3">${empty u ? 'Nuevo usuario' : 'Editar usuario'}</h3>
<form action="${ctx}/admin/usuario_guardar.jsp" method="post" class="card card-body shadow-sm">
  <input type="hidden" name="accion" value="guardar">
  <input type="hidden" name="id" value="${empty u ? '' : u.id_usuario}">
  <div class="row">
    <div class="col-md-6 mb-2"><label class="form-label">Nombres</label><input class="form-control" name="nombres" required maxlength="80" value="<c:out value='${u.nombres}'/>"></div>
    <div class="col-md-6 mb-2"><label class="form-label">Apellidos</label><input class="form-control" name="apellidos" required maxlength="80" value="<c:out value='${u.apellidos}'/>"></div>
    <div class="col-md-6 mb-2"><label class="form-label">Correo</label><input type="email" class="form-control" name="correo" required maxlength="120" value="<c:out value='${u.correo}'/>"></div>
    <div class="col-md-6 mb-2"><label class="form-label">Documento de identidad</label><input class="form-control" name="documento" required maxlength="20" value="<c:out value='${u.documento_identidad}'/>"></div>
    <div class="col-md-6 mb-2"><label class="form-label">Contrase&ntilde;a ${empty u ? '' : '(vac&iacute;a = no cambiar)'}</label>
      <input type="password" class="form-control" name="clave" ${empty u ? 'required' : ''} minlength="4"></div>
  </div>
  <label class="form-label">Roles</label>
  <div class="mb-3">
    <c:forEach var="r" items="${rsRoles.rows}">
      <c:set var="marca" value=",${r.id_rol},"/>
      <div class="form-check form-check-inline">
        <input class="form-check-input" type="checkbox" name="roles" id="r${r.id_rol}" value="${r.id_rol}" ${fn:contains(misRoles, marca) ? 'checked' : ''}>
        <label class="form-check-label" for="r${r.id_rol}">${r.nombre}</label>
      </div>
    </c:forEach>
  </div>
  <div><button class="btn btn-primary">Guardar</button> <a class="btn btn-outline-secondary" href="${ctx}/admin/usuarios.jsp">Cancelar</a></div>
</form>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
