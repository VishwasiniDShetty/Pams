﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-c2796cf2-d083-4a29-8daf-e87efc0d52a2]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-c2796cf2-d083-4a29-8daf-e87efc0d52a2] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-c2796cf2-d083-4a29-8daf-e87efc0d52a2]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-c2796cf2-d083-4a29-8daf-e87efc0d52a2] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-c2796cf2-d083-4a29-8daf-e87efc0d52a2') > 0)   DROP SERVICE [SqlQueryNotificationService-c2796cf2-d083-4a29-8daf-e87efc0d52a2]; if (OBJECT_ID('SqlQueryNotificationService-c2796cf2-d083-4a29-8daf-e87efc0d52a2', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-c2796cf2-d083-4a29-8daf-e87efc0d52a2]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-c2796cf2-d083-4a29-8daf-e87efc0d52a2]; END COMMIT TRANSACTION; END
