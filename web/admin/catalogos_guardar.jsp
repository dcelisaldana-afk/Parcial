<%-- admin/catalogos_guardar.jsp - Altas/bajas de catalogos y edicion de parametros. --%>
<c:set var="rolRequerido" value="ADMINISTRADOR"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>

<c:set var="msg" value="Cambio guardado."/>
<c:catch var="eTx">
<c:choose>
    <c:when test="${param.accion == 'linea_add'}">
        <sql:update dataSource="${ds}">INSERT INTO linea_investigacion (nombre) VALUES (?)<sql:param value="${fn:trim(param.nombre)}"/></sql:update>
    </c:when>
    <c:when test="${param.accion == 'linea_del'}">
        <sql:update dataSource="${ds}">DELETE FROM linea_investigacion WHERE id_linea = ?<sql:param value="${param.id}"/></sql:update>
    </c:when>
    <c:when test="${param.accion == 'prog_add'}">
        <sql:update dataSource="${ds}">INSERT INTO programa_academico (nombre, facultad) VALUES (?, ?)
            <sql:param value="${fn:trim(param.nombre)}"/><sql:param value="${fn:trim(param.facultad)}"/></sql:update>
    </c:when>
    <c:when test="${param.accion == 'prog_del'}">
        <sql:update dataSource="${ds}">DELETE FROM programa_academico WHERE id_programa = ?<sql:param value="${param.id}"/></sql:update>
    </c:when>
    <c:when test="${param.accion == 'param_set'}">
        <sql:update dataSource="${ds}">UPDATE parametro_sistema SET valor = ? WHERE clave = ?
            <sql:param value="${fn:trim(param.valor)}"/><sql:param value="${param.clave}"/></sql:update>
    </c:when>
    <c:otherwise><c:set var="msg" value="Acción no válida."/></c:otherwise>
</c:choose>
</c:catch>
<c:choose>
    <c:when test="${not empty eTx}"><c:redirect url="/admin/catalogos.jsp"><c:param name="err" value="No se pudo: el registro está en uso o ya existe."/></c:redirect></c:when>
    <c:otherwise><c:redirect url="/admin/catalogos.jsp"><c:param name="ok" value="${msg}"/></c:redirect></c:otherwise>
</c:choose>
