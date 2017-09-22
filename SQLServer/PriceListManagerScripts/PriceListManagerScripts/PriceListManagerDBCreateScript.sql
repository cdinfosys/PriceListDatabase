DECLARE @dbname nvarchar(128)
SET @dbname = N'PriceListManagerDB'

IF 
(
    EXISTS 
    (
        SELECT TOP 1 1
        FROM master.dbo.sysdatabases 
        WHERE ('[' + name + ']' = @dbname OR name = @dbname)
    )
)
RAISERROR ('The database already exists.', 20, 1)  WITH LOG
GO

CREATE DATABASE PriceListManagerDB;
GO


USE PriceListManagerDB;
GO

GRANT EXEC TO PUBLIC;
GO

------------------------------------------------------------------------------------------------------------------------
-- Schemas
------------------------------------------------------------------------------------------------------------------------

CREATE SCHEMA UserControl;
GO

CREATE SCHEMA Support;
GO

CREATE SCHEMA Linking;
GO

CREATE SCHEMA Suppliers;
GO

CREATE SCHEMA Locations;
GO

CREATE SCHEMA Products;
GO

CREATE SCHEMA Shared;
GO

------------------------------------------------------------------------------------------------------------------------
-- Users of the database
------------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS 
(
    SELECT TOP 1 1  
    FROM master.sys.server_principals
    WHERE name = 'CDInfoSysSecurityModule'
)
BEGIN
    CREATE LOGIN 
        [CDInfoSysSecurityModule] 
    WITH 
        PASSWORD = N'ILV0p2CxlUFJuvcwM2my', 
        DEFAULT_DATABASE=[PriceListManagerDB], 
        DEFAULT_LANGUAGE=[us_english],
        CHECK_EXPIRATION=OFF, 
        CHECK_POLICY=OFF 
END
GO

CREATE USER [CDInfoSysSecurityModuleUser] FOR LOGIN [CDInfoSysSecurityModule] WITH DEFAULT_SCHEMA=[UserControl];
EXEC sp_addrolemember 'db_datareader', 'CDInfoSysSecurityModuleUser';
EXEC sp_addrolemember 'db_datawriter', 'CDInfoSysSecurityModuleUser';
GO

IF NOT EXISTS 
(
    SELECT TOP 1 1  
    FROM master.sys.server_principals
    WHERE name = 'CDInfoSysService'
)
BEGIN
    CREATE LOGIN 
        [CDInfoSysService] 
    WITH 
        PASSWORD = N'CkAWQ0SinhyvwfFXSs3v', 
        DEFAULT_DATABASE=[PriceListManagerDB], 
        DEFAULT_LANGUAGE=[us_english],
        CHECK_EXPIRATION=OFF, 
        CHECK_POLICY=OFF 
END
GO

CREATE USER [CDInfoSysServiceUser] FOR LOGIN [CDInfoSysService] WITH DEFAULT_SCHEMA=[dbo]
EXEC sp_addrolemember 'db_datareader', 'CDInfoSysServiceUser';
EXEC sp_addrolemember 'db_datawriter', 'CDInfoSysServiceUser';
GO

------------------------------------------------------------------------------------------------------------------------
-- User defined types
------------------------------------------------------------------------------------------------------------------------

-- A table of GUIDs
CREATE TYPE [Shared].[GuidTable] AS TABLE (identifier UNIQUEIDENTIFIER);
GO

------------------------------------------------------------------------------------------------------------------------
-- Support Tables
------------------------------------------------------------------------------------------------------------------------
CREATE TABLE Support.SchemaVersion
(
    SchemaVersionID INT NOT NULL,
    LastUpdateTime DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
ALTER TABLE Support.SchemaVersion
ADD CONSTRAINT PK_Support_SchemaVersion PRIMARY KEY CLUSTERED (SchemaVersionID);
GO

CREATE TABLE Support.ExceptionCode
(
    ExceptionCodeID INT NOT NULL,
    Descr VARCHAR(256)
);
ALTER TABLE Support.ExceptionCode
ADD CONSTRAINT PK_Support_ExceptionCode PRIMARY KEY CLUSTERED (ExceptionCodeID);
GO

------------------------------------------------------------------------------------------------------------------------
-- User Control (Security)
------------------------------------------------------------------------------------------------------------------------
CREATE TABLE UserControl.SystemUser
(
    SystemUserID INT IDENTITY(1, 1) NOT NULL,
    UniqueID UNIQUEIDENTIFIER NOT NULL,
    LastUpdateTime DATETIME2 NOT NULL,
    UserName VARCHAR(100) NOT NULL,
    AdditionalData VARCHAR(256) NULL,
    EmailAddress VARCHAR(256) NOT NULL,
    ContactNumber VARCHAR(50) NOT NULL,
    AccountLocked INT NULL,
    PasswordHash VARCHAR(256) NOT NULL,
    PasswordExpiryDate DATETIME2 NULL,
    RequiresLogin INT NULL,
    UnsuccessfulLoginAttempts INT NULL,
    SessionTimeoutMinutes INT NULL,
    Deactivated INT
);

ALTER TABLE UserControl.SystemUser
ADD CONSTRAINT PK_UserControl_SystemUser PRIMARY KEY CLUSTERED (SystemUserID);  
GO 

ALTER TABLE UserControl.SystemUser
ADD CONSTRAINT UC_UserControl_SystemUser_UniqueID UNIQUE (UniqueID);
GO 

ALTER TABLE UserControl.SystemUser
ADD CONSTRAINT UC_UserControl_SystemUser_UserName UNIQUE (UserName);  
GO 

CREATE TABLE UserControl.SystemGroup 
(
    SystemGroupID INT NOT NULL,
    UniqueID UNIQUEIDENTIFIER NOT NULL,
    LastUpdateTime DATETIME2 NOT NULL,
    Code VARCHAR(50) NOT NULL,
    Descr VARCHAR(100) NOT NULL 
);

ALTER TABLE UserControl.SystemGroup
ADD CONSTRAINT PK_UserControl_SystemGroup PRIMARY KEY CLUSTERED (SystemGroupID);  
GO 

ALTER TABLE UserControl.SystemGroup
ADD CONSTRAINT UC_UserControl_SystemGroup_UniqueID UNIQUE (UniqueID);
GO 

ALTER TABLE UserControl.SystemGroup
ADD CONSTRAINT UC_UserControl_SystemGroup_Code UNIQUE (Code);  
GO 

CREATE TABLE UserControl.AccessRight
(
    AccessRightID INT NOT NULL,
    UniqueID UNIQUEIDENTIFIER NOT NULL,
    LastUpdateTime DATETIME2 NOT NULL,
    Code VARCHAR(50) NOT NULL,
    Descr VARCHAR(100) NOT NULL 
);

ALTER TABLE UserControl.AccessRight
ADD CONSTRAINT PK_UserControl_AccessRight PRIMARY KEY CLUSTERED (AccessRightID);  
GO 

ALTER TABLE UserControl.AccessRight
ADD CONSTRAINT UC_UserControl_AccessRight_UniqueID UNIQUE (UniqueID);
GO 

ALTER TABLE UserControl.AccessRight
ADD CONSTRAINT UC_UserControl_AccessRight_Code UNIQUE (Code);  
GO 

CREATE TABLE UserControl.UserSession
(
    UserSessionID INT IDENTITY(1, 1) NOT NULL,
    SystemUserID INT NOT NULL,
    SessionExpiryTime DATETIME2 NULL,
    SessionToken VARCHAR(80) NOT NULL
);

ALTER TABLE UserControl.UserSession
ADD CONSTRAINT PK_UserControl_UserSession PRIMARY KEY CLUSTERED (UserSessionID);  
GO 

ALTER TABLE UserControl.UserSession
ADD CONSTRAINT UC_UserControl_UserSession_SystemUserID UNIQUE (SystemUserID);
GO 

ALTER TABLE UserControl.UserSession
ADD CONSTRAINT FK_UserControl_UserSession_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID)
ON DELETE CASCADE;
GO

