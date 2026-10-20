# pruebas/ — verificación automática (NO es parte de la aplicación)

La aplicación web usa **solo JSP + JSTL**. Esta carpeta contiene herramientas en Python que
sirvieron para revisar el código sin necesidad de levantar Tomcat ni MySQL. No hace falta
copiarla a Tomcat; puede borrarla sin afectar la aplicación.

| Archivo | Qué hace |
|---|---|
| `jstl_emu.py` | Intérprete mínimo de JSP/JSTL/EL: ejecuta las páginas reales de `web/` contra SQLite. |
| `sqlite_mysql.py` | Convierte `sql/01_base_datos_trabajos_grado.sql` a SQLite y simula las funciones de MySQL usadas (`SHA2`, `DATE_ADD`, `DATEDIFF`, `CONCAT_WS`, `LAST_INSERT_ID`…). |
| `lint.py` | Revisa todas las páginas: etiquetas balanceadas, atributos válidos, sintaxis EL, que cada `?` tenga su `<sql:param>` y que no haya scriptlets Java. |
| `scenarios.py` | Recorre el flujo completo (inscripción → 6 fases → cierre, prórrogas, bloqueo por intentos, permisos por rol, CRUD de administración) y comprueba ~170 resultados. |

Uso (Python 3.9+, sin instalar nada):

```
python3 pruebas/lint.py
python3 pruebas/scenarios.py
```

**Límite honesto:** el emulador valida la lógica de las páginas y las consultas, pero SQLite no es
MySQL ni el emulador es Tomcat. La prueba definitiva es desplegar en Tomcat con MySQL (ver README principal).
