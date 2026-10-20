<%--
    estudiante/inscripcion_accion.jsp - Controlador de la inscripcion (FASE 1).
    Valida todo en el servidor y guarda en UNA transaccion: trabajo, estudiantes,
    pagos (uno por estudiante) y bitacora. Patron PRG: siempre termina en redirect.
--%>
<c:set var="rolRequerido" value="ESTUDIANTE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>

<c:set var="volver" value="/estudiante/inscripcion.jsp"/>
<c:set var="pago1" value="${fn:trim(param.pago1)}"/>
<c:set var="pago2" value="${fn:trim(param.pago2)}"/>
<c:set var="correo2" value="${fn:toLowerCase(fn:trim(param.correo2))}"/>
<c:set var="propia" value="${param.modo_idea == 'propia'}"/>

<%-- 1. un solo trabajo activo por estudiante --%>
<sql:query var="rsActivo" dataSource="${ds}">
    SELECT COUNT(*) AS n FROM trabajo_grado t JOIN trabajo_grado_estudiante e ON e.id_trabajo = t.id_trabajo
    WHERE e.id_usuario_estudiante = ? AND t.estado = 'ACTIVO'
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:if test="${rsActivo.rows[0].n > 0}">
    <c:redirect url="/estudiante/panel.jsp"><c:param name="err" value="Ya tiene un trabajo de grado activo."/></c:redirect>
</c:if>

<%-- 2. validaciones de formulario --%>
<c:if test="${not fn:startsWith(pago1, 'http://') and not fn:startsWith(pago1, 'https://')}">
    <c:redirect url="${volver}"><c:param name="err" value="La URL del recibo de pago debe empezar por http:// o https://"/></c:redirect>
</c:if>
<c:if test="${propia and (empty fn:trim(param.titulo) or empty fn:trim(param.descripcion))}">
    <c:redirect url="${volver}"><c:param name="err" value="La idea propia requiere título y descripción."/><c:param name="modo_idea" value="propia"/></c:redirect>
</c:if>
<c:if test="${not propia and empty param.id_idea}">
    <c:redirect url="${volver}"><c:param name="err" value="Seleccione una idea del banco."/></c:redirect>
</c:if>

<%-- 3. segundo estudiante (opcional) --%>
<c:set var="idEst2" value=""/>
<c:if test="${not empty correo2}">
    <c:if test="${not fn:startsWith(pago2, 'http://') and not fn:startsWith(pago2, 'https://')}">
        <c:redirect url="${volver}"><c:param name="err" value="El segundo estudiante debe tener su propia URL de recibo de pago."/></c:redirect>
    </c:if>
    <sql:query var="rs2" dataSource="${ds}">
        SELECT u.id_usuario,
               (SELECT COUNT(*) FROM trabajo_grado_estudiante e JOIN trabajo_grado t ON t.id_trabajo = e.id_trabajo
                 WHERE e.id_usuario_estudiante = u.id_usuario AND t.estado = 'ACTIVO') AS activos
        FROM usuario u
        JOIN usuario_rol ur ON ur.id_usuario = u.id_usuario
        JOIN rol r ON r.id_rol = ur.id_rol AND r.nombre = 'ESTUDIANTE'
        WHERE u.correo = ? AND u.estado = 'ACTIVO' AND u.id_usuario <> ?
        <sql:param value="${correo2}"/>
        <sql:param value="${sessionScope.idUsuario}"/>
    </sql:query>
    <c:if test="${rs2.rowCount == 0}">
        <c:redirect url="${volver}"><c:param name="err" value="El segundo estudiante no existe, está inactivo o es usted mismo."/></c:redirect>
    </c:if>
    <c:if test="${rs2.rows[0].activos > 0}">
        <c:redirect url="${volver}"><c:param name="err" value="El segundo estudiante ya tiene un trabajo activo."/></c:redirect>
    </c:if>
    <c:set var="idEst2" value="${rs2.rows[0].id_usuario}"/>
</c:if>

<sql:query var="rsValor" dataSource="${ds}">
    SELECT valor FROM parametro_sistema WHERE clave = 'valor_derechos_grado'
</sql:query>
<c:set var="valorPago" value="${rsValor.rows[0].valor}"/>

<%-- 4. datos de la idea --%>
<c:set var="tituloT" value=""/><c:set var="resumenT" value=""/><c:set var="lineaT" value=""/><c:set var="ideaT" value=""/>
<c:if test="${not propia}">
    <sql:query var="rsIdea" dataSource="${ds}">
        SELECT id_idea, titulo, descripcion, id_linea FROM banco_idea WHERE id_idea = ? AND estado = 'DISPONIBLE'
        <sql:param value="${param.id_idea}"/>
    </sql:query>
    <c:if test="${rsIdea.rowCount == 0}">
        <c:redirect url="${volver}"><c:param name="err" value="Esa idea ya no está disponible."/></c:redirect>
    </c:if>
    <c:set var="tituloT" value="${rsIdea.rows[0].titulo}"/>
    <c:set var="resumenT" value="${rsIdea.rows[0].descripcion}"/>
    <c:set var="lineaT" value="${rsIdea.rows[0].id_linea}"/>
    <c:set var="ideaT" value="${rsIdea.rows[0].id_idea}"/>
