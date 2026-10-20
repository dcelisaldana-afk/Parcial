<%--
    login.jsp - Formulario de inicio de sesion. NO existe registro publico:
    las cuentas las crea el administrador.
--%>
<c:set var="tituloPagina" value="Ingresar"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:if test="${not empty sessionScope.idUsuario}"><c:redirect url="/index.jsp"/></c:if>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="row justify-content-center">
  <div class="col-md-5">
    <div class="card shadow-sm"><div class="card-body p-4">
      <h4 class="mb-3"><i class="bi bi-box-arrow-in-right"></i> Iniciar sesi&oacute;n</h4>
      <form action="${ctx}/acceso.jsp" method="post">
        <div class="mb-3"><label class="form-label">Correo institucional</label>
          <input type="email" class="form-control" name="correo" required autofocus></div>
        <div class="mb-3"><label class="form-label">Contrase&ntilde;a</label>
          <input type="password" class="form-control" name="clave" required></div>
        <div class="d-grid"><button class="btn btn-primary">Ingresar</button></div>
      </form>
      <p class="small text-muted mt-3 mb-0">Tras 3 intentos fallidos la cuenta se bloquea; el administrador puede desbloquearla.
         Las cuentas las crea el administrador (nadie se autorregistra).</p>
    </div></div>
    <div class="card mt-3 shadow-sm"><div class="card-body small">
      <b>Usuarios de prueba</b> (clave <code>1234</code>):
      <ul class="mb-0">
        <li>admin@uts.edu.co &mdash; Administrador</li>
        <li>comite@uts.edu.co &mdash; Comit&eacute;</li>
        <li>ana.rojas@uts.edu.co, carlos.mendez@uts.edu.co &mdash; Docentes</li>
        <li>estudiante1@uts.edu.co &hellip; estudiante10@uts.edu.co &mdash; Estudiantes</li>
      </ul>
    </div></div>
  </div>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
