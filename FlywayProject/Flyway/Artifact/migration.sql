SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
PRINT N'Altering [Logistics].[EmployeeTerritories]'
GO
ALTER TABLE [Logistics].[EmployeeTerritories] DROP
COLUMN [Test]
GO
PRINT N'Altering [Operation].[Products]'
GO
ALTER TABLE [Operation].[Products] DROP
COLUMN [NickHape]
GO
PRINT N'Altering [Logistics].[Region]'
GO
ALTER TABLE [Logistics].[Region] DROP
COLUMN [FlywayPlugin]
GO
PRINT N'Refreshing [Sales].[Order Details Extended]'
GO
EXEC sp_refreshview N'[Sales].[Order Details Extended]'
GO
PRINT N'Refreshing [Sales].[Sales by Category]'
GO
EXEC sp_refreshview N'[Sales].[Sales by Category]'
GO
PRINT N'Creating [dbo].[PlugNPlay]'
GO
CREATE TABLE [dbo].[PlugNPlay]
(
[FirstTest] [int] NULL
)
GO

