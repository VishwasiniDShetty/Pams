﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-4fe46544-e48c-47b1-9aac-1a8ea1443004]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-4fe46544-e48c-47b1-9aac-1a8ea1443004] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-4fe46544-e48c-47b1-9aac-1a8ea1443004]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-4fe46544-e48c-47b1-9aac-1a8ea1443004] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-4fe46544-e48c-47b1-9aac-1a8ea1443004') > 0)   DROP SERVICE [SqlQueryNotificationService-4fe46544-e48c-47b1-9aac-1a8ea1443004]; if (OBJECT_ID('SqlQueryNotificationService-4fe46544-e48c-47b1-9aac-1a8ea1443004', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-4fe46544-e48c-47b1-9aac-1a8ea1443004]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-4fe46544-e48c-47b1-9aac-1a8ea1443004]; END COMMIT TRANSACTION; END