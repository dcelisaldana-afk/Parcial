<%--
    index.jsp - Punto de entrada. Sin sesion muestra la landing publica; con
    sesion manda al panel del rol de mayor jerarquia del usuario.
--%>
<c:choose>
    <c:when test="${empty sessionScope.idUsuario}"><c:redirect url="/landing.jsp"/></c:when>
    <c:when test="${fn:contains(sessionScope.roles, 'ADMINISTRADOR')}"><c:redirect url="/admin/usuarios.jsp"/></c:when>
    <c:when test="${fn:contains(sessionScope.roles, 'COMITE')}"><c:redirect url="/comite/panel.jsp"/></c:when>
    <c:when test="${fn:contains(sessionScope.roles, 'DOCENTE')}"><c:redirect url="/docente/panel.jsp"/></c:when>
    <c:otherwise><c:redirect url="/estudiante/panel.jsp"/></c:otherwise>
</c:choose>
