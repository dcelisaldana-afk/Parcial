<%--
    calendario.jsp - Calendario academico por fases, visible para todos.
    El Comite y el Administrador pueden agregar o quitar eventos.
--%>
<c:set var="tituloPagina" value="Calendario académico"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<sql:query var="rsE" dataSource="${ds}">
    SELECT c.id_evento, c.titulo, c.descripcion, c.tipo_evento, c.fecha_inicio, c.fecha_fin, c.id_fase,
           DATEDIFF(c.fecha_fin, CURDATE()) AS dias
    FROM calendario_academico c ORDER BY c.fecha_inicio
</sql:query>
<sql:query var="rsFases" dataSource="${ds}">SELECT id_fase, nombre FROM fase ORDER BY orden</sql:query>
<c:set var="puedeEditar" value="${fn:contains(sessionScope.roles, 'COMITE') or fn:contains(sessionScope.roles, 'ADMINISTRADOR')}"/>

<h3 class="mb-3"><i class="bi bi-calendar3"></i> Calendario acad&eacute;mico</h3>
<table class="table tabla-compacta"><thead><tr><th>Evento</th><th>Tipo</th><th>Fase</th><th>Desde</th><th>Hasta</th><th></th>
  <c:if test="${puedeEditar}"><th></th></c:if></tr></thead><tbody>
  <c:forEach var="e" items="${rsE.rows}">
    <tr class="${e.dias < 0 ? 'text-muted' : ''}"><td><b><c:out value="${e.titulo}"/></b><div class="small"><c:out value="${e.descripcion}"/></div></td>
      <td>${e.tipo_evento}</td><td>${empty e.id_fase ? '-' : e.id_fase}</td>
      <td><fmt:formatDate value="${e.fecha_inicio}" pattern="dd/MM/yyyy"/></td>
      <td><fmt:formatDate value="${e.fecha_fin}" pattern="dd/MM/yyyy"/></td>
      <td><c:choose><c:when test="${e.dias < 0}"><span class="badge text-bg-secondary">pasado</span></c:when>
        <c:when test="${e.dias <= 7}"><span class="badge text-bg-warning">pr&oacute;ximo a vencer</span></c:when></c:choose></td>
      <c:if test="${puedeEditar}"><td><a class="text-danger" data-confirmar="¿Eliminar el evento?" href="${ctx}/calendario_accion.jsp?accion=del&id=${e.id_evento}"><i class="bi bi-trash"></i></a></td></c:if></tr>
  </c:forEach></tbody></table>

<c:if test="${puedeEditar}">
  <form class="card card-body mt-3" action="${ctx}/calendario_accion.jsp" method="post">
    <input type="hidden" name="accion" value="add"><h6>Nuevo evento</h6>
    <div class="row g-2">
      <div class="col-md-4"><input class="form-control" name="titulo" placeholder="T&iacute;tulo" required maxlength="150"></div>
      <div class="col-md-3"><select class="form-select" name="tipo">
        <option>INSCRIPCION</option><option>ENTREGA</option><option>EVALUACION</option><option>CIERRE</option><option>OTRO</option></select></div>
      <div class="col-md-3"><select class="form-select" name="id_fase"><option value="">Sin fase</option>
        <c:forEach var="f" items="${rsFases.rows}"><option value="${f.id_fase}">Fase ${f.id_fase}</option></c:forEach></select></div>
      <div class="col-md-2"><input class="form-control" name="descripcion" placeholder="Nota" maxlength="255"></div>
      <div class="col-md-3"><label class="small">Desde</label><input type="date" class="form-control" name="inicio" required></div>
      <div class="col-md-3"><label class="small">Hasta</label><input type="date" class="form-control" name="fin" required></div>
      <div class="col-md-2 d-grid align-items-end"><button class="btn btn-primary">Agregar</button></div>
    </div>
  </form>
</c:if>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
