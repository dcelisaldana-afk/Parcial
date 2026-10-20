<%--
    docente/evaluar_accion.jsp - Controlador de director y evaluador.
      dir_anteproyecto : director conceptua el FD-124 (Fase 2). Si APRUEBA: fija
                         fecha de aprobacion y plazo, pasa a Fase 3 y abre la tarea del evaluador.
      dir_informe      : director registra el informe FD-125 con su concepto (Fase 4,
                         solo si pasaron los dias minimos). Si APRUEBA pasa a Fase 5.
      evaluador        : evaluador responde (Fases 3 y 5). Si NO aprueba, el trabajo
                         regresa a la fase anterior (3->2, 5->4).
    Cada docente solo actua sobre trabajos donde esta asignado con ese rol.
--%>
<c:set var="rolRequerido" value="DOCENTE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/dias_evaluador.jspf" %>

<c:set var="idT" value="${param.id_trabajo}"/>
<c:set var="concepto" value="${param.concepto}"/>
<c:if test="${concepto != 'APROBADO' and concepto != 'APLAZADO' and concepto != 'RECHAZADO'}">
    <c:redirect url="/trabajo.jsp"><c:param name="id" value="${idT}"/><c:param name="err" value="Concepto no válido."/></c:redirect>
</c:if>

<sql:query var="rsG" dataSource="${ds}">
    SELECT t.fase_actual, rd.tipo_rol,
           DATEDIFF(CURDATE(), t.fecha_aprob_propuesta) AS dias_desde_aprob,
           (SELECT valor FROM parametro_sistema WHERE clave = 'dias_minimos_informe') AS dias_min,
           (SELECT valor FROM parametro_sistema WHERE clave = 'plazo_dias') AS plazo
    FROM trabajo_grado t
    JOIN rol_docente rd ON rd.id_trabajo = t.id_trabajo AND rd.id_usuario_docente = ? AND rd.activo = 1
    WHERE t.id_trabajo = ? AND t.estado = 'ACTIVO'
    <sql:param value="${sessionScope.idUsuario}"/><sql:param value="${idT}"/>
</sql:query>
<c:if test="${rsG.rowCount == 0}"><c:redirect url="/acceso_denegado.jsp"/></c:if>
<c:set var="g" value="${rsG.rows[0]}"/>
<c:set var="plazo" value="${g.plazo + 0}"/>
<c:set var="obs" value="${fn:trim(param.observaciones)}"/>
<c:set var="msg" value=""/><c:set var="error" value=""/>

<c:choose>
<%-- ================= DIRECTOR: ANTEPROYECTO ================= --%>
<c:when test="${param.accion == 'dir_anteproyecto'}">
    <c:if test="${g.tipo_rol != 'DIRECTOR' or g.fase_actual != 2}"><c:redirect url="/acceso_denegado.jsp"/></c:if>
    <sql:query var="rsE" dataSource="${ds}">
        SELECT id_entrega FROM entrega WHERE id_entrega = ? AND id_trabajo = ? AND tipo_documento = 'FD124' AND estado = 'PENDIENTE'
        <sql:param value="${param.id_entrega}"/><sql:param value="${idT}"/>
    </sql:query>
    <c:if test="${rsE.rowCount == 0}"><c:redirect url="/trabajo.jsp"><c:param name="id" value="${idT}"/><c:param name="err" value="No hay un anteproyecto pendiente."/></c:redirect></c:if>
    <c:catch var="eTx">
    <sql:transaction dataSource="${ds}">
        <sql:update>INSERT INTO evaluacion (id_entrega, id_usuario_evaluador, rol_evaluador, concepto, observaciones, fecha_evaluacion)
            VALUES (?, ?, 'DIRECTOR', ?, ?, NOW())
            <sql:param value="${param.id_entrega}"/><sql:param value="${sessionScope.idUsuario}"/>
            <sql:param value="${concepto}"/><sql:param value="${obs}"/></sql:update>
        <sql:update>UPDATE entrega SET estado = CASE ? WHEN 'APROBADO' THEN 'APROBADA' WHEN 'APLAZADO' THEN 'APLAZADA' ELSE 'RECHAZADA' END
            WHERE id_entrega = ?
            <sql:param value="${concepto}"/><sql:param value="${param.id_entrega}"/></sql:update>
        <c:if test="${concepto == 'APROBADO'}">
            <sql:update>UPDATE trabajo_grado
                SET fecha_aprob_propuesta = CURDATE(), fecha_limite_entrega = DATE_ADD(CURDATE(), INTERVAL ? DAY), fase_actual = 3
                WHERE id_trabajo = ?
                <sql:param value="${plazo}"/><sql:param value="${idT}"/></sql:update>
            <sql:update>INSERT INTO evaluacion (id_entrega, id_usuario_evaluador, rol_evaluador, fecha_limite_respuesta)
                SELECT ?, id_usuario_docente, 'EVALUADOR', DATE_ADD(NOW(), INTERVAL ? DAY)
                FROM rol_docente WHERE id_trabajo = ? AND tipo_rol = 'EVALUADOR' AND activo = 1
                <sql:param value="${param.id_entrega}"/><sql:param value="${diasEval}"/><sql:param value="${idT}"/></sql:update>
            <sql:update>INSERT INTO historico_trabajo_grado (id_trabajo, campo_modificado, valor_anterior, valor_nuevo, modificado_por)
                VALUES (?, 'fase_actual', '2', '3', ?)
                <sql:param value="${idT}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
        </c:if>
    </sql:transaction>
    </c:catch>
    <c:set var="msg" value="Concepto registrado."/>
