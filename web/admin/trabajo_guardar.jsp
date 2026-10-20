<%-- admin/trabajo_guardar.jsp - Guarda la edicion del Administrador y registra el historico. --%>
<c:set var="rolRequerido" value="ADMINISTRADOR"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>

<sql:query var="rsT" dataSource="${ds}">SELECT * FROM trabajo_grado WHERE id_trabajo = ?<sql:param value="${param.id}"/></sql:query>
<c:if test="${rsT.rowCount == 0}"><c:redirect url="/admin/trabajos.jsp"><c:param name="err" value="Trabajo inexistente."/></c:redirect></c:if>
<c:set var="t" value="${rsT.rows[0]}"/>

<c:choose>
<c:when test="${param.accion == 'cancelar' or param.accion == 'reactivar'}">
    <c:set var="nuevo" value="${param.accion == 'cancelar' ? 'CANCELADO' : 'ACTIVO'}"/>
    <c:catch var="eTx">
    <sql:transaction dataSource="${ds}">
        <sql:update>UPDATE trabajo_grado SET estado = ? WHERE id_trabajo = ?<sql:param value="${nuevo}"/><sql:param value="${t.id_trabajo}"/></sql:update>
        <sql:update>INSERT INTO historico_trabajo_grado (id_trabajo, campo_modificado, valor_anterior, valor_nuevo, modificado_por)
            VALUES (?, 'estado', ?, ?, ?)
            <sql:param value="${t.id_trabajo}"/><sql:param value="${t.estado}"/><sql:param value="${nuevo}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
    </sql:transaction>
    </c:catch>
    <c:redirect url="/admin/trabajos.jsp"><c:param name="ok" value="${empty eTx ? 'Estado actualizado.' : 'No se pudo actualizar.'}"/></c:redirect>
</c:when>
<c:otherwise>
    <c:set var="fecha" value="${fn:trim(param.fecha_limite)}"/>
    <c:if test="${empty fn:trim(param.titulo)}">
        <c:redirect url="/admin/trabajo_editar.jsp"><c:param name="id" value="${t.id_trabajo}"/><c:param name="err" value="El título es obligatorio."/></c:redirect>
    </c:if>
    <c:catch var="eTx">
    <sql:transaction dataSource="${ds}">
        <sql:update>UPDATE trabajo_grado SET titulo = ?, resumen = ?, id_linea = ?, id_programa = ?, modalidad = ?, fecha_limite_entrega = NULLIF(?, '')
            WHERE id_trabajo = ?
            <sql:param value="${fn:trim(param.titulo)}"/><sql:param value="${param.resumen}"/><sql:param value="${param.id_linea}"/>
            <sql:param value="${param.id_programa}"/><sql:param value="${param.modalidad}"/><sql:param value="${fecha}"/><sql:param value="${t.id_trabajo}"/></sql:update>
        <c:if test="${t.titulo != fn:trim(param.titulo)}">
            <sql:update>INSERT INTO historico_trabajo_grado (id_trabajo, campo_modificado, valor_anterior, valor_nuevo, modificado_por) VALUES (?, 'titulo', ?, ?, ?)
                <sql:param value="${t.id_trabajo}"/><sql:param value="${t.titulo}"/><sql:param value="${fn:trim(param.titulo)}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
        </c:if>
        <c:if test="${t.modalidad != param.modalidad}">
            <sql:update>INSERT INTO historico_trabajo_grado (id_trabajo, campo_modificado, valor_anterior, valor_nuevo, modificado_por) VALUES (?, 'modalidad', ?, ?, ?)
                <sql:param value="${t.id_trabajo}"/><sql:param value="${t.modalidad}"/><sql:param value="${param.modalidad}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
        </c:if>
        <c:if test="${fn:trim(t.fecha_limite_entrega) != fecha}">
            <sql:update>INSERT INTO historico_trabajo_grado (id_trabajo, campo_modificado, valor_anterior, valor_nuevo, modificado_por) VALUES (?, 'fecha_limite_entrega', ?, ?, ?)
                <sql:param value="${t.id_trabajo}"/><sql:param value="${t.fecha_limite_entrega}"/><sql:param value="${fecha}"/><sql:param value="${sessionScope.idUsuario}"/></sql:update>
        </c:if>
    </sql:transaction>
    </c:catch>
    <c:redirect url="/admin/trabajos.jsp"><c:param name="ok" value="${empty eTx ? 'Trabajo actualizado.' : 'No se pudo guardar (revise la fecha).'}"/></c:redirect>
</c:otherwise>
</c:choose>
