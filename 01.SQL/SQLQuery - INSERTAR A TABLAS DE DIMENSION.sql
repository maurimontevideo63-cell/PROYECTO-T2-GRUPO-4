
USE DM_FIJA_2025;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Cargar_Modelo_Estrella
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        ;WITH Datos AS
        (
            SELECT
                NULLIF(LTRIM(RTRIM(SOT)), '') AS SOT,
                NULLIF(LTRIM(RTRIM(DNI)), '') AS DNI,
                Fecha_Nacimiento,
                NULLIF(LTRIM(RTRIM(Sexo)), '') AS Sexo,

                COALESCE(
                    NULLIF(LTRIM(RTRIM(Asesor)), ''),
                    'NO ESPECIFICADO'
                ) AS Nombre_Asesor,

                COALESCE(
                    NULLIF(LTRIM(RTRIM(Nombre_Plan)), ''),
                    NULLIF(LTRIM(RTRIM(Paquete)), ''),
                    NULLIF(LTRIM(RTRIM(Internet)), ''),
                    'PLAN NO ESPECIFICADO'
                ) AS Nombre_Plan,

                COALESCE(
                    NULLIF(LTRIM(RTRIM(Tipo_Servicio)), ''),
                    'NO ESPECIFICADO'
                ) AS Tipo_Servicio,

                COALESCE(
                    NULLIF(LTRIM(RTRIM(Zona_Plano)), ''),
                    'NO ESPECIFICADO'
                ) AS Zona,

                COALESCE(
                    NULLIF(LTRIM(RTRIM(Distrito)), ''),
                    'NO ESPECIFICADO'
                ) AS Distrito,

                COALESCE(
                    NULLIF(LTRIM(RTRIM(Provincia)), ''),
                    'NO ESPECIFICADO'
                ) AS Provincia,

                COALESCE(
                    NULLIF(LTRIM(RTRIM(Departamento)), ''),
                    'NO ESPECIFICADO'
                ) AS Departamento,

                COALESCE(
                    NULLIF(LTRIM(RTRIM(Nodo)), ''),
                    'NO ESPECIFICADO'
                ) AS Tipo_Tecnologia,

                Fecha_Ingreso AS Fecha_Pedido,

                COALESCE(
                    NULLIF(LTRIM(RTRIM(Estado)), ''),
                    'SIN ESTADO'
                ) AS Estado,

                NULLIF(LTRIM(RTRIM(Sub_Estado)), '')
                    AS Sub_Estado,

                ROW_NUMBER() OVER (
                    PARTITION BY NULLIF(LTRIM(RTRIM(SOT)), '')
                    ORDER BY Fecha_Ingreso DESC
                ) AS Numero_Fila

            FROM dbo.STG_PEDIDOS
            WHERE NULLIF(LTRIM(RTRIM(SOT)), '') IS NOT NULL
              AND Fecha_Ingreso IS NOT NULL
        )
        SELECT
            SOT,
            DNI,
            Fecha_Nacimiento,
            Sexo,
            Nombre_Asesor,
            Nombre_Plan,
            Tipo_Servicio,
            Zona,
            Distrito,
            Provincia,
            Departamento,
            Tipo_Tecnologia,
            Fecha_Pedido,
            Estado,
            Sub_Estado
        INTO #PEDIDOS_VALIDOS
        FROM Datos
        WHERE Numero_Fila = 1;
        ;WITH Clientes AS
        (
            SELECT *,
                ROW_NUMBER() OVER (
                    PARTITION BY DNI
                    ORDER BY Fecha_Pedido DESC
                ) AS Numero_Fila
            FROM #PEDIDOS_VALIDOS
            WHERE DNI IS NOT NULL
        )
        SELECT
            DNI,

            CASE
                WHEN Fecha_Nacimiento IS NULL
                  OR Fecha_Nacimiento > Fecha_Pedido
                    THEN NULL
                ELSE
                    DATEDIFF(
                        YEAR,
                        Fecha_Nacimiento,
                        Fecha_Pedido
                    )
                    -
                    CASE
                        WHEN DATEADD(
                            YEAR,
                            DATEDIFF(
                                YEAR,
                                Fecha_Nacimiento,
                                Fecha_Pedido
                            ),
                            Fecha_Nacimiento
                        ) > Fecha_Pedido
                        THEN 1
                        ELSE 0
                    END
            END AS Edad,

            Sexo
        INTO #CLIENTES
        FROM Clientes
        WHERE Numero_Fila = 1;
        DECLARE @CLIENTES_NUEVOS TABLE
        (
            DNI VARCHAR(15),
            Cliente_Key INT
        );

        MERGE dbo.DIM_CLIENTE AS DESTINO
        USING
        (
            SELECT C.DNI, C.Edad, C.Sexo
            FROM #CLIENTES AS C
            WHERE NOT EXISTS
            (
                SELECT 1
                FROM dbo.ETL_CLIENTE_MAP AS M
                WHERE M.DNI = C.DNI
            )
        ) AS ORIGEN
        ON 1 = 0

        WHEN NOT MATCHED THEN
            INSERT (Edad, Sexo)
            VALUES (ORIGEN.Edad, ORIGEN.Sexo)

        OUTPUT ORIGEN.DNI, inserted.Cliente_Key
        INTO @CLIENTES_NUEVOS (DNI, Cliente_Key);

        INSERT INTO dbo.ETL_CLIENTE_MAP
            (DNI, Cliente_Key)
        SELECT DNI, Cliente_Key
        FROM @CLIENTES_NUEVOS;
        UPDATE C
        SET
            C.Edad = COALESCE(N.Edad, C.Edad),
            C.Sexo = COALESCE(N.Sexo, C.Sexo)
        FROM dbo.DIM_CLIENTE AS C
        INNER JOIN dbo.ETL_CLIENTE_MAP AS M
            ON C.Cliente_Key = M.Cliente_Key
        INNER JOIN #CLIENTES AS N
            ON M.DNI = N.DNI;

        INSERT INTO dbo.DIM_ASESOR (Nombre_Asesor)
        SELECT DISTINCT P.Nombre_Asesor
        FROM #PEDIDOS_VALIDOS AS P
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.DIM_ASESOR AS A
            WHERE A.Nombre_Asesor = P.Nombre_Asesor
        );
        INSERT INTO dbo.DIM_PLAN
            (Nombre_Plan, Tipo_Servicio)
        SELECT DISTINCT
            P.Nombre_Plan,
            P.Tipo_Servicio
        FROM #PEDIDOS_VALIDOS AS P
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.DIM_PLAN AS D
            WHERE D.Nombre_Plan = P.Nombre_Plan
              AND D.Tipo_Servicio = P.Tipo_Servicio
        );

        INSERT INTO dbo.DIM_ZONA
        (
            Zona, Distrito, Provincia, Departamento
        )
        SELECT DISTINCT
            P.Zona,
            P.Distrito,
            P.Provincia,
            P.Departamento
        FROM #PEDIDOS_VALIDOS AS P
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.DIM_ZONA AS Z
            WHERE Z.Zona = P.Zona
              AND Z.Distrito = P.Distrito
              AND Z.Provincia = P.Provincia
              AND Z.Departamento = P.Departamento
        );

        INSERT INTO dbo.DIM_TECNOLOGIA (Tipo_Tecnologia)
        SELECT DISTINCT P.Tipo_Tecnologia
        FROM #PEDIDOS_VALIDOS AS P
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.DIM_TECNOLOGIA AS T
            WHERE T.Tipo_Tecnologia = P.Tipo_Tecnologia
        );

        DECLARE @Inicio DATE, @Fin DATE;

        SELECT
            @Inicio = MIN(Fecha_Pedido),
            @Fin = MAX(Fecha_Pedido)
        FROM #PEDIDOS_VALIDOS;

        WHILE @Inicio <= @Fin
        BEGIN
            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.DIM_FECHA
                WHERE Fecha = @Inicio
            )
            BEGIN
                INSERT INTO dbo.DIM_FECHA
                (
                    Fecha_Key, Fecha, Dia, Mes,
                    Nombre_Mes, Trimestre, Año
                )
                VALUES
                (
                    CONVERT(INT, CONVERT(CHAR(8), @Inicio, 112)),
                    @Inicio,
                    DAY(@Inicio),
                    MONTH(@Inicio),

                    CASE MONTH(@Inicio)
                        WHEN 1 THEN 'Enero'
                        WHEN 2 THEN 'Febrero'
                        WHEN 3 THEN 'Marzo'
                        WHEN 4 THEN 'Abril'
                        WHEN 5 THEN 'Mayo'
                        WHEN 6 THEN 'Junio'
                        WHEN 7 THEN 'Julio'
                        WHEN 8 THEN 'Agosto'
                        WHEN 9 THEN 'Septiembre'
                        WHEN 10 THEN 'Octubre'
                        WHEN 11 THEN 'Noviembre'
                        WHEN 12 THEN 'Diciembre'
                    END,

                    DATEPART(QUARTER, @Inicio),
                    YEAR(@Inicio)
                );
            END;

            SET @Inicio = DATEADD(DAY, 1, @Inicio);
        END;
        UPDATE F
        SET
            F.Cliente_Key = M.Cliente_Key,
            F.Asesor_Key = A.Asesor_Key,
            F.Plan_Key = P.Plan_Key,
            F.Zona_Key = Z.Zona_Key,
            F.Tecnologia_Key = T.Tecnologia_Key,
            F.Fecha_Key = FE.Fecha_Key,
            F.Estado = B.Estado,
            F.Sub_Estado = B.Sub_Estado,

            F.Cantidad_Pedido = 1,

            F.Cantidad_Instalacion =
                CASE
                    WHEN UPPER(LTRIM(RTRIM(B.Estado))) = 'ATENDIDA'
                    THEN 1 ELSE 0
                END,

            F.Cantidad_Perdido =
                CASE
                    WHEN UPPER(LTRIM(RTRIM(B.Estado))) = 'PERDIDO'
                    THEN 1 ELSE 0
                END

        FROM dbo.FACT_PEDIDO AS F

        INNER JOIN dbo.ETL_PEDIDO_CARGADO AS E
            ON F.Pedido_Key = E.Pedido_Key

        INNER JOIN #PEDIDOS_VALIDOS AS B
            ON E.SOT = B.SOT

        LEFT JOIN dbo.ETL_CLIENTE_MAP AS M
            ON B.DNI = M.DNI

        INNER JOIN dbo.DIM_ASESOR AS A
            ON B.Nombre_Asesor = A.Nombre_Asesor

        INNER JOIN dbo.DIM_PLAN AS P
            ON B.Nombre_Plan = P.Nombre_Plan
           AND B.Tipo_Servicio = P.Tipo_Servicio

        INNER JOIN dbo.DIM_ZONA AS Z
            ON B.Zona = Z.Zona
           AND B.Distrito = Z.Distrito
           AND B.Provincia = Z.Provincia
           AND B.Departamento = Z.Departamento

        INNER JOIN dbo.DIM_TECNOLOGIA AS T
            ON B.Tipo_Tecnologia = T.Tipo_Tecnologia

        INNER JOIN dbo.DIM_FECHA AS FE
            ON B.Fecha_Pedido = FE.Fecha;

        DECLARE @PEDIDOS_NUEVOS TABLE
        (
            SOT VARCHAR(30),
            Pedido_Key INT
        );

        MERGE dbo.FACT_PEDIDO AS DESTINO
        USING
        (
            SELECT
                B.SOT,
                M.Cliente_Key,
                A.Asesor_Key,
                P.Plan_Key,
                Z.Zona_Key,
                T.Tecnologia_Key,
                FE.Fecha_Key,
                B.Estado,
                B.Sub_Estado

            FROM #PEDIDOS_VALIDOS AS B

            LEFT JOIN dbo.ETL_CLIENTE_MAP AS M
                ON B.DNI = M.DNI

            INNER JOIN dbo.DIM_ASESOR AS A
                ON B.Nombre_Asesor = A.Nombre_Asesor

            INNER JOIN dbo.DIM_PLAN AS P
                ON B.Nombre_Plan = P.Nombre_Plan
               AND B.Tipo_Servicio = P.Tipo_Servicio

            INNER JOIN dbo.DIM_ZONA AS Z
                ON B.Zona = Z.Zona
               AND B.Distrito = Z.Distrito
               AND B.Provincia = Z.Provincia
               AND B.Departamento = Z.Departamento

            INNER JOIN dbo.DIM_TECNOLOGIA AS T
                ON B.Tipo_Tecnologia = T.Tipo_Tecnologia

            INNER JOIN dbo.DIM_FECHA AS FE
                ON B.Fecha_Pedido = FE.Fecha

            WHERE NOT EXISTS
            (
                SELECT 1
                FROM dbo.ETL_PEDIDO_CARGADO AS E
                WHERE E.SOT = B.SOT
            )
        ) AS ORIGEN

        ON 1 = 0

        WHEN NOT MATCHED THEN
            INSERT
            (
                Cliente_Key, Asesor_Key, Plan_Key,
                Zona_Key, Tecnologia_Key, Fecha_Key,
                Estado, Sub_Estado,
                Cantidad_Pedido, Cantidad_Instalacion,
                Cantidad_Perdido
            )
            VALUES
            (
                ORIGEN.Cliente_Key,
                ORIGEN.Asesor_Key,
                ORIGEN.Plan_Key,
                ORIGEN.Zona_Key,
                ORIGEN.Tecnologia_Key,
                ORIGEN.Fecha_Key,
                ORIGEN.Estado,
                ORIGEN.Sub_Estado,
                1,

                CASE
                    WHEN UPPER(LTRIM(RTRIM(ORIGEN.Estado))) = 'ATENDIDA'
                    THEN 1 ELSE 0
                END,

                CASE
                    WHEN UPPER(LTRIM(RTRIM(ORIGEN.Estado))) = 'PERDIDO'
                    THEN 1 ELSE 0
                END
            )

        OUTPUT ORIGEN.SOT, inserted.Pedido_Key
        INTO @PEDIDOS_NUEVOS (SOT, Pedido_Key);

        INSERT INTO dbo.ETL_PEDIDO_CARGADO
            (SOT, Pedido_Key)
        SELECT SOT, Pedido_Key
        FROM @PEDIDOS_NUEVOS;

        COMMIT TRANSACTION;

        SELECT
            (SELECT COUNT(*) FROM #PEDIDOS_VALIDOS)
                AS Pedidos_Validos,

            (SELECT COUNT(*) FROM @CLIENTES_NUEVOS)
                AS Clientes_Nuevos,

            (SELECT COUNT(*) FROM @PEDIDOS_NUEVOS)
                AS Pedidos_Nuevos_Cargados;

        SELECT
            COUNT(*) AS Registros_Sin_SOT_O_Fecha
        FROM dbo.STG_PEDIDOS
        WHERE NULLIF(LTRIM(RTRIM(SOT)), '') IS NULL
           OR Fecha_Ingreso IS NULL;

    END TRY
    BEGIN CATCH

        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
GO

