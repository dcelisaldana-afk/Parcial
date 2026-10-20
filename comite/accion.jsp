<%--
    comite/accion.jsp - Controlador del Comite/Coordinacion. Acciones:
      verificar_pago, aprobar_inscripcion, rechazar_inscripcion  (Fase 1)
      avanzar (Fase 3->4 y 5->6), cerrar (Fase 6, cierre definitivo)
      aprobar_idea, rechazar_idea, aprobar_prorroga, rechazar_prorroga
    Cada accion revalida en el servidor la fase y las reglas de negocio.
--%>
<c:set var="rolRequerido" value="COMITE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>

<c:set var="idT" value="${param.id_trabajo}"/>
<c:set var="accion" value="${param.accion}"/>
<c:set var="msg" value=""/><c:set var="error" value=""/><c:set var="destino" value="/trabajo.jsp"/>

<c:choose>

<%-- ---------- IDEAS DEL BANCO ---------- --%>
<c:when test="${accion == 'aprobar_idea' or accion == 'rechazar_idea'}">
    <c:set var="destino" value="/comite/ideas.jsp"/>
    <sql:update var="n" dataSource="${ds}">
        UPDATE banco_idea SET estado = ? WHERE id_idea = ? AND estado = 'PENDIENTE'
        <sql:param value="${accion == 'aprobar_idea' ? 'DISPONIBLE' : 'RECHAZADA'}"/><sql:param value="${param.id_idea}"/>
    </sql:update>
    <c:set var="msg" value="${accion == 'aprobar_idea' ? 'Idea publicada en el banco.' : 'Idea rechazada.'}"/>
</c:when>

<%-- ---------- PRORROGAS ---------- --%>
<c:when test="${accion == 'aprobar_prorroga' or accion == 'rechazar_prorroga'}">
    <c:set var="destino" value="/comite/prorrogas.jsp"/>
    <sql:query var="rsPr" dataSource="${ds}">
        SELECT p.id_prorroga, p.id_trabajo, p.id_pago, t.numero_prorrogas, t.fecha_limite_entrega,
               (SELECT valor FROM parametro_sistema WHERE clave = 'max_prorrogas') AS maxp,
               (SELECT valor FROM parametro_sistema WHERE clave = 'dias_prorroga') AS dias
        FROM prorroga p JOIN trabajo_grado t ON t.id_trabajo = p.id_trabajo
        WHERE p.id_prorroga = ? AND p.estado = 'PENDIENTE' AND t.estado = 'ACTIVO'
        <sql:param value="${param.id_prorroga}"/>
    </sql:query>
    <c:choose>
    <c:when test="${rsPr.rowCount == 0}"><c:set var="error" value="La prórroga ya no está pendiente."/></c:when>
    <c:when test="${accion == 'rechazar_prorroga'}">
        <c:catch var="eTx">
        <sql:transaction dataSource="${ds}">
            <sql:update>UPDATE prorroga SET estado = 'RECHAZADA', aprobada_por = ?, fecha_aprobacion = NOW() WHERE id_prorroga = ?
                <sql:param value="${sessionScope.idUsuario}"/><sql:param value="${rsPr.rows[0].id_prorroga}"/></sql:update>
            <sql:update>UPDATE pago SET estado = 'RECHAZADO' WHERE id_pago = ?<sql:param value="${rsPr.rows[0].id_pago}"/></sql:update>
        </sql:transaction>
        </c:catch>
        <c:set var="msg" value="Prórroga rechazada."/>
    </c:when>
    <c:when test="${rsPr.rows[0].numero_prorrogas >= rsPr.rows[0].maxp}">
        <c:set var="error" value="El trabajo ya alcanzó el máximo de prórrogas."/>
    </c:when>
    <c:otherwise>
        <sql:query var="rsNuevo" dataSource="${ds}">
            SELECT DATE_ADD(fecha_limite_entrega, INTERVAL ? DAY) AS nuevo FROM trabajo_grado WHERE id_trabajo = ?
            <sql:param value="${rsPr.rows[0].dias + 0}"/><sql:param value="${rsPr.rows[0].id_trabajo}"/>
        </sql:query>
        <c:catch var="eTx">
        <sql:transaction dataSource="${ds}">
            <sql:update>UPDATE prorroga SET estado = 'APROBADA', aprobada_por = ?, fecha_aprobacion = NOW(), nuevo_plazo_fecha = ?
                WHERE id_prorroga = ?
                <sql:param value="${sessionScope.idUsuario}"/><sql:param value="${rsNuevo.rows[0].nuevo}"/><sql:param value="${rsPr.rows[0].id_prorroga}"/></sql:update>
            <sql:update>UPDATE pago SET estado = 'VERIFICADO' WHERE id_pago = ?<sql:param value="${rsPr.rows[0].id_pago}"/></sql:update>
            <sql:update>UPDATE trabajo_grado SET fecha_limite_entrega = ?, numero_prorrogas = numero_prorrogas + 1 WHERE id_trabajo = ?
                <sql:param value="${rsNuevo.rows[0].nuevo}"/><sql:param value="${rsPr.rows[0].id_trabajo}"/></sql:update>
            <sql:update>INSERT INTO historico_trabajo_grado (id_trabajo, campo_modificado, valor_anterior, valor_nuevo, modificado_por)
                VALUES (?, 'fecha_limite_entrega', ?, ?, ?)
                <sql:param value="${rsPr.rows[0].id_trabajo}"/><sql:param value="${rsPr.rows[0].fecha_limite_entrega}"/>
                <sql:param value="${rsNuevo.rows[0].nuevo}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
        </sql:transaction>
        </c:catch>
        <c:set var="msg" value="Prórroga aprobada: se amplió la fecha límite."/>
    </c:otherwise>
    </c:choose>
