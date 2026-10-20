<%-- idea_guardar.jsp - Guarda la idea propuesta por un docente o por el Comite. --%>
<c:set var="rolRequerido" value="DOCENTE,COMITE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>

<c:if test="${empty fn:trim(param.titulo) or empty fn:trim(param.descripcion)}">
    <c:redirect url="/idea_nueva.jsp"><c:param name="err" value="Título y descripción son obligatorios."/></c:redirect>
</c:if>
<c:set var="esComiteS" value="${fn:contains(sessionScope.roles, 'COMITE')}"/>
<sql:update var="n" dataSource="${ds}">
    INSERT INTO banco_idea (titulo, descripcion, objetivos, id_linea, propuesto_por, origen, director_sugerido,
                            palabras_clave, periodo_academico, nivel, estado)
    VALUES (?, ?, ?, ?, ?, ?, NULLIF(?, ''), ?, ?, ?, ?)
    <sql:param value="${fn:trim(param.titulo)}"/><sql:param value="${fn:trim(param.descripcion)}"/>
    <sql:param value="${param.objetivos}"/><sql:param value="${param.id_linea}"/>
    <sql:param value="${sessionScope.idUsuario}"/>
    <sql:param value="${esComiteS ? 'COMITE' : 'DOCENTE'}"/>
    <sql:param value="${param.director}"/>
    <sql:param value="${param.palabras_clave}"/><sql:param value="${param.periodo}"/><sql:param value="${param.nivel}"/>
    <sql:param value="${esComiteS ? 'DISPONIBLE' : 'PENDIENTE'}"/>
</sql:update>
<c:redirect url="/index.jsp"><c:param name="ok" value="${esComiteS ? 'Idea publicada en el banco.' : 'Idea enviada. El Comité la revisará.'}"/></c:redirect>