CREATE TABLE UserControl.UserGroup
(
    UserGroupID INT IDENTITY(1, 1) NOT NULL,
    LastUpdateTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL,
    SystemGroupID INT NOT NULL
)

ALTER TABLE UserControl.UserGroup
ADD CONSTRAINT PK_UserControl_UserGroup PRIMARY KEY CLUSTERED (UserGroupID);  
GO 

ALTER TABLE UserControl.UserGroup
ADD CONSTRAINT UC_UserControl_UserGroup_UserIDGroupID UNIQUE (SystemUserID, SystemGroupID);
GO 

ALTER TABLE UserControl.UserGroup
ADD CONSTRAINT FK_UserControl_UserGroup_SystemGroupID FOREIGN KEY (SystemGroupID)
REFERENCES UserControl.SystemGroup(SystemGroupID)
ON DELETE CASCADE;
GO

ALTER TABLE UserControl.UserGroup
ADD CONSTRAINT FK_UserControl_UserGroup_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID)
ON DELETE CASCADE;
GO


CREATE TABLE UserControl.UserRight
(
    UserRightID INT IDENTITY(1, 1) NOT NULL,
    LastUpdateTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL,
    AccessRightID INT NOT NULL,
    Disallow INT NULL
);

ALTER TABLE UserControl.UserRight
ADD CONSTRAINT PK_UserControl_UserRight PRIMARY KEY CLUSTERED (UserRightID);  
GO 

ALTER TABLE UserControl.UserRight
ADD CONSTRAINT UC_UserControl_UserRight_UserIDAccessID UNIQUE (SystemUserID, AccessRightID);
GO 

ALTER TABLE UserControl.UserRight
ADD CONSTRAINT FK_UserControl_UserRight_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID)
ON DELETE CASCADE;
GO

ALTER TABLE UserControl.UserRight
ADD CONSTRAINT FK_UserControl_UserRight_AccessRightID FOREIGN KEY (AccessRightID)
REFERENCES UserControl.AccessRight(AccessRightID)
ON DELETE CASCADE;
GO

CREATE TABLE UserControl.GroupRight
(
    GroupRightID INT NOT NULL,
    LastUpdateTime DATETIME2 NOT NULL,
    SystemGroupID INT NOT NULL,
    AccessRightID INT NOT NULL
)

ALTER TABLE UserControl.GroupRight
ADD CONSTRAINT PK_UserControl_GroupRight PRIMARY KEY CLUSTERED (GroupRightID);  
GO 

ALTER TABLE UserControl.GroupRight
ADD CONSTRAINT UC_UserControl_GroupRight_GroupIDAccessID UNIQUE (SystemGroupID, AccessRightID);
GO 

ALTER TABLE UserControl.GroupRight
ADD CONSTRAINT FK_UserControl_GroupRight_SystemGroupID FOREIGN KEY (SystemGroupID)
REFERENCES UserControl.SystemGroup(SystemGroupID)
ON DELETE CASCADE;
GO

ALTER TABLE UserControl.GroupRight
ADD CONSTRAINT FK_UserControl_GroupRight_AccessRightID FOREIGN KEY (AccessRightID)
REFERENCES UserControl.AccessRight(AccessRightID)
ON DELETE CASCADE;
GO

------------------------------------------------------------------------------------------------------------------------
-- Suppliers
------------------------------------------------------------------------------------------------------------------------

CREATE TABLE Suppliers.Supplier
(
    SupplierID INT IDENTITY(1, 1) NOT NULL,
    UniqueID UNIQUEIDENTIFIER NOT NULL,
    Code VARCHAR(50) NOT NULL,
    Descr VARCHAR(80) NOT NULL,
    AddressDetail VARCHAR(200) NULL,
    Retired INT NULL,
    LastUpdateTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL
);

ALTER TABLE Suppliers.Supplier
ADD CONSTRAINT PK_Suppliers_Supplier PRIMARY KEY CLUSTERED (SupplierID);  
GO 

ALTER TABLE Suppliers.Supplier
ADD CONSTRAINT UC_Suppliers_Supplier_UniqueID UNIQUE (UniqueID);
GO 

ALTER TABLE Suppliers.Supplier
ADD CONSTRAINT UC_Suppliers_Supplier_Code UNIQUE (Code);  
GO 

ALTER TABLE Suppliers.Supplier
ADD CONSTRAINT FK_Suppliers_Supplier_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

CREATE TABLE Suppliers.SupplierArchive
(
    SupplierArchiveID INT IDENTITY(1, 1) NOT NULL,
    SupplierID INT NOT NULL,
    Code VARCHAR(50) NOT NULL,
    Descr VARCHAR(100) NOT NULL,
    AddressDetail VARCHAR(200) NULL,
    Retired INT NULL,
    ArchivedTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL,
    PreviousUpdateTime DATETIME2 NOT NULL,
    PreviousSystemUserID INT NOT NULL
);

ALTER TABLE Suppliers.SupplierArchive
ADD CONSTRAINT PK_Suppliers_SupplierArchive PRIMARY KEY CLUSTERED (SupplierArchiveID);  
GO 

ALTER TABLE Suppliers.SupplierArchive
ADD CONSTRAINT FK_Suppliers_SupplierArchive_SupplierID FOREIGN KEY (SupplierID)
REFERENCES Suppliers.Supplier(SupplierID);
GO

