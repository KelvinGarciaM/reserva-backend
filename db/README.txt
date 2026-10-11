BACKEND SQL EXTRAIDO DEL SCRIPT MAESTRO

Esta carpeta contiene definiciones extraídas por lote GO del archivo ScriptV2_COMPLETO (1).sql. El cuerpo de cada objeto se conserva del script maestro; se agrega USE reservasdbV2 y GO cuando hace falta para que los archivos sean ejecutables individualmente.

Estructura: schema/tables, views, procedures, functions, triggers, indexes, audit/tables, audit/indexes y security.

IMPORTANTE: este paquete NO incluye la sección inicial que elimina y recrea reservasdbV2. No ejecutar sobre una base con datos que se quieran conservar. Crear o seleccionar la base de datos y sus tablas antes de ejecutar vistas, funciones, procedimientos, triggers e índices. La sección security se conserva como bloque del original y debe ejecutarse con privilegios adecuados; revise contraseñas de ejemplo antes de usarla.

Comparación de cobertura con el script maestro: se incluyen todos los lotes de creación de vistas, procedimientos, funciones, triggers, tablas e índices detectados, más la sección original de seguridad. Los INSERT de datos de ejemplo y el bloque destructivo de creación de base de datos no forman parte de este paquete modular.

La carpeta version_anterior_function_zip conserva los archivos del ZIP anterior sin reorganizarlos ni modificarlos. Consulte INFORME_COMPARACION.txt para ver las 11 definiciones que difieren entre las dos fuentes.
