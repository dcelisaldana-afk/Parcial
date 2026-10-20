<%--
    comite/reportes.jsp - Las 5 consultas de reporte (2 INNER JOIN de 3+ tablas,
    1 N:M, 1 LEFT JOIN y 1 GROUP BY + HAVING). Visible para Comite y Administrador.
    Cada consulta esta comentada tambien en sql/01_base_datos_trabajos_grado.sql.
--%>
<c:set var="tituloPagina" value="Reportes"/>
<c:set var="rolRequerido" value="COMITE,ADMINISTRADOR"/>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<%-- 1. INNER JOIN de 4 tablas: trabajos activos con programa, linea y fase --%>
<sql:query var="rs1" dataSource="${ds}">
    SELECT t.id_trabajo, t.titulo, p.nombre AS programa, l.nombre AS linea, f.nombre AS fase
    FROM trabajo_grado t
    INNER JOIN programa_academico p ON p.id_programa = t.id_programa
    INNER JOIN linea_investigacion l ON l.id_linea = t.id_linea
    INNER JOIN fase f ON f.id_fase = t.fase_actual
    WHERE t.estado = 'ACTIVO'
    ORDER BY t.fase_actual, t.id_trabajo
</sql:query>
<%-- 2. INNER JOIN de 4 tablas: carga de cada docente (rol por trabajo) --%>
<sql:query var="rs2" dataSource="${ds}">
    SELECT CONCAT(u.nombres, ' ', u.apellidos) AS docente, rd.tipo_rol, t.id_trabajo, t.titulo, f.orden AS fase
    FROM rol_docente rd
    INNER JOIN usuario u ON u.id_usuario = rd.id_usuario_docente
    INNER JOIN trabajo_grado t ON t.id_trabajo = rd.id_trabajo
    INNER JOIN fase f ON f.id_fase = t.fase_actual
    WHERE rd.activo = 1 AND t.estado = 'ACTIVO'
    ORDER BY u.apellidos, rd.tipo_rol
</sql:query>
<%-- 3. N:M: estudiantes y trabajos a traves de trabajo_grado_estudiante --%>
<sql:query var="rs3" dataSource="${ds}">
    SELECT CONCAT(u.nombres, ' ', u.apellidos) AS estudiante, u.correo, t.id_trabajo, t.titulo, t.estado
    FROM trabajo_grado_estudiante e
    INNER JOIN usuario u ON u.id_usuario = e.id_usuario_estudiante
    INNER JOIN trabajo_grado t ON t.id_trabajo = e.id_trabajo
    ORDER BY t.id_trabajo, u.apellidos
</sql:query>
<%-- 4. LEFT JOIN: ideas del banco y, si existe, el trabajo que las tomo --%>
<sql:query var="rs4" dataSource="${ds}">
    SELECT i.id_idea, i.titulo, i.estado AS estado_idea, t.id_trabajo, t.estado AS estado_trabajo
    FROM banco_idea i
    LEFT JOIN trabajo_grado t ON t.id_idea = i.id_idea
    ORDER BY i.id_idea
</sql:query>
<%-- 5. GROUP BY + HAVING: programas con mas de un trabajo y su avance promedio --%>
<sql:query var="rs5" dataSource="${ds}">
    SELECT p.nombre AS programa, COUNT(*) AS trabajos, SUM(CASE WHEN t.estado = 'CERRADO' THEN 1 ELSE 0 END) AS cerrados,
           AVG(t.fase_actual) AS fase_promedio
    FROM trabajo_grado t
    INNER JOIN programa_academico p ON p.id_programa = t.id_programa
    GROUP BY p.id_programa, p.nombre
    HAVING COUNT(*) >= 1
    ORDER BY trabajos DESC
</sql:query>

<h3 class="mb-3"><i class="bi bi-bar-chart"></i> Reportes</h3>

<h5>1. Trabajos activos por programa, l&iacute;nea y fase <small class="text-muted">(INNER JOIN, 4 tablas)</small></h5>
<table class="table table-sm tabla-compacta"><thead><tr><th>#</th><th>T&iacute;tulo</th><th>Programa</th><th>L&iacute;nea</th><th>Fase</th></tr></thead><tbody>
<c:forEach var="r" items="${rs1.rows}"><tr><td>${r.id_trabajo}</td><td><c:out value="${r.titulo}"/></td><td><c:out value="${r.programa}"/></td><td><c:out value="${r.linea}"/></td><td><c:out value="${r.fase}"/></td></tr></c:forEach>
</tbody></table>

<h5 class="mt-4">2. Carga de los docentes <small class="text-muted">(INNER JOIN, 4 tablas)</small></h5>
<table class="table table-sm tabla-compacta"><thead><tr><th>Docente</th><th>Rol</th><th>Trabajo</th><th>Fase</th></tr></thead><tbody>
<c:forEach var="r" items="${rs2.rows}"><tr><td><c:out value="${r.docente}"/></td><td>${r.tipo_rol}</td><td>#${r.id_trabajo} <c:out value="${r.titulo}"/></td><td>${r.fase}</td></tr></c:forEach>
</tbody></table>

<h5 class="mt-4">3. Estudiantes y sus trabajos <small class="text-muted">(relaci&oacute;n N:M)</small></h5>
<table class="table table-sm tabla-compacta"><thead><tr><th>Estudiante</th><th>Correo</th><th>Trabajo</th><th>Estado</th></tr></thead><tbody>
<c:forEach var="r" items="${rs3.rows}"><tr><td><c:out value="${r.estudiante}"/></td><td><c:out value="${r.correo}"/></td><td>#${r.id_trabajo} <c:out value="${r.titulo}"/></td><td><t:badge valor="${r.estado}"/></td></tr></c:forEach>
</tbody></table>

<h5 class="mt-4">4. Ideas del banco y su trabajo <small class="text-muted">(LEFT JOIN)</small></h5>
<table class="table table-sm tabla-compacta"><thead><tr><th>Idea</th><th>Estado de la idea</th><th>Trabajo</th></tr></thead><tbody>
<c:forEach var="r" items="${rs4.rows}"><tr><td>#${r.id_idea} <c:out value="${r.titulo}"/></td><td><t:badge valor="${r.estado_idea}"/></td>
  <td><c:choose><c:when test="${empty r.id_trabajo}"><span class="text-muted">sin trabajo</span></c:when><c:otherwise>#${r.id_trabajo} (${r.estado_trabajo})</c:otherwise></c:choose></td></tr></c:forEach>
</tbody></table>

<h5 class="mt-4">5. Trabajos por programa <small class="text-muted">(GROUP BY + HAVING)</small></h5>
<table class="table table-sm tabla-compacta"><thead><tr><th>Programa</th><th>Trabajos</th><th>Cerrados</th><th>Fase promedio</th></tr></thead><tbody>
<c:forEach var="r" items="${rs5.rows}"><tr><td><c:out value="${r.programa}"/></td><td>${r.trabajos}</td><td>${r.cerrados}</td><td><fmt:formatNumber value="${r.fase_promedio}" pattern="#,##0.0"/></td></tr></c:forEach>
</tbody></table>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