</c:when>

<%-- ================= DIRECTOR: INFORME ================= --%>
<c:when test="${param.accion == 'dir_informe'}">
    <c:set var="url" value="${fn:trim(param.url)}"/>
    <c:if test="${g.tipo_rol != 'DIRECTOR' or g.fase_actual != 4}"><c:redirect url="/acceso_denegado.jsp"/></c:if>
    <c:if test="${not fn:startsWith(url, 'http://') and not fn:startsWith(url, 'https://')}">
        <c:redirect url="/trabajo.jsp"><c:param name="id" value="${idT}"/><c:param name="err" value="La URL del informe debe empezar por http:// o https://"/></c:redirect>
    </c:if>
    <c:if test="${g.dias_desde_aprob < g.dias_min}">
        <c:redirect url="/trabajo.jsp"><c:param name="id" value="${idT}"/><c:param name="err" value="Aún no se cumplen los ${g.dias_min} días mínimos desde la aprobación."/></c:redirect>
    </c:if>
    <sql:query var="rsU" dataSource="${ds}">
        SELECT COALESCE(MAX(version), 0) AS v,
               COALESCE(MAX(CASE WHEN estado IN ('PENDIENTE','APROBADA') THEN 1 ELSE 0 END), 0) AS bloquea
        FROM entrega WHERE id_trabajo = ? AND tipo_documento = 'FD125'
        <sql:param value="${idT}"/>
    </sql:query>
    <c:if test="${rsU.rows[0].bloquea == 1}">
        <c:redirect url="/trabajo.jsp"><c:param name="id" value="${idT}"/><c:param name="err" value="El informe ya está en revisión o aprobado."/></c:redirect>
    </c:if>
    <c:catch var="eTx">
    <sql:transaction dataSource="${ds}">
        <sql:update>INSERT INTO entrega (id_trabajo, id_fase, tipo_documento, version, estado)
            VALUES (?, 4, 'FD125', ?, CASE ? WHEN 'APROBADO' THEN 'APROBADA' WHEN 'APLAZADO' THEN 'APLAZADA' ELSE 'RECHAZADA' END)
            <sql:param value="${idT}"/><sql:param value="${rsU.rows[0].v + 1}"/><sql:param value="${concepto}"/></sql:update>
        <sql:query var="rsE">SELECT LAST_INSERT_ID() AS id</sql:query>
        <sql:update>INSERT INTO documento (id_entrega, url_documento, subido_por) VALUES (?, ?, ?)
            <sql:param value="${rsE.rows[0].id}"/><sql:param value="${url}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
        <sql:update>INSERT INTO evaluacion (id_entrega, id_usuario_evaluador, rol_evaluador, concepto, observaciones, fecha_evaluacion)
            VALUES (?, ?, 'DIRECTOR', ?, ?, NOW())
            <sql:param value="${rsE.rows[0].id}"/><sql:param value="${sessionScope.idUsuario}"/>
            <sql:param value="${concepto}"/><sql:param value="${obs}"/></sql:update>
        <c:if test="${concepto == 'APROBADO'}">
            <sql:update>INSERT INTO evaluacion (id_entrega, id_usuario_evaluador, rol_evaluador, fecha_limite_respuesta)
                SELECT ?, id_usuario_docente, 'EVALUADOR', DATE_ADD(NOW(), INTERVAL ? DAY)
                FROM rol_docente WHERE id_trabajo = ? AND tipo_rol = 'EVALUADOR' AND activo = 1
                <sql:param value="${rsE.rows[0].id}"/><sql:param value="${diasEval}"/><sql:param value="${idT}"/></sql:update>
            <sql:update>UPDATE trabajo_grado SET fase_actual = 5 WHERE id_trabajo = ?<sql:param value="${idT}"/></sql:update>
            <sql:update>INSERT INTO historico_trabajo_grado (id_trabajo, campo_modificado, valor_anterior, valor_nuevo, modificado_por)
                VALUES (?, 'fase_actual', '4', '5', ?)
                <sql:param value="${idT}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
        </c:if>
    </sql:transaction>
    </c:catch>
    <c:set var="msg" value="Informe registrado."/>