ALTER TABLE Suppliers.SupplierArchive
ADD CONSTRAINT FK_Suppliers_SupplierArchive_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

ALTER TABLE Suppliers.SupplierArchive
ADD CONSTRAINT FK_Suppliers_SupplierArchive_PreviousSystemUserID FOREIGN KEY (PreviousSystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

------------------------------------------------------------------------------------------------------------------------
-- Product
------------------------------------------------------------------------------------------------------------------------
CREATE TABLE Products.Product
(
    ProductID INT IDENTITY(1, 1) NOT NULL,
    UniqueID UNIQUEIDENTIFIER NOT NULL,
    Code VARCHAR(50) NOT NULL,
    Descr VARCHAR(100) NOT NULL,
    Retired INT NULL,
    LastUpdateTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL
);

ALTER TABLE Products.Product
ADD CONSTRAINT PK_Products_Product PRIMARY KEY CLUSTERED (ProductID);  
GO 

ALTER TABLE Products.Product
ADD CONSTRAINT UC_Products_Product_UniqueID UNIQUE (UniqueID);
GO 

ALTER TABLE Products.Product
ADD CONSTRAINT UC_Products_Product_Code UNIQUE (Code);  
GO 

ALTER TABLE Products.Product
ADD CONSTRAINT FK_Products_Product_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

CREATE TABLE Products.ProductArchive
(
    ProductArchiveID INT IDENTITY(1, 1) NOT NULL,
    ProductID INT NOT NULL,
    Code VARCHAR(50) NOT NULL,
    Descr VARCHAR(100) NOT NULL,
    Retired INT NULL,
    LastUpdateTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL,
    PreviousUpdateTime DATETIME2 NOT NULL,
    PreviousSystemUserID INT NOT NULL
);

ALTER TABLE Products.ProductArchive
ADD CONSTRAINT PK_Products_ProductArchive PRIMARY KEY CLUSTERED (ProductArchiveID);  
GO 

ALTER TABLE Products.ProductArchive
ADD CONSTRAINT FK_Products_ProductArchive_ProductID FOREIGN KEY (ProductID)
REFERENCES Products.Product(ProductID);
GO

ALTER TABLE Products.ProductArchive
ADD CONSTRAINT FK_Products_ProductArchive_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

ALTER TABLE Products.ProductArchive
ADD CONSTRAINT FK_Products_ProductArchive_PreviousSystemUserID FOREIGN KEY (PreviousSystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

CREATE TABLE Products.ProductComponent
(
    ProductComponentID INT IDENTITY(1, 1) NOT NULL,
    UniqueID UNIQUEIDENTIFIER NOT NULL,
    FinishedProductID INT NOT NULL,
    ComponentProductID INT NOT NULL,
    LastUpdateTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL
);

ALTER TABLE Products.ProductComponent
ADD CONSTRAINT PK_Products_ProductComponent PRIMARY KEY CLUSTERED (ProductComponentID);  
GO 

ALTER TABLE Products.ProductComponent
ADD CONSTRAINT UC_Products_ProductComponent_UniqueID UNIQUE (UniqueID);
GO 

ALTER TABLE Products.ProductComponent
ADD CONSTRAINT UC_Products_ProductComponent_FinishedComponentID UNIQUE (FinishedProductID, ComponentProductID);
GO 

ALTER TABLE Products.ProductComponent
ADD CONSTRAINT FK_Products_ProductComponent_FinishedProductID FOREIGN KEY (FinishedProductID)
REFERENCES Products.Product(ProductID);
GO

ALTER TABLE Products.ProductComponent
ADD CONSTRAINT FK_Products_ProductComponent_ComponentProductID FOREIGN KEY (ComponentProductID)
REFERENCES Products.Product(ProductID);
GO

ALTER TABLE Products.ProductComponent
ADD CONSTRAINT FK_Product_ProductComponent_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

CREATE TABLE Products.ProductComponentArchive
(
    ProductComponentArchiveID INT IDENTITY(1, 1) NOT NULL,
    ProductComponentID INT NOT NULL,
    FinishedProductID INT NOT NULL,
    ComponentProductID INT NOT NULL,
    ArchiveTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL,
    PreviousUpdateTime DATETIME2 NOT NULL,
    PreviousSystemUserID INT NOT NULL
);

ALTER TABLE Products.ProductComponentArchive
ADD CONSTRAINT PK_Products_ProductComponentArchive PRIMARY KEY CLUSTERED (ProductComponentArchiveID);  
GO 

ALTER TABLE Products.ProductComponentArchive
ADD CONSTRAINT FK_Products_ProductComponentArchive_ProductComponentID FOREIGN KEY (ProductComponentID)
REFERENCES Products.ProductComponent(ProductComponentID);
GO

ALTER TABLE Products.ProductComponentArchive
ADD CONSTRAINT FK_Products_ProductComponentArchive_FinishedProductID FOREIGN KEY (FinishedProductID)
REFERENCES Products.Product(ProductID);
GO

ALTER TABLE Products.ProductComponentArchive
ADD CONSTRAINT FK_Products_ProductComponentArchive_ComponentProductID FOREIGN KEY (ComponentProductID)
REFERENCES Products.Product(ProductID);
GO

ALTER TABLE Products.ProductComponentArchive
ADD CONSTRAINT FK_Product_ProductComponentArchive_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

ALTER TABLE Products.ProductComponentArchive
ADD CONSTRAINT FK_Product_ProductComponentArchive_PreviousSystemUserID FOREIGN KEY (PreviousSystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

------------------------------------------------------------------------------------------------------------------------
-- Location
------------------------------------------------------------------------------------------------------------------------
CREATE TABLE Locations.Location
(
    LocationID INT IDENTITY(1, 1) NOT NULL,
    UniqueID UNIQUEIDENTIFIER NOT NULL,
    Code VARCHAR(50) NOT NULL,
    Descr VARCHAR(100) NOT NULL,
    Retired INT NULL,
    LastUpdateTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL
);

ALTER TABLE Locations.Location
ADD CONSTRAINT PK_Locations_Location PRIMARY KEY CLUSTERED (LocationID);  
GO 

ALTER TABLE Locations.Location
ADD CONSTRAINT UC_Locations_Location_UniqueID UNIQUE (UniqueID);
GO 

ALTER TABLE Locations.Location
ADD CONSTRAINT UC_Locations_Location_Code UNIQUE (Code);
GO 

ALTER TABLE Locations.Location
ADD CONSTRAINT FK_Locations_Location_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

CREATE TABLE Locations.LocationArchive
(
    LocationArchiveID INT IDENTITY(1, 1) NOT NULL,
    LocationID INT NOT NULL,
    Code VARCHAR(50) NOT NULL,
    Descr VARCHAR(100) NOT NULL,
    Retired INT NULL,
    ArchiveTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL,
    PreviousUpdateTime DATETIME2 NOT NULL,
    PreviousSystemUserID INT NOT NULL
);

ALTER TABLE Locations.LocationArchive
ADD CONSTRAINT PK_Locations_LocationArchive PRIMARY KEY CLUSTERED (LocationArchiveID);  
GO 

ALTER TABLE Locations.LocationArchive
ADD CONSTRAINT FK_Locations_LocationArchive_LocationID FOREIGN KEY (LocationID)
REFERENCES Locations.Location(LocationID);
GO

ALTER TABLE Locations.LocationArchive
ADD CONSTRAINT FK_Locations_LocationArchive_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

ALTER TABLE Locations.LocationArchive
ADD CONSTRAINT FK_Locations_LocationArchive_PreviousSystemUserID FOREIGN KEY (PreviousSystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

------------------------------------------------------------------------------------------------------------------------
-- Linking Tables
------------------------------------------------------------------------------------------------------------------------

CREATE TABLE Linking.SupplierProduct
(
    SupplierProductID INT IDENTITY(1, 1) NOT NULL,
    SupplierID INT NOT NULL,
    ProductID INT NOT NULL,
    LastUpdateTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL
);
GO

ALTER TABLE Linking.SupplierProduct
ADD CONSTRAINT PK_Linking_SupplierProduct PRIMARY KEY CLUSTERED (SupplierProductID);  
GO 

ALTER TABLE Linking.SupplierProduct
ADD CONSTRAINT UC_Linking_SupplierProduct_SupplierProduct UNIQUE (SupplierID, ProductID);
GO 

ALTER TABLE Linking.SupplierProduct
ADD CONSTRAINT FK_Linking_SupplierProduct_ProductID FOREIGN KEY (ProductID)
REFERENCES Products.Product(ProductID);
GO

ALTER TABLE Linking.SupplierProduct
ADD CONSTRAINT FK_Linking_SupplierProduct_SupplierID FOREIGN KEY (SupplierID)
REFERENCES Suppliers.Supplier(SupplierID);
GO

ALTER TABLE Linking.SupplierProduct
ADD CONSTRAINT FK_Linking_SupplierProduct_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

CREATE TABLE Linking.SupplierProductArchive
(
    SupplierProductArchiveID INT IDENTITY(1, 1) NOT NULL,
    SupplierProductID INT NOT NULL,
    SupplierID INT NOT NULL,
    ProductID INT NOT NULL,
    ArchiveTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL,
    PreviousUpdateTime DATETIME2 NOT NULL,
    PreviousSystemUserID INT NOT NULL
);
GO

ALTER TABLE Linking.SupplierProductArchive
ADD CONSTRAINT PK_Linking_SupplierProductArchive PRIMARY KEY CLUSTERED (SupplierProductArchiveID);  
GO 

ALTER TABLE Linking.SupplierProductArchive
ADD CONSTRAINT FK_Linking_SupplierProductArchive_SupplierProductID FOREIGN KEY (SupplierProductID)
REFERENCES Linking.SupplierProduct(SupplierProductID);
GO

ALTER TABLE Linking.SupplierProductArchive
ADD CONSTRAINT FK_Linking_SupplierProductArchive_ProductID FOREIGN KEY (ProductID)
REFERENCES Products.Product(ProductID);
GO

ALTER TABLE Linking.SupplierProductArchive
ADD CONSTRAINT FK_Linking_SupplierProductArchive_SupplierID FOREIGN KEY (SupplierID)
REFERENCES Suppliers.Supplier(SupplierID);
GO

ALTER TABLE Linking.SupplierProductArchive
ADD CONSTRAINT FK_Linking_SupplierProductArchive_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

ALTER TABLE Linking.SupplierProductArchive
ADD CONSTRAINT FK_Linking_SupplierProductArchive_PreviousSystemUserID FOREIGN KEY (PreviousSystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

CREATE TABLE Linking.LocationProduct
(
    LocationProductID INT IDENTITY(1, 1) NOT NULL,
    LocationID INT NOT NULL,
    ProductID INT NOT NULL,
    LastUpdateTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL
);
GO

ALTER TABLE Linking.LocationProduct
ADD CONSTRAINT PK_Linking_LocationProduct PRIMARY KEY CLUSTERED (LocationProductID);  
GO 

ALTER TABLE Linking.LocationProduct
ADD CONSTRAINT UC_Linking_LocationProduct_LocationProduct UNIQUE (LocationID, ProductID);
GO 

ALTER TABLE Linking.LocationProduct
ADD CONSTRAINT FK_Linking_LocationProduct_ProductID FOREIGN KEY (ProductID)
REFERENCES Products.Product(ProductID);
GO

ALTER TABLE Linking.LocationProduct
ADD CONSTRAINT FK_Linking_LocationProduct_LocationID FOREIGN KEY (LocationID)
REFERENCES Locations.Location(LocationID);
GO

ALTER TABLE Linking.LocationProduct
ADD CONSTRAINT FK_Linking_LocationProduct_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

CREATE TABLE Linking.LocationProductArchive
(
    LocationProductArchiveID INT IDENTITY(1, 1) NOT NULL,
    LocationProductID INT NOT NULL,
    LocationID INT NOT NULL,
    ProductID INT NOT NULL,
    ArchiveTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL,
    PreviousUpdateTime DATETIME2 NOT NULL,
    PreviousSystemUserID INT NOT NULL
);
GO

ALTER TABLE Linking.LocationProductArchive
ADD CONSTRAINT PK_Linking_LocationProductArchive PRIMARY KEY CLUSTERED (LocationProductArchiveID);  
GO 

ALTER TABLE Linking.LocationProductArchive
ADD CONSTRAINT FK_Linking_LocationProductArchive_LocationProductID FOREIGN KEY (LocationProductID)
REFERENCES Linking.LocationProduct(LocationProductID);
GO

ALTER TABLE Linking.LocationProductArchive
ADD CONSTRAINT FK_Linking_LocationProductArchive_ProductID FOREIGN KEY (ProductID)
REFERENCES Products.Product(ProductID);
GO

ALTER TABLE Linking.LocationProductArchive
ADD CONSTRAINT FK_Linking_LocationProductArchive_LocationID FOREIGN KEY (LocationID)
REFERENCES Locations.Location(LocationID);
GO

ALTER TABLE Linking.LocationProductArchive
ADD CONSTRAINT FK_Linking_LocationProductArchive_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

ALTER TABLE Linking.LocationProductArchive
ADD CONSTRAINT FK_Linking_LocationProductArchive_PreviousSystemUserID FOREIGN KEY (PreviousSystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

CREATE TABLE Linking.ProductSellingPrice
(
    ProductSellingPriceID INT IDENTITY(1, 1) NOT NULL,
    LocationProductID INT NOT NULL,
    SellingPrice NUMERIC (12, 5),
    LastUpdateTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL
);

ALTER TABLE Linking.ProductSellingPrice
ADD CONSTRAINT PK_Linking_ProductSellingPrice PRIMARY KEY CLUSTERED (ProductSellingPriceID);  
GO 

ALTER TABLE Linking.ProductSellingPrice
ADD CONSTRAINT UC_Linking_ProductSellingPrice_LocationProduct UNIQUE (LocationProductID);
GO 

ALTER TABLE Linking.ProductSellingPrice
ADD CONSTRAINT FK_Linking_ProductSellingPrice_LocationProductID FOREIGN KEY (LocationProductID)
REFERENCES Linking.LocationProduct(LocationProductID);
GO

ALTER TABLE Linking.ProductSellingPrice
ADD CONSTRAINT FK_Linking_ProductSellingPrice_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

CREATE TABLE Linking.ProductSellingPriceArchive
(
    ProductSellingPriceArchiveID INT IDENTITY(1, 1) NOT NULL,
    ProductSellingPriceID INT NOT NULL,
    LocationProductID INT NOT NULL,
    SellingPrice NUMERIC (12, 5),
    ArchiveTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL,
    PreviousUpdateTime DATETIME2 NOT NULL,
    PreviousUpdateSystemUserID INT NOT NULL
);

ALTER TABLE Linking.ProductSellingPriceArchive
ADD CONSTRAINT PK_Linking_ProductSellingPriceArchive PRIMARY KEY CLUSTERED (ProductSellingPriceArchiveID);
GO 

ALTER TABLE Linking.ProductSellingPriceArchive
ADD CONSTRAINT FK_Linking_ProductSellingPriceArchive_ProductSellingPriceID FOREIGN KEY (ProductSellingPriceID)
REFERENCES Linking.ProductSellingPrice(ProductSellingPriceID);
GO

ALTER TABLE Linking.ProductSellingPriceArchive
ADD CONSTRAINT FK_Linking_ProductSellingPriceArchive_LocationProductID FOREIGN KEY (LocationProductID)
REFERENCES Linking.LocationProduct(LocationProductID);
GO

ALTER TABLE Linking.ProductSellingPriceArchive
ADD CONSTRAINT FK_Linking_ProductSellingPriceArchive_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

ALTER TABLE Linking.ProductSellingPriceArchive
ADD CONSTRAINT FK_Linking_ProductSellingPriceArchive_PreviousUpdateSystemUserID FOREIGN KEY (PreviousUpdateSystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

CREATE TABLE Linking.ProductPurchasePrice
(
    ProductPurchasePriceID INT IDENTITY(1, 1) NOT NULL,
    SupplierProductID INT NOT NULL,
    PurchaseDate DATETIME2 NOT NULL,
    PurchasePrice NUMERIC (12, 5) NOT NULL,
    Volume NUMERIC (12, 5) NOT NULL,
    LastUpdateTime DATETIME2 NOT NULL,
    SystemUserID INT NOT NULL
);
GO

ALTER TABLE Linking.ProductPurchasePrice
ADD CONSTRAINT PK_Linking_ProductPurchasePrice PRIMARY KEY CLUSTERED (ProductPurchasePriceID);
GO 

ALTER TABLE Linking.ProductPurchasePrice
ADD CONSTRAINT FK_Linking_ProductPurchasePrice_SupplierProductID FOREIGN KEY (SupplierProductID)
REFERENCES Linking.SupplierProduct(SupplierProductID);
GO

ALTER TABLE Linking.ProductPurchasePrice
ADD CONSTRAINT FK_Linking_ProductPurchasePrice_SystemUserID FOREIGN KEY (SystemUserID)
REFERENCES UserControl.SystemUser(SystemUserID);
GO

------------------------------------------------------------------------------------------------------------------------
-- Functions
------------------------------------------------------------------------------------------------------------------------

------
-- Check if a user name exists in the database
------
CREATE OR ALTER FUNCTION [UserControl].[UserNameExists](@username as VARCHAR(100))
RETURNS INT
AS
BEGIN
    IF EXISTS 
    (
        SELECT TOP 1 1 
        FROM [UserControl].[SystemUser] 
        WHERE UserName = @username
    ) RETURN  1

    RETURN 0;
END;
GO

------
-- Check if a user name exists in the database
------
CREATE OR ALTER FUNCTION [UserControl].[GetUserID](@username as VARCHAR(100))
RETURNS INT
AS
BEGIN
    DECLARE @userIdResult AS INT;

    IF EXISTS 
    (
        SELECT TOP 1 1
        FROM [UserControl].[SystemUser] 
        WHERE UserName = @username
    )
    BEGIN
        SELECT @userIdResult = SystemUserID
        FROM [UserControl].[SystemUser] 
        WHERE UserName = @username
        RETURN @userIdResult;
    END;

    RETURN NULL;
END;
GO

------
-- Check if an account is active
------
CREATE OR ALTER FUNCTION [UserControl].[IsAccountActive] (@userID AS INT)
RETURNS INT
AS
BEGIN
    DECLARE @result AS INT = 0;

    IF EXISTS (SELECT TOP 1 1 FROM [UserControl].[SystemUser] WHERE SystemUserID = @userID)
    BEGIN
        SELECT
            @result = CASE ISNULL(Deactivated, 0)
                WHEN 0 THEN 0
                ELSE 1
            END
        FROM
            [UserControl].[SystemUser]
        WHERE
            SystemUserID = @userID
    END

    return @result;
END;
GO

------
-- Find a session token for a SystemUserID
------
CREATE OR ALTER FUNCTION [UserControl].[GetSessionTokenForUser](@userID INT)
RETURNS VARCHAR(80)
AS
BEGIN
    DECLARE @result VARCHAR(80);
    SELECT
        @result = US.SessionToken
    FROM
        [UserControl].[SystemUser] SU
        INNER JOIN
            [UserControl].[UserSession] US
            ON
                SU.SystemUserID = US.SystemUserID
    WHERE
        SessionExpiryTime < SYSUTCDATETIME()

    RETURN @result;
END;
GO

------
-- Return the current time of the server
------
CREATE OR ALTER FUNCTION [Support].[GetDatabaseUtcTime]()
RETURNS DATETIME2
AS
BEGIN
    RETURN SYSUTCDATETIME();
END;
GO

------------------------------------------------------------------------------------------------------------------------
-- Stored procedures
------------------------------------------------------------------------------------------------------------------------
------
-- Add records to the SystemUser table
------
CREATE OR ALTER PROCEDURE [UserControl].[CreateSystemUser]
(
    @userName AS VARCHAR(100),
    @additionalData AS VARCHAR(256),
    @emailAddress AS VARCHAR(256),
    @contactNumber AS VARCHAR(50),
    @passwordHash AS VARCHAR(256),
    @passwordExpiryDate AS DATETIME2,
    @requiresLogin AS INT,
    @sessionTimeoutMinutes AS INT
)
AS
BEGIN
    DECLARE @systemUserHighestID AS INT;
    SELECT @systemUserHighestID = COALESCE(MAX(SystemUserID), 0) FROM [UserControl].[SystemUser];

    INSERT INTO
        [UserControl].[SystemUser]
        (
            SystemUserID,
            UniqueID,
            LastUpdateTime,
            UserName,
            AdditionalData,
            EmailAddress,
            ContactNumber,
            AccountLocked,
            PasswordHash,
            PasswordExpiryDate,
            RequiresLogin,
            UnsuccessfulLoginAttempts,
            SessionTimeoutMinutes,
            Deactivated
        )
    VALUES
        (
            @systemUserHighestID + 1,
            NEWID(),
            SYSUTCDATETIME(),
            @userName,
            @additionalData,
            @emailAddress,
            @contactNumber,
            0,
            @passwordHash,
            @passwordExpiryDate,
            @requiresLogin,
            0,
            @sessionTimeoutMinutes,
            0
        );

    SELECT @systemUserHighestID + 1;
END;
GO

------
-- Update an existing record in the SystemUser table
------
CREATE OR ALTER PROCEDURE [UserControl].[AlterSystemUserData]
(
    @systemUserID AS INT,
    @additionalData AS VARCHAR(256),
    @emailAddress AS VARCHAR(256),
    @contactNumber AS VARCHAR(50)
)
AS
BEGIN
    UPDATE
        [UserControl].[SystemUser]
    SET
        LastUpdateTime = SYSUTCDATETIME(),
        AdditionalData = @additionalData,
        EmailAddress = @emailAddress,
        ContactNumber = @contactNumber
    WHERE
        SystemUserID = @systemUserID;
END;
GO

------
-- Generates a string of random characters
------
CREATE OR ALTER PROCEDURE [UserControl].[GenerateTokenString](@resultLength AS INT)
AS
BEGIN
    DECLARE @charPool AS NVARCHAR(MAX) = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    DECLARE @poolLength AS INT = Len(@charPool);
    DECLARE @loopCounter AS INT = @resultLength;
    DECLARE @result AS NVARCHAR(MAX) = '';
    DECLARE @charIndex AS INT;
    DECLARE @randomizer AS INT;
    DECLARE @foo AS FLOAT;

    WHILE (@loopCounter > 0) 
    BEGIN
        SET @charIndex = (CONVERT(INT, RAND() * 1000000) % @poolLength) + 1;
        SET @result = @result + SUBSTRING(@charpool, @charIndex, 1);
        SET @loopCounter = @loopCounter - 1;

        SET @randomizer = (CONVERT(INT, RAND() * 10)) + 5;
        WHILE (@randomizer > 0)
        BEGIN
            SET @randomizer = @randomizer - 1;
            SET @foo = RAND();
        END;
    END

    SELECT @result;
END;
GO


------
-- Disable or re-enable a user account
------
CREATE OR ALTER PROCEDURE [UserControl].[DeactivateUser] 
(
    @sessionToken AS VARCHAR(80),
    @userID AS INT, 
    @deactivationStatus AS INT
)
AS
BEGIN
    UPDATE [UserControl].[SystemUser]
    SET 
        Deactivated = CASE @deactivationStatus
            WHEN 1 THEN 1
            ELSE 0
        END,
        LastUpdateTime = SYSUTCDATETIME()
    WHERE
        SystemUserID = @userID;
END;
GO

------
-- Attempt to log into the system
------
CREATE OR ALTER PROCEDURE [UserControl].[LogUserIn]
(
    @userName VARCHAR(100),
    @passwordHash VARCHAR(256)
)
AS
BEGIN
    DECLARE @userID INT;
    DECLARE @accountDeactivated INT;
--    DECLARE @passwordHash VARCHAR(256);

    SELECT
        @userID = SystemUserID,
        @accountDeactivated = ISNULL(Deactivated, 0),
        @passwordHash = @passwordHash
    FROM
        [UserControl].[SystemUser] SU
    WHERE
        SU.UserName = @userName;

    IF (@userID IS NULL) THROW 100000, 'User name not found', 1;
    IF (@accountDeactivated <> 0) THROW 100001, 'Account is deactivated', 1;

    

END;
GO

------
-- Select all active suppliers
------
CREATE OR ALTER PROCEDURE [Suppliers].[GetSuppliers]
AS
BEGIN
    SELECT
        SupplierID,
        UniqueID,
        Code,
        Descr,
        AddressDetail,
        LastUpdateTime
    FROM
        [Suppliers].[Supplier]
    WHERE
        ISNULL(Retired, 0) != 1
END;
GO

------
-- Select all suppliers, including deleted ones.
------
CREATE OR ALTER PROCEDURE [Suppliers].[GetAllSuppliers]
AS
BEGIN
    SELECT
        SupplierID,
        UniqueID,
        Code,
        Descr,
        AddressDetail,
        Retired,
        LastUpdateTime
    FROM
        [Suppliers].[Supplier]
END;
GO

CREATE OR ALTER PROCEDURE [Suppliers].[GetSupplierHistory] (@supplierID INT)
AS
BEGIN
    SELECT
        SA.SupplierID,
        S.UniqueID,
        SA.Code,
        SA.Descr,
        SA.AddressDetail,
        SA.Retired,
        SA.ArchivedTime,
        SA.SystemUserID,
        SA.PreviousUpdateTime,
        SA.PreviousSystemUserID
    FROM
        [Suppliers].[SupplierArchive] SA
        INNER JOIN
            [Suppliers].[Supplier] S
            ON
                S.SupplierID = SA.SupplierID
    WHERE
        SA.SupplierID = @supplierID;
END;
GO

------
-- Get supplier records for the items identified in the identifiersList table parameter
------
CREATE OR ALTER PROCEDURE [Suppliers].[GetSuppliersWithIdentifiers]
    @identifiersList AS [Shared].[GuidTable] READONLY
AS
BEGIN
    SELECT
        SupplierID,
        UniqueID,
        Code,
        Descr,
        AddressDetail,
        LastUpdateTime,
        SystemUserID
    FROM
        [Suppliers].[Supplier] S
        INNER JOIN
            @identifiersList IL
            ON
                IL.identifier = S.UniqueID
END;
GO

------
-- Create an archive copy of a supplier record in the supplier archive table
------
CREATE OR ALTER PROCEDURE [Suppliers].[CreateSupplierArchiveCopy]
(
    @supplierID INT,
    @systemUserID INT
)
AS
BEGIN
    INSERT INTO
        [Suppliers].[SupplierArchive]
        (
            SupplierID,
            Code,
            Descr,
            AddressDetail,
            Retired,
            ArchivedTime,
            SystemUserID,
            PreviousUpdateTime,
            PreviousSystemUserID
        )
    SELECT
        SupplierID,
        Code,
        Descr,
        AddressDetail,
        Retired,
        SYSUTCDATETIME(),
        @systemUserID,
        LastUpdateTime,
        SystemUserID
    FROM
        [Suppliers].[Supplier]
    WHERE
        SupplierID = @supplierID
END;
GO

------
-- Add a new supplier record
------
CREATE OR ALTER PROCEDURE [Suppliers].[AddSupplier]
(
    @code AS VARCHAR(50),
    @descr AS VARCHAR(80),
    @addressDetail AS VARCHAR(200),
    @systemUserID AS INT
)
AS
BEGIN
    -- Table variable to receive inserted record identifiers
    DECLARE @insertedRec AS TABLE
    (
        SupplierID INT,
        UniqueID UNIQUEIDENTIFIER
    );

    INSERT INTO
        [Suppliers].[Supplier]
        (
            UniqueID,
            Code,
            Descr,
            AddressDetail,
            LastUpdateTime,
            SystemUserID
        )
    OUTPUT
        inserted.SupplierID, 
        inserted.UniqueID 
        INTO 
            @insertedRec(SupplierID, UniqueID)
    VALUES
        (
            NEWID(),
            @code,
            @descr,
            @addressDetail,
            SYSUTCDATETIME(),
            @systemUserID
        );

    -- Return the identifiers for the new record.
    SELECT SupplierID, UniqueID FROM @insertedRec;
END;
GO

------
-- Update a supplier record
------
CREATE OR ALTER PROCEDURE [Suppliers].[UpdateSupplier]
(
    @supplierID AS INT,
    @code AS VARCHAR(50),
    @descr AS VARCHAR(80),
    @addressDetail AS VARCHAR(200),
    @recordUpdatedTime DATETIME2,
    @systemUserID AS INT
)
AS
BEGIN
    DECLARE @actionCode INT;

    -- Check if a record with a newer update time exists. If so, do not update the existing record but return
    -- the existing data.
    IF EXISTS
    (
        SELECT TOP 1 1 
        FROM 
            [Suppliers].[Supplier] 
        WHERE 
            SupplierID = @supplierID AND 
            LastUpdateTime >= @recordUpdatedTime
    )
    BEGIN
        -- Indicate returning other data
        SET @actionCode = 1;
    END
    ELSE
    BEGIN
        -- Create a copy of the record in the archive table
        EXEC [Suppliers].[CreateSupplierArchiveCopy] @supplierID, @systemUserID;

        -- Update the new record.
        UPDATE 
            [Suppliers].[Supplier]
        SET
            Code = @code,
            Descr = @descr,
            AddressDetail = @addressDetail,
            LastUpdateTime = SYSUTCDATETIME(),
            SystemUserID = @systemUserID
        WHERE
            SupplierID = @supplierID

        -- Indicate update
        SET @actionCode = 2;
    END

    SELECT
        @actionCode AS ActionCode,
        SupplierID,
        UniqueID,
        Code,
        Descr,
        AddressDetail,
        Retired,
        LastUpdateTime,
        SystemUserID
    FROM
        [Suppliers].[Supplier]
    WHERE
        SupplierID = @supplierID
END;
GO

------
-- Mark a supplier as retired
------
CREATE OR ALTER PROCEDURE [Suppliers].[RetireSupplier]
(
    @supplierID AS INT,
    @retiredState AS INT,
    @recordUpdatedTime DATETIME2,
    @systemUserID AS INT
)
AS
BEGIN
    DECLARE @actionCode INT;

    -- Check if a record with a newer update time exists. If so, do not update the existing record but return
    -- the existing data.
    IF EXISTS
    (
        SELECT TOP 1 1 
        FROM 
            [Suppliers].[Supplier] 
        WHERE 
            SupplierID = @supplierID AND 
            LastUpdateTime >= @recordUpdatedTime
    )
    BEGIN
        -- Indicate returning other data
        SET @actionCode = 1;
    END
    ELSE
    BEGIN
        -- Create a copy of the record in the archive table
        EXEC [Suppliers].[CreateSupplierArchiveCopy] @supplierID, @systemUserID;

        -- Update the new record.
        UPDATE 
            [Suppliers].[Supplier]
        SET
            Retired = CASE @retiredState
                WHEN 1 THEN 1
                ELSE 0
            END,
            LastUpdateTime = SYSUTCDATETIME(),
            SystemUserID = @systemUserID
        WHERE
            SupplierID = @supplierID

        -- Indicate update
        SET @actionCode = 2;
    END

    SELECT
        @actionCode AS ActionCode,
        SupplierID,
        UniqueID,
        Code,
        Descr,
        AddressDetail,
        Retired,
        LastUpdateTime,
        SystemUserID
    FROM
        [Suppliers].[Supplier]
    WHERE
        SupplierID = @supplierID
END;
GO

------------------------------------------------------------------------------------------------------------------------
-- Data Initialisation
------------------------------------------------------------------------------------------------------------------------
INSERT INTO Support.SchemaVersion (SchemaVersionID) VALUES (1);
GO

INSERT INTO Support.ExceptionCode(ExceptionCodeID, Descr) 
VALUES
    (100000, 'User name not found'),
    (100001, 'Account is deactivated'),
    (100002, 'Concurrent record update')
;
GO

------
-- Access rights table population
------
INSERT INTO [UserControl].[AccessRight]
(
    AccessRightID,
    UniqueID,
    LastUpdateTime,
    Code,
    Descr
)
VALUES (   1, NEWID(), SYSUTCDATETIME(), 'SYSADMIN', 'System Administrator'),
       (  50, NEWID(), SYSUTCDATETIME(), 'USER_MAINTAIN', 'Can maintain users'),
       (  51, NEWID(), SYSUTCDATETIME(), 'USER_GROUP_MAINTAIN', 'Can maintain user groups'),
       (  52, NEWID(), SYSUTCDATETIME(), 'ACCOUNT_RESET', 'Can reset accounts that are locked'),
       (  53, NEWID(), SYSUTCDATETIME(), 'CHANGE_USERNAME', 'Can change a user name'),
       ( 100, NEWID(), SYSUTCDATETIME(), 'SUPPLIER_ADD', 'User can add suppliers'),
       ( 101, NEWID(), SYSUTCDATETIME(), 'SUPPLIER_DELETE', 'User can delete suppliers'),
       ( 102, NEWID(), SYSUTCDATETIME(), 'SUPPLIER_EDIT', 'User can edit suppliers'),
       ( 103, NEWID(), SYSUTCDATETIME(), 'SUPPLIER_VIEW', 'User can view suppliers'),
       ( 200, NEWID(), SYSUTCDATETIME(), 'PRODUCT_ADD', 'User can add products'),
       ( 201, NEWID(), SYSUTCDATETIME(), 'PRODUCT_DELETE', 'User can delete products'),
       ( 202, NEWID(), SYSUTCDATETIME(), 'PRODUCT_EDIT', 'User can edit products'),
       ( 203, NEWID(), SYSUTCDATETIME(), 'PRODUCT_VIEW', 'User can view products'),
       ( 210, NEWID(), SYSUTCDATETIME(), 'PRODUCT_SELLING_PRICE_VIEW', 'User can view product selling prices'),
       ( 211, NEWID(), SYSUTCDATETIME(), 'PRODUCT_SELLING_PRICE_MAINTAIN', 'User can maintain product selling prices'),
       ( 220, NEWID(), SYSUTCDATETIME(), 'PRODUCT_PURCHASE_PRICE_VIEW', 'User can view product purchase prices'),
       ( 221, NEWID(), SYSUTCDATETIME(), 'PRODUCT_PURCHASE_PRICE_MAINTAIN', 'User can maintain product purchase prices'),
       ( 300, NEWID(), SYSUTCDATETIME(), 'LOCATION_ADD', 'User can add locations'),
       ( 301, NEWID(), SYSUTCDATETIME(), 'LOCATION_DELETE', 'User can delete locations'),
       ( 302, NEWID(), SYSUTCDATETIME(), 'LOCATION_EDIT', 'User can edit locations'),
       ( 303, NEWID(), SYSUTCDATETIME(), 'LOCATION_VIEW', 'User can view locations'),
       (1000, NEWID(), SYSUTCDATETIME(), 'LINK_SUPPLIER_PRODUCT', 'User can link suppliers to products'),
       (1001, NEWID(), SYSUTCDATETIME(), 'LINK_LOCATION_PRODUCT', 'User can link products to locations')
;
GO

------
-- System groups table population
------
INSERT INTO [UserControl].[SystemGroup]
(
    SystemGroupID,
    UniqueID,
    LastUpdateTime,
    Code,
    Descr
)
VALUES
    (    1, NEWID(), SYSUTCDATETIME(), 'SYSADMINS', 'Sytstem administrators'),
    (   10, NEWID(), SYSUTCDATETIME(), 'POWER_USERS', 'Power users'),
    (  100, NEWID(), SYSUTCDATETIME(), 'SUPPLIERS_MAINTAINER', 'Access rights to maintain suppliers'),
    (  200, NEWID(), SYSUTCDATETIME(), 'PRODUCTS_MAINTAINER', 'Access rights to maintain products'),
    (  300, NEWID(), SYSUTCDATETIME(), 'LOCATIONS_MAINTAINER', 'Access rights to maintain locations'),
    ( 1000, NEWID(), SYSUTCDATETIME(), 'USER_ADMIN', 'User administrator')
;
GO

------
-- Creation of default group rights
------
INSERT INTO [UserControl].[GroupRight]
(
    GroupRightID,
    LastUpdateTime,
    SystemGroupID,
    AccessRightID
)
VALUES
    -- System administrators
    (       1, SYSUTCDATETIME(),     1,     1),

    -- Power users
    (     104, SYSUTCDATETIME(),    10,   100),
    (     105, SYSUTCDATETIME(),    10,   101),
    (     106, SYSUTCDATETIME(),    10,   102),
    (     107, SYSUTCDATETIME(),    10,   103),
    (     108, SYSUTCDATETIME(),    10,   200),
    (     109, SYSUTCDATETIME(),    10,   201),
    (     110, SYSUTCDATETIME(),    10,   202),
    (     111, SYSUTCDATETIME(),    10,   203),
    (     112, SYSUTCDATETIME(),    10,   210),
    (     113, SYSUTCDATETIME(),    10,   211),
    (     114, SYSUTCDATETIME(),    10,   220),
    (     115, SYSUTCDATETIME(),    10,   221),
    (     116, SYSUTCDATETIME(),    10,   300),
    (     117, SYSUTCDATETIME(),    10,   301),
    (     118, SYSUTCDATETIME(),    10,   302),
    (     119, SYSUTCDATETIME(),    10,   303),
    (     120, SYSUTCDATETIME(),    10,  1000),
    (     121, SYSUTCDATETIME(),    10,  1001),

    -- Suppliers maintainer
    (     200, SYSUTCDATETIME(),   100,   100),
    (     201, SYSUTCDATETIME(),   100,   101),
    (     202, SYSUTCDATETIME(),   100,   102),
    (     203, SYSUTCDATETIME(),   100,   103),

    -- Products maintainer
    (     300, SYSUTCDATETIME(),   200,   200),
    (     301, SYSUTCDATETIME(),   200,   201),
    (     302, SYSUTCDATETIME(),   200,   202),
    (     303, SYSUTCDATETIME(),   200,   203),
    (     304, SYSUTCDATETIME(),   200,   210),
    (     305, SYSUTCDATETIME(),   200,   211),
    (     306, SYSUTCDATETIME(),   200,   220),
    (     307, SYSUTCDATETIME(),   200,   221),

    -- Locations maintainer
    (     400, SYSUTCDATETIME(),   300,   300),
    (     401, SYSUTCDATETIME(),   300,   301),
    (     402, SYSUTCDATETIME(),   300,   302),
    (     403, SYSUTCDATETIME(),   300,   303)
;
GO

------
-- Create a default user
------
INSERT INTO [UserControl].[SystemUser]
(
    UniqueID,
    LastUpdateTime,
    UserName,
    EmailAddress,
    ContactNumber,
    AccountLocked,
    PasswordHash,
    PasswordExpiryDate,
    RequiresLogin,
    UnsuccessfulLoginAttempts,
    SessionTimeoutMinutes,
    Deactivated
)
VALUES
(
    NEWID(), 
    SYSUTCDATETIME(),
    'DefaultUser',
    'defaultuser@example.com',
    '(123)456-7890',
    0,
    '',
    '9999-12-31 23:59:59',
    0,
    0,
    999999999,
    0
);
GO