</c:when>

<%-- ---------- ACCIONES SOBRE UN TRABAJO ---------- --%>
<c:otherwise>
    <sql:query var="rsT" dataSource="${ds}">
        SELECT fase_actual, id_idea FROM trabajo_grado WHERE id_trabajo = ? AND estado = 'ACTIVO'
        <sql:param value="${idT}"/>
    </sql:query>
    <c:if test="${rsT.rowCount == 0}"><c:redirect url="/comite/panel.jsp"><c:param name="err" value="El trabajo no está activo."/></c:redirect></c:if>
    <c:set var="fase" value="${rsT.rows[0].fase_actual}"/>

    <c:choose>
    <c:when test="${accion == 'verificar_pago'}">
        <sql:update var="n" dataSource="${ds}">
            UPDATE pago SET estado = ? WHERE id_pago = ? AND id_trabajo = ? AND tipo_pago = 'DERECHOS_GRADO' AND estado = 'PENDIENTE'
            <sql:param value="${param.resultado == 'VERIFICADO' ? 'VERIFICADO' : 'RECHAZADO'}"/>
            <sql:param value="${param.id_pago}"/><sql:param value="${idT}"/>
        </sql:update>
        <c:set var="msg" value="Pago actualizado."/>
    </c:when>

    <c:when test="${accion == 'aprobar_inscripcion'}">
        <sql:query var="rsPend" dataSource="${ds}">
            SELECT COUNT(*) AS n FROM pago WHERE id_trabajo = ? AND tipo_pago = 'DERECHOS_GRADO' AND estado <> 'VERIFICADO'
            <sql:param value="${idT}"/>
        </sql:query>
        <sql:query var="rsDoc" dataSource="${ds}">
            SELECT COUNT(DISTINCT u.id_usuario) AS n FROM usuario u
            JOIN usuario_rol ur ON ur.id_usuario = u.id_usuario JOIN rol r ON r.id_rol = ur.id_rol
            WHERE r.nombre = 'DOCENTE' AND u.estado = 'ACTIVO' AND u.id_usuario IN (?, ?)
            <sql:param value="${param.id_director}"/><sql:param value="${param.id_evaluador}"/>
        </sql:query>
        <c:choose>
        <c:when test="${fase != 1}"><c:set var="error" value="El trabajo ya no está en la Fase 1."/></c:when>
        <c:when test="${param.id_director == param.id_evaluador}"><c:set var="error" value="El director y el evaluador deben ser docentes distintos."/></c:when>
        <c:when test="${rsDoc.rows[0].n != 2}"><c:set var="error" value="Director y evaluador deben ser docentes activos."/></c:when>
        <c:when test="${rsPend.rows[0].n > 0}"><c:set var="error" value="Faltan recibos de pago por verificar."/></c:when>
        <c:otherwise>
            <c:catch var="eTx">
            <sql:transaction dataSource="${ds}">
                <sql:update>INSERT INTO rol_docente (id_trabajo, id_usuario_docente, tipo_rol) VALUES (?, ?, 'DIRECTOR')
                    <sql:param value="${idT}"/><sql:param value="${param.id_director}"/></sql:update>
                <sql:update>INSERT INTO rol_docente (id_trabajo, id_usuario_docente, tipo_rol) VALUES (?, ?, 'EVALUADOR')
                    <sql:param value="${idT}"/><sql:param value="${param.id_evaluador}"/></sql:update>
                <sql:update>UPDATE banco_idea SET estado = 'ASIGNADA' WHERE id_idea = ? AND estado = 'PENDIENTE'
                    <sql:param value="${rsT.rows[0].id_idea}"/></sql:update>
                <sql:update>UPDATE trabajo_grado SET fase_actual = 2 WHERE id_trabajo = ?<sql:param value="${idT}"/></sql:update>
                <sql:update>INSERT INTO historico_trabajo_grado (id_trabajo, campo_modificado, valor_anterior, valor_nuevo, modificado_por)
                    VALUES (?, 'fase_actual', '1', '2', ?)
                    <sql:param value="${idT}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
            </sql:transaction>
            </c:catch>
            <c:set var="msg" value="Inscripción aprobada: el trabajo pasa a la Fase 2."/>
        </c:otherwise>
        </c:choose>
    </c:when>

    <c:when test="${accion == 'rechazar_inscripcion'}">
        <c:if test="${fase != 1}"><c:redirect url="/trabajo.jsp"><c:param name="id" value="${idT}"/><c:param name="err" value="Solo se rechaza en la Fase 1."/></c:redirect></c:if>
        <c:catch var="eTx">
        <sql:transaction dataSource="${ds}">
            <sql:update>UPDATE banco_idea SET estado = CASE WHEN estado = 'PENDIENTE' THEN 'RECHAZADA' ELSE 'DISPONIBLE' END WHERE id_idea = ?
                <sql:param value="${rsT.rows[0].id_idea}"/></sql:update>
            <sql:update>UPDATE trabajo_grado SET estado = 'CANCELADO' WHERE id_trabajo = ?<sql:param value="${idT}"/></sql:update>
            <sql:update>INSERT INTO historico_trabajo_grado (id_trabajo, campo_modificado, valor_anterior, valor_nuevo, modificado_por)
                VALUES (?, 'estado', 'ACTIVO', 'CANCELADO', ?)
                <sql:param value="${idT}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
        </sql:transaction>
        </c:catch>
        <c:set var="msg" value="Inscripción rechazada."/>
    </c:when>

    <c:when test="${accion == 'avanzar'}">
        <c:set var="tipoDoc" value="${fase == 3 ? 'FD124' : 'FD125'}"/>
        <sql:query var="rsC" dataSource="${ds}">
            SELECT ev.concepto FROM evaluacion ev JOIN entrega e ON e.id_entrega = ev.id_entrega
            WHERE e.id_trabajo = ? AND e.tipo_documento = ? AND ev.rol_evaluador = 'EVALUADOR'
            ORDER BY e.version DESC LIMIT 1
            <sql:param value="${idT}"/><sql:param value="${tipoDoc}"/>
        </sql:query>
        <c:choose>
        <c:when test="${fase != 3 and fase != 5}"><c:set var="error" value="La fase actual no se cierra desde aquí."/></c:when>
        <c:when test="${rsC.rowCount == 0 or rsC.rows[0].concepto != 'APROBADO'}"><c:set var="error" value="El evaluador aún no aprueba."/></c:when>
        <c:otherwise>
            <c:catch var="eTx">
            <sql:transaction dataSource="${ds}">
                <sql:update>UPDATE trabajo_grado SET fase_actual = fase_actual + 1 WHERE id_trabajo = ?<sql:param value="${idT}"/></sql:update>
                <sql:update>INSERT INTO historico_trabajo_grado (id_trabajo, campo_modificado, valor_anterior, valor_nuevo, modificado_por)
                    VALUES (?, 'fase_actual', ?, ?, ?)
                    <sql:param value="${idT}"/><sql:param value="${fase}"/><sql:param value="${fase + 1}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
            </sql:transaction>
            </c:catch>
            <c:set var="msg" value="Fase cerrada: el trabajo avanza a la Fase ${fase + 1}."/>
        </c:otherwise>
        </c:choose>
    </c:when>

    <c:when test="${accion == 'cerrar'}">
        <c:choose>
        <c:when test="${fase != 6}"><c:set var="error" value="Solo se cierra en la Fase 6."/></c:when>
        <c:when test="${not empty fn:trim(param.repositorio_url) and not fn:startsWith(fn:trim(param.repositorio_url), 'http')}">
            <c:set var="error" value="La URL del repositorio debe empezar por http:// o https://"/></c:when>
        <c:otherwise>
            <c:catch var="eTx">
            <sql:transaction dataSource="${ds}">
                <sql:update>UPDATE trabajo_grado SET estado = 'CERRADO', fecha_cierre = NOW(), cerrado_por = ?, repositorio_url = NULLIF(?, '')
                    WHERE id_trabajo = ?
                    <sql:param value="${sessionScope.idUsuario}"/><sql:param value="${fn:trim(param.repositorio_url)}"/><sql:param value="${idT}"/></sql:update>
                <sql:update>INSERT INTO historico_trabajo_grado (id_trabajo, campo_modificado, valor_anterior, valor_nuevo, modificado_por)
                    VALUES (?, 'estado', 'ACTIVO', 'CERRADO', ?)
                    <sql:param value="${idT}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
            </sql:transaction>
            </c:catch>
            <c:set var="msg" value="Trabajo cerrado definitivamente."/>
        </c:otherwise>
        </c:choose>
    </c:when>

    <c:otherwise><c:set var="error" value="Acción no válida."/></c:otherwise>
    </c:choose>
</c:otherwise>
</c:choose>

<c:choose>
    <c:when test="${not empty error or not empty eTx}">
        <c:redirect url="${destino}"><c:if test="${destino == '/trabajo.jsp'}"><c:param name="id" value="${idT}"/></c:if>
            <c:param name="err" value="${empty error ? 'No se pudo completar la operación.' : error}"/></c:redirect>
    </c:when>
    <c:otherwise>
        <c:redirect url="${destino}"><c:if test="${destino == '/trabajo.jsp'}"><c:param name="id" value="${idT}"/></c:if>
            <c:param name="ok" value="${msg}"/></c:redirect>
    </c:otherwise>
</c:choose>
