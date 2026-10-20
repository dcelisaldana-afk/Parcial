<%--
    admin/usuarios.jsp - CRUD de usuarios (Administrador): filtros opcionales,
    busqueda global, paginacion y acciones de estado (desbloquear, inactivar).
    No se borran usuarios: se inactivan (borrado logico).
--%>
<c:set var="tituloPagina" value="Usuarios"/>
<c:set var="rolRequerido" value="ADMINISTRADOR"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/pagina.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<c:set var="q" value="${empty param.q ? '' : fn:trim(param.q)}"/>
<c:set var="fRol" value="${empty param.rol ? '' : param.rol}"/>
<c:set var="fEstado" value="${empty param.estado ? '' : param.estado}"/>

<sql:query var="rsRoles" dataSource="${ds}">SELECT id_rol, nombre FROM rol ORDER BY nombre</sql:query>
<sql:query var="rsTotal" dataSource="${ds}">
    SELECT COUNT(*) AS n FROM usuario u
    WHERE (? = '' OR CONCAT_WS(' ', u.nombres, u.apellidos, u.correo, u.documento_identidad) LIKE CONCAT('%', ?, '%'))
      AND (? = '' OR u.estado = ?)
      AND (? = '' OR EXISTS (SELECT 1 FROM usuario_rol ur WHERE ur.id_usuario = u.id_usuario AND ur.id_rol = ?))
    <sql:param value="${q}"/><sql:param value="${q}"/><sql:param value="${fEstado}"/><sql:param value="${fEstado}"/>
    <sql:param value="${fRol}"/><sql:param value="${fRol}"/>
</sql:query>
<c:set var="total" value="${rsTotal.rows[0].n}"/>
<sql:query var="rsU" dataSource="${ds}">
    SELECT u.id_usuario, u.nombres, u.apellidos, u.correo, u.documento_identidad, u.estado, u.intentos_fallidos,
           (SELECT CAST(GROUP_CONCAT(r.nombre) AS CHAR) FROM usuario_rol ur JOIN rol r ON r.id_rol = ur.id_rol WHERE ur.id_usuario = u.id_usuario) AS roles
    FROM usuario u
    WHERE (? = '' OR CONCAT_WS(' ', u.nombres, u.apellidos, u.correo, u.documento_identidad) LIKE CONCAT('%', ?, '%'))
      AND (? = '' OR u.estado = ?)
      AND (? = '' OR EXISTS (SELECT 1 FROM usuario_rol ur WHERE ur.id_usuario = u.id_usuario AND ur.id_rol = ?))
    ORDER BY u.apellidos, u.nombres
    LIMIT ?, ?
    <sql:param value="${q}"/><sql:param value="${q}"/><sql:param value="${fEstado}"/><sql:param value="${fEstado}"/>
    <sql:param value="${fRol}"/><sql:param value="${fRol}"/>
    <sql:param value="${desde}"/><sql:param value="${porPagina}"/>
</sql:query>

<div class="d-flex justify-content-between align-items-center mb-3">
  <h3><i class="bi bi-people"></i> Usuarios</h3>
  <div>
    <a class="btn btn-outline-primary" href="${ctx}/admin/catalogos.jsp">Cat&aacute;logos y par&aacute;metros</a>
    <a class="btn btn-outline-primary" href="${ctx}/admin/trabajos.jsp">Trabajos</a>
    <a class="btn btn-warning" href="${ctx}/admin/usuario_form.jsp"><i class="bi bi-person-plus"></i> Nuevo usuario</a>
  </div>
</div>

<form class="row g-2 mb-3" method="get">
  <div class="col-md-5"><input class="form-control" name="q" value="<c:out value='${q}'/>" placeholder="Nombre, correo o documento"></div>
  <div class="col-md-3"><select class="form-select" name="rol"><option value="">Todos los roles</option>
    <c:forEach var="r" items="${rsRoles.rows}"><option value="${r.id_rol}" ${fRol == r.id_rol ? 'selected' : ''}>${r.nombre}</option></c:forEach></select></div>
  <div class="col-md-2"><select class="form-select" name="estado"><option value="">Todos</option>
    <option value="ACTIVO" ${fEstado == 'ACTIVO' ? 'selected' : ''}>Activo</option>
    <option value="INACTIVO" ${fEstado == 'INACTIVO' ? 'selected' : ''}>Inactivo</option>
    <option value="BLOQUEADO" ${fEstado == 'BLOQUEADO' ? 'selected' : ''}>Bloqueado</option></select></div>
  <div class="col-md-2 d-grid"><button class="btn btn-primary">Filtrar</button></div>
</form>

<p class="small text-muted">${total} usuario(s).</p>
<div class="table-responsive"><table class="table table-hover tabla-compacta">
  <thead><tr><th>Nombre</th><th>Correo</th><th>Documento</th><th>Roles</th><th>Estado</th><th></th></tr></thead>
  <tbody>
  <c:forEach var="u" items="${rsU.rows}">
    <tr><td><c:out value="${u.apellidos} ${u.nombres}"/></td><td><c:out value="${u.correo}"/></td><td><c:out value="${u.documento_identidad}"/></td>
      <td><c:out value="${u.roles}"/></td><td><t:badge valor="${u.estado}"/></td>
      <td class="text-nowrap">
        <a class="btn btn-sm btn-outline-primary" href="${ctx}/admin/usuario_form.jsp?id=${u.id_usuario}">Editar</a>
        <c:if test="${u.estado != 'ACTIVO'}">
          <a class="btn btn-sm btn-outline-success" href="${ctx}/admin/usuario_guardar.jsp?accion=activar&id=${u.id_usuario}">Activar / desbloquear</a>
        </c:if>
        <c:if test="${u.estado == 'ACTIVO' and u.id_usuario != sessionScope.idUsuario}">
          <a class="btn btn-sm btn-outline-danger" data-confirmar="¿Inactivar este usuario?" href="${ctx}/admin/usuario_guardar.jsp?accion=inactivar&id=${u.id_usuario}">Inactivar</a>
        </c:if>
      </td></tr>
  </c:forEach>
  </tbody></table></div>
<t:paginacion pagina="${pagina}" total="${total}" porPagina="${porPagina}"/>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
