﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-ea1bc3ce-4a73-4f39-9a73-87376e503916]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-ea1bc3ce-4a73-4f39-9a73-87376e503916] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-ea1bc3ce-4a73-4f39-9a73-87376e503916]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-ea1bc3ce-4a73-4f39-9a73-87376e503916] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-ea1bc3ce-4a73-4f39-9a73-87376e503916') > 0)   DROP SERVICE [SqlQueryNotificationService-ea1bc3ce-4a73-4f39-9a73-87376e503916]; if (OBJECT_ID('SqlQueryNotificationService-ea1bc3ce-4a73-4f39-9a73-87376e503916', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-ea1bc3ce-4a73-4f39-9a73-87376e503916]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-ea1bc3ce-4a73-4f39-9a73-87376e503916]; END COMMIT TRANSACTION; END