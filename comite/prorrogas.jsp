<%-- comite/prorrogas.jsp - Solicitudes de prorroga pendientes (con pago adjunto como URL). --%>
<c:set var="tituloPagina" value="Prórrogas"/>
<c:set var="rolRequerido" value="COMITE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<sql:query var="rsP" dataSource="${ds}">
    SELECT p.id_prorroga, p.numero_prorroga, p.fecha_solicitud, t.id_trabajo, t.titulo, t.fecha_limite_entrega, t.numero_prorrogas,
           pg.comprobante_url
    FROM prorroga p JOIN trabajo_grado t ON t.id_trabajo = p.id_trabajo JOIN pago pg ON pg.id_pago = p.id_pago
    WHERE p.estado = 'PENDIENTE' ORDER BY p.fecha_solicitud
</sql:query>

<h3 class="mb-3"><i class="bi bi-hourglass-split"></i> Solicitudes de pr&oacute;rroga</h3>
<table class="table tabla-compacta"><thead><tr><th>Trabajo</th><th>N&deg;</th><th>L&iacute;mite actual</th><th>Recibo (URL)</th><th></th></tr></thead><tbody>
  <c:forEach var="p" items="${rsP.rows}">
    <tr><td><a href="${ctx}/trabajo.jsp?id=${p.id_trabajo}">#${p.id_trabajo}</a> <c:out value="${p.titulo}"/></td>
      <td>${p.numero_prorroga}</td>
      <td><fmt:formatDate value="${p.fecha_limite_entrega}" pattern="dd/MM/yyyy"/></td>
      <td class="url-doc"><a target="_blank" rel="noopener" href="<c:out value='${p.comprobante_url}'/>"><c:out value="${p.comprobante_url}"/></a></td>
      <td><form action="${ctx}/comite/accion.jsp" method="post" class="d-flex gap-1">
        <input type="hidden" name="id_prorroga" value="${p.id_prorroga}">
        <button name="accion" value="aprobar_prorroga" class="btn btn-sm btn-success">Aprobar</button>
        <button name="accion" value="rechazar_prorroga" class="btn btn-sm btn-outline-danger">Rechazar</button></form></td></tr>
  </c:forEach>
  <c:if test="${rsP.rowCount == 0}"><tr><td colspan="5" class="text-muted">No hay pr&oacute;rrogas pendientes.</td></tr></c:if>
</tbody></table>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
