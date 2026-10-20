<%-- estudiante/prorroga_accion.jsp - Registra la solicitud de prorroga (pago + prorroga en una transaccion). --%>
<c:set var="rolRequerido" value="ESTUDIANTE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>

<c:set var="url" value="${fn:trim(param.url)}"/>
<c:if test="${not fn:startsWith(url, 'http://') and not fn:startsWith(url, 'https://')}">
    <c:redirect url="/estudiante/prorroga.jsp"><c:param name="id" value="${param.id_trabajo}"/><c:param name="err" value="La URL del recibo debe empezar por http:// o https://"/></c:redirect>
</c:if>

<sql:query var="rsT" dataSource="${ds}">
    SELECT t.numero_prorrogas, DATEDIFF(t.fecha_limite_entrega, CURDATE()) AS dias_restantes,
           (SELECT COUNT(*) FROM prorroga WHERE id_trabajo = t.id_trabajo AND estado = 'PENDIENTE') AS pend,
           (SELECT valor FROM parametro_sistema WHERE clave = 'max_prorrogas') AS maxp,
           (SELECT valor FROM parametro_sistema WHERE clave = 'dias_aviso_prorroga') AS aviso,
           (SELECT valor FROM parametro_sistema WHERE clave = 'valor_derechos_grado') AS valor
    FROM trabajo_grado t JOIN trabajo_grado_estudiante e ON e.id_trabajo = t.id_trabajo
    WHERE t.id_trabajo = ? AND e.id_usuario_estudiante = ? AND t.estado = 'ACTIVO' AND t.fecha_limite_entrega IS NOT NULL
    <sql:param value="${param.id_trabajo}"/><sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:if test="${rsT.rowCount == 0}"><c:redirect url="/acceso_denegado.jsp"/></c:if>
<c:set var="t" value="${rsT.rows[0]}"/>

<%-- reglas de negocio (el servidor decide, no el formulario) --%>
<c:set var="motivo" value=""/>
<c:if test="${t.numero_prorrogas + t.pend >= t.maxp}"><c:set var="motivo" value="Se alcanzó el máximo de prórrogas."/></c:if>
<c:if test="${t.pend > 0}"><c:set var="motivo" value="Ya hay una prórroga pendiente."/></c:if>
<c:if test="${t.dias_restantes > t.aviso}"><c:set var="motivo" value="Aún no está en la ventana para solicitar prórroga."/></c:if>
<c:if test="${not empty motivo}">
    <c:redirect url="/estudiante/prorroga.jsp"><c:param name="id" value="${param.id_trabajo}"/><c:param name="err" value="${motivo}"/></c:redirect>
</c:if>

<c:catch var="eTx">
<sql:transaction dataSource="${ds}">
    <sql:update>INSERT INTO pago (id_trabajo, id_usuario_estudiante, tipo_pago, valor, comprobante_url) VALUES (?, ?, 'PRORROGA', ?, ?)
        <sql:param value="${param.id_trabajo}"/><sql:param value="${sessionScope.idUsuario}"/>
        <sql:param value="${t.valor}"/><sql:param value="${url}"/></sql:update>
    <sql:query var="rsPg">SELECT LAST_INSERT_ID() AS id</sql:query>
    <sql:update>INSERT INTO prorroga (id_trabajo, numero_prorroga, id_pago, estado) VALUES (?, ?, ?, 'PENDIENTE')
        <sql:param value="${param.id_trabajo}"/><sql:param value="${t.numero_prorrogas + 1}"/><sql:param value="${rsPg.rows[0].id}"/></sql:update>
</sql:transaction>
</c:catch>
<c:redirect url="/estudiante/prorroga.jsp"><c:param name="id" value="${param.id_trabajo}"/>
    <c:param name="ok" value="${empty eTx ? 'Prórroga solicitada. El Comité la revisará.' : 'No se pudo registrar la prórroga.'}"/></c:redirect>
