<%@ tag body-content="empty" pageEncoding="UTF-8" description="Paginacion que conserva los filtros de la URL" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ attribute name="pagina" required="true" description="Pagina actual (desde 1)" %>
<%@ attribute name="total" required="true" description="Total de filas" %>
<%@ attribute name="porPagina" required="true" description="Filas por pagina" %>
<%-- "div" siempre devuelve decimal (1.9); parseNumber integerOnly lo trunca a entero (1).
     parseLocale en_US: con es_CO el punto decimal se leeria como separador de miles. --%>
<fmt:parseNumber var="paginas" integerOnly="true" parseLocale="en_US" value="${(total + porPagina - 1) div porPagina}"/>
<c:if test="${paginas > 1}">
  <nav><ul class="pagination pagination-sm justify-content-center">
    <c:forEach var="i" begin="1" end="${paginas}">
      <c:url var="enlace" value="${pageContext.request.servletPath}">
        <c:forEach var="p" items="${param}">
          <c:if test="${p.key ne 'pagina' and p.key ne 'ok' and p.key ne 'err'}"><c:param name="${p.key}" value="${p.value}"/></c:if>
        </c:forEach>
        <c:param name="pagina" value="${i}"/>
      </c:url>
      <li class="page-item ${i == pagina ? 'active' : ''}"><a class="page-link" href="${enlace}">${i}</a></li>
    </c:forEach>
  </ul></nav>
</c:if>
