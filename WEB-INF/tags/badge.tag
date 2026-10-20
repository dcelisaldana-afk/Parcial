<%@ tag body-content="empty" pageEncoding="UTF-8" description="Etiqueta de color segun un estado" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ attribute name="valor" required="false" description="Texto del estado" %>
<c:choose>
  <c:when test="${valor == 'APROBADO' or valor == 'APROBADA' or valor == 'VERIFICADO' or valor == 'DISPONIBLE' or valor == 'ACTIVO' or valor == 'CERRADO'}"><c:set var="color" value="success"/></c:when>
  <c:when test="${valor == 'PENDIENTE' or valor == 'ASIGNADA'}"><c:set var="color" value="warning"/></c:when>
  <c:when test="${valor == 'APLAZADO' or valor == 'APLAZADA'}"><c:set var="color" value="info"/></c:when>
  <c:when test="${valor == 'RECHAZADO' or valor == 'RECHAZADA' or valor == 'BLOQUEADO'}"><c:set var="color" value="danger"/></c:when>
  <c:otherwise><c:set var="color" value="secondary"/></c:otherwise>
</c:choose>
<span class="badge text-bg-${color}"><c:out value="${valor}"/></span>
