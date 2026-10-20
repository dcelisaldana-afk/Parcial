<%-- acceso_denegado.jsp - Destino cuando hay sesion pero el rol no corresponde. --%>
<c:set var="tituloPagina" value="Acceso denegado"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<div class="text-center py-5">
  <i class="bi bi-shield-x display-1 text-danger"></i>
  <h3 class="mt-3">Acceso denegado</h3>
  <p class="text-muted">Su rol no tiene permiso para abrir esa p&aacute;gina.</p>
  <a class="btn btn-primary" href="${ctx}/index.jsp">Volver a mi panel</a>
</div>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>
