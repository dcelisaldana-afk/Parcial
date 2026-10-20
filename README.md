# TrabajosGradoWeb — Sistema para la gestión y seguimiento de los trabajos de grado de la UTS

Proyecto de **Programación Java (JSP)** — Unidades Tecnológicas de Santander.
Aplicación web hecha **solo con JSP + JSTL** (sin Servlets, sin Filters y sin scriptlets Java),
sobre **MySQL**, que lleva cada trabajo de grado por **6 fases** con roles diferenciados.

> **Regla del curso:** nada de código Java dentro de las páginas. `web.xml` lo hace cumplir con
> `<scripting-invalid>true</scripting-invalid>`: si alguien escribe un scriptlet, Tomcat se niega a compilar la página.

## 1. Qué hace

| Rol | Qué puede hacer |
|---|---|
| **Visitante** | Ver la landing y el **banco de ideas** (buscador global por ID, título, palabras clave, área o docente). |
| **Estudiante** | Inscribir su trabajo (idea del banco o propia, hasta 2 estudiantes, **un recibo de pago por estudiante**, todo por **URL**), registrar el anteproyecto (Fase 2), consultar el estado y solicitar prórrogas. Solo un trabajo activo a la vez. |
| **Docente** | Según el trabajo es **Director** (concepto del anteproyecto, registro del informe) o **Evaluador** (concepto en 5 días hábiles). Ve todas las fases de sus trabajos y solo actúa en las que le corresponden. Puede proponer ideas. |
| **Comité** | Verifica pagos, aprueba la inscripción asignando director y evaluador (distintos), cierra las fases de evaluación, aprueba prórrogas, hace el **cierre final** y consulta reportes. |
| **Administrador** | CRUD de usuarios y roles (borrado lógico), edición/cancelación lógica de trabajos con **histórico**, catálogos y parámetros del sistema. |

### Las 6 fases (dos roles por fase, salvo la última)

| Fase | Quién actúa | Qué pasa |
|---|---|---|
| 1. Idea y pago | Estudiante + Comité | Inscripción con URL de recibo(s) de pago; el Comité verifica y asigna Director y Evaluador. |
| 2. Anteproyecto | Estudiante + Director | El estudiante registra la URL del FD-124; el Director lo aprueba, aplaza o rechaza. Al aprobar corre el plazo de **180 días**. |
| 3. Evaluación del anteproyecto | Evaluador + Comité | El Evaluador responde (si no aprueba, el trabajo **regresa a la Fase 2**); el Comité cierra la fase. |
| 4. Informe | Director + Evaluador | Solo después de **90 días** de aprobado el anteproyecto el Director registra el informe (FD-125) con su concepto. |
| 5. Evaluación del trabajo | Evaluador + Comité | Concepto del Evaluador (si no aprueba, **regresa a la Fase 4**) y aprobación del Comité. |
| 6. Cierre final | Solo Comité | Cierre definitivo (la sustentación y la biblioteca se gestionan fuera del software). |

Reglas de negocio implementadas en el servidor: máximo 2 estudiantes por trabajo; un trabajo activo por estudiante;
director ≠ evaluador (`UNIQUE(id_trabajo, id_usuario_docente)`); plazo de 180 días; **máximo 2 prórrogas** (cada una suma 90 días, exige su propio pago y solo se pide
cuando faltan ≤ 30 días); bloqueo de cuenta tras **3 intentos fallidos**; contraseñas con **SHA-256 + sal** por usuario calculado en SQL; todos los documentos son **URLs** (no se suben archivos).

## 2. Estructura

```
TrabajosGradoWeb/
├── sql/01_base_datos_trabajos_grado.sql   <- 18 tablas (3FN) + datos de prueba + 5 consultas de reporte
├── web/                                   <- raiz publicable en Tomcat
│   ├── index.jsp, landing.jsp, banco_ideas.jsp, login.jsp, acceso.jsp, logout.jsp, acceso_denegado.jsp
│   ├── trabajo.jsp                        <- detalle del trabajo (compartido por todos los roles)
│   ├── calendario.jsp, formatos.jsp, cuenta.jsp, idea_nueva.jsp (+ *_accion / *_guardar)
│   ├── estudiante/  panel, inscripcion, prorroga (+ controladores)
│   ├── docente/     panel, revisiones, evaluar_accion
│   ├── comite/      panel, ideas, prorrogas, reportes, accion
│   ├── admin/       usuarios, usuario_form, trabajos, trabajo_editar, catalogos (+ controladores)
│   ├── css/estilos.css, js/validaciones.js
│   └── WEB-INF/
│       ├── web.xml                        <- Tomcat 9 (javax). Sin servlets ni filtros.
│       ├── web_tomcat10-11.xml.txt        <- alternativa Tomcat 10/11 (jakarta)
│       ├── jspf/   taglibs (prologo automatico), conexion, seguridad, cabecera, pie, pagina, dias_evaluador
│       ├── tags/   badge.tag, fases.tag, paginacion.tag   (etiquetas propias, tambien sin Java)
│       └── lib/    <- aqui van 3 .jar (se descargan con el script)
├── descargar_librerias.sh / .bat          <- bajan los .jar de Maven Central
├── pruebas/                               <- verificacion automatica (opcional, ver pruebas/README.md)
└── docs/                                  <- informe en PDF
```

