﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-496e0bc6-440d-4f26-9487-dd4eacb165ed]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-496e0bc6-440d-4f26-9487-dd4eacb165ed] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-496e0bc6-440d-4f26-9487-dd4eacb165ed]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-496e0bc6-440d-4f26-9487-dd4eacb165ed] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-496e0bc6-440d-4f26-9487-dd4eacb165ed') > 0)   DROP SERVICE [SqlQueryNotificationService-496e0bc6-440d-4f26-9487-dd4eacb165ed]; if (OBJECT_ID('SqlQueryNotificationService-496e0bc6-440d-4f26-9487-dd4eacb165ed', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-496e0bc6-440d-4f26-9487-dd4eacb165ed]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-496e0bc6-440d-4f26-9487-dd4eacb165ed]; END COMMIT TRANSACTION; END