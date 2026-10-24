# DATA MART: DM_FIJA_2025

## Proyecto 2R -- Teleservicios Contact Center

### 1. Descripción del proyecto

El presente proyecto implementa un **Data Mart orientado al análisis de
la efectividad de las instalaciones de Internet Hogar**. Su finalidad es
integrar, transformar y organizar los registros de pedidos para
facilitar el análisis de indicadores relacionados con las instalaciones
efectivas, los pedidos perdidos, los planes comerciales, los asesores,
las zonas geográficas y las características de los clientes.

La solución utiliza las siguientes tecnologías:

-   **SQL Server:** almacenamiento de datos, creación del modelo
    dimensional y ejecución de procedimientos almacenados.
-   **SQL Server Integration Services (SSIS):** extracción,
    transformación y carga de los datos mediante un proceso ETL.
-   **Power BI:** elaboración de dashboards e indicadores para el
    análisis de resultados.

### 2. Estructura del repositorio

El repositorio está organizado de la siguiente manera:

-   **`01.SQL/`**: scripts SQL para la creación de tablas y carga de
    dimensiones, diagramas e imágenes de referencia.
-   **`02_SSIS_ETL/`**: proyecto SSIS comprimido, evidencias del proceso
    ETL y referencia a la extensión necesaria.
-   **`03_Datos/`**: archivo Excel que contiene los registros de pedidos
    de Internet Hogar utilizados como fuente de datos.
-   **`04_PowerBI/`**: informe de Power BI comprimido y otros informes
    relacionados.
-   **`README.md`**: instrucciones para configurar y ejecutar el
    proyecto.

### 3. Requisitos previos

Antes de ejecutar el proyecto, se recomienda disponer de:

-   Microsoft SQL Server.
-   SQL Server Management Studio (SSMS).
-   Visual Studio con la extensión de SQL Server Integration Services
    (SSIS) compatible con el proyecto.
-   Microsoft Power BI Desktop.
-   El archivo Excel fuente incluido en el repositorio.

### 4. Paso 1: Descargar el proyecto

1.  Ingresar al repositorio de GitHub.
2.  Seleccionar **Code → Download ZIP** para descargar el repositorio
    completo.
3.  Extraer el archivo ZIP en una carpeta local.
4.  Verificar que se encuentren disponibles las carpetas `01.SQL`,
    `02_SSIS_ETL`, `03_Datos` y `04_PowerBI`.

### 5. Paso 2: Crear y configurar el Data Mart en SQL Server

1.  Abrir SQL Server Management Studio (SSMS).
2.  Conectarse a la instancia de SQL Server que se utilizará para el
    proyecto.
3.  Ingresar a la carpeta `01.SQL/`.
4.  Abrir y ejecutar `SQLQuery - CREACION DE TABLAS.sql` para crear las
    estructuras necesarias del Data Mart.
5.  Abrir y revisar `SQLQuery - INSERTAR A TABLAS DE DIMENSION.sql`.
6.  Ejecutar el script de creación del procedimiento almacenado de
    carga, si se encuentra en un archivo independiente.
7.  Verificar que existan la tabla de staging (`STG_PEDIDOS`), las
    dimensiones (`DIM_CLIENTE`, `DIM_ASESOR`, `DIM_PLAN`, `DIM_ZONA`,
    `DIM_TECNOLOGIA` y `DIM_FECHA`), la tabla de hechos (`FACT_PEDIDO`)
    y las tablas auxiliares que utilice el ETL.
8.  Confirmar que la base de datos y las conexiones estén configuradas
    correctamente.

**Importante:** el nombre de la base de datos utilizado en este
documento es `DM_FIJA_2025`. Si la instancia o la configuración local
utilizan otro nombre, debe ajustarse en los scripts y conexiones
correspondientes.

### 6. Paso 3: Configurar y ejecutar el proceso ETL en SSIS

1.  Ingresar a `02_SSIS_ETL/`.
2.  Extraer el archivo `BI_2RTELESERVICIOST2.zip`.
3.  Abrir la solución o el proyecto SSIS desde Visual Studio.
4.  Verificar que esté instalada la extensión de Integration Services
    compatible con el proyecto.
5.  Revisar las conexiones del paquete y configurarlas para que apunten
    a la instancia y base de datos correctas.
6.  Verificar que la ruta del archivo fuente corresponda a
    `03_Datos/BASE_PRINCIPAL_FIJA_2025 .xlsx`.

#### Flujo de control

El paquete ejecuta las siguientes tareas en orden:

1.  **Limpiar Stagging:** limpia la tabla de staging antes de una nueva
    carga.
2.  **CARGAR EXCEL A STAGGING:** importa los registros del archivo Excel
    hacia SQL Server.
3.  **Cargar modelo estrella:** ejecuta el procedimiento almacenado que
    distribuye los datos hacia las dimensiones y la tabla de hechos del
    Data Mart.

#### Flujo de datos: CARGAR EXCEL A STAGGING

-   **Origen:** archivo Excel, hoja o rango `CONSOLIDADO PEDIDOS`.
-   **Destino:** tabla de staging de SQL Server.

7.  Ejecutar el paquete SSIS.
8.  Verificar que las tareas finalicen correctamente.
9.  Abrir SSMS y comprobar que las tablas de staging, dimensiones y
    hechos contengan los registros esperados.

**Nota:** el paquete limpia y vuelve a cargar datos según su
configuración. Antes de ejecutarlo nuevamente, comprobar que ese
comportamiento sea el esperado.

### 7. Paso 4: Abrir y actualizar el informe de Power BI

1.  Ingresar a `04_PowerBI/`.
2.  Extraer `DASHBOARDT2.pbix.zip` para obtener el archivo `.pbix`.
3.  Abrir el archivo `.pbix` mediante Power BI Desktop.
4.  Revisar la conexión a SQL Server y comprobar que apunte a la
    instancia y base de datos donde se cargó el Data Mart.
5.  Si la conexión no coincide, actualizar la configuración del origen
    de datos o los parámetros correspondientes en Power Query.
6.  Configurar las credenciales de acceso si Power BI las solicita.
7.  Aplicar los cambios y seleccionar **Actualizar**.
8.  Comprobar que los indicadores, gráficos y filtros muestren los datos
    correctamente.

### 8. Verificación final

Antes de finalizar, comprobar que:

-   Las tablas del Data Mart se crearon correctamente.
-   Los registros del archivo Excel se cargaron en staging.
-   El procedimiento almacenado finalizó sin errores.
-   Las dimensiones y la tabla de hechos contienen información.
-   Las relaciones del modelo de Power BI son correctas.
-   Los indicadores del dashboard coinciden con los resultados obtenidos
    en SQL Server.

### 9. Resultado esperado

Al completar los pasos, se contará con el **Data Mart DM_FIJA_2025**
configurado en SQL Server, el proceso ETL implementado mediante SSIS y
el dashboard de Power BI conectado al modelo dimensional.

Esta solución permitirá analizar la efectividad de las instalaciones de
Internet Hogar mediante indicadores de pedidos, instalaciones efectivas,
pedidos perdidos, planes, asesores, zonas, tecnologías y características
de los clientes.