## 3. Paso a paso (XAMPP + Tomcat 9)

**Requisitos:** JDK 11+, XAMPP (MySQL), Apache Tomcat 9.0.x.

1. **Base de datos.** Inicie MySQL, abra `http://localhost/phpmyadmin` → pestaña *SQL* → pegue y ejecute todo
   `sql/01_base_datos_trabajos_grado.sql`. Debe quedar la base `trabajos_grado_uts` con **18 tablas**.
2. **Librerías.** En la raíz del proyecto ejecute `descargar_librerias.bat` (Windows) o `./descargar_librerias.sh` (Mac/Linux).
   Deja en `web/WEB-INF/lib/`: `taglibs-standard-spec-1.2.5.jar`, `taglibs-standard-impl-1.2.5.jar` y `mysql-connector-j-8.3.0.jar`.
   (Los .jar no se suben a GitHub; por eso existe el script.)
3. **Conexión.** `web/WEB-INF/jspf/conexion.jspf` viene para XAMPP (`root`, sin clave, puerto 3306). Cambie `user`/`password`/`url` solo si su MySQL es distinto.
4. **Desplegar.** Copie el **contenido** de la carpeta `web/` en `TOMCAT_HOME/webapps/TrabajosGradoWeb/`
   (que `login.jsp` quede en `webapps/TrabajosGradoWeb/login.jsp`, **sin** una subcarpeta `web`). Inicie Tomcat.
5. **Probar.** Abra `http://localhost:8080/TrabajosGradoWeb/`.

### Usuarios de prueba (clave `1234`)

| Correo | Rol |
|---|---|
| admin@uts.edu.co | Administrador |
| comite@uts.edu.co | Comité |
| ana.rojas@uts.edu.co, carlos.mendez@uts.edu.co, laura.gomez@uts.edu.co, julian.jaimes@uts.edu.co, pedro.sanchez@uts.edu.co | Docentes |
| estudiante1@uts.edu.co … estudiante10@uts.edu.co | Estudiantes |

Los datos de prueba dejan trabajos en cada fase (1 a 6 y uno cerrado), una prórroga pendiente y un estudiante libre (`estudiante9`/`estudiante10`) para probar la inscripción en pareja.
Recorrido sugerido: `estudiante9` inscribe con `estudiante10` → `comite` verifica pagos y asigna docentes → `estudiante9` registra el anteproyecto →
`ana.rojas` (si fue designada director) lo aprueba → el evaluador responde → `comite` avanza de fase.

### Tomcat 10/11 (Jakarta)

Cambia el espacio de nombres: use `web/WEB-INF/web_tomcat10-11.xml.txt` como `web.xml`, `taglibs_tomcat10-11.jspf.txt` como `jspf/taglibs.jspf`,
ejecute `./descargar_librerias.sh tomcat10` y cambie en los 3 archivos `.tag` las URIs `http://java.sun.com/jsp/jstl/core` → `jakarta.tags.core` y `.../fmt` → `jakarta.tags.fmt`.

## 4. Cómo se cumple "solo JSTL"

* Conexión con `<sql:setDataSource>` guardada en el ámbito de aplicación; consultas con `<sql:query>`, `<sql:update>`, `<sql:transaction>` y `<sql:param>` (siempre con parámetros, nunca concatenando texto → sin inyección SQL).
* Control de acceso en `seguridad.jspf` (sesión + rol) incluido en cada página privada y **revalidado en cada controlador** y a nivel de registro (un estudiante solo ve sus trabajos, un docente solo los suyos).
* El patrón *Post-Redirect-Get* se hace con `<c:redirect>`; los errores de llaves duplicadas se capturan con `<c:catch>`.
* Cerrar sesión borra las variables de sesión con `<c:remove>` (JSTL no puede invalidar la sesión; el tiempo de vida es de 30 min).
* Prólogo automático de taglibs con `<include-prelude>` y etiquetas propias en `WEB-INF/tags` (sin clases Java).

## 5. Verificación realizada (y sus límites)

La carpeta `pruebas/` ejecuta las páginas reales con un intérprete de JSTL contra SQLite: **47 archivos sin errores de lint y 172 comprobaciones del flujo completo, todas en verde**
(inscripción en pareja, 6 fases, regresos de fase, 90 días, prórrogas y tope, bloqueo de cuenta, permisos por rol, CRUD de administración).
**No se probó contra un Tomcat ni un MySQL reales** (el entorno de desarrollo no tenía acceso a internet para descargarlos), por eso la prueba definitiva es el paso a paso de la sección 3.
Si Tomcat o MySQL reportan algún error, revise `TOMCAT_HOME/logs/catalina.*.log` y avísenos con el mensaje.

## 6. Subir a GitHub

```bash
cd TrabajosGradoWeb
git init            # si aun no es un repositorio
git add .
git commit -m "Sistema de trabajos de grado UTS"
git branch -M main
git remote add origin https://github.com/<usuario>/<repositorio>.git
git push -u origin main
```

El `.gitignore` excluye los `.jar` (se descargan con el script), archivos de IDE y temporales.
