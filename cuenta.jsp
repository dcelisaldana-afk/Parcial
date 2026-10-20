<%-- cuenta.jsp - El usuario ve sus datos y cambia su propia contrasena. --%>
<c:set var="tituloPagina" value="Mi cuenta"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<h3 class="mb-3"><i class="bi bi-person-circle"></i> Mi cuenta</h3>
<p><b><c:out value="${sessionScope.nombre}"/></b><br><c:out value="${sessionScope.correoSesion}"/><br>
   Roles: <c:out value="${sessionScope.roles}"/></p>
<form class="card card-body" style="max-width:420px" action="${ctx}/cuenta_guardar.jsp" method="post">
  <h6>Cambiar contrase&ntilde;a</h6>
  <input type="password" class="form-control mb-2" name="actual" placeholder="Contrase&ntilde;a actual" required>
  <input type="password" class="form-control mb-2" name="nueva" placeholder="Nueva contrase&ntilde;a (m&iacute;n. 4)" minlength="4" required>
  <input type="password" class="form-control mb-2" name="nueva2" placeholder="Repita la nueva" minlength="4" required>
  <button class="btn btn-primary">Cambiar</button>
</form>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>
