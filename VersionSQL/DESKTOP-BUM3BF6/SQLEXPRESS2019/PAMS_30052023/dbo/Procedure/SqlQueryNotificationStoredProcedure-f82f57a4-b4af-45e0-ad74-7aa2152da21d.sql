﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-f82f57a4-b4af-45e0-ad74-7aa2152da21d]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-f82f57a4-b4af-45e0-ad74-7aa2152da21d] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-f82f57a4-b4af-45e0-ad74-7aa2152da21d]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-f82f57a4-b4af-45e0-ad74-7aa2152da21d] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-f82f57a4-b4af-45e0-ad74-7aa2152da21d') > 0)   DROP SERVICE [SqlQueryNotificationService-f82f57a4-b4af-45e0-ad74-7aa2152da21d]; if (OBJECT_ID('SqlQueryNotificationService-f82f57a4-b4af-45e0-ad74-7aa2152da21d', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-f82f57a4-b4af-45e0-ad74-7aa2152da21d]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-f82f57a4-b4af-45e0-ad74-7aa2152da21d]; END COMMIT TRANSACTION; END
