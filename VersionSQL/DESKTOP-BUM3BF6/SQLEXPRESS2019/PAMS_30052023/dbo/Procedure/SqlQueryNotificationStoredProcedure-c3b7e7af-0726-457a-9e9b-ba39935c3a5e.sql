﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-c3b7e7af-0726-457a-9e9b-ba39935c3a5e]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-c3b7e7af-0726-457a-9e9b-ba39935c3a5e] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-c3b7e7af-0726-457a-9e9b-ba39935c3a5e]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-c3b7e7af-0726-457a-9e9b-ba39935c3a5e] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-c3b7e7af-0726-457a-9e9b-ba39935c3a5e') > 0)   DROP SERVICE [SqlQueryNotificationService-c3b7e7af-0726-457a-9e9b-ba39935c3a5e]; if (OBJECT_ID('SqlQueryNotificationService-c3b7e7af-0726-457a-9e9b-ba39935c3a5e', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-c3b7e7af-0726-457a-9e9b-ba39935c3a5e]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-c3b7e7af-0726-457a-9e9b-ba39935c3a5e]; END COMMIT TRANSACTION; END
