<%--
    admin/usuario_guardar.jsp - Controlador de usuarios (Administrador).
      accion=guardar  : crea o edita (hash con sal generado en SQL) y reasigna roles
      accion=activar  : estado ACTIVO + intentos en 0 (desbloqueo)
      accion=inactivar: borrado logico
--%>
<c:set var="rolRequerido" value="ADMINISTRADOR"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>

<c:choose>
<c:when test="${param.accion == 'activar'}">
    <sql:update dataSource="${ds}">UPDATE usuario SET estado = 'ACTIVO', intentos_fallidos = 0 WHERE id_usuario = ?
        <sql:param value="${param.id}"/></sql:update>
    <c:redirect url="/admin/usuarios.jsp"><c:param name="ok" value="Usuario activado."/></c:redirect>
</c:when>
<c:when test="${param.accion == 'inactivar'}">
    <c:if test="${param.id == sessionScope.idUsuario}">
        <c:redirect url="/admin/usuarios.jsp"><c:param name="err" value="No puede inactivar su propia cuenta."/></c:redirect>
    </c:if>
    <sql:update dataSource="${ds}">UPDATE usuario SET estado = 'INACTIVO' WHERE id_usuario = ?
        <sql:param value="${param.id}"/></sql:update>
    <c:redirect url="/admin/usuarios.jsp"><c:param name="ok" value="Usuario inactivado."/></c:redirect>
</c:when>

<c:when test="${param.accion == 'guardar'}">
    <c:set var="correo" value="${fn:toLowerCase(fn:trim(param.correo))}"/>
    <c:set var="volver" value="/admin/usuario_form.jsp"/>
    <c:if test="${empty fn:trim(param.nombres) or empty fn:trim(param.apellidos) or empty correo or empty fn:trim(param.documento)}">
        <c:redirect url="${volver}"><c:param name="id" value="${param.id}"/><c:param name="err" value="Complete todos los campos obligatorios."/></c:redirect>
    </c:if>
    <c:if test="${empty param.id and empty param.clave}">
        <c:redirect url="${volver}"><c:param name="err" value="La contraseña es obligatoria para un usuario nuevo."/></c:redirect>
    </c:if>
    <c:if test="${empty paramValues.roles}">
        <c:redirect url="${volver}"><c:param name="id" value="${param.id}"/><c:param name="err" value="Seleccione al menos un rol."/></c:redirect>
    </c:if>

    <c:catch var="eTx">
    <sql:transaction dataSource="${ds}">
        <c:choose>
            <c:when test="${empty param.id}">
                <sql:update>INSERT INTO usuario (correo, documento_identidad, nombres, apellidos, clave_hash, sal)
                    VALUES (?, ?, ?, ?, 'x', SUBSTRING(MD5(CONCAT(UUID(), RAND())), 1, 16))
                    <sql:param value="${correo}"/><sql:param value="${fn:trim(param.documento)}"/>
                    <sql:param value="${fn:trim(param.nombres)}"/><sql:param value="${fn:trim(param.apellidos)}"/></sql:update>
                <sql:query var="rsId">SELECT LAST_INSERT_ID() AS id</sql:query>
                <c:set var="idU" value="${rsId.rows[0].id}"/>
                <sql:update>UPDATE usuario SET clave_hash = SHA2(CONCAT(sal, ?), 256) WHERE id_usuario = ?
                    <sql:param value="${param.clave}"/><sql:param value="${idU}"/></sql:update>
            </c:when>
            <c:otherwise>
                <c:set var="idU" value="${param.id}"/>
                <sql:update>UPDATE usuario SET correo = ?, documento_identidad = ?, nombres = ?, apellidos = ? WHERE id_usuario = ?
                    <sql:param value="${correo}"/><sql:param value="${fn:trim(param.documento)}"/>
                    <sql:param value="${fn:trim(param.nombres)}"/><sql:param value="${fn:trim(param.apellidos)}"/><sql:param value="${idU}"/></sql:update>
                <c:if test="${not empty param.clave}">
                    <sql:update>UPDATE usuario SET sal = SUBSTRING(MD5(CONCAT(UUID(), RAND())), 1, 16) WHERE id_usuario = ?
                        <sql:param value="${idU}"/></sql:update>
                    <sql:update>UPDATE usuario SET clave_hash = SHA2(CONCAT(sal, ?), 256), intentos_fallidos = 0 WHERE id_usuario = ?
                        <sql:param value="${param.clave}"/><sql:param value="${idU}"/></sql:update>
                </c:if>
                <sql:update>DELETE FROM usuario_rol WHERE id_usuario = ?<sql:param value="${idU}"/></sql:update>
            </c:otherwise>
        </c:choose>
        <c:forEach var="idRol" items="${paramValues.roles}">
            <sql:update>INSERT INTO usuario_rol (id_usuario, id_rol) VALUES (?, ?)
                <sql:param value="${idU}"/><sql:param value="${idRol}"/></sql:update>
        </c:forEach>
    </sql:transaction>
    </c:catch>
    <c:choose>
        <c:when test="${not empty eTx}">
            <c:redirect url="${volver}"><c:param name="id" value="${param.id}"/><c:param name="err" value="No se pudo guardar: el correo o el documento ya existen."/></c:redirect>
        </c:when>
        <c:otherwise><c:redirect url="/admin/usuarios.jsp"><c:param name="ok" value="Usuario guardado."/></c:redirect></c:otherwise>
    </c:choose>
</c:when>
<c:otherwise><c:redirect url="/admin/usuarios.jsp"><c:param name="err" value="Acción no válida."/></c:redirect></c:otherwise>
</c:choose>
