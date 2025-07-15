SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
PRINT N'Altering [Logistics].[Flight]'
GO
ALTER TABLE [Logistics].[Flight] DROP
COLUMN [PlaneLocation]
GO
PRINT N'Altering [Operation].[Employees]'
GO
ALTER TABLE [Operation].[Employees] DROP
COLUMN [EmployeeBenefitCode]
GO
PRINT N'Refreshing [Logistics].[FlightMaintenanceStatus]'
GO
EXEC sp_refreshview N'[Logistics].[FlightMaintenanceStatus]'
GO

SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS, NOCOUNT ON
GO
SET DATEFORMAT YMD
GO
SET XACT_ABORT ON
GO

PRINT(N'Delete 11 rows from [Sales].[Customers]')
DELETE FROM [Sales].[Customers] WHERE [CustomerID] = N'CENTC'
DELETE FROM [Sales].[Customers] WHERE [CustomerID] = N'CHOPS'
DELETE FROM [Sales].[Customers] WHERE [CustomerID] = N'ERNSH'
DELETE FROM [Sales].[Customers] WHERE [CustomerID] = N'HANAR'
DELETE FROM [Sales].[Customers] WHERE [CustomerID] = N'HILAA'
DELETE FROM [Sales].[Customers] WHERE [CustomerID] = N'RICSU'
DELETE FROM [Sales].[Customers] WHERE [CustomerID] = N'SUPRD'
DELETE FROM [Sales].[Customers] WHERE [CustomerID] = N'TOMSP'
DELETE FROM [Sales].[Customers] WHERE [CustomerID] = N'VICTE'
DELETE FROM [Sales].[Customers] WHERE [CustomerID] = N'VINET'
DELETE FROM [Sales].[Customers] WHERE [CustomerID] = N'WELLI'

