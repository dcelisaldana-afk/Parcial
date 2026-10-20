<%-- formatos.jsp - Enlaces (URL) a los formatos FD-124, FD-125 y FD-129 y al reglamento. No hay descargas de archivos. --%>
<c:set var="tituloPagina" value="Formatos"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<sql:query var="rsF" dataSource="${ds}">
    SELECT clave, valor, descripcion FROM parametro_sistema WHERE clave LIKE 'url\_%' ORDER BY clave
</sql:query>
<h3 class="mb-3"><i class="bi bi-file-earmark-text"></i> Formatos y reglamento</h3>
<div class="list-group">
  <c:forEach var="f" items="${rsF.rows}">
    <a class="list-group-item list-group-item-action" target="_blank" rel="noopener" href="<c:out value='${f.valor}'/>">
      <b><c:out value="${f.descripcion}"/></b><div class="small text-muted url-doc"><c:out value="${f.valor}"/></div></a>
  </c:forEach>
</div>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>
