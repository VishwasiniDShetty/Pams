﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-cc5cac02-92f8-4632-914d-b9aabed9a769]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-cc5cac02-92f8-4632-914d-b9aabed9a769] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-cc5cac02-92f8-4632-914d-b9aabed9a769]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-cc5cac02-92f8-4632-914d-b9aabed9a769] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-cc5cac02-92f8-4632-914d-b9aabed9a769') > 0)   DROP SERVICE [SqlQueryNotificationService-cc5cac02-92f8-4632-914d-b9aabed9a769]; if (OBJECT_ID('SqlQueryNotificationService-cc5cac02-92f8-4632-914d-b9aabed9a769', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-cc5cac02-92f8-4632-914d-b9aabed9a769]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-cc5cac02-92f8-4632-914d-b9aabed9a769]; END COMMIT TRANSACTION; END