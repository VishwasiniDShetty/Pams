﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-b9ed24b6-0e51-4052-a7e2-f76faf919981]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-b9ed24b6-0e51-4052-a7e2-f76faf919981] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-b9ed24b6-0e51-4052-a7e2-f76faf919981]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-b9ed24b6-0e51-4052-a7e2-f76faf919981] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-b9ed24b6-0e51-4052-a7e2-f76faf919981') > 0)   DROP SERVICE [SqlQueryNotificationService-b9ed24b6-0e51-4052-a7e2-f76faf919981]; if (OBJECT_ID('SqlQueryNotificationService-b9ed24b6-0e51-4052-a7e2-f76faf919981', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-b9ed24b6-0e51-4052-a7e2-f76faf919981]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-b9ed24b6-0e51-4052-a7e2-f76faf919981]; END COMMIT TRANSACTION; END