</c:when>

<%-- ================= EVALUADOR ================= --%>
<c:when test="${param.accion == 'evaluador'}">
    <c:if test="${g.tipo_rol != 'EVALUADOR' or (g.fase_actual != 3 and g.fase_actual != 5)}"><c:redirect url="/acceso_denegado.jsp"/></c:if>
    <sql:query var="rsEv" dataSource="${ds}">
        SELECT ev.id_evaluacion, ev.id_entrega FROM evaluacion ev JOIN entrega e ON e.id_entrega = ev.id_entrega
        WHERE ev.id_evaluacion = ? AND ev.id_usuario_evaluador = ? AND ev.rol_evaluador = 'EVALUADOR'
          AND ev.concepto IS NULL AND e.id_trabajo = ?
        <sql:param value="${param.id_evaluacion}"/><sql:param value="${sessionScope.idUsuario}"/><sql:param value="${idT}"/>
    </sql:query>
    <c:if test="${rsEv.rowCount == 0}"><c:redirect url="/trabajo.jsp"><c:param name="id" value="${idT}"/><c:param name="err" value="No tiene una evaluación pendiente."/></c:redirect></c:if>
    <c:catch var="eTx">
    <sql:transaction dataSource="${ds}">
        <sql:update>UPDATE evaluacion SET concepto = ?, observaciones = ?, fecha_evaluacion = NOW() WHERE id_evaluacion = ?
            <sql:param value="${concepto}"/><sql:param value="${obs}"/><sql:param value="${param.id_evaluacion}"/></sql:update>
        <c:if test="${concepto != 'APROBADO'}">
            <sql:update>UPDATE entrega SET estado = CASE ? WHEN 'APLAZADO' THEN 'APLAZADA' ELSE 'RECHAZADA' END WHERE id_entrega = ?
                <sql:param value="${concepto}"/><sql:param value="${rsEv.rows[0].id_entrega}"/></sql:update>
            <%-- los CASE van ANTES de fase_actual: MySQL evalua los SET de izquierda a derecha --%>
            <sql:update>UPDATE trabajo_grado
                SET fecha_aprob_propuesta = CASE WHEN fase_actual = 3 THEN NULL ELSE fecha_aprob_propuesta END,
                    fecha_limite_entrega  = CASE WHEN fase_actual = 3 THEN NULL ELSE fecha_limite_entrega END,
                    fase_actual = fase_actual - 1
                WHERE id_trabajo = ?
                <sql:param value="${idT}"/></sql:update>
            <sql:update>INSERT INTO historico_trabajo_grado (id_trabajo, campo_modificado, valor_anterior, valor_nuevo, modificado_por)
                VALUES (?, 'fase_actual', ?, ?, ?)
                <sql:param value="${idT}"/><sql:param value="${g.fase_actual}"/><sql:param value="${g.fase_actual - 1}"/>
                <sql:param value="${sessionScope.idUsuario}"/></sql:update>
        </c:if>
    </sql:transaction>
    </c:catch>
    <c:set var="msg" value="${concepto == 'APROBADO' ? 'Evaluación enviada. El Comité cerrará la fase.' : 'Evaluación enviada: el trabajo regresa a la fase anterior.'}"/>
</c:when>

<c:otherwise><c:set var="error" value="Acción no válida."/></c:otherwise>
</c:choose>

<c:choose>
    <c:when test="${not empty error or not empty eTx}">
        <c:redirect url="/trabajo.jsp"><c:param name="id" value="${idT}"/><c:param name="err" value="${empty error ? 'No se pudo guardar la operación.' : error}"/></c:redirect>
    </c:when>
    <c:otherwise>
        <c:redirect url="/trabajo.jsp"><c:param name="id" value="${idT}"/><c:param name="ok" value="${msg}"/></c:redirect>
    </c:otherwise>
</c:choose>
