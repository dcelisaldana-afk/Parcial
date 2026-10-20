<%--
    acceso.jsp - Valida las credenciales (solo JSTL + SQL).
    La contrasena NUNCA se compara en texto plano: la base de datos calcula
    SHA2(CONCAT(sal, clave), 256) y lo compara con el hash guardado.
    Tras 3 intentos fallidos consecutivos la cuenta pasa a BLOQUEADO.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="correo" value="${fn:toLowerCase(fn:trim(param.correo))}"/>

<c:if test="${empty correo or empty param.clave}">
    <c:redirect url="/login.jsp"><c:param name="err" value="Escriba su correo y su contraseña."/></c:redirect>
</c:if>

<sql:query var="rsU" dataSource="${ds}">
    SELECT id_usuario, nombres, apellidos, correo, estado, intentos_fallidos
    FROM usuario WHERE correo = ?
    <sql:param value="${correo}"/>
</sql:query>

<c:if test="${rsU.rowCount == 0}">
    <c:redirect url="/login.jsp"><c:param name="err" value="Correo o contraseña incorrectos."/></c:redirect>
</c:if>
<c:set var="u" value="${rsU.rows[0]}"/>

<c:if test="${u.estado == 'BLOQUEADO'}">
    <c:redirect url="/login.jsp"><c:param name="err" value="Cuenta bloqueada por intentos fallidos. Solicite al administrador que la desbloquee."/></c:redirect>
</c:if>
<c:if test="${u.estado == 'INACTIVO'}">
    <c:redirect url="/login.jsp"><c:param name="err" value="La cuenta está inactiva."/></c:redirect>
</c:if>

<sql:query var="rsOk" dataSource="${ds}">
    SELECT id_usuario FROM usuario
    WHERE id_usuario = ? AND clave_hash = SHA2(CONCAT(sal, ?), 256)
    <sql:param value="${u.id_usuario}"/>
    <sql:param value="${param.clave}"/>
</sql:query>

<c:if test="${rsOk.rowCount == 0}">
    <%-- estado se calcula ANTES de sumar el intento (MySQL evalua de izquierda a derecha) --%>
    <sql:update dataSource="${ds}">
        UPDATE usuario
        SET estado = CASE WHEN intentos_fallidos + 1 >= 3 THEN 'BLOQUEADO' ELSE estado END,
            intentos_fallidos = intentos_fallidos + 1
        WHERE id_usuario = ?
        <sql:param value="${u.id_usuario}"/>
    </sql:update>
    <c:choose>
        <c:when test="${u.intentos_fallidos + 1 >= 3}">
            <c:redirect url="/login.jsp"><c:param name="err" value="Tercer intento fallido: la cuenta quedó bloqueada."/></c:redirect>
        </c:when>
        <c:otherwise>
            <c:redirect url="/login.jsp"><c:param name="err" value="Correo o contraseña incorrectos."/></c:redirect>
        </c:otherwise>
    </c:choose>
</c:if>

<%-- Credenciales correctas: reinicia el contador y carga los roles --%>
<sql:update dataSource="${ds}">
    UPDATE usuario SET intentos_fallidos = 0 WHERE id_usuario = ?
    <sql:param value="${u.id_usuario}"/>
</sql:update>
<sql:query var="rsRoles" dataSource="${ds}">
    SELECT CAST(GROUP_CONCAT(r.nombre) AS CHAR) AS roles
    FROM usuario_rol ur JOIN rol r ON r.id_rol = ur.id_rol
    WHERE ur.id_usuario = ?
    <sql:param value="${u.id_usuario}"/>
</sql:query>

<c:set var="idUsuario" value="${u.id_usuario}" scope="session"/>
<c:set var="nombre" value="${u.nombres} ${u.apellidos}" scope="session"/>
<c:set var="correoSesion" value="${u.correo}" scope="session"/>
<c:set var="roles" value="${rsRoles.rows[0].roles}" scope="session"/>
<c:redirect url="/index.jsp"/>
