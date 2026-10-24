
USE DM_FIJA_2025;
GO
CREATE TABLE dbo.STG_PEDIDOS (
    SOT NVARCHAR(30)  NULL,
    DNI NVARCHAR(15)  NULL,
    Fecha_Nacimiento DATE          NULL,
    Sexo NVARCHAR(255) NULL,
    Asesor NVARCHAR(255) NULL,
    Nombre_Plan NVARCHAR(255) NULL,
    Paquete NVARCHAR(255) NULL,
    Internet NVARCHAR(255) NULL,
    Tipo_Servicio NVARCHAR(255) NULL,
    Zona_Plano NVARCHAR(255) NULL,
    Distrito NVARCHAR(255) NULL,
    Provincia NVARCHAR(255) NULL,
    Departamento NVARCHAR(255) NULL,
    Nodo NVARCHAR(255) NULL,
    Fecha_Ingreso DATE NULL,
    Estado NVARCHAR(255) NULL,
    Sub_Estado NVARCHAR(500) NULL
);
GO
CREATE TABLE dbo.DIM_CLIENTE (
    Cliente_Key INT IDENTITY(1,1) PRIMARY KEY,
    Edad INT NULL,
    Sexo VARCHAR(20) NULL
);
GO

CREATE TABLE dbo.DIM_ASESOR (
    Asesor_Key INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Asesor VARCHAR(100) NOT NULL UNIQUE
);
GO

CREATE TABLE dbo.DIM_PLAN (
    Plan_Key INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Plan VARCHAR(150) NOT NULL,
    Tipo_Servicio VARCHAR(100) NOT NULL,
    CONSTRAINT UQ_DIM_PLAN
        UNIQUE (Nombre_Plan, Tipo_Servicio)
);
GO

CREATE TABLE dbo.DIM_ZONA (
    Zona_Key INT IDENTITY(1,1) PRIMARY KEY,
    Zona VARCHAR(100) NOT NULL,
    Distrito VARCHAR(100) NOT NULL,
    Provincia VARCHAR(100) NOT NULL,
    Departamento VARCHAR(100) NOT NULL,
    CONSTRAINT UQ_DIM_ZONA
        UNIQUE (Zona, Distrito, Provincia, Departamento)
);
GO

CREATE TABLE dbo.DIM_TECNOLOGIA (
    Tecnologia_Key INT IDENTITY(1,1) PRIMARY KEY,
    Tipo_Tecnologia VARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE dbo.DIM_FECHA (
    Fecha_Key INT PRIMARY KEY,
    Fecha DATE NOT NULL UNIQUE,
    Dia INT NOT NULL,
    Mes INT NOT NULL,
    Nombre_Mes VARCHAR(20) NOT NULL,
    Trimestre INT NOT NULL,
    Año INT NOT NULL
);
GO

CREATE TABLE dbo.FACT_PEDIDO (
    Pedido_Key INT IDENTITY(1,1) PRIMARY KEY,

    Cliente_Key INT NULL,
    Asesor_Key INT NOT NULL,
    Plan_Key INT NOT NULL,
    Zona_Key INT NOT NULL,
    Tecnologia_Key INT NOT NULL,
    Fecha_Key INT NOT NULL,

    Estado VARCHAR(100) NOT NULL,
    Sub_Estado VARCHAR(500) NULL,

    Cantidad_Pedido INT NOT NULL,
    Cantidad_Instalacion INT NOT NULL,
    Cantidad_Perdido INT NOT NULL,

    FOREIGN KEY (Cliente_Key)
        REFERENCES dbo.DIM_CLIENTE(Cliente_Key),

    FOREIGN KEY (Asesor_Key)
        REFERENCES dbo.DIM_ASESOR(Asesor_Key),

    FOREIGN KEY (Plan_Key)
        REFERENCES dbo.DIM_PLAN(Plan_Key),

    FOREIGN KEY (Zona_Key)
        REFERENCES dbo.DIM_ZONA(Zona_Key),

    FOREIGN KEY (Tecnologia_Key)
        REFERENCES dbo.DIM_TECNOLOGIA(Tecnologia_Key),

    FOREIGN KEY (Fecha_Key)
        REFERENCES dbo.DIM_FECHA(Fecha_Key)
);
GO

CREATE TABLE dbo.ETL_CLIENTE_MAP (
    DNI VARCHAR(15) PRIMARY KEY,
    Cliente_Key INT NOT NULL UNIQUE,

    FOREIGN KEY (Cliente_Key)
        REFERENCES dbo.DIM_CLIENTE(Cliente_Key)
);
GO

CREATE TABLE dbo.ETL_PEDIDO_CARGADO (
    SOT VARCHAR(30) PRIMARY KEY,
    Pedido_Key INT NOT NULL UNIQUE,

    FOREIGN KEY (Pedido_Key)
        REFERENCES dbo.FACT_PEDIDO(Pedido_Key)
);
