<%--
    estudiante/prorroga.jsp - Solicitud de prorroga. Reglas: el plazo es de 180
    dias desde la aprobacion del anteproyecto; maximo 2 prorrogas; solo se
    puede pedir cuando faltan <= dias_aviso_prorroga dias; cada prorroga exige
    su propio pago (URL) y la aprueba el Comite.
--%>
<c:set var="tituloPagina" value="Prórrogas"/>
<c:set var="rolRequerido" value="ESTUDIANTE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>

<sql:query var="rsT" dataSource="${ds}">
    SELECT t.id_trabajo, t.titulo, t.estado, t.numero_prorrogas, t.fecha_limite_entrega,
           DATEDIFF(t.fecha_limite_entrega, CURDATE()) AS dias_restantes
    FROM trabajo_grado t JOIN trabajo_grado_estudiante e ON e.id_trabajo = t.id_trabajo
    WHERE t.id_trabajo = ? AND e.id_usuario_estudiante = ?
    <sql:param value="${param.id}"/><sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:if test="${rsT.rowCount == 0}"><c:redirect url="/acceso_denegado.jsp"/></c:if>
<c:set var="t" value="${rsT.rows[0]}"/>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<sql:query var="rsP" dataSource="${ds}">SELECT clave, valor FROM parametro_sistema</sql:query>
<c:forEach var="pr" items="${rsP.rows}">
    <c:if test="${pr.clave == 'max_prorrogas'}"><c:set var="maxPro" value="${pr.valor}"/></c:if>
    <c:if test="${pr.clave == 'dias_aviso_prorroga'}"><c:set var="aviso" value="${pr.valor}"/></c:if>
    <c:if test="${pr.clave == 'dias_prorroga'}"><c:set var="diasPro" value="${pr.valor}"/></c:if>
    <c:if test="${pr.clave == 'valor_derechos_grado'}"><c:set var="valorPro" value="${pr.valor}"/></c:if>
</c:forEach>
<sql:query var="rsPend" dataSource="${ds}">
    SELECT COUNT(*) AS n FROM prorroga WHERE id_trabajo = ? AND estado = 'PENDIENTE'
    <sql:param value="${t.id_trabajo}"/>
</sql:query>
<sql:query var="rsHist" dataSource="${ds}">
    SELECT numero_prorroga, estado, fecha_solicitud, nuevo_plazo_fecha FROM prorroga WHERE id_trabajo = ? ORDER BY numero_prorroga
    <sql:param value="${t.id_trabajo}"/>
</sql:query>

<h3><i class="bi bi-hourglass-split"></i> Pr&oacute;rrogas</h3>
<p class="text-muted"><c:out value="${t.titulo}"/></p>
<ul>
  <li>Fecha l&iacute;mite actual: <b><fmt:formatDate value="${t.fecha_limite_entrega}" pattern="dd/MM/yyyy"/></b> (${t.dias_restantes} d&iacute;as)</li>
  <li>Pr&oacute;rrogas aprobadas: <b>${t.numero_prorrogas}</b> de ${maxPro}. Cada una suma ${diasPro} d&iacute;as y requiere un nuevo pago.</li>
</ul>

<c:choose>
  <c:when test="${t.estado != 'ACTIVO'}"><div class="alert alert-secondary">El trabajo no est&aacute; activo.</div></c:when>
  <c:when test="${t.numero_prorrogas >= maxPro}"><div class="alert alert-danger">Alcanz&oacute; el m&aacute;ximo de pr&oacute;rrogas.</div></c:when>
  <c:when test="${rsPend.rows[0].n > 0}"><div class="alert alert-info">Hay una pr&oacute;rroga pendiente de aprobaci&oacute;n del Comit&eacute;.</div></c:when>
  <c:when test="${t.dias_restantes > aviso}"><div class="alert alert-warning">Podr&aacute; solicitarla cuando falten ${aviso} d&iacute;as o menos para la fecha l&iacute;mite.</div></c:when>
  <c:otherwise>
    <form class="card card-body" action="${ctx}/estudiante/prorroga_accion.jsp" method="post">
      <input type="hidden" name="id_trabajo" value="${t.id_trabajo}">
      <label class="form-label">URL del recibo de pago de la pr&oacute;rroga ($<fmt:formatNumber value="${valorPro}" pattern="#,##0"/>)</label>
      <input type="url" class="form-control mb-3" name="url" data-url required placeholder="https://...">
      <button class="btn btn-warning">Solicitar pr&oacute;rroga</button>
    </form>
  </c:otherwise>
</c:choose>

<h5 class="mt-4">Historial</h5>
<ul>
  <c:forEach var="p" items="${rsHist.rows}">
    <li>Pr&oacute;rroga ${p.numero_prorroga} &mdash; <t:badge valor="${p.estado}"/>
      <c:if test="${not empty p.nuevo_plazo_fecha}"> &middot; nuevo plazo <fmt:formatDate value="${p.nuevo_plazo_fecha}" pattern="dd/MM/yyyy"/></c:if></li>
  </c:forEach>
  <c:if test="${rsHist.rowCount == 0}"><li class="text-muted">Sin pr&oacute;rrogas.</li></c:if>
</ul>
<a class="btn btn-outline-secondary" href="${ctx}/trabajo.jsp?id=${t.id_trabajo}">Volver al trabajo</a>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
