﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-37de4e96-36da-43c2-9d9a-6210fbe38666]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-37de4e96-36da-43c2-9d9a-6210fbe38666] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-37de4e96-36da-43c2-9d9a-6210fbe38666]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-37de4e96-36da-43c2-9d9a-6210fbe38666] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-37de4e96-36da-43c2-9d9a-6210fbe38666') > 0)   DROP SERVICE [SqlQueryNotificationService-37de4e96-36da-43c2-9d9a-6210fbe38666]; if (OBJECT_ID('SqlQueryNotificationService-37de4e96-36da-43c2-9d9a-6210fbe38666', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-37de4e96-36da-43c2-9d9a-6210fbe38666]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-37de4e96-36da-43c2-9d9a-6210fbe38666]; END COMMIT TRANSACTION; END