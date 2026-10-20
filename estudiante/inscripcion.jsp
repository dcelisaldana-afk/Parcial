<%--
    estudiante/inscripcion.jsp - FASE 1. Inscribe el trabajo: idea del banco
    o idea propia, hasta 2 estudiantes y un recibo de pago (URL) POR estudiante.
    La segunda casilla de pago aparece solo cuando se escribe el correo del
    segundo estudiante (validaciones.js).
--%>
<c:set var="tituloPagina" value="Inscribir trabajo de grado"/>
<c:set var="rolRequerido" value="ESTUDIANTE"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>

<sql:query var="rsActivo" dataSource="${ds}">
    SELECT COUNT(*) AS n
    FROM trabajo_grado t JOIN trabajo_grado_estudiante e ON e.id_trabajo = t.id_trabajo
    WHERE e.id_usuario_estudiante = ? AND t.estado = 'ACTIVO'
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:if test="${rsActivo.rows[0].n > 0}">
    <c:redirect url="/estudiante/panel.jsp"><c:param name="err" value="Ya tiene un trabajo de grado activo: solo se permite uno a la vez."/></c:redirect>
</c:if>

<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<sql:query var="rsIdeas" dataSource="${ds}">
    SELECT id_idea, titulo FROM banco_idea WHERE estado = 'DISPONIBLE' ORDER BY titulo
</sql:query>
<sql:query var="rsLineas" dataSource="${ds}">SELECT id_linea, nombre FROM linea_investigacion ORDER BY nombre</sql:query>
<sql:query var="rsProg" dataSource="${ds}">SELECT id_programa, nombre FROM programa_academico ORDER BY nombre</sql:query>
<sql:query var="rsValor" dataSource="${ds}">
    SELECT valor FROM parametro_sistema WHERE clave = 'valor_derechos_grado'
</sql:query>

<h3 class="mb-3"><i class="bi bi-pencil-square"></i> Inscribir trabajo de grado</h3>
<div class="alert alert-secondary small">
  Derechos de grado por estudiante: <b>$<fmt:formatNumber value="${rsValor.rows[0].valor}" pattern="#,##0"/></b>.
  Pegue la <b>URL del recibo de pago</b> (no la URL del anteproyecto ni del informe). Cada estudiante paga y registra su propio recibo.
</div>

<form action="${ctx}/estudiante/inscripcion_accion.jsp" method="post" class="card card-body shadow-sm">
  <h5>1. Idea</h5>
  <div class="mb-3">
    <div class="form-check form-check-inline">
      <input class="form-check-input" type="radio" name="modo_idea" id="m1" value="banco" ${empty param.idea and param.modo_idea == 'propia' ? '' : 'checked'}>
      <label class="form-check-label" for="m1">Idea del banco</label></div>
    <div class="form-check form-check-inline">
      <input class="form-check-input" type="radio" name="modo_idea" id="m2" value="propia" ${empty param.idea and param.modo_idea == 'propia' ? 'checked' : ''}>
      <label class="form-check-label" for="m2">Idea propia (la aprueba el Comit&eacute;)</label></div>
  </div>

  <div id="bloque-banco" class="mb-3">
    <label class="form-label">Seleccione la idea</label>
    <select class="form-select" name="id_idea">
      <option value="">-- Elija --</option>
      <c:forEach var="i" items="${rsIdeas.rows}">
        <option value="${i.id_idea}" ${param.idea == i.id_idea ? 'selected' : ''}>#${i.id_idea} &middot; <c:out value="${i.titulo}"/></option>
      </c:forEach>
    </select>
  </div>

  <div id="bloque-propia" class="d-none">
    <div class="mb-2"><label class="form-label">T&iacute;tulo</label><input class="form-control" name="titulo" maxlength="200"></div>
    <div class="mb-2"><label class="form-label">Descripci&oacute;n</label><textarea class="form-control" name="descripcion" rows="3"></textarea></div>
    <div class="mb-2"><label class="form-label">Objetivos</label><textarea class="form-control" name="objetivos" rows="2"></textarea></div>
    <div class="row">
      <div class="col-md-6 mb-2"><label class="form-label">Palabras clave</label><input class="form-control" name="palabras_clave" maxlength="200"></div>
      <div class="col-md-3 mb-2"><label class="form-label">Per&iacute;odo</label><input class="form-control" name="periodo" value="2026-2" maxlength="10"></div>
      <div class="col-md-3 mb-2"><label class="form-label">Nivel</label>
        <select class="form-select" name="nivel"><option>Tecnolog&iacute;a</option><option>Profesional</option></select></div>
    </div>
    <div class="mb-2"><label class="form-label">L&iacute;nea de investigaci&oacute;n</label>
      <select class="form-select" name="id_linea">
        <c:forEach var="l" items="${rsLineas.rows}"><option value="${l.id_linea}"><c:out value="${l.nombre}"/></option></c:forEach>
      </select></div>
  </div>

  <h5 class="mt-3">2. Trabajo</h5>
  <div class="row">
    <div class="col-md-6 mb-2"><label class="form-label">Programa acad&eacute;mico</label>
      <select class="form-select" name="id_programa" required>
        <c:forEach var="p" items="${rsProg.rows}"><option value="${p.id_programa}"><c:out value="${p.nombre}"/></option></c:forEach>
      </select></div>
    <div class="col-md-6 mb-2"><label class="form-label">Modalidad</label>
      <select class="form-select" name="modalidad" required>
        <option value="DESARROLLO_SOFTWARE">Desarrollo de software</option>
        <option value="INVESTIGACION">Investigaci&oacute;n</option>
        <option value="MONOGRAFIA">Monograf&iacute;a</option>
      </select></div>
  </div>

  <h5 class="mt-3">3. Pago de derechos de grado (URL del recibo)</h5>
  <div class="mb-2"><label class="form-label">Su recibo de pago</label>
    <input type="url" class="form-control" name="pago1" data-url required placeholder="https://..."></div>
  <div class="mb-2"><label class="form-label">Correo del segundo estudiante (opcional, m&aacute;x. 2)</label>
    <input type="email" class="form-control" name="correo2" id="correo2" placeholder="estudiante2@uts.edu.co"></div>
  <div id="caja-pago2" class="mb-2 d-none"><label class="form-label">Recibo de pago del segundo estudiante</label>
    <input type="url" class="form-control" name="pago2" id="pago2" data-url placeholder="https://..."></div>

  <div class="mt-3"><button class="btn btn-primary">Inscribir</button>
    <a class="btn btn-outline-secondary" href="${ctx}/estudiante/panel.jsp">Cancelar</a></div>
</form>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
