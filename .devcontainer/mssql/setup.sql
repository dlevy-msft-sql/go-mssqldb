-- go-mssqldb Development Database Setup
-- This script runs automatically when the devcontainer starts

USE master;
GO

-- Create a test database for development
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'GoDriverTest')
BEGIN
    CREATE DATABASE GoDriverTest;
    PRINT 'Created database: GoDriverTest';
END
GO

-- Enable contained database authentication for testing
EXEC sp_configure 'contained database authentication', 1;
RECONFIGURE;
GO

-- Make GoDriverTest a contained database for testing
ALTER DATABASE GoDriverTest SET CONTAINMENT = PARTIAL;
GO

USE GoDriverTest;
GO

-- Create a sample table for quick testing
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TestTable')
BEGIN
    CREATE TABLE TestTable (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Value NVARCHAR(MAX),
        CreatedAt DATETIME2 DEFAULT GETUTCDATE()
    );
    
    INSERT INTO TestTable (Name, Value) VALUES 
        ('Test1', 'Sample value 1'),
        ('Test2', 'Sample value 2');
    
    PRINT 'Created table: TestTable with sample data';
END
GO

PRINT 'go-mssqldb development database setup complete!';
GO
