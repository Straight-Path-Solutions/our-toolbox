USE [master]
GO

CREATE OR ALTER PROCEDURE sp_FindOrphanedUser @DatabaseName sysname = NULL
AS

BEGIN

IF (@DatabaseName IS NOT NULL AND LEFT(@DatabaseName, 1) = '[' and RIGHT (@DatabaseName, 1) = ']')
	BEGIN
	PRINT 'Adjusting database name to fit expected format...'
	SET @DatabaseName = (SELECT REPLACE(@DatabaseName, '[', ''))
	SET @DatabaseName = (SELECT REPLACE(@DatabaseName, ']', ''))
	END

DECLARE @command varchar(4000)

IF (@DatabaseName IS NOT NULL)
BEGIN
	DECLARE @exec nvarchar(max) = QUOTENAME(@DatabaseName) + N'.sys.sp_executesql',
        @sql  nvarchar(max) = N'BEGIN
		INSERT INTO #tblTempOrphaned
		SELECT DISTINCT @@SERVERNAME, @DatabaseName as DatabaseName, dp.name AS [User], dp.sid, dp.type_desc, dp.authentication_type_desc, ''['' + dp.name + ''] is an orphaned user in the '' + ''['' + @DatabaseName +  ''] database.'' + '' This means that they do not have a corresponding server login. The orphaned user should be repaired or dropped.'' AS [Report], ''CREATE LOGIN ['' + dp.name + ''] WITH PASSWORD = '''' '''' / FROM WINDOWS '' + '' USE ['' + @DatabaseName + ''] ALTER USER ['' + dp.name + ''] WITH Login = ['' + dp.name + '']''as [repair_orphaned_user], ''USE ['' + @DatabaseName + ''] DROP USER ['' + dp.name + '']'' as [drop_orphaned_user]
		FROM sys.database_principals AS dp
		LEFT JOIN sys.server_principals AS sp
		on dp.sid = sp.sid
		WHERE
		sp.sid IS NULL
		and dp.authentication_type_desc in (''INSTANCE'', ''WINDOWS'')
		and dp.type_desc in (''SQL_USER'', ''WINDOWS_GROUP'', ''WINDOWS_USER'')

		INSERT INTO #tblTempOrphaned3
		SELECT ''USE '' + ''['' + @DatabaseName + ''] '' + ''EXEC sp_change_users_login ''' + '''UPDATE_ONE''' + ''','''''' + dp.name + '''''','''''' + sp.name + '''''''' AS [link_to_existing_login]
		FROM sys.database_principals AS dp
		LEFT JOIN sys.server_principals AS sp
		on dp.sid <> sp.sid
		and dp.name COLLATE DATABASE_DEFAULT = sp.name COLLATE DATABASE_DEFAULT
		where dp.is_fixed_role = 0 and sp.is_fixed_role = 0
		and dp.authentication_type_desc in (''INSTANCE'', ''WINDOWS'')
		and dp.type_desc in (''SQL_USER'', ''WINDOWS_GROUP'', ''WINDOWS_USER'')

		INSERT INTO #tblTempOrphaned5
		SELECT dp.name AS [DB User], s.name AS [Schema], ''USE ['' + @DatabaseName + ''] ALTER AUTHORIZATION ON SCHEMA::['' + s.name + ''] TO [dbo]'' AS AlterAuthorization
		FROM sys.database_principals AS dp
		JOIN sys.schemas s ON s.principal_id = dp.principal_id
		LEFT JOIN sys.server_principals AS sp
		on dp.sid = sp.sid
		WHERE
		sp.sid IS NULL
		and dp.authentication_type_desc in (''INSTANCE'', ''WINDOWS'')
		and dp.type_desc in (''SQL_USER'', ''WINDOWS_GROUP'', ''WINDOWS_USER'')
		and s.name <> ''dbo''
	END';
	
	
	IF OBJECT_ID('tempdb..#tblTempOrphaned') IS NOT NULL DROP TABLE #tblTempOrphaned
	IF OBJECT_ID('tempdb..#tblTempOrphaned3') IS NOT NULL DROP TABLE #tblTempOrphaned3
	IF OBJECT_ID('tempdb..#tblTempOrphaned3') IS NOT NULL DROP TABLE #tblTempOrphaned5
	CREATE TABLE #tblTempOrphaned ([ComputerName] varchar (100),  [DatabaseName] varchar(100), [User] varchar(100), [sid] varbinary(100), [type_desc] varchar(100), [authentication_type_desc] varchar(100), [Report] varchar (300), [repair_orphaned_user] varchar(200), [drop_orphaned_user] varchar(200))
	CREATE TABLE #tblTempOrphaned3 ([link_to_existing_login] varchar(200))
	CREATE TABLE #tblTempOrphaned5 ([DB User] varchar(100), [Schema] varchar (100), [AlterAuthorization] varchar (200))
	EXEC @exec @sql, N'@DatabaseName sysname', @DatabaseName;
	DELETE FROM #tblTempOrphaned
	WHERE [User] = 'dbo'
	SELECT *
	FROM #tblTempOrphaned
	ORDER BY DatabaseName
	DROP TABLE #tblTempOrphaned

	DECLARE @Rows1 INT = NULL
	SET @Rows1 = (SELECT COUNT(*) FROM #tblTempOrphaned3)

	IF(@Rows1 > 0)
	BEGIN
		SELECT *
		FROM #tblTempOrphaned3
		DROP TABLE #tblTempOrphaned3
	END
	IF OBJECT_ID('tempdb..#tblTempOrphaned3') IS NOT NULL DROP TABLE #tblTempOrphaned3


	DECLARE @Rows3 INT = NULL
	SET @Rows3 = (SELECT COUNT(*) FROM #tblTempOrphaned5)

	IF(@Rows3 > 0)
	BEGIN
		SELECT *
		FROM #tblTempOrphaned5
		DROP TABLE #tblTempOrphaned5
	END
	IF OBJECT_ID('tempdb..#tblTempOrphaned5') IS NOT NULL DROP TABLE #tblTempOrphaned5
	
END	
ELSE 
BEGIN
	SELECT @command = 
	'USE [?]
	BEGIN
		INSERT INTO #tblTempOrphaned2
		SELECT DISTINCT @@SERVERNAME, ''?'' as DatabaseName, dp.name AS [User], dp.sid, dp.type_desc, dp.authentication_type_desc, ''['' + dp.name + ''] is an orphaned user in the ['' + ''?'' +  ''] database.'' + '' This means that they do not have a corresponding server login. The orphaned user should be repaired or dropped.'' AS [Report], ''CREATE LOGIN ['' + dp.name + ''] WITH PASSWORD = '''' '''' / FROM WINDOWS '' + '' USE ['' + ''?'' + ''] ALTER USER ['' + dp.name + ''] WITH Login = ['' + dp.name + '']''as [repair_orphaned_user], ''USE ['' + ''?'' + ''] DROP USER ['' + dp.name + '']'' as [drop_orphaned_user]
		FROM sys.database_principals AS dp
		LEFT JOIN sys.server_principals AS sp
		on dp.sid = sp.sid
		WHERE
		sp.sid IS NULL
		and dp.authentication_type_desc in (''INSTANCE'', ''WINDOWS'')
		and dp.type_desc in (''SQL_USER'', ''WINDOWS_GROUP'', ''WINDOWS_USER'')

		INSERT INTO #tblTempOrphaned4
		SELECT ''USE '' + ''['' + ''?'' + ''] '' + ''EXEC sp_change_users_login ''' + '''UPDATE_ONE''' + ''','''''' + dp.name + '''''','''''' + sp.name + '''''''' AS [link_to_existing_login]
		FROM sys.database_principals AS dp
		LEFT JOIN sys.server_principals AS sp
		on dp.sid <> sp.sid
		and dp.name COLLATE DATABASE_DEFAULT = sp.name COLLATE DATABASE_DEFAULT
		where dp.is_fixed_role = 0 and sp.is_fixed_role = 0
		and dp.authentication_type_desc in (''INSTANCE'', ''WINDOWS'')
		and dp.type_desc in (''SQL_USER'', ''WINDOWS_GROUP'', ''WINDOWS_USER'')

		INSERT INTO #tblTempOrphaned6
		SELECT dp.name AS [DB User], s.name AS [Schema], ''USE ['' + ''?'' + ''] ALTER AUTHORIZATION ON SCHEMA::['' + s.name + ''] TO [dbo]'' AS AlterAuthorization
		FROM sys.database_principals AS dp
		JOIN sys.schemas s ON s.principal_id = dp.principal_id
		LEFT JOIN sys.server_principals AS sp
		on dp.sid = sp.sid
		WHERE
		sp.sid IS NULL
		and dp.authentication_type_desc in (''INSTANCE'', ''WINDOWS'')
		and dp.type_desc in (''SQL_USER'', ''WINDOWS_GROUP'', ''WINDOWS_USER'')
		and s.name <> ''dbo''
	END'



	IF OBJECT_ID('tempdb..#tblTempOrphaned2') IS NOT NULL DROP TABLE #tblTempOrphaned2
	IF OBJECT_ID('tempdb..#tblTempOrphaned4') IS NOT NULL DROP TABLE #tblTempOrphaned4
	IF OBJECT_ID('tempdb..#tblTempOrphaned6') IS NOT NULL DROP TABLE #tblTempOrphaned6
	CREATE TABLE #tblTempOrphaned2 ([ComputerName] varchar (100),  [DatabaseName] varchar(100), [User] varchar(100), [sid] varbinary(100), [type_desc] varchar(100), [authentication_type_desc] varchar(100), [Report] varchar (300), [repair_orphaned_user] varchar(200), [drop_orphaned_user] varchar(200))
	CREATE TABLE #tblTempOrphaned4 ([link_to_existing_login] varchar(200))
	CREATE TABLE #tblTempOrphaned6 ([DB User] varchar(100), [Schema] varchar (100), [AlterAuthorization] varchar (200))
	--EXEC sp_MSforeachdb @command
	EXEC sp_MSforeachdb @command
	DELETE FROM #tblTempOrphaned2
	WHERE [User] = 'dbo'
	SELECT *
	FROM #tblTempOrphaned2
	ORDER BY DatabaseName
	DROP TABLE #tblTempOrphaned2

	DECLARE @Rows2 INT = NULL
	SET @Rows2 = (SELECT COUNT(*) FROM #tblTempOrphaned4)

	IF(@Rows2 > 0)
	BEGIN
		SELECT *
		FROM #tblTempOrphaned4
		DROP TABLE #tblTempOrphaned4
	END
	IF OBJECT_ID('tempdb..#tblTempOrphaned4') IS NOT NULL DROP TABLE #tblTempOrphaned4

	DECLARE @Rows4 INT = NULL
	SET @Rows4 = (SELECT COUNT(*) FROM #tblTempOrphaned6)

	IF(@Rows4 > 0)
	BEGIN
		SELECT *
		FROM #tblTempOrphaned6
		DROP TABLE #tblTempOrphaned6
	END
	IF OBJECT_ID('tempdb..#tblTempOrphaned6') IS NOT NULL DROP TABLE #tblTempOrphaned6
END


	

END
