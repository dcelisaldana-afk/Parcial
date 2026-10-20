#!/usr/bin/env bash
# descargar_librerias.sh - Descarga las 3 librerias que necesita la aplicacion
# (JSTL spec + impl para Tomcat 9, y el driver de MySQL) en web/WEB-INF/lib.
# Uso:  ./descargar_librerias.sh            (Tomcat 9, por defecto)
#       ./descargar_librerias.sh tomcat10   (Tomcat 10/11: JSTL 3.0 de Jakarta)
set -e
DESTINO="$(cd "$(dirname "$0")" && pwd)/web/WEB-INF/lib"
MAVEN="https://repo1.maven.org/maven2"
mkdir -p "$DESTINO"

bajar() {
  local url="$1" nombre
  nombre="$(basename "$url")"
  if [ -f "$DESTINO/$nombre" ]; then echo "  ya existe: $nombre"; return; fi
  echo "  descargando $nombre ..."
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$url" -o "$DESTINO/$nombre"
  elif command -v wget >/dev/null 2>&1; then wget -q "$url" -O "$DESTINO/$nombre"
  else echo "Necesita curl o wget"; exit 1; fi
}

echo "Descargando librerias en $DESTINO"
if [ "$1" = "tomcat10" ]; then
  bajar "$MAVEN/jakarta/servlet/jsp/jstl/jakarta.servlet.jsp.jstl-api/3.0.0/jakarta.servlet.jsp.jstl-api-3.0.0.jar"
  bajar "$MAVEN/org/glassfish/web/jakarta.servlet.jsp.jstl/3.0.1/jakarta.servlet.jsp.jstl-3.0.1.jar"
else
  bajar "$MAVEN/org/apache/taglibs/taglibs-standard-spec/1.2.5/taglibs-standard-spec-1.2.5.jar"
  bajar "$MAVEN/org/apache/taglibs/taglibs-standard-impl/1.2.5/taglibs-standard-impl-1.2.5.jar"
fi
bajar "$MAVEN/com/mysql/mysql-connector-j/8.3.0/mysql-connector-j-8.3.0.jar"
echo "Listo. Contenido de WEB-INF/lib:"; ls -1 "$DESTINO"/*.jar
