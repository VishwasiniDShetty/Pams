﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-139cbcb8-7112-4c6c-9ba7-83c20b169497]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-139cbcb8-7112-4c6c-9ba7-83c20b169497] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-139cbcb8-7112-4c6c-9ba7-83c20b169497]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-139cbcb8-7112-4c6c-9ba7-83c20b169497] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-139cbcb8-7112-4c6c-9ba7-83c20b169497') > 0)   DROP SERVICE [SqlQueryNotificationService-139cbcb8-7112-4c6c-9ba7-83c20b169497]; if (OBJECT_ID('SqlQueryNotificationService-139cbcb8-7112-4c6c-9ba7-83c20b169497', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-139cbcb8-7112-4c6c-9ba7-83c20b169497]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-139cbcb8-7112-4c6c-9ba7-83c20b169497]; END COMMIT TRANSACTION; END