<%--
    banco_ideas.jsp - Banco de ideas PUBLICO con buscador global tipo comodin.
    Una sola caja busca a la vez por ID, titulo, palabras clave, area/linea
    o nombre del docente (proponente o director sugerido).
--%>
<c:set var="tituloPagina" value="Banco de ideas"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/pagina.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<c:set var="q" value="${empty param.q ? '' : fn:trim(param.q)}"/>
<c:set var="linea" value="${empty param.linea ? '' : param.linea}"/>

<sql:query var="rsLineas" dataSource="${ds}">
    SELECT id_linea, nombre FROM linea_investigacion ORDER BY nombre
</sql:query>

<sql:query var="rsTotal" dataSource="${ds}">
    SELECT COUNT(*) AS n
    FROM banco_idea i
    JOIN linea_investigacion l ON l.id_linea = i.id_linea
    JOIN usuario p ON p.id_usuario = i.propuesto_por
    LEFT JOIN usuario d ON d.id_usuario = i.director_sugerido
    WHERE i.estado = 'DISPONIBLE'
      AND (? = '' OR i.id_idea = ?
           OR CONCAT_WS(' ', i.titulo, i.palabras_clave, l.nombre, p.nombres, p.apellidos, d.nombres, d.apellidos)
              LIKE CONCAT('%', ?, '%'))
      AND (? = '' OR i.id_linea = ?)
    <sql:param value="${q}"/><sql:param value="${q}"/><sql:param value="${q}"/>
    <sql:param value="${linea}"/><sql:param value="${linea}"/>
</sql:query>
<c:set var="total" value="${rsTotal.rows[0].n}"/>

<sql:query var="rsIdeas" dataSource="${ds}">
    SELECT i.id_idea, i.titulo, i.descripcion, i.objetivos, i.palabras_clave, i.periodo_academico, i.nivel,
           l.nombre AS linea, CONCAT(p.nombres, ' ', p.apellidos) AS proponente, i.origen,
           CONCAT(d.nombres, ' ', d.apellidos) AS director
    FROM banco_idea i
    JOIN linea_investigacion l ON l.id_linea = i.id_linea
    JOIN usuario p ON p.id_usuario = i.propuesto_por
    LEFT JOIN usuario d ON d.id_usuario = i.director_sugerido
    WHERE i.estado = 'DISPONIBLE'
      AND (? = '' OR i.id_idea = ?
           OR CONCAT_WS(' ', i.titulo, i.palabras_clave, l.nombre, p.nombres, p.apellidos, d.nombres, d.apellidos)
              LIKE CONCAT('%', ?, '%'))
      AND (? = '' OR i.id_linea = ?)
    ORDER BY i.id_idea DESC
    LIMIT ?, ?
    <sql:param value="${q}"/><sql:param value="${q}"/><sql:param value="${q}"/>
    <sql:param value="${linea}"/><sql:param value="${linea}"/>
    <sql:param value="${desde}"/><sql:param value="${porPagina}"/>
</sql:query>

<h3 class="mb-3"><i class="bi bi-lightbulb"></i> Banco de ideas</h3>
<form class="row g-2 mb-3" method="get">
  <div class="col-md-6"><input class="form-control" name="q" value="<c:out value='${q}'/>"
       placeholder="ID, t&iacute;tulo, palabra clave, &aacute;rea o docente"></div>
  <div class="col-md-4">
    <select class="form-select" name="linea">
      <option value="">Todas las l&iacute;neas</option>
      <c:forEach var="l" items="${rsLineas.rows}">
        <option value="${l.id_linea}" ${linea == l.id_linea ? 'selected' : ''}><c:out value="${l.nombre}"/></option>
      </c:forEach>
    </select>
  </div>
  <div class="col-md-2 d-grid"><button class="btn btn-primary"><i class="bi bi-search"></i> Buscar</button></div>
</form>
<p class="text-muted small">${total} idea(s) disponible(s).</p>

<div class="row g-3">
  <c:forEach var="i" items="${rsIdeas.rows}">
    <div class="col-md-6">
      <div class="card card-idea h-100 shadow-sm"><div class="card-body">
        <div class="d-flex justify-content-between">
          <span class="badge text-bg-secondary"><c:out value="${i.linea}"/></span>
          <small class="text-muted">#${i.id_idea} &middot; <c:out value="${i.periodo_academico}"/> &middot; <c:out value="${i.nivel}"/></small>
        </div>
        <h5 class="mt-2"><c:out value="${i.titulo}"/></h5>
        <p class="small"><c:out value="${i.descripcion}"/></p>
        <p class="small mb-1"><b>Objetivos:</b> <c:out value="${i.objetivos}"/></p>
        <p class="small text-muted mb-1"><i class="bi bi-tags"></i> <c:out value="${i.palabras_clave}"/></p>
        <p class="small text-muted mb-2"><i class="bi bi-person"></i> Propuesta por <c:out value="${i.proponente}"/>
          <c:if test="${not empty i.director}"> &middot; Director sugerido: <c:out value="${i.director}"/></c:if></p>
        <c:if test="${esEstudiante}">
          <a class="btn btn-sm btn-warning" href="${ctx}/estudiante/inscripcion.jsp?idea=${i.id_idea}">
            <i class="bi bi-check2-circle"></i> Seleccionar esta idea</a>
        </c:if>
      </div></div>
    </div>
  </c:forEach>
</div>
<c:if test="${rsIdeas.rowCount == 0}"><div class="alert alert-info">No se encontraron ideas con ese criterio.</div></c:if>
<t:paginacion pagina="${pagina}" total="${total}" porPagina="${porPagina}"/>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
