<%-- calendario_accion.jsp - Alta y baja de eventos del calendario (Comite o Administrador). --%>
<c:set var="rolRequerido" value="COMITE,ADMINISTRADOR"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:catch var="eTx">
<c:choose>
  <c:when test="${param.accion == 'add'}">
    <sql:update dataSource="${ds}">INSERT INTO calendario_academico (titulo, descripcion, id_fase, tipo_evento, fecha_inicio, fecha_fin)
        VALUES (?, ?, NULLIF(?, ''), ?, ?, ?)
        <sql:param value="${fn:trim(param.titulo)}"/><sql:param value="${param.descripcion}"/><sql:param value="${param.id_fase}"/>
        <sql:param value="${param.tipo}"/><sql:param value="${param.inicio}"/><sql:param value="${param.fin}"/></sql:update>
  </c:when>
  <c:when test="${param.accion == 'del'}">
    <sql:update dataSource="${ds}">DELETE FROM calendario_academico WHERE id_evento = ?<sql:param value="${param.id}"/></sql:update>
  </c:when>
</c:choose>
</c:catch>
<c:redirect url="/calendario.jsp">
    <c:param name="ok" value="${empty eTx ? 'Calendario actualizado.' : ''}"/>
    <c:param name="err" value="${empty eTx ? '' : 'No se pudo guardar el evento (revise las fechas).'}"/>
</c:redirect>
