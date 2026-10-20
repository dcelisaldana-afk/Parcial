<%--
    landing.jsp - Pagina publica de bienvenida: buscador rapido del banco de
    ideas, cifras del sistema y las ideas disponibles mas recientes.
--%>
<c:set var="tituloPagina" value="Inicio"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<sql:query var="rsCifras" dataSource="${ds}">
    SELECT (SELECT COUNT(*) FROM trabajo_grado WHERE estado = 'ACTIVO')   AS activos,
           (SELECT COUNT(*) FROM trabajo_grado WHERE estado = 'CERRADO')  AS cerrados,
           (SELECT COUNT(*) FROM banco_idea    WHERE estado = 'DISPONIBLE') AS ideas
</sql:query>
<c:set var="cifras" value="${rsCifras.rows[0]}"/>

<sql:query var="rsIdeas" dataSource="${ds}">
    SELECT i.id_idea, i.titulo, i.palabras_clave, l.nombre AS linea
    FROM banco_idea i JOIN linea_investigacion l ON l.id_linea = i.id_linea
    WHERE i.estado = 'DISPONIBLE'
    ORDER BY i.id_idea DESC LIMIT 6
</sql:query>

<div class="hero p-5 mb-4 shadow-sm">
  <h1 class="display-6 fw-bold">Seguimiento de trabajos de grado</h1>
  <p class="lead mb-4">Registre su idea, pague sus derechos de grado y siga cada una de las 6 fases hasta el cierre, en un solo lugar.</p>
  <form class="row g-2" action="${ctx}/banco_ideas.jsp" method="get">
    <div class="col-md-8"><input class="form-control form-control-lg" name="q" placeholder="Buscar ideas por t&iacute;tulo, palabra clave, l&iacute;nea o docente"></div>
    <div class="col-md-4 d-grid"><button class="btn btn-warning btn-lg"><i class="bi bi-search"></i> Buscar en el banco</button></div>
  </form>
</div>

<div class="row text-center mb-4">
  <div class="col-md-4"><div class="card shadow-sm"><div class="card-body">
    <div class="display-6 text-primary"><c:out value="${cifras.ideas}"/></div>Ideas disponibles</div></div></div>
  <div class="col-md-4"><div class="card shadow-sm"><div class="card-body">
    <div class="display-6 text-warning"><c:out value="${cifras.activos}"/></div>Trabajos en curso</div></div></div>
  <div class="col-md-4"><div class="card shadow-sm"><div class="card-body">
    <div class="display-6 text-success"><c:out value="${cifras.cerrados}"/></div>Trabajos cerrados</div></div></div>
</div>

<h4 class="mb-3">Ideas disponibles recientes</h4>
<div class="row g-3">
  <c:forEach var="i" items="${rsIdeas.rows}">
    <div class="col-md-4">
      <div class="card card-idea h-100 shadow-sm"><div class="card-body">
        <span class="badge text-bg-secondary mb-2"><c:out value="${i.linea}"/></span>
        <h6 class="card-title"><c:out value="${i.titulo}"/></h6>
        <p class="small text-muted mb-0"><i class="bi bi-tags"></i> <c:out value="${i.palabras_clave}"/></p>
      </div></div>
    </div>
  </c:forEach>
  <c:if test="${rsIdeas.rowCount == 0}"><p class="text-muted">A&uacute;n no hay ideas disponibles.</p></c:if>
</div>
<div class="text-center mt-4"><a class="btn btn-outline-primary" href="${ctx}/banco_ideas.jsp">Ver todo el banco de ideas</a></div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
