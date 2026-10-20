<%--
    estudiante/entrega_accion.jsp - Controlador del estudiante.
      accion=anteproyecto : registra la URL del FD-124 (FASE 2) como nueva version
      accion=pago         : reenvia un recibo de pago RECHAZADO (FASE 1)
    Toda URL es texto: NO se suben archivos.
--%>
<c:set var="rolRequerido" value="ESTUDIANTE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>

<c:set var="url" value="${fn:trim(param.url)}"/>
<c:set var="volver" value="/trabajo.jsp"/>
<c:if test="${not fn:startsWith(url, 'http://') and not fn:startsWith(url, 'https://')}">
    <c:redirect url="${volver}"><c:param name="id" value="${param.id_trabajo}"/><c:param name="err" value="La URL debe empezar por http:// o https://"/></c:redirect>
</c:if>

<%-- el estudiante debe pertenecer al trabajo y el trabajo estar activo --%>
<sql:query var="rsT" dataSource="${ds}">
    SELECT t.fase_actual FROM trabajo_grado t
    JOIN trabajo_grado_estudiante e ON e.id_trabajo = t.id_trabajo
    WHERE t.id_trabajo = ? AND e.id_usuario_estudiante = ? AND t.estado = 'ACTIVO'
    <sql:param value="${param.id_trabajo}"/><sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:if test="${rsT.rowCount == 0}"><c:redirect url="/acceso_denegado.jsp"/></c:if>

<c:choose>
<c:when test="${param.accion == 'pago'}">
    <sql:update var="n" dataSource="${ds}">
        UPDATE pago SET comprobante_url = ?, estado = 'PENDIENTE', fecha_pago = NOW()
        WHERE id_pago = ? AND id_trabajo = ? AND id_usuario_estudiante = ? AND estado = 'RECHAZADO'
        <sql:param value="${url}"/><sql:param value="${param.id_pago}"/>
        <sql:param value="${param.id_trabajo}"/><sql:param value="${sessionScope.idUsuario}"/>
    </sql:update>
    <c:redirect url="${volver}"><c:param name="id" value="${param.id_trabajo}"/>
        <c:param name="ok" value="${n == 1 ? 'Recibo reenviado.' : 'No se pudo reenviar el recibo.'}"/></c:redirect>
</c:when>

<c:when test="${param.accion == 'anteproyecto'}">
    <c:if test="${rsT.rows[0].fase_actual != 2}">
        <c:redirect url="${volver}"><c:param name="id" value="${param.id_trabajo}"/><c:param name="err" value="El anteproyecto solo se registra en la Fase 2."/></c:redirect>
    </c:if>
    <sql:query var="rsU" dataSource="${ds}">
        SELECT COALESCE(MAX(version), 0) AS v,
               COALESCE(MAX(CASE WHEN estado IN ('PENDIENTE','APROBADA') THEN 1 ELSE 0 END), 0) AS bloquea
        FROM entrega WHERE id_trabajo = ? AND tipo_documento = 'FD124'
        <sql:param value="${param.id_trabajo}"/>
    </sql:query>
    <c:if test="${rsU.rows[0].bloquea == 1}">
        <c:redirect url="${volver}"><c:param name="id" value="${param.id_trabajo}"/><c:param name="err" value="Ya hay un anteproyecto en revisión o aprobado."/></c:redirect>
    </c:if>
    <c:catch var="eTx">
    <sql:transaction dataSource="${ds}">
        <sql:update>INSERT INTO entrega (id_trabajo, id_fase, tipo_documento, version, estado) VALUES (?, 2, 'FD124', ?, 'PENDIENTE')
            <sql:param value="${param.id_trabajo}"/><sql:param value="${rsU.rows[0].v + 1}"/></sql:update>
        <sql:query var="rsE">SELECT LAST_INSERT_ID() AS id</sql:query>
        <sql:update>INSERT INTO documento (id_entrega, url_documento, subido_por) VALUES (?, ?, ?)
            <sql:param value="${rsE.rows[0].id}"/><sql:param value="${url}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
    </sql:transaction>
    </c:catch>
    <c:redirect url="${volver}"><c:param name="id" value="${param.id_trabajo}"/>
        <c:param name="ok" value="${empty eTx ? 'Anteproyecto registrado. El director lo revisará.' : 'No se pudo registrar el anteproyecto.'}"/></c:redirect>
</c:when>

<c:otherwise><c:redirect url="${volver}"><c:param name="id" value="${param.id_trabajo}"/><c:param name="err" value="Acción no válida."/></c:redirect></c:otherwise>
</c:choose>
