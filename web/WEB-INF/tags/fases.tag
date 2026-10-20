<%@ tag body-content="empty" pageEncoding="UTF-8" description="Barra de avance por las 6 fases del trabajo de grado" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ attribute name="actual" required="true" description="Numero de la fase actual (1 a 6)" %>
<%@ attribute name="estado" required="false" description="ACTIVO, CERRADO o CANCELADO" %>
<div class="barra-fases d-flex flex-wrap gap-2 my-3">
  <c:forTokens items="Idea y pago,Anteproyecto,Evaluación del anteproyecto,Informe de trabajo de grado,Evaluación del trabajo de grado,Cierre final"
               delims="," var="nombreFase" varStatus="s">
    <c:choose>
      <c:when test="${estado == 'CERRADO' or s.count < actual}"><c:set var="clase" value="paso-hecho"/></c:when>
      <c:when test="${s.count == actual}"><c:set var="clase" value="paso-actual"/></c:when>
      <c:otherwise><c:set var="clase" value="paso-pendiente"/></c:otherwise>
    </c:choose>
    <div class="paso ${clase}"><span class="num">${s.count}</span> <c:out value="${nombreFase}"/></div>
  </c:forTokens>
</div>
