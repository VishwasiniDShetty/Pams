﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-a62ebb2e-9e63-479f-bebc-61608e0d03e7]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-a62ebb2e-9e63-479f-bebc-61608e0d03e7] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-a62ebb2e-9e63-479f-bebc-61608e0d03e7]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-a62ebb2e-9e63-479f-bebc-61608e0d03e7] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-a62ebb2e-9e63-479f-bebc-61608e0d03e7') > 0)   DROP SERVICE [SqlQueryNotificationService-a62ebb2e-9e63-479f-bebc-61608e0d03e7]; if (OBJECT_ID('SqlQueryNotificationService-a62ebb2e-9e63-479f-bebc-61608e0d03e7', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-a62ebb2e-9e63-479f-bebc-61608e0d03e7]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-a62ebb2e-9e63-479f-bebc-61608e0d03e7]; END COMMIT TRANSACTION; END