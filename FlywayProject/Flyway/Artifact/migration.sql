SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
PRINT N'Dropping [dbo].[tom]'
GO
DROP TABLE [dbo].[tom]
GO
PRINT N'Dropping [dbo].[quickTest]'
GO
DROP TABLE [dbo].[quickTest]
GO
PRINT N'Dropping [dbo].[plugindemo]'
GO
DROP TABLE [dbo].[plugindemo]
GO
PRINT N'Dropping [dbo].[peterlaws]'
GO
DROP TABLE [dbo].[peterlaws]
GO
PRINT N'Dropping [dbo].[newTable]'
GO
DROP TABLE [dbo].[newTable]
GO
PRINT N'Dropping [dbo].[imogen]'
GO
DROP TABLE [dbo].[imogen]
GO
PRINT N'Dropping [dbo].[huxtest]'
GO
DROP TABLE [dbo].[huxtest]
GO
PRINT N'Dropping [dbo].[elijah]'
GO
DROP TABLE [dbo].[elijah]
GO
PRINT N'Dropping [dbo].[elijah3]'
GO
DROP TABLE [dbo].[elijah3]
GO
PRINT N'Dropping [dbo].[elijah2]'
GO
DROP TABLE [dbo].[elijah2]
GO
PRINT N'Dropping [dbo].[demoplug]'
GO
DROP TABLE [dbo].[demoplug]
GO
PRINT N'Dropping [dbo].[alexYates]'
GO
DROP TABLE [dbo].[alexYates]
GO
PRINT N'Dropping [dbo].[PlugNPlay]'
GO
DROP TABLE [dbo].[PlugNPlay]
GO
PRINT N'Dropping [dbo].[FlightTimings]'
GO
DROP TABLE [dbo].[FlightTimings]
GO
PRINT N'Dropping [dbo].[BeccaTest]'
GO
DROP TABLE [dbo].[BeccaTest]
GO
PRINT N'Dropping [Sales].[Sales by Year]'
GO
DROP PROCEDURE [Sales].[Sales by Year]
GO
PRINT N'Altering [Operation].[Products]'
GO
ALTER TABLE [Operation].[Products] DROP
COLUMN [Twitter]
GO
PRINT N'Creating [Sales].[Sales by Years]'
GO

CREATE PROCEDURE [Sales].[Sales by Years] @Beginning_Date DATETIME, @Ending_Date DATETIME
AS
SELECT Orders.ShippedDate, Orders.OrderID, "Order Subtotals".Subtotal, DATENAME(yy, ShippedDate) AS Year
FROM Orders
     INNER JOIN "Order Subtotals" ON Orders.OrderID="Order Subtotals".OrderID
WHERE Orders.ShippedDate BETWEEN @Beginning_Date AND @Ending_Date;
GO
PRINT N'Refreshing [Sales].[Order Details Extended]'
GO
EXEC sp_refreshview N'[Sales].[Order Details Extended]'
GO
PRINT N'Refreshing [Sales].[Sales by Category]'
GO
EXEC sp_refreshview N'[Sales].[Sales by Category]'
GO

SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS, NOCOUNT ON
GO
SET DATEFORMAT YMD
GO
SET XACT_ABORT ON
GO

