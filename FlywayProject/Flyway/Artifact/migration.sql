SET NUMERIC_ROUNDABORT OFF
GO
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
PRINT N'Dropping foreign keys from [Logistics].[EmployeeTerritories]'
GO
ALTER TABLE [Logistics].[EmployeeTerritories] DROP CONSTRAINT [FK_EmployeeTerritories_Employees]
GO
ALTER TABLE [Logistics].[EmployeeTerritories] DROP CONSTRAINT [FK_EmployeeTerritories_Territories]
GO
PRINT N'Dropping constraints from [Logistics].[EmployeeTerritories]'
GO
ALTER TABLE [Logistics].[EmployeeTerritories] DROP CONSTRAINT [PK_EmployeeTerritories]
GO
PRINT N'Rebuilding [Logistics].[EmployeeTerritories]'
GO
CREATE TABLE [Logistics].[RG_Recovery_1_EmployeeTerritories]
(
[EmployeeID] [int] NOT NULL,
[TerritoryID] [nvarchar] (20) NOT NULL,
[Test] [nvarchar] (20) NOT NULL
)
GO
INSERT INTO [Logistics].[RG_Recovery_1_EmployeeTerritories]([EmployeeID], [TerritoryID]) SELECT [EmployeeID], [TerritoryID] FROM [Logistics].[EmployeeTerritories]
GO
DROP TABLE [Logistics].[EmployeeTerritories]
GO
EXEC sp_rename N'[Logistics].[RG_Recovery_1_EmployeeTerritories]', N'EmployeeTerritories', N'OBJECT'
GO
PRINT N'Creating primary key [PK_EmployeeTerritories] on [Logistics].[EmployeeTerritories]'
GO
ALTER TABLE [Logistics].[EmployeeTerritories] ADD CONSTRAINT [PK_EmployeeTerritories] PRIMARY KEY NONCLUSTERED ([EmployeeID], [TerritoryID])
GO
PRINT N'Adding foreign keys to [Logistics].[EmployeeTerritories]'
GO
ALTER TABLE [Logistics].[EmployeeTerritories] ADD CONSTRAINT [FK_EmployeeTerritories_Employees] FOREIGN KEY ([EmployeeID]) REFERENCES [Operation].[Employees] ([EmployeeID])
GO
ALTER TABLE [Logistics].[EmployeeTerritories] ADD CONSTRAINT [FK_EmployeeTerritories_Territories] FOREIGN KEY ([TerritoryID]) REFERENCES [Sales].[Territories] ([TerritoryID])
GO
PRINT N'Disabling constraints on [Logistics].[EmployeeTerritories]'
GO
ALTER TABLE [Logistics].[EmployeeTerritories] NOCHECK CONSTRAINT [FK_EmployeeTerritories_Employees]
GO
ALTER TABLE [Logistics].[EmployeeTerritories] NOCHECK CONSTRAINT [FK_EmployeeTerritories_Territories]
GO

