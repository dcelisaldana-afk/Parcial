@echo off
REM descargar_librerias.bat - Descarga las librerias en web\WEB-INF\lib (Windows 10/11, usa curl incluido).
REM Uso:  descargar_librerias.bat            (Tomcat 9)
REM       descargar_librerias.bat tomcat10   (Tomcat 10/11)
setlocal
set DESTINO=%~dp0web\WEB-INF\lib
set MAVEN=https://repo1.maven.org/maven2
if not exist "%DESTINO%" mkdir "%DESTINO%"
echo Descargando librerias en %DESTINO%
if /I "%1"=="tomcat10" (
  curl -fsSL -o "%DESTINO%\jakarta.servlet.jsp.jstl-api-3.0.0.jar" "%MAVEN%/jakarta/servlet/jsp/jstl/jakarta.servlet.jsp.jstl-api/3.0.0/jakarta.servlet.jsp.jstl-api-3.0.0.jar"
  curl -fsSL -o "%DESTINO%\jakarta.servlet.jsp.jstl-3.0.1.jar" "%MAVEN%/org/glassfish/web/jakarta.servlet.jsp.jstl/3.0.1/jakarta.servlet.jsp.jstl-3.0.1.jar"
) else (
  curl -fsSL -o "%DESTINO%\taglibs-standard-spec-1.2.5.jar" "%MAVEN%/org/apache/taglibs/taglibs-standard-spec/1.2.5/taglibs-standard-spec-1.2.5.jar"
  curl -fsSL -o "%DESTINO%\taglibs-standard-impl-1.2.5.jar" "%MAVEN%/org/apache/taglibs/taglibs-standard-impl/1.2.5/taglibs-standard-impl-1.2.5.jar"
)
curl -fsSL -o "%DESTINO%\mysql-connector-j-8.3.0.jar" "%MAVEN%/com/mysql/mysql-connector-j/8.3.0/mysql-connector-j-8.3.0.jar"
if errorlevel 1 (echo ERROR: no se pudo descargar. Revise su conexion a Internet. & exit /b 1)
echo Listo.
dir /b "%DESTINO%\*.jar"
endlocal
