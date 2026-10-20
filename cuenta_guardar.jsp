<%-- cuenta_guardar.jsp - Cambia la clave verificando la actual (hash con sal calculado en SQL). --%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:if test="${param.nueva != param.nueva2 or fn:length(param.nueva) < 4}">
    <c:redirect url="/cuenta.jsp"><c:param name="err" value="Las contraseñas nuevas no coinciden o son muy cortas."/></c:redirect>
</c:if>
<sql:query var="rsOk" dataSource="${ds}">
    SELECT id_usuario FROM usuario WHERE id_usuario = ? AND clave_hash = SHA2(CONCAT(sal, ?), 256)
    <sql:param value="${sessionScope.idUsuario}"/><sql:param value="${param.actual}"/>
</sql:query>
<c:if test="${rsOk.rowCount == 0}">
    <c:redirect url="/cuenta.jsp"><c:param name="err" value="La contraseña actual es incorrecta."/></c:redirect>
</c:if>
<c:catch var="eTx">
<sql:transaction dataSource="${ds}">
    <sql:update>UPDATE usuario SET sal = SUBSTRING(MD5(CONCAT(UUID(), RAND())), 1, 16) WHERE id_usuario = ?<sql:param value="${sessionScope.idUsuario}"/></sql:update>
    <sql:update>UPDATE usuario SET clave_hash = SHA2(CONCAT(sal, ?), 256) WHERE id_usuario = ?
        <sql:param value="${param.nueva}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
</sql:transaction>
</c:catch>
<c:redirect url="/cuenta.jsp"><c:param name="ok" value="${empty eTx ? 'Contraseña actualizada.' : ''}"/><c:param name="err" value="${empty eTx ? '' : 'No se pudo cambiar la contraseña.'}"/></c:redirect>
