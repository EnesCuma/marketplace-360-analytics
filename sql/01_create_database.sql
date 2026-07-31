IF DB_ID(N'Marketplace360') IS NULL
BEGIN
    CREATE DATABASE Marketplace360;
END;
GO

USE Marketplace360;
GO

SELECT DB_NAME() AS current_database;