﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-f0fb3d82-b5fc-4d58-8358-054886592759]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-f0fb3d82-b5fc-4d58-8358-054886592759] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-f0fb3d82-b5fc-4d58-8358-054886592759]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-f0fb3d82-b5fc-4d58-8358-054886592759] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-f0fb3d82-b5fc-4d58-8358-054886592759') > 0)   DROP SERVICE [SqlQueryNotificationService-f0fb3d82-b5fc-4d58-8358-054886592759]; if (OBJECT_ID('SqlQueryNotificationService-f0fb3d82-b5fc-4d58-8358-054886592759', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-f0fb3d82-b5fc-4d58-8358-054886592759]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-f0fb3d82-b5fc-4d58-8358-054886592759]; END COMMIT TRANSACTION; END
