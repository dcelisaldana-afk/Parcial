<%-- admin/catalogos.jsp - Lineas de investigacion, programas academicos y parametros del sistema. --%>
<c:set var="tituloPagina" value="Catálogos y parámetros"/>
<c:set var="rolRequerido" value="ADMINISTRADOR"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<sql:query var="rsL" dataSource="${ds}">SELECT id_linea, nombre FROM linea_investigacion ORDER BY nombre</sql:query>
<sql:query var="rsP" dataSource="${ds}">SELECT id_programa, nombre, facultad FROM programa_academico ORDER BY nombre</sql:query>
<sql:query var="rsPar" dataSource="${ds}">SELECT clave, valor, descripcion FROM parametro_sistema ORDER BY clave</sql:query>

<h3 class="mb-3"><i class="bi bi-gear"></i> Cat&aacute;logos y par&aacute;metros</h3>
<div class="row g-3">
  <div class="col-lg-6"><div class="card"><div class="card-body">
    <h6>L&iacute;neas de investigaci&oacute;n</h6>
    <ul class="list-group mb-2">
      <c:forEach var="l" items="${rsL.rows}">
        <li class="list-group-item d-flex justify-content-between"><c:out value="${l.nombre}"/>
          <a class="text-danger" data-confirmar="¿Eliminar la línea?" href="${ctx}/admin/catalogos_guardar.jsp?accion=linea_del&id=${l.id_linea}"><i class="bi bi-trash"></i></a></li>
      </c:forEach></ul>
    <form class="d-flex gap-2" action="${ctx}/admin/catalogos_guardar.jsp" method="post">
      <input type="hidden" name="accion" value="linea_add">
      <input class="form-control" name="nombre" placeholder="Nueva l&iacute;nea" required maxlength="120"><button class="btn btn-primary">Agregar</button></form>
  </div></div></div>
  <div class="col-lg-6"><div class="card"><div class="card-body">
    <h6>Programas acad&eacute;micos</h6>
    <ul class="list-group mb-2">
      <c:forEach var="p" items="${rsP.rows}">
        <li class="list-group-item d-flex justify-content-between"><span><c:out value="${p.nombre}"/> <small class="text-muted">(<c:out value="${p.facultad}"/>)</small></span>
          <a class="text-danger" data-confirmar="¿Eliminar el programa?" href="${ctx}/admin/catalogos_guardar.jsp?accion=prog_del&id=${p.id_programa}"><i class="bi bi-trash"></i></a></li>
      </c:forEach></ul>
    <form class="row g-2" action="${ctx}/admin/catalogos_guardar.jsp" method="post">
      <input type="hidden" name="accion" value="prog_add">
      <div class="col-5"><input class="form-control" name="nombre" placeholder="Programa" required maxlength="120"></div>
      <div class="col-5"><input class="form-control" name="facultad" placeholder="Facultad" required maxlength="120"></div>
      <div class="col-2 d-grid"><button class="btn btn-primary">+</button></div></form>
  </div></div></div>
</div>

<h5 class="mt-4">Par&aacute;metros del sistema</h5>
<div class="table-responsive"><table class="table tabla-compacta"><tbody>
  <c:forEach var="p" items="${rsPar.rows}">
    <tr><td><code>${p.clave}</code><div class="small text-muted"><c:out value="${p.descripcion}"/></div></td>
      <td><form class="d-flex gap-2" action="${ctx}/admin/catalogos_guardar.jsp" method="post">
        <input type="hidden" name="accion" value="param_set"><input type="hidden" name="clave" value="${p.clave}">
        <input class="form-control form-control-sm" name="valor" value="<c:out value='${p.valor}'/>" required maxlength="255">
        <button class="btn btn-sm btn-outline-primary">Guardar</button></form></td></tr>
  </c:forEach></tbody></table></div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
