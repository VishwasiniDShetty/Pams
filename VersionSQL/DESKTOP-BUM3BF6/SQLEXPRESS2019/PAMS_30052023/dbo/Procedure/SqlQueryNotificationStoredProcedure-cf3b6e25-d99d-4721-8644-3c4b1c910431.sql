﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-cf3b6e25-d99d-4721-8644-3c4b1c910431]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-cf3b6e25-d99d-4721-8644-3c4b1c910431] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-cf3b6e25-d99d-4721-8644-3c4b1c910431]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-cf3b6e25-d99d-4721-8644-3c4b1c910431] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-cf3b6e25-d99d-4721-8644-3c4b1c910431') > 0)   DROP SERVICE [SqlQueryNotificationService-cf3b6e25-d99d-4721-8644-3c4b1c910431]; if (OBJECT_ID('SqlQueryNotificationService-cf3b6e25-d99d-4721-8644-3c4b1c910431', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-cf3b6e25-d99d-4721-8644-3c4b1c910431]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-cf3b6e25-d99d-4721-8644-3c4b1c910431]; END COMMIT TRANSACTION; END