<%-- admin/trabajos.jsp - El Administrador busca trabajos para editarlos o cancelarlos (borrado logico). --%>
<c:set var="tituloPagina" value="Trabajos (administración)"/>
<c:set var="rolRequerido" value="ADMINISTRADOR"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/pagina.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<c:set var="q" value="${empty param.q ? '' : fn:trim(param.q)}"/>
<sql:query var="rsTotal" dataSource="${ds}">
    SELECT COUNT(*) AS n FROM trabajo_grado t
    WHERE (? = '' OR t.id_trabajo = ? OR t.titulo LIKE CONCAT('%', ?, '%'))
    <sql:param value="${q}"/><sql:param value="${q}"/><sql:param value="${q}"/>
</sql:query>
<c:set var="total" value="${rsTotal.rows[0].n}"/>
<sql:query var="rsT" dataSource="${ds}">
    SELECT t.id_trabajo, t.titulo, t.fase_actual, t.estado FROM trabajo_grado t
    WHERE (? = '' OR t.id_trabajo = ? OR t.titulo LIKE CONCAT('%', ?, '%'))
    ORDER BY t.id_trabajo DESC LIMIT ?, ?
    <sql:param value="${q}"/><sql:param value="${q}"/><sql:param value="${q}"/>
    <sql:param value="${desde}"/><sql:param value="${porPagina}"/>
</sql:query>

<h3 class="mb-3"><i class="bi bi-journal-text"></i> Trabajos de grado</h3>
<form class="row g-2 mb-3" method="get">
  <div class="col-md-9"><input class="form-control" name="q" value="<c:out value='${q}'/>" placeholder="ID o t&iacute;tulo"></div>
  <div class="col-md-3 d-grid"><button class="btn btn-primary">Buscar</button></div>
</form>
<table class="table table-hover tabla-compacta"><thead><tr><th>#</th><th>T&iacute;tulo</th><th>Fase</th><th>Estado</th><th></th></tr></thead><tbody>
  <c:forEach var="t" items="${rsT.rows}">
    <tr><td>${t.id_trabajo}</td><td><c:out value="${t.titulo}"/></td><td>${t.fase_actual}</td><td><t:badge valor="${t.estado}"/></td>
      <td><a class="btn btn-sm btn-outline-primary" href="${ctx}/admin/trabajo_editar.jsp?id=${t.id_trabajo}">Editar</a>
          <a class="btn btn-sm btn-outline-secondary" href="${ctx}/trabajo.jsp?id=${t.id_trabajo}">Ver</a></td></tr>
  </c:forEach></tbody></table>
<t:paginacion pagina="${pagina}" total="${total}" porPagina="${porPagina}"/>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
