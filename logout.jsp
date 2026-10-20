<%-- logout.jsp - Cierra la sesion borrando las variables de sesion (sin Java). --%>
<c:remove var="idUsuario" scope="session"/>
<c:remove var="nombre" scope="session"/>
<c:remove var="correoSesion" scope="session"/>
<c:remove var="roles" scope="session"/>
<c:redirect url="/landing.jsp"><c:param name="ok" value="Sesión cerrada correctamente."/></c:redirect>