</c:if>

<%-- 5. transaccion --%>
<c:catch var="eTx">
<sql:transaction dataSource="${ds}">
    <c:choose>
        <c:when test="${propia}">
            <sql:update var="nIdea">
                INSERT INTO banco_idea (titulo, descripcion, objetivos, id_linea, propuesto_por, origen, palabras_clave, periodo_academico, nivel, estado)
                VALUES (?, ?, ?, ?, ?, 'ESTUDIANTE', ?, ?, ?, 'PENDIENTE')
                <sql:param value="${fn:trim(param.titulo)}"/><sql:param value="${fn:trim(param.descripcion)}"/>
                <sql:param value="${param.objetivos}"/><sql:param value="${param.id_linea}"/>
                <sql:param value="${sessionScope.idUsuario}"/><sql:param value="${param.palabras_clave}"/>
                <sql:param value="${param.periodo}"/><sql:param value="${param.nivel}"/>
            </sql:update>
            <sql:query var="rsNuevaIdea">SELECT LAST_INSERT_ID() AS id</sql:query>
            <c:set var="ideaT" value="${rsNuevaIdea.rows[0].id}"/>
            <c:set var="tituloT" value="${fn:trim(param.titulo)}"/>
            <c:set var="resumenT" value="${fn:trim(param.descripcion)}"/>
            <c:set var="lineaT" value="${param.id_linea}"/>
            <c:set var="reservada" value="1"/>
        </c:when>
        <c:otherwise>
            <%-- reserva atomica: solo una persona puede tomar la idea --%>
            <sql:update var="reservada">
                UPDATE banco_idea SET estado = 'ASIGNADA' WHERE id_idea = ? AND estado = 'DISPONIBLE'
                <sql:param value="${ideaT}"/>
            </sql:update>
        </c:otherwise>
    </c:choose>

    <c:if test="${reservada == 1}">
        <sql:update>
            INSERT INTO trabajo_grado (titulo, resumen, id_linea, id_programa, id_idea, modalidad, fase_actual, estado)
            VALUES (?, ?, ?, ?, ?, ?, 1, 'ACTIVO')
            <sql:param value="${tituloT}"/><sql:param value="${resumenT}"/><sql:param value="${lineaT}"/>
            <sql:param value="${param.id_programa}"/><sql:param value="${ideaT}"/><sql:param value="${param.modalidad}"/>
        </sql:update>
        <sql:query var="rsT">SELECT LAST_INSERT_ID() AS id</sql:query>
        <c:set var="idT" value="${rsT.rows[0].id}"/>

        <sql:update>INSERT INTO trabajo_grado_estudiante (id_trabajo, id_usuario_estudiante) VALUES (?, ?)
            <sql:param value="${idT}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
        <sql:update>INSERT INTO pago (id_trabajo, id_usuario_estudiante, tipo_pago, valor, comprobante_url)
            VALUES (?, ?, 'DERECHOS_GRADO', ?, ?)
            <sql:param value="${idT}"/><sql:param value="${sessionScope.idUsuario}"/>
            <sql:param value="${valorPago}"/><sql:param value="${pago1}"/></sql:update>
        <c:if test="${not empty idEst2}">
            <sql:update>INSERT INTO trabajo_grado_estudiante (id_trabajo, id_usuario_estudiante) VALUES (?, ?)
                <sql:param value="${idT}"/><sql:param value="${idEst2}"/></sql:update>
            <sql:update>INSERT INTO pago (id_trabajo, id_usuario_estudiante, tipo_pago, valor, comprobante_url)
                VALUES (?, ?, 'DERECHOS_GRADO', ?, ?)
                <sql:param value="${idT}"/><sql:param value="${idEst2}"/>
                <sql:param value="${valorPago}"/><sql:param value="${pago2}"/></sql:update>
        </c:if>
        <sql:update>INSERT INTO historico_trabajo_grado (id_trabajo, campo_modificado, valor_anterior, valor_nuevo, modificado_por)
            VALUES (?, 'inscripcion', NULL, 'Fase 1', ?)
            <sql:param value="${idT}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
    </c:if>
</sql:transaction>
</c:catch>

<c:choose>
    <c:when test="${not empty eTx}">
        <c:redirect url="${volver}"><c:param name="err" value="No se pudo inscribir: revise los datos e intente de nuevo."/></c:redirect>
    </c:when>
    <c:when test="${reservada != 1}">
        <c:redirect url="${volver}"><c:param name="err" value="Otra persona tomó la idea antes que usted."/></c:redirect>
    </c:when>
    <c:otherwise>
        <c:redirect url="/estudiante/panel.jsp"><c:param name="ok" value="Trabajo inscrito. El Comité verificará el pago y asignará director y evaluador."/></c:redirect>
    </c:otherwise>
</c:choose>
