﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-87bafee5-acf1-4fdd-a3bf-6f5a3601dcf1]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-87bafee5-acf1-4fdd-a3bf-6f5a3601dcf1] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-87bafee5-acf1-4fdd-a3bf-6f5a3601dcf1]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-87bafee5-acf1-4fdd-a3bf-6f5a3601dcf1] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-87bafee5-acf1-4fdd-a3bf-6f5a3601dcf1') > 0)   DROP SERVICE [SqlQueryNotificationService-87bafee5-acf1-4fdd-a3bf-6f5a3601dcf1]; if (OBJECT_ID('SqlQueryNotificationService-87bafee5-acf1-4fdd-a3bf-6f5a3601dcf1', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-87bafee5-acf1-4fdd-a3bf-6f5a3601dcf1]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-87bafee5-acf1-4fdd-a3bf-6f5a3601dcf1]; END COMMIT TRANSACTION; END
